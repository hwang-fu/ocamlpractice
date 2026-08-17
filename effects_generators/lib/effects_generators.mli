(** Generators: write an imperative producer, consume it as a lazy
    sequence. *)

(** Build a sequence out of an imperative producer function.

    The producer receives a function, conventionally called [yield].
    Every value the producer passes to [yield] becomes the next element
    of the resulting sequence. The producer does not run ahead of the
    consumer: asking for one element runs it exactly up to its next
    [yield], where it pauses until the following element is asked for.

    Warning: the resulting sequence can be walked only once. Walking it
    a second time raises [Effect.Continuation_already_resumed]. If you
    need to walk it several times, wrap it in [Seq.memoize]. *)
val to_seq : (('a -> unit) -> unit) -> 'a Seq.t

(** A binary tree that stores a value at every leaf and nothing at the
    inner nodes. *)
type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

(** Hand out the values stored at the leaves of the tree, from the
    leftmost leaf to the rightmost, as an on-demand sequence: the tree
    is walked only as far as the consumer asks. Walkable once, like
    every sequence built by {!to_seq}. *)
val fringe : 'a tree -> 'a Seq.t

(** Check whether two trees store the same leaf values in the same
    left-to-right order, even when the tree shapes differ. The two trees
    are walked together, one leaf at a time, and the walk stops as soon
    as a difference is found. *)
val same_fringe : 'a tree -> 'a tree -> bool
