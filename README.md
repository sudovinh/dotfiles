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

The profile controls which Brewfile, Flox environment, Claude settings, and chezmoi data (git email) are applied. Dotfiles under `dot/` are the same for both profiles.

---

## What Gets Set Up

### Homebrew
Installs apps and CLI tools from two Brewfiles:
- `brew/default` — installed on every machine
- `brew/<profile>` — profile-specific additions

### Chezmoi (Dotfiles)
Manages your dotfiles via templates rendered per-machine:
- `~/.zshrc` — Oh My Zsh, zsh-helper files, flox, atuin, direnv; sources `dev_setup/zsh_work` or `zsh_main` by hostname
- `~/.zprofile`, `~/.gitignore_global`
- `~/.gitconfig` — email comes from the profile's chezmoi toml
- `~/.atuin/config.toml` — Atuin history
- `~/.config/zed/settings.json` — Zed settings
- `~/.config/ghostty/config`, `~/.config/zellij/config.kdl` — terminal configs
- `~/.config/herdr/`, `~/.config/herdr-app/` — Herdr CLI and app config, theme, mods
- `~/.config/rex/init.lua` — Rex keybindings (see [Rex](#rex))
- `~/.claude/agents/herdr/` — Herdr skill for Claude Code
- `~/.local/bin/` — `git-clone-bare-for-worktrees`, `wt-add`, `chezmoi-session-sync`

### Flox (Package Manager)
Nix-based reproducible package environments, version-controlled alongside your dotfiles:
- `flox/main/` — personal profile packages (go, kubectl, k9s, gh, jq, …)
- `flox/work/` — work profile packages (extends main + argocd, colima, ripgrep, …)

Activated automatically in your shell via `flox activate --dir`. Add packages by editing the manifest and running `make refresh-flox-config`.

### Shell
- Oh My Zsh + plugins (zsh-autosuggestions, zsh-syntax-highlighting)
- Direnv for per-directory environment variables
- Flox environment activated on shell start

### Rex
Rex (by Superlogical) is in beta, so you install it by hand; it isn't in a Brewfile.
Chezmoi still writes `~/.config/rex/init.lua` on every machine. When that file changes,
`run_onchange_after_rex-reload.sh` checks it with `rex config check` and reloads Rex (macOS only).
If Rex isn't installed or running, the script says so and skips.

On a new machine: run `make`, install Rex, then choose **Reload Config** in Rex.

- Prefix: `Ctrl-a` (`Ctrl-a Ctrl-a` sends `Ctrl-a` to the program)
- Splits: `prefix + |` (right) / `prefix + -` (down)
- Navigation: `prefix + h/j/k/l`
- Reload config: `prefix + r`
- `Shift-Enter` sends a newline

### Zellij
`make setup-zellij` checks that it's installed. On Linux, `make install-zellij` installs it.

### Claude Code
Links settings and MCP server configs from `dev_setup` (if configured). Safe no-op if `DEV_SETUP_REPO` is not set.

### Herdr
Installs the Claude integration. Set `HERDR_APP=true` in `.env` to also install the desktop app.

### macOS Defaults
Not part of `make`; run `make setup-macos-defaults` yourself. Applies system preferences (Finder, Dock, keyboard, screenshots). Override any setting in `.env`:
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
make update-chezmoi        Pull and apply dotfiles
make setup-shell           Install Zsh + Oh My Zsh
make setup-zellij          Verify Zellij installation
make install-flox          Install the flox CLI
make install-direnv        Install direnv
make setup-flox-config     Verify flox environment for active profile
make refresh-flox-config   Update flox packages
make upgrade-flox          Upgrade the flox CLI itself
make install-chezmoi       Install chezmoi (Linux)
make install-zellij        Install zellij (Linux)
make install-orion         Install Orion browser (Linux)
make install-powerline-fonts  Install Powerline fonts
make setup-iterm2-shell-integration  Install iTerm2 shell integration (macOS)
make brew-bundle-default   Install default Brewfile
make brew-bundle-profile   Install profile Brewfile
make brew-reconcile        Interactively reconcile installed brew packages vs Brewfiles
make setup-claude-config   Link Claude settings + agents/commands
make setup-herdr           Install Herdr agent integrations
make install-herdr-app     Install Herdr desktop app (needs HERDR_APP=true)
make setup-macos-defaults  Apply macOS system preferences
make setup-notes           Clone Obsidian notes repo
make clone-dev-setup       Clone private dev_setup repo
make update-repos          Pull dev_setup and notes repos
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
├── claude/                   # Shared Claude agents, commands, skills
├── configs/
│   ├── chezmoi/              # Profile chezmoi .toml configs + chezmoiroot
│   └── iterm2/               # iTerm2 profile export (not applied by make)
├── dot/                      # Chezmoi source — rendered and deployed to ~
│   ├── dot_zshrc.tmpl        # → ~/.zshrc
│   ├── dot_gitconfig.tmpl    # → ~/.gitconfig
│   ├── dot_local/bin/        # → ~/.local/bin/ (scripts)
│   ├── private_dot_config/   # → ~/.config/ (ghostty, herdr, rex, zed, zellij)
│   └── run_onchange_after_rex-reload.sh.tmpl  # checks + reloads Rex
├── docs/                     # Design notes and plans
├── flox/
│   ├── main/                 # Flox environment for personal profile
│   └── work/                 # Flox environment for work profile
├── make/                     # Makefile modules
├── macos/
│   └── defaults.sh           # macOS system preferences script
├── scripts/                  # Brew reconcile and migration helpers
├── zsh-helper/               # Aliases, env, functions, prompts sourced by ~/.zshrc
├── bootstrap.sh              # Linux first-run prerequisites
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
