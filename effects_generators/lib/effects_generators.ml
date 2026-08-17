(* Generators from effect handlers; the concepts are in README.md. *)

open Effect
open Effect.Deep

(* [to_seq producer] turns each [yield x] of the producer into one lazy
   sequence node; the paused producer rides in the node's tail. Single
   traversal only: see the mli. *)
let to_seq (type elt) (producer : (elt -> unit) -> unit) : elt Seq.t =
  (* a local effect, so the payload type is this call's [elt]; a global
     polymorphic [Yield] would forget its payload type *)
  let module M = struct
    type _ Effect.t += Yield : elt -> unit Effect.t
  end
  in
  let yield = fun x -> perform (M.Yield x) in
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
