(** Generators: write an imperative producer, consume it as a lazy
    sequence. *)

(** [to_seq producer] is the sequence of values that [producer] passes to
    its [yield] argument. The producer does not run ahead of the
    consumer: asking for one element runs it exactly up to its next
    [yield], where it pauses until the following element is asked for.

    Sharing caution. Walking the sequence again from its head simply
    restarts the producer from the beginning, running its side effects a
    second time. Pulling the {e same} already-pulled node twice, however,
    would resume a one-shot continuation twice and raises
    [Effect.Continuation_already_resumed]. Wrapping the sequence in
    [Seq.memoize] removes both hazards: every node is computed once and
    cached, so repeated walks are safe and the producer runs once. *)
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
