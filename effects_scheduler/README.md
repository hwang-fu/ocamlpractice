# effects_scheduler

Quiz B of the effect-handlers pair. Read `effects_generators/README.md`
first: this quiz assumes you know what `perform`, a handler, and a stored
continuation are.

## The idea in one paragraph

Quiz A stored **one** paused computation and resumed it on demand. Now
store **many**. Keep a queue of paused computations, run one until it
pauses itself, put it at the back of the queue, run the next. That loop
has a name: a **cooperative scheduler**, and the paused computations are
its tasks. This is concurrency without threads: one core, no locks, tasks
interleaving wherever they explicitly pause. It is also, not by accident,
how OCaml's modern async libraries work under the hood; this quiz builds
a miniature of them from nothing but effects.

## What the API will feel like

```ocaml
Effects_scheduler.run (fun () ->
  Effects_scheduler.spawn (fun () ->
    for i = 1 to 3 do
      Printf.printf "task A step %d\n" i;
      Effects_scheduler.yield ()          (* politely let someone else run *)
    done);
  Effects_scheduler.spawn (fun () ->
    for i = 1 to 3 do
      Printf.printf "task B step %d\n" i;
      Effects_scheduler.yield ()
    done))
```

Expected output: the A and B lines interleave (A1 B1 A2 B2 A3 B3), even
though there is no threading anywhere. Each `yield ()` performs an
effect; the handler stores the task's continuation at the back of the
run queue and resumes whatever is at the front.

The four operations, each one effect:

- `spawn f` starts `f` as a new task, child first: it runs immediately
  and the spawner pauses until a running task finishes or yields
- `yield ()` pauses the current task, letting others run
- `async f` starts `f` like `spawn` and returns the promise of its
  result
- `await p` gives the promise's value: immediately if it is already
  fulfilled, otherwise the current task pauses until the promise's task
  finishes; any number of tasks may wait on one promise

## Why "cooperative"

Nothing ever interrupts a task; it runs until it *chooses* to pause.
Forget to yield inside a long loop and every other task starves. That
weakness is also the model's strength: between pauses you can never be
preempted, so there are no data races and no locks. Understanding this
trade is understanding most of async programming.

## What we produced

- `lib`: the `Yield` / `Fork` / `Async` / `Await` effects and the
  scheduler loop over a queue of resumption thunks (a thunk bakes in
  whatever value its paused task is waiting for, so one queue carries
  differently-typed pauses)
- `test`: exact interleaving orders captured in a buffer and asserted,
  the never-yielding starvation case, await before and after
  fulfillment, several waiters on one promise
- `bin`: demo programs printing live interleaved task output

## Concepts covered

- a queue of stored continuations as program state
- the scheduler loop: the handler IS the runtime
- spawn / yield / async / await semantics; cooperative versus preemptive
  trade-offs
- how async/await desugars to effects underneath real libraries
- polymorphic recursion (`let rec exec : type r. ...`), needed because
  one task runner serves tasks of every result type
