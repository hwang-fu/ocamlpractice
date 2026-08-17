# effects_generators

Quiz A of the effect-handlers pair. Read this first; the scheduler quiz
builds on everything here.

## What is an effect handler?

Start from something familiar. An exception jumps out of a computation:

```ocaml
exception Need_input
let compute () = 1 + raise Need_input   (* control leaves; the "1 +" is lost *)
```

Once an exception is caught, the interrupted computation is gone forever.
The handler cannot say "fine, the input is 42, please carry on with the
addition".

An **effect** is exactly that, but resumable. Three ingredients, then a
timeline of how they run.

**Ingredient 1: declare the effect.** This extends the open type
`Effect.t` with a new constructor, the same mechanism `exception`
declarations use to extend `exn`. The `int` is the answer type: what a
`perform` of this effect will evaluate to once the handler answers.

```ocaml
open Effect
open Effect.Deep

type _ Effect.t += Need_input : int Effect.t
```

**Ingredient 2: perform it.** Like `raise`, but the expression has a
value, of the answer type:

```ocaml
let compute () = 1 + perform Need_input    (* perform ... : int *)
```

**Ingredient 3: handle it.** `try_with compute () handler` runs
`compute ()` under supervision. The handler's `effc` field is asked
about every effect performed inside; it answers `Some f` for "mine,
here is what to do" or `None` for "not mine, pass it outward":

```ocaml
let result =
  try_with compute ()
    { effc =
        (fun (type a) (eff : a Effect.t) ->
           match eff with
           | Need_input ->
             Some (fun (k : (a, _) continuation) -> continue k 42)
           | _ -> None)
    }
(* result = 43 *)
```

**The timeline**, the part that matters:

1. `try_with` starts running `compute ()`.
2. `compute` reaches `1 + perform Need_input`; to add, it needs the
   right operand first.
3. `perform` freezes `compute` on the spot. The frozen rest, "compute
   `1 + hole`, then return", is packaged as a value: the
   **continuation** `k`.
4. The handler's `effc` receives `Need_input` and answers with a
   function; that function receives `k`.
5. `continue k 42` thaws the computation: the `perform` expression
   itself evaluates to 42, the addition runs, `compute` returns 43,
   and 43 becomes the value of the whole `try_with`.

Between steps 3 and 5, `compute` exists only as the value `k`, going
nowhere. The handler chose to resume immediately, but it has options:
drop `k` (the effect then acts like an exception) or **store `k`
somewhere and resume it much later**. Storing continuations is the door
everything else in these two quizzes walks through.

Two more things and the toolbox is complete:

- `match_with` is the full-dress version of `try_with`: besides `effc`
  it takes `retc` (called on a normal finish, letting you transform the
  result) and `exnc` (called on an exception). We will need `retc` in
  this quiz, since turning a finished producer into an empty sequence is
  precisely a "transform the normal result" job.
- A continuation is **one-shot**: each `k` may be continued at most
  once; a second resume is a runtime error.

The odd `(type a)` annotation in the handler is a typing formality (the
handler must be ready for effects of every answer type; matching
`Need_input` teaches the compiler that this `a` is `int`). Read past it
for now; it will make sense hands-on.

## What this quiz builds

A **generator** library: the ability to write an ordinary imperative
producer, sprinkle `yield x` calls into it, and hand it to a consumer as
a lazy on-demand sequence.

```ocaml
let producer yield =
  for i = 1 to 5 do
    yield (i * i)
  done

let squares : int Seq.t = Gen.to_seq producer
(* nothing has run yet; pulling the first element runs the loop exactly
   until the first `yield`, then FREEZES IT MID-LOOP until the next pull *)
```

Under the hood `yield` performs a `Yield` effect; the handler stores the
continuation (the paused loop) and gives one element to the consumer.
Control has been turned inside out: the producer thinks it is pushing
values with plain function calls, the consumer pulls at its own pace.

The finale is the **same-fringe problem**: do two trees of different
shapes contain the same leaves in the same left-to-right order? With
generators it is three lines: turn each tree walk into a sequence, walk
the two sequences in lockstep, compare. Without generators this problem
is famously annoying (you must hand-write the "pause mid-traversal"
machinery that effects give for free).

## What we will produce

- `lib`: the `Yield` effect, `to_seq : (('a -> unit) -> unit) -> 'a Seq.t`,
  tree fringe as a generator, same-fringe comparison
- `test`: sequence prefixes, laziness checks, same-fringe cases (equal
  fringes across different shapes, unequal fringes, different lengths)
- `bin`: small demos printing generated sequences and same-fringe verdicts

## Concepts covered

- declaring effects (`type _ Effect.t += ...`), `perform`
- deep handlers (`Effect.Deep.match_with`), the `retc` / `exnc` / `effc`
  triple
- continuations as first-class values, `continue`, the one-shot rule
- inversion of control: push-style code consumed pull-style
