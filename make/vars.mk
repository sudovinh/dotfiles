# ============================================
# CONFIGURABLE VARIABLES (define in .env)
# ============================================
# Required
GIT_USER        ?=
PROFILE         ?=   # main | work

# Optional - leave empty to skip
DEV_SETUP_REPO        ?=
OBSIDIAN_NOTES_REPO   ?=

# ============================================
# FIXED VARIABLES
# ============================================
CHEZMOI_DIR     := $(HOME)/.local/share/chezmoi
DOTFILES_DIR    := $(CHEZMOI_DIR)
BREW_DIR        := $(DOTFILES_DIR)/brew
BREWFILE_DEFAULT := $(BREW_DIR)/default
CHEZMOI_CONFIG_DIR := $(HOME)/.config/chezmoi
CONFIGS_DIR     := $(DOTFILES_DIR)/configs
DIRENV_INSTALL_SCRIPT := https://direnv.net/install.sh
FLOX_DEB_KEYRING_URL  := https://downloads.flox.dev/by-env/stable/deb/flox-archive-keyring.gpg
FLOX_DEB_REPO_URL     := https://downloads.flox.dev/by-env/stable/deb/
FLOX_VERSION          ?=
DOTFILE_SCRIPTS := $(DOTFILES_DIR)/scripts
HOMEBREW_URL    := https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
LOCAL_BIN       := $(HOME)/.local/bin
ZELLIJ_RELEASE_URL := https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
CLAUDE_CONFIG_DIR := $(HOME)/.claude
DEV_SETUP_DIR   := $(HOME)/dev_setup
DEV_SETUP_CLAUDE_DIR := $(DEV_SETUP_DIR)/claude
OH_MY_ZSH_INSTALL_SCRIPT := https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
ZSH_PLUGIN_URLS := \
	"https://github.com/zsh-users/zsh-autosuggestions.git" \
	"https://github.com/zsh-users/zsh-syntax-highlighting.git"
UNAME_S         := $(shell uname -s)
UNAME_M         := $(shell uname -m)
# Orion browser (Linux Flatpak; macOS uses the brew cask). Version-pinned —
# no "latest" URL exists, so bump ORION_VERSION (or set it in .env) on updates.
ORION_VERSION   ?= 0.3.0
FLATHUB_REPO_URL := https://flathub.org/repo/flathub.flatpakrepo

# Derived paths (depend on PROFILE)
CHEZMOI_TOML    := $(CONFIGS_DIR)/chezmoi/$(PROFILE).toml
BREWFILE_PROFILE := $(BREW_DIR)/$(PROFILE)
FLOX_CONFIG_DIR  := $(DOTFILES_DIR)/flox
FLOX_PROFILE_DIR := $(FLOX_CONFIG_DIR)/$(PROFILE)
