(** Generators: push-style producers consumed as pull-style sequences. *)

(** [to_seq producer] is the lazy sequence of values that [producer]
    passes to its [yield] argument, produced on demand: the producer runs
    exactly as far as the consumer pulls, frozen mid-flight in between.

    The sequence is {b single-traversal}: it resumes one-shot
    continuations, so walking it a second time raises
    [Effect.Continuation_already_resumed]. Wrap it in [Seq.memoize] to
    make it re-traversable. *)
val to_seq : (('a -> unit) -> unit) -> 'a Seq.t
