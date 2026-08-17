(* A cooperative scheduler built from effect handlers; the concepts are
   in README.md. *)

open Effect
open Effect.Deep

type _ Effect.t += Yield : unit Effect.t
type _ Effect.t += Fork : (unit -> unit) -> unit Effect.t

(* Runs the main task and every task it spawns, until all are finished.
   The run queue holds the paused tasks as continuations; the handler
   decides who runs next. *)
let run main =
  let queue : (unit, unit) continuation Queue.t = Queue.create () in
  (* Runs the next paused task, or returns when nothing is left to do. *)
  let run_next () = if Queue.is_empty queue then () else continue (Queue.pop queue) () in
  (* Runs one task under the scheduling handler. Every task gets its own
     handler this way, but they all share the one queue. *)
  let rec exec task =
    match_with
      task
      ()
      { retc = run_next (* this task finished: schedule the next one *)
      ; exnc = raise
      ; effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Yield ->
              Some
                (fun (k : (a, _) continuation) ->
                  (* pause the yielder at the back of the queue and let
                     the front of the queue run *)
                  Queue.push k queue;
                  run_next ())
            | Fork f ->
              Some
                (fun (k : (a, _) continuation) ->
                  (* child-first policy: pause the parent, run the new
                     task immediately *)
                  Queue.push k queue;
                  exec f)
            | _ -> None)
      }
  in
  exec main
;;

let yield () = perform Yield
let spawn f = perform (Fork f)
