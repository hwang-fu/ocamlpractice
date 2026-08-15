SHELL := /bin/bash
.ONESHELL:

# Every top-level directory containing a dune-project is a quiz.
QUIZZES := $(patsubst %/dune-project,%,$(wildcard */dune-project))

# Run dune through the opam switch resolved from the working directory, so
# recipes use the pinned repo-local toolchain regardless of the caller's
# shell environment.
DUNE := opam exec -- dune

.PHONY: all build test fmt clean list env

all: build

# Create (or update) the repo-local opam switch pinned by ocamlpractice.opam.
# First run compiles the OCaml compiler: expect several minutes.
env:
	opam switch create . 5.4.0 --deps-only --yes || opam install . --deps-only --yes
	opam pin add --yes timeit ./timeit

# $(call run_in,<command>): prompt for a quiz name; empty = run in all.
define run_in
	read -r -p "quiz name (empty = all): " q || true
	if [ -z "$$q" ]; then
	  for d in $(QUIZZES); do
	    echo "== $$d =="
	    (cd "$$d" && $(1)) || exit 1
	  done
	elif [ -f "$$q/dune-project" ]; then
	  cd "$$q" && $(1)
	else
	  echo "error: unknown quiz '$$q'" >&2
	  exit 1
	fi
endef

build:
	@$(call run_in,$(DUNE) build)

test:
	@$(call run_in,$(DUNE) test --force)

fmt:
	@$(call run_in,$(DUNE) fmt)

clean:
	@for d in $(QUIZZES); do
	  echo "== $$d =="
	  (cd "$$d" && $(DUNE) clean) || exit 1
	done

list:
	@printf '%s\n' $(QUIZZES)

# Non-interactive per-quiz bypasses: make build-<quiz>, test-<quiz>, fmt-<quiz>
build-%:
	@[ -f "$*/dune-project" ] || { echo "error: unknown quiz '$*'" >&2; exit 1; }
	cd "$*" && $(DUNE) build

test-%:
	@[ -f "$*/dune-project" ] || { echo "error: unknown quiz '$*'" >&2; exit 1; }
	cd "$*" && $(DUNE) test --force

fmt-%:
	@[ -f "$*/dune-project" ] || { echo "error: unknown quiz '$*'" >&2; exit 1; }
	cd "$*" && $(DUNE) fmt
