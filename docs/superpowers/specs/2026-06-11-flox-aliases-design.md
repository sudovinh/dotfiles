# Flox Shell Aliases — Design

**Date:** 2026-06-11

## Summary

Add three flox-related shell helpers to the dotfiles zsh config.

## Changes

### `.zsh_aliases`

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `flox-update` | `flox upgrade` | Upgrade packages in the active env |
| `flox-list` | `flox list` | Show installed packages in the active env |

### `.zsh_functions`

| Function | Purpose |
|----------|---------|
| `flox-help` | Print a quick cheatsheet covering flox commands and the existing `floxswitch` helper |

## `flox-help` content

Mirrors the `zj-help` pattern — a single `echo` call listing:

- `flox-update` — upgrade packages in active env
- `flox-list` — list installed packages
- `floxswitch` — interactive env switcher (fzf)
- `flox activate -d <path>` — activate an env by path
- `flox install <pkg>` — install a package
- `flox uninstall <pkg>` — remove a package
- `flox search <query>` — search available packages
- `flox show <pkg>` — show package versions

## Constraints

- Scope: active environment only (no multi-env batch operations)
- No new dependencies required
