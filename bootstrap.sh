#!/usr/bin/env bash
# Bootstrap a fresh Linux machine to the point where `make` can run.
#
# On a brand-new Ubuntu/Debian box, `make` itself (and a few apt-level
# prerequisites) may not be installed, so the Makefile cannot be invoked.
# This script installs those prerequisites, then hands off to the normal
# idempotent `make` flow. Safe to re-run.
#
# Usage:  ./bootstrap.sh [make-target...]
set -euo pipefail

if command -v apt-get >/dev/null 2>&1; then
	echo "Installing apt prerequisites (make, git, curl, build-essential, fontconfig)..."
	sudo apt-get update
	sudo apt-get install -y make git curl build-essential fontconfig
else
	echo "Warning: apt-get not found; skipping apt prerequisites." >&2
	echo "Ensure make, git, curl and fontconfig are installed, then run 'make'." >&2
fi

exec make "$@"
