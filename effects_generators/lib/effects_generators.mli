(** Generators: write an imperative producer, consume it as a lazy
    sequence. *)

(** [to_seq producer] is the sequence of values that [producer] passes to
    its [yield] argument. The producer does not run ahead of the
    consumer: asking for one element runs it exactly up to its next
    [yield], where it pauses until the following element is asked for.

    The resulting sequence can be walked only once; a second walk raises
    [Effect.Continuation_already_resumed]. Wrap the sequence in
    [Seq.memoize] if you need to walk it several times. *)
val to_seq : (('a -> unit) -> unit) -> 'a Seq.t

(** A binary tree that stores a value at every leaf and nothing at the
    inner nodes. *)
type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

(** [fringe t] is the sequence of values stored at the leaves of [t],
    from the leftmost leaf to the rightmost. The tree is walked on
    demand, only as far as the consumer asks, and the sequence can be
    walked only once, like every sequence built by {!to_seq}. *)
val fringe : 'a tree -> 'a Seq.t

(** [same_fringe t1 t2] is [true] exactly when the two trees store the
    same leaf values in the same left-to-right order, whatever their
    shapes. The two walks advance together, one leaf at a time, and stop
    as soon as a difference is found. *)
val same_fringe : 'a tree -> 'a tree -> bool
