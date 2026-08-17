(** Memoized infinite streams.

    A stream always has a head and a suspended rest; there is no empty
    case. Suspensions are [Lazy.t], so every cell is computed at most once
    however many times the stream is traversed. This is the difference
    from the stdlib's [Seq.t], whose thunks re-run per traversal. *)

type 'a t = Cons of 'a * 'a t Lazy.t

(** [head s] is the first element, at no cost. *)
val head : 'a t -> 'a

(** [tail s] forces one step of the stream (memoized). *)
val tail : 'a t -> 'a t

(** [take n s] is the list of the first [n] elements ([] for [n <= 0]). *)
val take : int -> 'a t -> 'a list

(** [map f s] applies [f] elementwise, lazily. *)
val map : ('a -> 'b) -> 'a t -> 'b t

(** [filter p s] keeps the elements satisfying [p]. Diverges when the
    stream stops producing satisfying elements. *)
val filter : ('a -> bool) -> 'a t -> 'a t

(** [zip_with f s1 s2] combines two streams elementwise. *)
val zip_with : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t

(** [iterate f x] is the stream [x], [f x], [f (f x)], ... *)
val iterate : ('a -> 'a) -> 'a -> 'a t

(** [merge s1 s2] merges two strictly ascending streams, dropping
    duplicates. Behavior on unsorted input is unspecified. *)
val merge : 'a t -> 'a t -> 'a t

(** [to_seq s] views the stream as a stdlib sequence. *)
val to_seq : 'a t -> 'a Seq.t

(** [of_seq s] converts an infinite sequence; raises [Invalid_argument]
    if the sequence ends. *)
val of_seq : 'a Seq.t -> 'a t

(** 0, 1, 2, 3, ... *)
val nats : int t

(** 0, 1, 1, 2, 3, 5, 8, ... (beware of silent [int] overflow near
    the 91st element) *)
val fibs : int t

(** 2, 3, 5, 7, 11, ... by the lazy sieve. *)
val primes : int t

(** 1, 2, 3, 4, 5, 6, 8, 9, 10, 12, ... the numbers whose only prime
    factors are 2, 3 and 5. *)
val hamming : int t
