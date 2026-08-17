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

An **effect** is exactly that, but resumable. OCaml 5 syntax:

```ocaml
open Effect
open Effect.Deep

type _ Effect.t += Need_input : int Effect.t   (* an effect producing an int *)

let compute () = 1 + perform Need_input        (* like raise, but... *)

let result =
  match_with compute ()
    { retc = (fun v -> v)                      (* computation finished normally *)
    ; exnc = raise                             (* real exceptions pass through *)
    ; effc =
        (fun (type a) (eff : a Effect.t) ->
           match eff with
           | Need_input ->
             Some (fun (k : (a, _) continuation) ->
               continue k 42)                  (* resume with the answer! *)
           | _ -> None)
    }
(* result = 43: the "1 +" was NOT lost *)
```

The magic argument is `k`, the **continuation**: the frozen rest of the
computation, "1 + [hole]", handed to the handler as a value. `continue k 42`
fills the hole and lets the computation finish. The handler could also
drop `k` (then the effect behaves like an exception) or store `k` somewhere
and resume it much later. Storing continuations is the door everything
else walks through.

One rule to remember: a continuation is **one-shot**. Each `k` may be
continued at most once; resuming twice is a runtime error.

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
   until the first [yield], then FREEZES IT MID-LOOP until the next pull *)
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
