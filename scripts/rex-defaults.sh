#!/bin/bash
# Sync Rex appearance settings between configs/rex/defaults and macOS defaults.
#   apply  write the file's values to Rex
#   check  report drift: changed values, keys Rex dropped, untracked keys (exit 1 on drift)
#   pull   copy Rex's current values back into the file
# Types: string, bool, json (value is a file in configs/rex; Rex stores it as JSON data).
set -euo pipefail

domain="com.superlogical.rex"
dir="$(cd "$(dirname "$0")/.." && pwd)/configs/rex"
file="$dir/defaults"
# Per-machine state; never tracked or reported.
ignore=" Workspace.lastFocusedSession Workspace.programActivitySeen Workspace.sidebarCollapsed Workspace.sidebarWidth Workspace.activityGroupingResetToPriority "

[ "$(uname -s)" = Darwin ] || { echo "rex-defaults: macOS only, skipping."; exit 0; }

# json values: same (0 same, 1 differs), pull (0 unchanged, 1 updated), apply.
# Exit 3 when Rex doesn't have the key.
json_value() {
  python3 -I - "$1" "$domain" "$2" "$3" <<'PY'
import json, os, plistlib, subprocess, sys
op, domain, key, path = sys.argv[1:5]

def rex():
    out = subprocess.run(["defaults", "export", domain, "-"], capture_output=True, check=True).stdout
    v = plistlib.loads(out).get(key)
    if v is None:
        sys.exit(3)
    return json.loads(v)

def ours():
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)

if op == "same":
    sys.exit(0 if rex() == ours() else 1)
if op == "pull":
    v, old = rex(), ours()
    with open(path, "w") as f:
        json.dump(v, f, indent=2, ensure_ascii=False)
        f.write("\n")
    sys.exit(0 if v == old else 1)
if op == "apply":
    data = json.dumps(ours(), separators=(",", ":"), ensure_ascii=False).encode()
    subprocess.run(["defaults", "write", domain, key, "-data", data.hex()], check=True)
PY
}

# Print a scalar key's current value in the file's format; fail if unset.
current() {
  local v
  v=$(defaults read "$domain" "$1" 2>/dev/null) || return 1
  if [ "$2" = bool ]; then
    if [ "$v" = 1 ]; then echo true; else echo false; fi
  else
    echo "$v"
  fi
}

entries() { grep -Ev '^[[:space:]]*(#|$)' "$file"; }

# Workspace.* keys Rex has that the file doesn't track.
untracked() {
  local tracked key
  tracked=" $(entries | awk '{print $1}' | tr '\n' ' ') "
  defaults read "$domain" 2>/dev/null \
    | sed -nE 's/^    "?(Workspace\.[A-Za-z]+)"? = .*/\1/p' \
    | while read -r key; do
        case "$tracked$ignore" in *" $key "*) ;; *) echo "$key" ;; esac
      done
}

cmd_apply() {
  local key type value
  while read -r key type value; do
    if [ "$type" = json ]; then
      json_value apply "$key" "$dir/$value"
    else
      defaults write "$domain" "$key" "-$type" "$value"
    fi
  done < <(entries)
  echo "Rex appearance settings written; restart Rex if it was running."
}

cmd_check() {
  local drift=0 key type value now rc
  while read -r key type value; do
    if [ "$type" = json ]; then
      json_value same "$key" "$dir/$value" && rc=0 || rc=$?
      case $rc in
        0) ;;
        3) echo "missing  $key (renamed or removed by Rex?)"; drift=1 ;;
        *) echo "changed  $key: differs from configs/rex/$value"; drift=1 ;;
      esac
    elif ! now=$(current "$key" "$type"); then
      echo "missing  $key (renamed or removed by Rex?)"; drift=1
    elif [ "$now" != "$value" ]; then
      echo "changed  $key: dotfiles=$value rex=$now"; drift=1
    fi
  done < <(entries)
  for key in $(untracked); do
    echo "new      $key (add it to configs/rex/defaults to track it)"; drift=1
  done
  if [ "$drift" = 0 ]; then
    echo "Rex settings match dotfiles."
  else
    echo "Keep Rex's values: make rex-pull. Restore the dotfiles' values: make rex-apply."
  fi
  return "$drift"
}

cmd_pull() {
  local tmp line key type value now rc
  tmp=$(mktemp)
  while IFS= read -r line; do
    case "$line" in ''|\#*) echo "$line"; continue ;; esac
    read -r key type value <<<"$line"
    if [ "$type" = json ]; then
      json_value pull "$key" "$dir/$value" && rc=0 || rc=$?
      [ "$rc" = 1 ] && echo "updated  $key -> configs/rex/$value" >&2
      [ "$rc" = 3 ] && echo "missing  $key, kept as is" >&2
      echo "$line"
    elif now=$(current "$key" "$type"); then
      [ "$now" != "$value" ] && echo "updated  $key: $value -> $now" >&2
      printf '%-48s %-6s %s\n' "$key" "$type" "$now"
    else
      echo "missing  $key, kept as is" >&2
      echo "$line"
    fi
  done < "$file" > "$tmp"
  cat "$tmp" > "$file" && rm -f "$tmp"
  for key in $(untracked); do
    echo "new      $key not tracked; add a line for it to sync it" >&2
  done
  echo "Wrote $dir. Review with: git -C \"$dir\" diff" >&2
}

case "${1:-}" in
  apply) cmd_apply ;;
  check) cmd_check ;;
  pull)  cmd_pull ;;
  *) echo "Usage: $0 apply|check|pull" >&2; exit 2 ;;
esac
