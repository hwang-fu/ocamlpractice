(** Tutor-mode rendering of a solving trace. *)

(** [run trace] opens a window and replays the trace on a board: givens
    appear rapidly, then each deduction is announced by highlighting its
    reason (the cell for a naked single, the whole unit for a hidden one),
    guesses are marked orange, contradictions flash red, and backtracking
    visibly rewinds the board. Returns once a key is pressed or the window
    is closed. *)
val run : Sudoku.step list -> unit
