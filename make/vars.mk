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
DOTFILES_DIR    := $(HOME)/dotfiles
BREW_DIR        := $(DOTFILES_DIR)/brew
BREWFILE_DEFAULT := $(BREW_DIR)/default
CHEZMOI_CONFIG_DIR := $(HOME)/.config/chezmoi
CHEZMOI_DIR     := $(HOME)/.local/share/chezmoi
CONFIGS_DIR     := $(DOTFILES_DIR)/configs
DEVBOX_CONFIG_DIR := $(CHEZMOI_DIR)/devbox
DEVBOX_INSTALL_SCRIPT := https://get.jetify.com/devbox
DIRENV_INSTALL_SCRIPT := https://direnv.net/install.sh
DEVBOX_GLOBAL_CONFIG := $(HOME)/.local/share/devbox/global/default
DOTFILE_SCRIPTS := $(DOTFILES_DIR)/scripts
HOMEBREW_URL    := https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
CLAUDE_CONFIG_DIR := $(HOME)/.claude
DEV_SETUP_DIR   := $(HOME)/dev_setup
DEV_SETUP_CLAUDE_DIR := $(DEV_SETUP_DIR)/claude
OH_MY_ZSH_INSTALL_SCRIPT := https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
ZSH_PLUGIN_URLS := \
	"https://github.com/zsh-users/zsh-autosuggestions.git" \
	"https://github.com/zsh-users/zsh-syntax-highlighting.git"
TPM_DIR         := $(HOME)/.tmux/plugins/tpm
TPM_REPO        := https://github.com/tmux-plugins/tpm
UNAME_S         := $(shell uname -s)

# Derived paths (depend on PROFILE)
CHEZMOI_TOML    := $(CONFIGS_DIR)/chezmoi/$(PROFILE).toml
BREWFILE_PROFILE := $(BREW_DIR)/$(PROFILE)
DEVBOX_PROFILE_DIR := $(DEVBOX_CONFIG_DIR)/$(PROFILE)
