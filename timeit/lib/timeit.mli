(** Execution-time measurement utilities. *)

(** [time f] runs [f ()] and returns the CPU time it consumed, in seconds.

    The measurement is user-space CPU time (the [tms_utime] field of
    [Unix.times]), not wall-clock time: sleeping or blocking on I/O counts
    for (almost) nothing. The underlying clock is coarse -- typically 10ms
    ticks -- so very short computations may measure as [0.]. *)
val time : (unit -> unit) -> float
