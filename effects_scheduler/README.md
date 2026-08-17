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
Scheduler.run (fun () ->
  Scheduler.spawn (fun () ->
    for i = 1 to 3 do
      Printf.printf "task A step %d\n" i;
      Scheduler.yield ()          (* politely let someone else run *)
    done);
  Scheduler.spawn (fun () ->
    for i = 1 to 3 do
      Printf.printf "task B step %d\n" i;
      Scheduler.yield ()
    done))
```

Expected output: the A and B lines interleave (A1 B1 A2 B2 A3 B3), even
though there is no threading anywhere. Each `yield ()` performs an
effect; the handler stores the task's continuation at the back of the
run queue and resumes whatever is at the front.

The three operations, each one effect:

- `spawn f` puts a new task on the queue ("run this too, when there is
  time")
- `yield ()` pauses the current task, letting others run
- `await p` pauses the current task until a promise `p` is filled, the
  seed of async/await (stretch goal: promises + `async` returning them)

## Why "cooperative"

Nothing ever interrupts a task; it runs until it *chooses* to pause.
Forget to yield inside a long loop and every other task starves. That
weakness is also the model's strength: between pauses you can never be
preempted, so there are no data races and no locks. Understanding this
trade is understanding most of async programming.

## What we will produce

- `lib`: the `Fork` / `Yield` effects, the run-queue scheduler loop, and
  (stretch) promises with `async` / `await`
- `test`: interleaving order captured in a buffer and asserted, spawn
  inside spawn, starvation demo, await resolution order
- `bin`: demo programs printing interleaved task output

## Concepts covered

- a queue of stored continuations as program state
- the scheduler loop: the handler IS the runtime
- spawn / yield / await semantics; cooperative vs preemptive trade-offs
- how async/await desugars to effects underneath real libraries
