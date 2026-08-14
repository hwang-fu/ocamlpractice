(** Drawing of the Koch snowflake in a Graphics window. All rendering
    parameters (window size, style, depth budget) are private to the
    implementation. *)

(** [depth_in_range depth] is whether [depth] fits the drawing budget. *)
val depth_in_range : int -> bool

(** Human-readable form of the accepted depth bounds, for error messages. *)
val depth_range : string

(** [run_with_depth depth] opens the window, draws the snowflake at
    [depth], and returns once a key is pressed or the window is closed. *)
val run_with_depth : int -> unit

(** [run_with_default_depth ()] is [run_with_depth] at the built-in default. *)
val run_with_default_depth : unit -> unit
