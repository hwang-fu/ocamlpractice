(** Animated rendering of a knight's tour. *)

(** [animate ~n tour] opens a window, draws the [n x n] board, and animates
    the tour jump by jump: an arrow flies along each jump, visited squares
    are numbered, and the closing move is highlighted (about half a minute
    in total, any board size). Returns once a key is pressed or the window
    is closed. *)
val animate : n:int -> Knights_tour.square list -> unit
