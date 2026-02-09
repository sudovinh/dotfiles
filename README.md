# Dotfiles

Automated macOS/Linux environment configuration using Chezmoi, Devbox, and Homebrew. Designed to be idempotent with profile-based configurations.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Configure your settings
cp .env.example .env
# Edit .env with your GitHub username and optional repos

# Run first-time setup
make initialize
```

## Configuration

Copy `.env.example` to `.env` and customize:

```bash
# Required - your GitHub username for chezmoi
GIT_USER=your-github-username

# Optional - private repo for sensitive configs (leave empty to skip)
DEV_SETUP_REPO=git@github.com:your-username/dev_setup.git

# Optional - Obsidian notes repository (leave empty to skip)
OBSIDIAN_NOTES_REPO=git@github.com:your-username/second-brain.git
```

## Make Targets

| Command | Description |
|---------|-------------|
| `make initialize` | First-time setup - installs all tools and configures environment |
| `make update` | Safe idempotent update - pulls changes and applies them |
| `make update-chezmoi` | Pull and apply chezmoi changes only |
| `make update-repos` | Pull dev_setup and notes repositories |
| `make update-oh-my-zsh-plugins` | Update all oh-my-zsh plugins |
| `make setup-claude-config` | Symlink Claude Code settings |
| `make setup-macos-defaults` | Apply macOS system preferences (Finder, Dock, keyboard) |
| `make setup-zed-config` | Setup Zed IDE configuration directory |
| `make select-ide` | Choose default IDE (VS Code, Cursor, Zed, Sublime) |
| `make refresh-devbox-config` | Force regenerate devbox lock and reinstall |
| `make print-variables` | Show current configuration |
| `make help` | Display available targets |

## Directory Structure

```
dotfiles/
├── brew/                 # Homebrew Brewfiles
│   ├── default           # Base packages (all profiles)
│   ├── main              # Personal profile additions
│   └── work              # Work profile additions
├── claude/               # Claude Code settings
│   └── settings.json     # Global Claude configuration
├── configs/              # Application configs
│   ├── chezmoi/          # Chezmoi profile configs
│   └── iterm2/           # iTerm2 settings
├── devbox/               # Devbox environments
│   ├── main/             # Personal devbox packages
│   └── work/             # Work devbox packages
├── dot/                  # Chezmoi-managed dotfiles
│   ├── dot_local/bin/    # Scripts installed to ~/.local/bin/
│   │   └── executable_git-clone-bare-for-worktrees
│   ├── dot_zshrc.tmpl    # Zsh configuration
│   ├── dot_gitconfig.tmpl
│   └── ...
├── macos/                # macOS-specific scripts
│   └── defaults.sh       # System preferences script
├── zsh-helper/           # Shell utilities
│   ├── .zsh_aliases
│   ├── .zsh_functions
│   ├── .zsh_worktrees    # Git worktree helpers (wt-add, wt-rm, wt-ls, etc.)
│   └── ...
├── .env.example          # Configuration template
├── .env                  # Your local config (gitignored)
└── Makefile              # Automation targets
```

## Profiles

The setup supports two profiles selected during `make initialize`:

| Profile | Use Case | Includes |
|---------|----------|----------|
| **Main** | Personal machine | Basic tools, WhatsApp |
| **Work** | Work machine | Extended devops tools, Okta, work-specific configs |

Profiles affect:
- Brewfile packages installed
- Devbox global packages
- Chezmoi template variables (email, hostname-based config)
- Claude Code local settings

## Features

- **Environment Detection**: Auto-detects macOS/Linux
- **Idempotent Updates**: Safe to run `make update` repeatedly
- **Profile System**: Separate configs for personal/work machines
- **Chezmoi Integration**: Template-based dotfile management
- **Devbox**: Nix-based reproducible dev environments
- **Claude Code**: Managed settings with `includeCoAuthoredBy: false`
- **IDE Switcher**: Switch between VS Code, Cursor, Zed with one command
- **Git Worktrees**: Bare-repo worktree workflow with `git-clone-bare-for-worktrees` bootstrap and shell helpers
- **macOS Defaults**: Sensible system preferences (configurable via .env)

## macOS Defaults

The `macos/defaults.sh` script configures sensible system preferences:

- **Finder**: Show hidden files, path bar, status bar, disable .DS_Store on network drives
- **Dock**: Auto-hide, fast animations, no recent apps
- **Keyboard**: Fast key repeat, disable press-and-hold, full keyboard access
- **Screenshots**: Save to ~/Screenshots as PNG, no shadow
- **Safari**: Show full URL, enable Developer menu
- **General**: Expand save/print dialogs, disable auto-correct

Run with: `make setup-macos-defaults`

**Override any setting** via `.env`:
```bash
MACOS_DOCK_AUTOHIDE=false
MACOS_DOCK_ICON_SIZE=64
MACOS_KEYBOARD_REPEAT_RATE=1
```

> Note: Some changes require logout/restart to take effect.

## IDE Switcher

Switch between IDEs with a single `code` command:

```bash
# Interactive selection with fzf
switch-ide

