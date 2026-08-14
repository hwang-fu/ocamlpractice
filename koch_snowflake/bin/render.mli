(** Drawing of the Koch snowflake in a Graphics window. All rendering
    parameters (window size, style, depth budget) are private to the
    implementation. *)

(** [depth_in_range depth] is whether [depth] fits the drawing budget. *)
val depth_in_range : int -> bool

(** [exit_invalid_depth arg] prints an error naming the accepted depth range
    and the offending argument, then exits with a nonzero code. *)
val exit_invalid_depth : string -> 'a

(** [run ?depth ()] opens the window, draws the snowflake ([depth] defaults
    to a built-in value), and returns once a key is pressed or the window is
    closed. *)
val run : ?depth:int -> unit -> unit
