(** A cooperative scheduler: tasks on one core, interleaving wherever
    they explicitly pause. *)

(** [run main] runs [main] and every task it spawns, and returns once all
    of them have finished. This is the only entry point: [spawn] and
    [yield] work only inside a computation started by [run]; performed
    elsewhere they raise [Effect.Unhandled]. *)
val run : (unit -> unit) -> unit

(** [spawn f] registers [f] as a new task. The scheduler is child first:
    the current task pauses, [f] runs immediately, and the paused parent
    resumes when a running task next finishes or yields. *)
val spawn : (unit -> unit) -> unit

(** [yield ()] pauses the current task, moving it to the back of the run
    queue, and lets the task at the front run. With no other task
    waiting, the current task just continues. *)
val yield : unit -> unit
