(** Closed knight's tour search. *)

(** A board square [(x, y)], both coordinates in [0, n-1]. *)
type square = int * int

(** [closed_tour ?warnsdorff n] is a closed knight's tour of the [n x n]
    board: the [n * n] squares in visiting order, starting at [(0, 0)],
    each a knight's move from its predecessor, the last a knight's move
    from the first. [None] exactly when no closed tour exists (odd [n] or
    [n < 6]) -- answered by theorem, without searching.

    With [warnsdorff] (default [true]) the search uses Warnsdorff's rule:
    greedy random-tie descents retried until one closes (near linear per
    attempt; the global [Random] state is drawn on, seed with [Random.init]
    for reproducibility), except on the special-cased [6 x 6] board, where
    descents almost never close and a deterministic Warnsdorff-ordered
    exhaustive search wins instead. Practical up to roughly [n = 20]
    (seconds); beyond that, closing descents become rare and the wait
    grows quickly.

    With [~warnsdorff:false] the search is exhaustive fixed-order
    backtracking: deterministic and guaranteed, but exponential -- [6 x 6]
    already takes on the order of a minute, larger boards are out of
    reach. *)
val closed_tour : ?warnsdorff:bool -> int -> square list option
