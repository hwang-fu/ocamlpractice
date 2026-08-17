(* Generators from effect handlers; the concepts are in README.md. *)

open Effect
open Effect.Deep

(* [to_seq producer] runs [producer yield] under a handler that turns
   every [yield x] into one node of a lazy sequence: the paused producer
   travels inside the node's tail, and pulling the tail resumes it.

   The [Yield] effect is declared locally, inside a local module, so its
   payload can be exactly this call's element type [elt]. A single global
   [Yield : 'a -> unit Effect.t] would make the payload existential: the
   handler would receive a value of forgotten type and could not build a
   typed sequence from it. Local module over a locally abstract type is
   the standard idiom for a type declaration that mentions [elt].

   The resulting sequence resumes one-shot continuations, so it may be
   traversed ONCE; wrap it in [Seq.memoize] if you need to walk it again
   (each node then caches, and each resumption happens exactly once). *)
let to_seq (type elt) (producer : (elt -> unit) -> unit) : elt Seq.t =
  let module M = struct
    type _ Effect.t += Yield : elt -> unit Effect.t
  end
  in
  let yield x = perform (M.Yield x) in
  fun () ->
    (* nothing has run before the consumer pulls this first node *)
    match_with
      producer
      yield
      { retc = (fun () -> Seq.Nil) (* producer finished: the sequence ends *)
      ; exnc = raise (* producer raised: let it escape to the consumer *)
      ; effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | M.Yield x ->
              Some
                (fun (k : (a, _) continuation) ->
                  (* the produced element becomes the node's head; the
                     paused producer [k] hides in its tail, resumed only
                     if the consumer pulls further *)
                  Seq.Cons (x, fun () -> continue k ()))
            | _ -> None)
      }
;;
