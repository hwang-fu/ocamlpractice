(** Tower of Hanoi solver. Pegs are numbered 0, 1, 2. *)

(** A move [(src, dst)] carries the top disc of peg [src] onto peg [dst]. *)
type move = int * int

(** [solve n] is the sequence of [2^n - 1] moves that legally carries [n]
    discs from peg 0 to peg 2, using peg 1 as scratch. *)
val solve : int -> move list
