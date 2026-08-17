(* Generators from effect handlers; the concepts are in README.md. *)

open Effect
open Effect.Deep

(* Runs the producer under an effect handler. Each time the producer
   calls yield, the handler pauses it and hands the consumer one sequence
   element; asking for the next element resumes the paused producer.
   Usage and the single-walk warning are in the mli. *)
let to_seq (type elt) (producer : (elt -> unit) -> unit) : elt Seq.t =
  (* The effect is declared locally so that its payload has this exact
     call's element type. One shared polymorphic Yield would forget the
     type of what it carries, and the handler could not use it. *)
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

(* a binary tree with values at the leaves *)
type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

(* Walks the tree left to right and yields the value at every leaf. The
   walk itself is ordinary recursion; the generator machinery takes care
   of pausing it between leaves. *)
let fringe t =
  to_seq (fun yield ->
    let rec walk = function
      | Leaf x -> yield x
      | Node (l, r) ->
        walk l;
        walk r
    in
    walk t)
;;

(* Compares the leaf values of the two trees pair by pair, advancing
   both walks together and stopping at the first difference. *)
let same_fringe t1 t2 = Seq.equal ( = ) (fringe t1) (fringe t2)
