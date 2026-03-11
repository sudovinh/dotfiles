SHELL := /bin/bash
.DEFAULT_GOAL := setup

-include .env
export

include make/vars.mk
include make/validation.mk
include make/homebrew.mk
include make/chezmoi.mk
include make/shell.mk
include make/tmux.mk
include make/devbox.mk
include make/claude.mk
include make/repos.mk
include make/system.mk
include make/macos.mk
include make/lint.mk

# ============================================
# DEFAULT: SETUP (idempotent full setup)
# ============================================

.PHONY: setup
setup: check-env print-variables
ifeq ($(UNAME_S), Darwin)
	$(MAKE) mac-setup
else ifeq ($(UNAME_S), Linux)
	$(MAKE) linux-setup
else
	@echo "Unsupported OS: $(UNAME_S)"
	@exit 1
endif

.PHONY: mac-setup
mac-setup: \
	install-xcode \
	install-homebrew \
	install-powerline-fonts \
	setup-iterm2-shell-integration \
	setup-chezmoi \
	install-devbox \
	install-direnv \
	brew-bundle-default \
	brew-bundle-profile \
	clone-dev-setup \
	setup-shell \
	setup-tmux \
	setup-devbox-config \
	setup-notes \
	setup-claude-config
	@echo ""
	@echo "macOS setup complete."

.PHONY: linux-setup
linux-setup: \
	install-powerline-fonts \
	install-devbox \
	install-direnv \
	clone-dev-setup \
	setup-shell \
	setup-tmux \
	setup-devbox-config \
	setup-chezmoi \
	setup-notes \
	setup-claude-config
	@echo ""
	@echo "Linux setup complete."

# ============================================
# UPDATE (pull latest + re-apply)
# ============================================

.PHONY: update
update: check-env print-variables
ifeq ($(UNAME_S), Darwin)
	$(MAKE) mac-update
else ifeq ($(UNAME_S), Linux)
	$(MAKE) linux-update
else
	@echo "Unsupported OS"
endif

.PHONY: mac-update
mac-update: \
	update-chezmoi \
	update-repos \
	update-oh-my-zsh-plugins \
	update-tmux-plugins \
	brew-bundle-default \
	brew-bundle-profile \
	setup-claude-config \
	refresh-devbox-config
	@echo "macOS update complete."

.PHONY: linux-update
linux-update: \
	update-chezmoi \
	update-repos \
	update-oh-my-zsh-plugins \
	update-tmux-plugins \
	setup-claude-config \
	refresh-devbox-config
	@echo "Linux update complete."

# ============================================
# UTILITIES
# ============================================

.PHONY: all
all: setup

.PHONY: clean
clean:
	@echo "Nothing to clean."

.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "First, copy and configure your environment:"
	@echo "  cp .env.example .env   # then edit .env with your values"
	@echo ""
	@echo "Primary targets:"
	@echo "  setup                  Full idempotent setup (default)"
	@echo "  update                 Pull latest changes and re-apply"
	@echo ""
	@echo "Individual targets:"
	@echo "  setup-chezmoi          Init/update chezmoi dotfiles"
	@echo "  setup-tmux             Install TPM and all tmux plugins"
	@echo "  update-tmux-plugins    Update all tmux plugins"
	@echo "  setup-claude-config    Link Claude settings + agents/commands"
	@echo "  setup-devbox-config    Link profile Devbox config"
	@echo "  refresh-devbox-config  Force-regenerate devbox.lock"
	@echo "  brew-bundle-default    Install default Brewfile"
	@echo "  brew-bundle-profile    Install profile Brewfile"
	@echo "  setup-macos-defaults   Apply macOS system preferences"
	@echo "  setup-shell            Install/configure Zsh + Oh My Zsh"
	@echo "  setup-notes            Clone Obsidian notes repo"
	@echo "  clone-dev-setup        Clone private dev_setup repo"
	@echo "  select-ide             Choose default IDE"
	@echo "  print-variables        Show resolved config values"
	@echo "  check-env              Validate .env is configured correctly"
	@echo "  lint                   Lint all Makefile modules with checkmake"
	@echo "  test                   Dry-run all targets to verify correctness"
	@echo "  help                   Show this message"
