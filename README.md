# ocamlpractice

OCaml practice quizzes. Each quiz lives in its own top-level folder as a
standalone dune project (own `dune-project`, `lib`/`bin`/`test`), so every
quiz builds, tests, and runs independently.

## Requirements

- opam (2.x) — everything else is pinned by the repo, see below
- An X11 display, for the drawing quizzes
- LuaLaTeX (TeX Live), only to rebuild the PDF notes under `*/docs/`

## Reproducible environment

The exact toolchain (OCaml 5.4.0, dune, `graphics` 5.2.0, `ocamlformat`
0.28.1) is declared in `ocamlpractice.opam`. Build the repo-local opam
switch once with:

```console
make env          # first run compiles the compiler: several minutes
eval $(opam env)  # select the local switch in the current shell
```

This creates `_opam/` at the repo root (gitignored). opam's shell hook, if
enabled, selects the switch automatically whenever you are inside the repo;
otherwise re-run `eval $(opam env)` per shell. Future upgrades of the
global opam world then cannot break these quizzes.

Without the hook or `eval`, prefix any command with `opam exec --` to run
it in the pinned switch (e.g. `opam exec -- dune test`); the `make` targets
already do this internally, so they always use the pinned toolchain.

## Building and testing

A root `Makefile` drives all quizzes:

```console
make list            # discovered quizzes
make build           # prompts: empty = all, or a quiz name
make test            # same prompt; runs each quiz's test suite
make fmt             # same prompt; applies ocamlformat
make clean           # dune clean in every quiz
make build-<quiz>    # non-interactive per-quiz variants
make test-<quiz>     #   e.g. make test-koch_snowflake
```

Or work inside one quiz directly: `cd <quiz> && dune build`, `dune test`,
`dune exec bin/main.exe -- <args>`.

Note the `--` before program arguments: it separates them from dune's own
options (required for anything starting with `-`, harmless otherwise).

## Quizzes

### leap_year

Reads a year, prints whether it is a leap year.

```console
$ dune exec bin/main.exe -- 2024
2024 is a leap year
```

### approx_pi

Monte-Carlo estimation of pi from `n` random points in the unit square,
plotted live in a window (red = inside the quarter circle, blue = outside).
Prints the estimate; any key closes.

```console
$ dune exec bin/main.exe -- 100000
3.141160
```

### cardioid

Animates a cardioid drawn over labeled axes. Optional radius argument
(default 300); the maximum is computed from the window size, and the error
message states the accepted range.

```console
$ dune exec bin/main.exe            # default radius
$ dune exec bin/main.exe -- 150     # custom radius
```

### mandelbrot

Renders the Mandelbrot set at 1200x800, colored by escape time (dark blue =
fast escape, warm yellow = near the boundary, black = member). Optional
viewport center (default -0.5 0).

```console
$ dune exec bin/main.exe                    # whole set
$ dune exec bin/main.exe -- -0.75 0.1       # pan elsewhere
```

### n_queens

Backtracking N-queens solver over persistent integer sets.

```console
$ dune exec bin/main.exe -- 8       # count solutions: 92
$ dune exec bin/main.exe -- -i 8    # interactive board viewer, n in [1, 10]
```

Interactive mode shows one solution on a board; navigate with the
Prev/Next buttons or the `n`/`p` keys, quit with `q`.

### koch_snowflake

Animates the Koch snowflake at a given recursion depth (default 4,
accepted range [0, 8]); the whole figure draws in about three seconds
regardless of depth.

```console
$ dune exec bin/main.exe            # depth 4
$ dune exec bin/main.exe -- 6      # lacier
```

### hanoi

Animates the classic Tower of Hanoi solution for five discs (31 moves, one
per 0.9 s). No arguments; any key closes once the tower has moved.

```console
$ dune exec bin/main.exe
```

### timeit

`Timeit.time` measures the CPU time (not wall-clock time) a function
consumes. The demo times summation loops of growing size to show
near-linear scaling; no arguments.

```console
$ dune exec bin/main.exe
sum of 1..10000000       0.005 s
sum of 1..100000000      0.036 s
sum of 1..1000000000     0.223 s
```

## Notes

- Some quizzes (`cardioid`, `mandelbrot`, `koch_snowflake`) carry a short
  mathematical note in `docs/` as LaTeX source with the committed PDF.
- Graphics windows close on any keypress; closing via the window manager is
  handled where the library allows it.
