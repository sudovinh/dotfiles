# Dotfiles

Idempotent macOS/Linux environment setup. Run `make` once to set up a new machine, run it again anytime to re-apply — it's always safe.

Managed with [Chezmoi](https://chezmoi.io) (dotfiles), [Flox](https://flox.dev) (packages), and [Homebrew](https://brew.sh) (apps).

---

## Quick Start

```bash
# 1. Clone
git clone git@github.com:sudovinh/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi

# 2. Configure
cp .env.example .env
# Edit .env — set GIT_USER and PROFILE at minimum

# 3. Run
make            # macOS
./bootstrap.sh  # Linux — installs make/git/curl/fontconfig first, then runs make
```

That's it. Re-running `make` (or `./bootstrap.sh`) at any time is safe and idempotent.

> **Linux:** a fresh machine may not have `make` installed yet, so use `./bootstrap.sh` for
> the first run. It installs the apt prerequisites and then hands off to `make`. The Makefile
> auto-detects the OS (`uname -s`) and runs the Linux setup path.

---

## Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
# Required
GIT_USER=your-github-username
PROFILE=main                          # main | work

# Optional — leave commented out to skip
# DEV_SETUP_REPO=git@github.com:you/dev_setup.git
# OBSIDIAN_NOTES_REPO=git@github.com:you/second-brain.git
```

### Profiles

| Profile | Use Case |
|---------|----------|
| `main`  | Personal machine |
| `work`  | Work machine (extra devops tools, work-specific configs) |

The profile controls which Brewfile, Flox environment, and Claude settings are applied.

---

## What Gets Set Up

### Homebrew
Installs apps and CLI tools from two Brewfiles:
- `brew/default` — installed on every machine
- `brew/<profile>` — profile-specific additions

### Chezmoi (Dotfiles)
Manages your dotfiles via templates rendered per-machine:
- `~/.zshrc` — Zsh config with flox activation, direnv, Oh My Zsh
- `~/.tmux.conf` — Tmux config
- `~/.gitconfig` — Git config with hostname-based identity
- `~/.config/zed/settings.json` — Zed IDE settings
- `~/.local/bin/git-clone-bare-for-worktrees` — worktree bootstrap script

### Flox (Package Manager)
Nix-based reproducible package environments, version-controlled alongside your dotfiles:
- `flox/main/` — personal profile packages (go, kubectl, k9s, gh, jq, …)
- `flox/work/` — work profile packages (extends main + argocd, colima, ripgrep, …)

Activated automatically in your shell via `flox activate --dir`. Add packages by editing the manifest and running `make refresh-flox-config`.

### Shell
- Oh My Zsh + plugins (zsh-autosuggestions, zsh-syntax-highlighting)
- Direnv for per-directory environment variables
- Flox environment activated on shell start

### Tmux
- TPM (Tmux Plugin Manager) with plugins: tmux-sensible, tmux-resurrect
- Prefix: `Ctrl-a`
- Splits: `prefix + |` (horizontal) / `prefix + -` (vertical)
- Navigation: `prefix + h/j/k/l`

### Claude Code
Links settings and MCP server configs from `dev_setup` (if configured). Safe no-op if `DEV_SETUP_REPO` is not set.

### macOS Defaults
Applies sensible system preferences (Finder, Dock, keyboard, screenshots). Override any setting in `.env`:
```bash
MACOS_DOCK_AUTOHIDE=true
MACOS_DOCK_ICON_SIZE=48
MACOS_FINDER_SHOW_HIDDEN=true
```

---

## Make Targets

```
make                       Full idempotent setup (default)
make update                Pull latest + re-apply everything

make setup-chezmoi         Init/update chezmoi dotfiles
make setup-shell           Install Zsh + Oh My Zsh
make setup-tmux            Install TPM and tmux plugins
make setup-flox-config     Verify flox environment for active profile
make refresh-flox-config   Update flox packages
make brew-bundle-default   Install default Brewfile
make brew-bundle-profile   Install profile Brewfile
make setup-claude-config   Link Claude settings + agents/commands
make setup-macos-defaults  Apply macOS system preferences
make setup-notes           Clone Obsidian notes repo
make clone-dev-setup       Clone private dev_setup repo
make select-ide            Choose default IDE

make print-variables       Show resolved config values
make check-env             Validate .env
make lint                  Lint Makefile modules
make test                  Dry-run all targets
make help                  Show this message
```

---

## Directory Structure

```
dotfiles/
├── brew/                     # Homebrew Brewfiles
│   ├── default               # Installed on all profiles
│   ├── main                  # Personal additions
│   └── work                  # Work additions
├── configs/
│   └── chezmoi/              # Profile-specific chezmoi .toml configs
├── dot/                      # Chezmoi source — rendered and deployed to ~
│   ├── dot_zshrc.tmpl        # → ~/.zshrc
│   ├── dot_tmux.conf         # → ~/.tmux.conf
│   ├── dot_gitconfig.tmpl    # → ~/.gitconfig
│   ├── dot_local/bin/        # → ~/.local/bin/ (scripts)
│   └── private_dot_config/   # → ~/.config/ (Zed, etc.)
├── flox/
│   ├── main/                 # Flox environment for personal profile
│   └── work/                 # Flox environment for work profile
├── make/                     # Makefile modules
├── macos/
│   └── defaults.sh           # macOS system preferences script
├── .env.example              # Configuration template
└── Makefile
```

---

## Git Worktrees

A bare-repo workflow for working on multiple branches simultaneously without stashing.

`git-clone-bare-for-worktrees` (installed to `~/.local/bin/`) sets up any repo:

```bash
git-clone-bare-for-worktrees git@github.com:org/repo.git ~/projects/repo
```

This creates a `.bare/` + `.git` file structure; worktrees are added as siblings.

Work-specific worktree tooling (wt-create, wt-rm, envrc hooks) lives in `dev_setup` if configured.

---

## Updating

```bash
# Pull and re-apply everything
make update

# Or individual pieces
make update-chezmoi            # Dotfiles only
make update-oh-my-zsh-plugins  # Zsh plugins
make update-tmux-plugins       # Tmux plugins
make refresh-flox-config       # Flox packages
```

---

## Troubleshooting

**`make` fails asking for GIT_USER**
```bash
cp .env.example .env
# Set GIT_USER and PROFILE, then re-run make
```

**Flox environment not found**
The `flox/main/` and `flox/work/` directories are in this repo. If chezmoi hasn't pulled them yet:
```bash
make setup-chezmoi
make setup-flox-config PROFILE=main
```

**Chezmoi source location**
```bash
ls -la ~/.local/share/chezmoi
# Should be the actual repo (or a symlink to it)
```

**MCP merge skipped with a warning**
The `dev_setup/claude/claude_mcp_<profile>.json` file may be commented out — this is intentional and safe to ignore.
