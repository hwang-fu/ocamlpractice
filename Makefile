SHELL := /bin/bash
.ONESHELL:

# Every top-level directory containing a dune-project is a quiz.
QUIZZES := $(patsubst %/dune-project,%,$(wildcard */dune-project))

.PHONY: build test fmt list

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
	@$(call run_in,dune build)

test:
	@$(call run_in,dune test --force)

fmt:
	@$(call run_in,dune fmt)

list:
	@printf '%s\n' $(QUIZZES)

# Non-interactive per-quiz bypasses: make build-<quiz>, test-<quiz>, fmt-<quiz>
build-%:
	@[ -f "$*/dune-project" ] || { echo "error: unknown quiz '$*'" >&2; exit 1; }
	cd "$*" && dune build

test-%:
	@[ -f "$*/dune-project" ] || { echo "error: unknown quiz '$*'" >&2; exit 1; }
	cd "$*" && dune test --force

fmt-%:
	@[ -f "$*/dune-project" ] || { echo "error: unknown quiz '$*'" >&2; exit 1; }
	cd "$*" && dune fmt
