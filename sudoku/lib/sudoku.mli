(** Sudoku solver: constraint propagation plus MRV-guided search.

    A grid is an [int array] of length 81, row-major: cell [9 * row + col],
    digits [1..9], with [0] for an empty cell. *)

(** A constraint unit of the board. *)
type unit_kind =
  | Row of int
  | Col of int
  | Box of int

(** One event of the solving process, in order of occurrence. [Given],
    [Naked], [Hidden] and [Guess] carry the cell (0..80) and the digit
    placed there; [Hidden] also names the unit in which the digit had a
    single home. [Contradiction] carries the cell whose candidate set
    became empty; the following [Backtrack] rewinds to the most recent
    [Guess] and tries differently. *)
type step =
  | Given of int * int
  | Naked of int * int
  | Hidden of int * int * unit_kind
  | Guess of int * int
  | Contradiction of int
  | Backtrack

(** [cells_of u] is the nine cells of unit [u]. *)
val cells_of : unit_kind -> int list

(** [candidates grid c] is the digits no peer of [c] holds: the pencil
    marks of an empty cell. *)
val candidates : int array -> int -> int list

(** [parse s] reads the 81-character interchange format: digits, with ['.']
    or ['0'] for empty cells. *)
val parse : string -> (int array, string) result

(** [to_string grid] is the inverse of {!parse}, using ['.'] for empties. *)
val to_string : int array -> string

(** [solve grid] is the full reasoning trace together with the solved grid,
    or [None] if the puzzle admits no solution. When several solutions
    exist, one is returned. The trace is complete either way: replaying it
    (placements, guesses, backtracks) reproduces the solver's process. *)
val solve : int array -> step list * int array option
