# Design: Makefile Lint + Test Targets + CI Workflow

## Context

The dotfiles Makefile was recently refactored into 11 domain `.mk` modules under `make/`. This design adds linting, dry-run testing, and a GitHub Actions workflow to validate correctness on every push and PR.

## Goals

- Catch Makefile structural issues (missing `.PHONY`, tab/space errors, etc.) via `checkmake`
- Validate all orchestration chains still resolve correctly via `make -n` dry-runs
- Confirm expected public targets and backwards-compat aliases are present
- Run all checks automatically on `push` and `pull_request` to `main`

## New Files

```
dotfiles/
├── make/lint.mk                          # lint and test targets
├── .github/
│   └── workflows/
│       └── makefile-lint.yml             # CI workflow
└── docs/plans/
    └── 2026-03-09-makefile-lint-test-design.md
```

## Modified Files

- `brew/default` — add `checkmake`
- `Makefile` — add `include make/lint.mk`
- `make/validation.mk` — add `lint` and `test` to help output (or handled in lint.mk)

## Target Design

### `make lint`

Runs `checkmake` against the main `Makefile` and all `make/*.mk` files. Fails fast on first error. Requires `checkmake` to be installed (available after `make setup` or `brew install checkmake`).

```
make lint
→ checkmake Makefile
→ checkmake make/vars.mk
→ checkmake make/validation.mk
→ ... (all 11 modules)
```

### `make test`

Runs two checks:

1. **Dry-run chains** — `make -n` for `mac-setup`, `mac-update`, `linux-setup`, `linux-update`. Fails if any target in the chain is undefined or errors.

2. **Target existence checks** — Uses `make -n <target>` to verify a checklist of expected public targets and backwards-compat aliases are defined:
   - `setup`, `update`, `mac-setup`, `linux-setup`, `mac-update`, `linux-update`
   - `setup-chezmoi`, `update-chezmoi`
   - `brew-bundle-default`, `brew-bundle-profile`, `setup-brewfile` (alias)
   - `setup-shell`, `setup-tmux`, `update-tmux-plugins`
   - `setup-devbox-config`, `refresh-devbox-config`
   - `setup-claude-config`, `clone-dev-setup`, `setup-notes`, `update-repos`
   - `install-xcode`, `install-powerline-fonts`, `setup-iterm2-shell-integration`
   - `setup-macos-defaults`, `select-ide`, `check-env`, `print-variables`

## GitHub Actions Workflow

**File:** `.github/workflows/makefile-lint.yml`

**Triggers:** `push` and `pull_request` targeting `main`

**Runner:** `ubuntu-latest`

**Steps:**
1. Checkout repo
2. Install `checkmake` via direct binary download from GitHub releases (no brew on Linux)
3. Run `make lint` — fails workflow if any `.mk` file has issues
4. Run `make test` — fails workflow if any dry-run chain or target check fails

If `checkmake` binary download fails, the lint step is skipped with a warning (non-blocking) so a network issue doesn't block PRs. The `make test` dry-run step has no external dependencies and always runs.

## Brewfile Change

Add to `brew/default`:
```
brew "checkmake"
```

So `checkmake` is available locally after a standard setup.

## Non-Goals

- No `shellcheck` integration (too noisy extracting shell from Make recipe bodies)
- No bats test suite (overkill for config-file validation)
- No pre-commit hook (manual `make lint` / `make test` only)
