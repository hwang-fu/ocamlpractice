(* A cooperative scheduler built from effect handlers; the concepts are
   in README.md. *)

open Effect
open Effect.Deep

(* A promise is either fulfilled, or a list of the continuations paused
   on it, waiting for the value. *)
type 'a promise_state =
  | Done of 'a
  | Waiting of ('a, unit) continuation list

type 'a promise = 'a promise_state ref
type _ Effect.t += Yield : unit Effect.t
type _ Effect.t += Fork : (unit -> unit) -> unit Effect.t
type _ Effect.t += Async : (unit -> 'a) -> 'a promise Effect.t
type _ Effect.t += Await : 'a promise -> 'a Effect.t

(* Runs the main task and every task it spawns, until all are finished.
   The run queue holds the paused tasks as resumption thunks: a paused
   yielder resumes with (), a paused waiter resumes with the awaited
   value, and the thunk bakes the difference in. *)
let run main =
  let queue : (unit -> unit) Queue.t = Queue.create () in
  (* Runs the next paused task, or returns when nothing is left to do. *)
  let run_next () = if Queue.is_empty queue then () else (Queue.pop queue) () in
  (* Runs one task under the scheduling handler. Every task gets its own
     handler this way, but they all share the one queue. *)
  let rec exec : type r. (unit -> r) -> (r -> unit) -> unit =
    fun task on_done ->
    match_with
      task
      ()
      { retc = on_done
      ; exnc = raise
      ; effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Yield ->
              Some
                (fun (k : (a, _) continuation) ->
                  (* pause the yielder at the back of the queue and let
                     the front of the queue run *)
                  Queue.push (fun () -> continue k ()) queue;
                  run_next ())
            | Fork f ->
              Some
                (fun (k : (a, _) continuation) ->
                  (* child-first policy: pause the parent, run the new
                     task immediately *)
                  Queue.push (fun () -> continue k ()) queue;
                  exec f (fun () -> run_next ()))
            | Async f ->
              Some
                (fun (k : (a, _) continuation) ->
                  (* like Fork, but the child's result fulfills a promise
                     and wakes everyone paused on it *)
                  let p = ref (Waiting []) in
                  Queue.push (fun () -> continue k p) queue;
                  exec f (fun v ->
                    (match !p with
                     | Done _ -> assert false (* only this task fulfills [p] *)
                     | Waiting waiters ->
                       p := Done v;
                       List.iter
                         (fun w -> Queue.push (fun () -> continue w v) queue)
                         waiters);
                    run_next ()))
            | Await p ->
              Some
                (fun (k : (a, _) continuation) ->
                  match !p with
                  | Done v -> continue k v (* already fulfilled: no pause *)
                  | Waiting waiters ->
                    (* pause on the promise; fulfillment re-enqueues us *)
                    p := Waiting (k :: waiters);
                    run_next ())
            | _ -> None)
      }
  in
  exec main (fun () -> run_next ())
;;

let yield () = perform Yield
let spawn f = perform (Fork f)
let async f = perform (Async f)
let await p = perform (Await p)
