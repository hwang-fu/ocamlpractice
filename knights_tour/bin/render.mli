(** Animated rendering of a knight's tour. *)

(** [animate ~n tour] opens a window, draws the [n x n] board, animates the
    tour jump by jump with visit numbers (about 12 seconds in total, any
    size), highlights the closing move, and returns once a key is pressed
    or the window is closed. *)
val animate : n:int -> Knights_tour.square list -> unit
