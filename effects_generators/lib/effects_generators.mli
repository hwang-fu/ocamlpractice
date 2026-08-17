(** Generators: push-style producers consumed as pull-style sequences. *)

(** [to_seq producer] is the lazy sequence of values that [producer]
    passes to its [yield] argument, produced on demand: the producer runs
    exactly as far as the consumer pulls, frozen mid-flight in between.

    The sequence is {b single-traversal}: it resumes one-shot
    continuations, so walking it a second time raises
    [Effect.Continuation_already_resumed]. Wrap it in [Seq.memoize] to
    make it re-traversable. *)
val to_seq : (('a -> unit) -> unit) -> 'a Seq.t

(** A binary tree with values at the leaves. *)
type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

(** [fringe t] is the leaves of [t], left to right, on demand.
    Single-traversal, like every {!to_seq} result. *)
val fringe : 'a tree -> 'a Seq.t

(** [same_fringe t1 t2] is whether the two trees hold the same leaves in
    the same left-to-right order, whatever their shapes. The walks run in
    lockstep and stop at the first difference. *)
val same_fringe : 'a tree -> 'a tree -> bool
