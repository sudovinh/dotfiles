# devbox → flox Migration Design

## Context

Devbox (Jetify) has had maintenance concerns; flox is the better-maintained Nix-based environment tool going forward. Both use nixpkgs as their package backend, so the package surface is nearly identical. The goal is a full cutover — global machine profiles (main/work) and git worktree direnv integration — while keeping devbox in place as a rollback escape hatch until flox is verified.

## Scope

| Area | Status |
|------|--------|
| `dotfiles/flox/main` — machine profile for personal laptop | migrate |
| `dotfiles/flox/work` — machine profile for work laptop (vinh-zip) | migrate |
| `make/flox.mk` — Makefile targets | new file |
| `make/vars.mk` — path variables | update |
| `Makefile` — mac-setup / linux-setup / update targets | update |
| `dot/dot_zshrc.tmpl` — shell activation | update |
| `dev_setup/worktree-config/envrc` — direnv template for ZR worktrees | update |
| `devbox/` and `make/devbox.mk` | keep during transition, remove after verification |

## Directory Structure

```
dotfiles/
├── flox/
│   ├── main/
│   │   └── .flox/env/manifest.toml   # migrated from devbox/main/devbox.json
│   └── work/
│       └── .flox/env/manifest.toml   # migrated from devbox/work/devbox.json
├── make/
│   ├── flox.mk      # NEW
│   └── devbox.mk    # keep until verified
└── devbox/          # keep until verified
```

## manifest.toml Format

Flox environments are configured via `manifest.toml`. Packages map 1:1 from nixpkgs (same backend as devbox). The `devbox.json` `packages` block → `[install]` section; `init_hook` → `[hook] on-activate`; `env` block → `[hook] on-activate` exports.

### main profile (`dotfiles/flox/main/.flox/env/manifest.toml`)

```toml
version = 1

[install]
curl.pkg-path = "curl"
wget.pkg-path = "wget"
tree.pkg-path = "tree"
fzf.pkg-path = "fzf"
gh.pkg-path = "gh"
nmap.pkg-path = "nmap"
htop.pkg-path = "htop"
tmux.pkg-path = "tmux"
krew.pkg-path = "krew"
awscli2.pkg-path = "awscli2"
jq.pkg-path = "jq"
docker-buildx.pkg-path = "docker-buildx"
docker-compose.pkg-path = "docker-compose"
kind.pkg-path = "kind"
aws-vault.pkg-path = "aws-vault"
doctl.pkg-path = "doctl"
opentofu.pkg-path = "opentofu"
opentofu.version = "1.7.1"
kubectl.pkg-path = "kubectl"
k3sup.pkg-path = "k3sup"
yq.pkg-path = "yq"
kustomize.pkg-path = "kustomize"
kubeseal.pkg-path = "kubeseal"
k9s.pkg-path = "k9s"
popeye.pkg-path = "popeye"
go.pkg-path = "go"
python3.pkg-path = "python3"
pip.pkg-path = "python311Packages.pip"
gcrane.pkg-path = "gcrane"
git.pkg-path = "git"

# helm and kubernetes excluded on aarch64-darwin in devbox;
# flox handles this via systems list — include and test on M-series Mac
helm.pkg-path = "kubernetes-helm"
kubernetes.pkg-path = "kubectl"
```

> **Note:** `helm` and `kubernetes` had `aarch64-darwin` exclusions in devbox. Verify these work in flox on Apple Silicon; if not, use `[install.<pkg>.systems]` to restrict.

### work profile (`dotfiles/flox/work/.flox/env/manifest.toml`)

All packages from `main` plus the additional work-only packages:

```toml
version = 1

[install]
# --- shared with main ---
curl.pkg-path = "curl"
wget.pkg-path = "wget"
# ... (all main packages) ...

# --- work-only additions ---
vulnix.pkg-path = "vulnix"
ripgrep.pkg-path = "ripgrep"
shellcheck.pkg-path = "shellcheck"
cue.pkg-path = "cue"
trufflehog.pkg-path = "trufflehog"
git-remote-codecommit.pkg-path = "git-remote-codecommit"
openjdk.pkg-path = "openjdk"
pyenv.pkg-path = "pyenv"
onepassword-cli.pkg-path = "_1password"
argocd.pkg-path = "argocd"
nodejs.pkg-path = "nodejs"
docker.pkg-path = "docker"
colima.pkg-path = "colima"
kops.pkg-path = "kops"
etcdctl.pkg-path = "etcd"
yamllint.pkg-path = "yamllint"
crossplane-cli.pkg-path = "crossplane-cli"
s5cmd.pkg-path = "s5cmd"
git-sizer.pkg-path = "git-sizer"
prometheus.pkg-path = "prometheus"
git-filter-repo.pkg-path = "git-filter-repo"
eks-node-viewer.pkg-path = "eks-node-viewer"
codeowners.pkg-path = "codeowners"
bash.pkg-path = "bash"
pip313.pkg-path = "python313Packages.pip"

[hook]
on-activate = '''
  export PATH="$HOME/zr/main/bin:$HOME/zr/main/infrastructure/terraform/bin:$PATH"
  if [ -n "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
    . "$VENV_DIR/bin/activate"
  fi
'''
```

> **Note:** `_1password` nixpkgs attr may differ in flox. Verify with `flox search 1password` during implementation.

