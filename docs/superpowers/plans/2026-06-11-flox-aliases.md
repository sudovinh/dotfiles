# Flox Aliases Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `flox-update`, `flox-list` aliases and a `flox-help` function to the zsh dotfiles.

**Architecture:** Two aliases appended to `zsh-helper/.zsh_aliases` under a new `## Flox` section; one `flox-help` function appended to `zsh-helper/.zsh_functions`. No new files.

**Tech Stack:** zsh, flox CLI

---

### Task 1: Add flox aliases to `.zsh_aliases`

**Files:**
- Modify: `zsh-helper/.zsh_aliases` (append at end)

- [ ] **Step 1: Append the Flox section**

Add to the bottom of `zsh-helper/.zsh_aliases`:

```zsh
## Flox
alias flox-update='flox upgrade'
alias flox-list='flox list'
alias flox-help='_flox_help'
```

- [ ] **Step 2: Commit**

```bash
git add zsh-helper/.zsh_aliases
git commit -m "feat(zsh): add flox-update and flox-list aliases"
```

---

### Task 2: Add `flox-help` function to `.zsh_functions`

**Files:**
- Modify: `zsh-helper/.zsh_functions` (append at end)

- [ ] **Step 1: Append the function**

Add to the bottom of `zsh-helper/.zsh_functions`:

```zsh
function _flox_help() {
  echo "Flox Aliases:
  flox-update          Upgrade packages in active env (flox upgrade)
  flox-list            List installed packages in active env (flox list)
  floxswitch           Interactive env switcher (fzf)

Flox Commands:
  flox activate -d <path>   Activate an env by path
  flox install <pkg>        Install a package
  flox uninstall <pkg>      Remove a package
  flox search <query>       Search available packages
  flox show <pkg>           Show available versions of a package
  flox envs                 List all known environments"
}
```

- [ ] **Step 2: Commit**

```bash
git add zsh-helper/.zsh_functions
git commit -m "feat(zsh): add flox-help function"
```

---

### Task 3: Verify

- [ ] **Step 1: Source the files and test**

```bash
source ~/.zshrc
flox-help
flox-list
```

Expected output of `flox-help`: the cheatsheet printed to terminal.
Expected output of `flox-list`: list of packages installed in your active flox env (or an error if no env is active — that's correct behaviour).

- [ ] **Step 2: Verify `flox-update` alias resolves**

```bash
which flox-update
# Expected: flox-update: aliased to flox upgrade
```