# Direct switch
switch-ide cursor
switch-ide zed
switch-ide vscode

# Check current IDE
which-ide

# Open files with current IDE
code .
code myfile.txt
```

Supports: VS Code, Cursor, Zed, Sublime Text, WebStorm, IntelliJ

## Git Worktrees

A bare-repo worktree workflow for working on multiple branches simultaneously without stashing or switching.

### Bootstrap Script

`git-clone-bare-for-worktrees` (installed to `~/.local/bin/` via chezmoi) sets up any repo for worktrees:

```bash
# Basic usage
git-clone-bare-for-worktrees git@github.com:org/repo.git ~/projects/repo

# With selective fetch (only fetches configured refspecs)
git-clone-bare-for-worktrees --selective-fetch git@github.com:org/repo.git ~/work
```

This creates a `<dir>/.bare/` + `<dir>/.git` file structure, then worktrees are added as sibling directories.

### Shell Functions (generic)

Sourced from `zsh-helper/.zsh_worktrees`:

| Function | Description |
|----------|-------------|
| `wt-add <name> [branch]` | Add a worktree from the bare repo root |
| `wt-rm <name>` | Remove a worktree (warns on uncommitted changes) |
| `wt-ls` | List worktrees with branch, last commit, dirty status |
| `wt-inspect [days]` | Find stale worktrees (default >7 days) |
| `cdwt` | cd to the bare repo root |
| `cdz` | cd to the current worktree root |

### Work-Specific Wrappers (via dev_setup)

Work-specific wrappers live in `dev_setup/zsh_work` and `dev_setup/worktree-config/`:

- `zr-worktree-init` — one-time setup: bare clone with selective fetch, hooks, main worktree
- `wt-create <TICKET> [desc]` — creates `$USER.TICKET.desc` branch + worktree off origin/main
- `worktree-config/envrc` — direnv/devbox integration for worktrees
- `worktree-config/post-checkout` — git hook that auto-links `.envrc` into new worktrees

See `~/dev_setup/worktree-config/README.md` for full setup and usage instructions.

## Zed IDE Configuration

Zed settings are managed by chezmoi with profile-specific templating:

- Located at: `dot/private_dot_config/private_zed/settings.json.tmpl`
- Deployed to: `~/.config/zed/settings.json`
- Profile differences (e.g., theme) use chezmoi templating based on hostname

Apply with: `chezmoi apply` or `make update`

## Tool Stack

| Tool | Purpose |
|------|---------|
| [Chezmoi](https://chezmoi.io) | Dotfile management with templating |
| [Devbox](https://jetify.com/devbox) | Nix-based dev environments |
| [Homebrew](https://brew.sh) | macOS/Linux package manager |
| [Oh My Zsh](https://ohmyz.sh) | Zsh framework |
| [Direnv](https://direnv.net) | Per-directory environment variables |

## Updating

After making changes to dotfiles:

```bash
# Pull latest and apply all changes
make update

# Or update specific components
make update-chezmoi           # Just dotfiles
make update-oh-my-zsh-plugins # Just plugins
make refresh-devbox-config    # Reinstall devbox packages
```

## Troubleshooting

**Chezmoi not seeing changes?**
```bash
# The chezmoi source is symlinked to ~/dotfiles
ls -la ~/.local/share/chezmoi
# Should show: chezmoi -> /Users/you/dotfiles
```

**Missing .env file?**
```bash
cp .env.example .env
# Edit with your settings
```

**GIT_USER error?**
```bash
# Make sure GIT_USER is set in .env
echo "GIT_USER=your-github-username" >> .env
```
