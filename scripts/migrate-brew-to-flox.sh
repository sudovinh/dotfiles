#!/usr/bin/env bash
# One-time (idempotent) cleanup after migrating CLIs from Homebrew to Flox.
#
# The dotfiles Brewfiles no longer list these packages — they now come from
# the Flox environments (flox/main, flox/work). But `brew bundle` only ever
# *installs*; it never removes a formula you dropped from a Brewfile. This
# script performs that removal: it uninstalls the migrated brew formulae,
# untaps taps that no longer serve anything, and deletes the superseded
# `go install` binaries. Every action is guarded by an "is it actually
# present?" check and `brew uninstall` refuses when something still depends
# on a formula — so this is safe to re-run and safe on a machine where a
# given package was never installed.
#
# Run it from a terminal where herdr has already activated your Flox profile
# (a normal new shell), so PATH resolution in the verify step is meaningful.
#
# Usage:  ./scripts/migrate-brew-to-flox.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- Precondition: the manifests dropped x86_64-darwin ------------------
# cloudquery / argo-rollouts have no Intel-mac build, so flox/main and
# flox/work now target arm64-darwin + linux only. On an Intel Mac the Flox
# envs won't build and this migration does not apply.
if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "x86_64" ]]; then
	echo "ERROR: this is an Intel Mac (x86_64), but the flox manifests dropped" >&2
	echo "       x86_64-darwin. Re-add it to flox/*/.flox/env/manifest.toml" >&2
	echo "       before migrating. Aborting." >&2
	exit 1
fi

# Formulae now provided by Flox (short names as shown by `brew list`).
BREW_FORMULAE=(
	# from brew/default
	checkmake zellij cloudquery
	# from brew/work
	bat cmctl coreutils unbound gnutls prometheus thanos
	kubectl-argo-rollouts granted
)

# Taps that only existed to serve a migrated formula.
BREW_TAPS=( cloudquery/tap argoproj/tap common-fate/granted )

# `go install` binaries (in $GOPATH/bin) superseded by Flox packages.
GOBIN="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
GO_BINS=( gojsontoyaml gopls hn-text jsonnet sonobuoy staticcheck xk6 )

# --- 1. Pre-build the active Flox environment from the committed lock ---
# Best-effort only: herdr already keeps the env activated in "run" mode in
# your open shells, and the new packages materialize automatically the next
# time you open a terminal. This step just pre-warms the build. Force "run"
# mode so it coexists with herdr's activations, and never abort on failure.
active_env="${FLOX_ENV_DESCRIPTION:-}"
if [[ -n "$active_env" && -d "$REPO_ROOT/flox/$active_env/.flox" ]]; then
	echo "==> Pre-building active flox env: $active_env"
	flox activate -d "$REPO_ROOT/flox/$active_env" --mode run -- true \
		|| echo "    (pre-build skipped; herdr will build it in your next new shell)"
else
	echo "No active flox env detected (FLOX_ENV_DESCRIPTION is empty) — skipping"
	echo "    pre-build; herdr builds it when you open a terminal in the profile."
fi

# --- 2. Uninstall migrated brew formulae (only if installed) -----------
if command -v brew >/dev/null 2>&1; then
	for f in "${BREW_FORMULAE[@]}"; do
		if brew list --formula 2>/dev/null | grep -qx "$f"; then
			echo "==> brew uninstall $f"
			brew uninstall "$f" || echo "    (skipped: $f still has dependents)"
		fi
	done
	for t in "${BREW_TAPS[@]}"; do
		if brew tap 2>/dev/null | grep -qx "$t"; then
			echo "==> brew untap $t"
			brew untap "$t" || true
		fi
	done
else
	echo "brew not found — skipping formula/tap cleanup."
fi

# --- 3. Remove superseded go-installed binaries ------------------------
for b in "${GO_BINS[@]}"; do
	if [[ -e "$GOBIN/$b" ]]; then
		echo "==> rm $GOBIN/$b"
		rm -f "$GOBIN/$b"
	fi
done

# --- 4. Verify resolution ----------------------------------------------
echo
echo "Verification (each should resolve under a .flox/run path):"
missing=0
for b in "${BREW_FORMULAE[@]}" "${GO_BINS[@]}"; do
	resolved="$(command -v "$b" 2>/dev/null || true)"
	printf "  %-24s %s\n" "$b" "${resolved:-<not found>}"
	[[ "$resolved" == *"/.flox/run/"* ]] || missing=1
done

echo
if [[ "$missing" -eq 0 ]]; then
	echo "All tools resolve from Flox. Migration complete."
else
	echo "Some tools did not resolve from Flox. Open a NEW terminal so herdr"
	echo "re-activates the env, then re-run this script to re-check."
fi
