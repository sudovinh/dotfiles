#!/usr/bin/env bash
# Interactively reconcile installed Homebrew formulae/casks against the
# Brewfiles (brew/default + brew/<profile>).
#
# `brew bundle` only ever installs — it never removes something you deleted
# from a Brewfile, so machines drift: packages installed by hand, or left
# over from a Brewfile entry that got migrated elsewhere (e.g. to Flox),
# stick around unnoticed. `brew bundle cleanup` (dry-run) surfaces that
# drift, but it's all-or-nothing. This script walks each extra package and
# asks: keep it (and declare it in the Brewfile) or drop it (uninstall now,
# or leave for later).
#
# Scoped to --formula --cask only: taps/Go/Cargo/npm/etc dependencies in the
# cleanup report are not necessarily Brewfile-managed (e.g. `go install`
# binaries on GOPATH) and uninstalling them by mistake would be destructive
# to unrelated tooling.
#
# Usage: ./scripts/reconcile-brew.sh <profile> <default-brewfile> <profile-brewfile>
set -euo pipefail

PROFILE="${1:?Usage: reconcile-brew.sh <profile> <default-brewfile> <profile-brewfile>}"
DEFAULT_FILE="${2:?Usage: reconcile-brew.sh <profile> <default-brewfile> <profile-brewfile>}"
PROFILE_FILE="${3:?Usage: reconcile-brew.sh <profile> <default-brewfile> <profile-brewfile>}"

if [[ ! -f "$DEFAULT_FILE" ]]; then
	echo "ERROR: $DEFAULT_FILE not found." >&2
	exit 1
fi

combined="$(mktemp "${TMPDIR:-/tmp}/brewfile-combined.XXXXXXXX")"
trap 'rm -f "$combined"' EXIT
cat "$DEFAULT_FILE" > "$combined"
[[ -f "$PROFILE_FILE" ]] && cat "$PROFILE_FILE" >> "$combined"

echo "Checking installed Homebrew packages against brew/default + brew/$PROFILE..."
cleanup_output="$(brew bundle cleanup --file="$combined" --formula --cask 2>/dev/null || true)"

extract_section() {
	awk -v header="$1" '
		$0 == header { infield=1; next }
		/^Would / { infield=0 }
		infield && NF { print }
	' <<<"$cleanup_output"
}

casks=()
while IFS= read -r line; do
	casks+=("$line")
done < <(extract_section "Would uninstall casks:")

formulae=()
while IFS= read -r line; do
	formulae+=("$line")
done < <(extract_section "Would uninstall formulae:")

if [[ ${#casks[@]} -eq 0 && ${#formulae[@]} -eq 0 ]]; then
	echo "Nothing to reconcile — installed brew formulae/casks match the Brewfiles."
	exit 0
fi

echo ""
echo "Installed on this machine but not declared in brew/default or brew/$PROFILE:"
echo ""

keep_casks=()
keep_formulae=()
drop_casks=()
drop_formulae=()

prompt_keep() {
	local kind="$1" name="$2" reply
	read -r -p "  Keep '$name' ($kind)? [y/N] " reply
	[[ "$reply" =~ ^[Yy]$ ]]
}

for c in "${casks[@]}"; do
	if prompt_keep "cask" "$c"; then keep_casks+=("$c"); else drop_casks+=("$c"); fi
done
for f in "${formulae[@]}"; do
	if prompt_keep "formula" "$f"; then keep_formulae+=("$f"); else drop_formulae+=("$f"); fi
done

if [[ ${#keep_casks[@]} -gt 0 || ${#keep_formulae[@]} -gt 0 ]]; then
	{
		echo ""
		echo "# Kept via reconcile-brew.sh"
		for f in "${keep_formulae[@]}"; do echo "brew \"$f\""; done
		for c in "${keep_casks[@]}"; do echo "cask \"$c\""; done
	} >>"$PROFILE_FILE"
	echo ""
	echo "Added ${#keep_formulae[@]} formula(e) and ${#keep_casks[@]} cask(s) to $PROFILE_FILE"
fi

to_drop=("${drop_formulae[@]}" "${drop_casks[@]}")
if [[ ${#to_drop[@]} -gt 0 ]]; then
	echo ""
	echo "Not keeping: ${to_drop[*]}"
	read -r -p "Uninstall these now via brew? [y/N] " reply
	if [[ "$reply" =~ ^[Yy]$ ]]; then
		for f in "${drop_formulae[@]}"; do brew uninstall "$f" || true; done
		for c in "${drop_casks[@]}"; do brew uninstall --cask "$c" || true; done
	else
		echo "Leaving them installed. Re-run this to decide again later."
	fi
fi