## Shell Integration (`dot/dot_zshrc.tmpl`)

Replace the devbox global shellenv block (lines 127–132) with flox activation, using existing chezmoi hostname templating to select the right profile:

**Remove:**
```bash
source <(devbox completion zsh); compdef _devbox devbox
eval "$(devbox global shellenv)"
```

**Add:**
```bash
{{ if eq .chezmoi.hostname "vinh-zip" }}
eval "$(flox activate --dir $HOME/dotfiles/flox/work -m run)"
{{ else }}
eval "$(flox activate --dir $HOME/dotfiles/flox/main -m run)"
{{- end }}
source <(flox completion zsh) 2>/dev/null || true
```

> **Verify:** `flox activate --dir <path> -m run` emits sourceable shell code (equivalent to `devbox global shellenv`). Confirm with `flox activate --help` before implementation.

Keep `eval "$(direnv hook zsh)"` unchanged — direnv stays.

## Worktree `.envrc` (`dev_setup/worktree-config/envrc`)

ZR monorepo already has its own `.flox/` environment (confirmed by user). The per-worktree envrc simplifies significantly:

**Replace:**
```bash
source_env .devbox-version
eval "$(devbox generate direnv --print-envrc)"
export ZR_ROOT="$PWD"
```

**With:**
```bash
eval "$(flox activate -m run)"
export ZR_ROOT="$PWD"
```

The global work profile is already active in the shell (from `.zshrc`), so flox layers the project environment on top. The `.devbox-version` pin file is no longer needed.

## Makefile Changes

### New file: `make/flox.mk`

```makefile
# ============================================
# FLOX
# ============================================

.PHONY: install-flox
install-flox:
	@command -v flox > /dev/null 2>&1 || (echo "Installing Flox..." && brew install flox)
	@echo "Flox ready."

.PHONY: setup-flox-config
setup-flox-config:
	@if [ -d "$(FLOX_PROFILE_DIR)/.flox" ]; then \
		echo "Flox environment found for profile '$(PROFILE)'."; \
	else \
		echo "ERROR: No flox env at $(FLOX_PROFILE_DIR)/.flox" && exit 1; \
	fi

.PHONY: refresh-flox-config
refresh-flox-config:
	@echo "Updating flox environment for profile '$(PROFILE)'..."
	@cd $(FLOX_PROFILE_DIR) && flox update
	@echo "Flox config refreshed."
```

### Updated `make/vars.mk`

Add:
```makefile
FLOX_INSTALL_SCRIPT := https://install.flox.dev
FLOX_CONFIG_DIR     := $(DOTFILES_DIR)/flox
FLOX_PROFILE_DIR    := $(FLOX_CONFIG_DIR)/$(PROFILE)
```

**Install method:** flox is already in the brewfiles (`brew/default`, `brew/work`), so on macOS it is installed by `brew-bundle-default` before `install-flox` runs. The `FLOX_INSTALL_SCRIPT` is the fallback for Linux (no brew). Alternatively, run `brew install flox` directly or use `curl -fsSL https://install.flox.dev | bash` on any platform.

Keep devbox vars during transition; remove after verification.

### Updated `Makefile`

In `mac-setup` and `linux-setup`: replace `install-devbox` + `setup-devbox-config` with `install-flox` + `setup-flox-config`. Keep `install-direnv` unchanged.

In `mac-update` and `linux-update`: replace `refresh-devbox-config` with `refresh-flox-config`.

Remove `include make/devbox.mk` from Makefile once devbox/ is deleted.

## Package Name Notes

Most nixpkgs package names are identical between devbox and flox. Items to verify during implementation:

| devbox name | likely flox name | note |
|-------------|------------------|------|
| `_1password` | `_1password` or `onepassword-cli` | Search `flox search 1password` |
| `python311Packages.pip` | `python311Packages.pip` | Full attr path may vary |
| `python313Packages.pip` | `python313Packages.pip` | Same |
| `opentofu@1.7.1` | `opentofu` + `version = "1.7.1"` | Version pin via manifest field |
| `kubernetes` | `kubectl` | devbox "kubernetes" pkg may be kubectl |
| `docker-buildx` | `docker-buildx` | Verify attr name |

Run `flox search <name>` for any package that fails during `flox install`.

## Verification

1. **Main profile:** On personal machine, `source ~/.zshrc` → run `which go`, `which kubectl`, `flox list` shows packages
2. **Work profile:** On `vinh-zip`, same check plus `which argocd`, `which colima`
3. **opentofu version pin:** `opentofu --version` shows 1.7.1
4. **Worktree direnv:** `cd ~/zr/main && direnv status` → shows flox env active, `ZR_ROOT` set
5. **Makefile:** `make setup-flox-config` passes; `make refresh-flox-config` runs without error
6. **No devbox dependency:** `which devbox` still works (for rollback), but nothing in the environment depends on it

## Rollback

`devbox/` directory and `make/devbox.mk` are preserved until verification passes. To roll back:
1. Revert `dot_zshrc.tmpl` lines (restore devbox shellenv + completion)
2. Revert `dev_setup/worktree-config/envrc`
3. Run `make setup-devbox-config` to restore symlinks

Delete `devbox/` and `make/devbox.mk` only after both profiles are verified stable.
