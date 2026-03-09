SHELL := /bin/bash
.DEFAULT_GOAL := setup

# ============================================
# LOAD .env FILE (if exists)
# ============================================
-include .env
export

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

# ============================================
# VALIDATION
# ============================================

.PHONY: check-env
check-env:
	@if [ ! -f .env ]; then \
		echo ""; \
		echo "ERROR: .env file not found."; \
		echo "  Copy the example and fill in your values:"; \
		echo "    cp .env.example .env"; \
		echo ""; \
		exit 1; \
	fi
	@if [ -z "$(GIT_USER)" ]; then \
		echo "ERROR: GIT_USER is not set in .env"; exit 1; \
	fi
	@if [ "$(PROFILE)" != "main" ] && [ "$(PROFILE)" != "work" ]; then \
		echo "ERROR: PROFILE must be 'main' or 'work' in .env (got: '$(PROFILE)')"; exit 1; \
	fi
	@echo "Config: profile=$(PROFILE) git_user=$(GIT_USER)"

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
	setup-brewfile \
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
	setup-brewfile \
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
# CHEZMOI
# ============================================

.PHONY: setup-chezmoi
setup-chezmoi:
ifeq ($(GIT_USER),)
	@echo "Error: GIT_USER not set."
	@exit 1
else
	@echo "Configuring chezmoi..."
	@if [ ! -d "$(CHEZMOI_DIR)" ]; then \
		echo "Initializing chezmoi..." && \
		chezmoi init --apply $(GIT_USER); \
	else \
		echo "Chezmoi already initialized. Pulling updates..." && \
		chezmoi git pull; \
	fi
endif
	@echo "Linking chezmoi toml config for profile '$(PROFILE)'..."
	@if [ -f "$(CHEZMOI_TOML)" ]; then \
		mkdir -p "$(CHEZMOI_CONFIG_DIR)" && \
		ln -sf "$(CHEZMOI_TOML)" "$(CHEZMOI_CONFIG_DIR)/chezmoi.toml" && \
		ln -sf "$(CONFIGS_DIR)/chezmoi/chezmoiroot" "$(CHEZMOI_DIR)/.chezmoiroot" && \
		echo "Chezmoi toml linked: $(CHEZMOI_TOML)"; \
	else \
		echo "Warning: $(CHEZMOI_TOML) not found, skipping toml link."; \
	fi
	@echo "Chezmoi setup complete."

.PHONY: update-chezmoi
update-chezmoi:
	@echo "Updating chezmoi..."
	@if [ ! -d "$(CHEZMOI_DIR)" ]; then \
		echo "Chezmoi not initialized. Run 'make setup' first." && exit 1; \
	fi
	@chezmoi update --apply
	@if [ -f "$(CHEZMOI_TOML)" ]; then \
		mkdir -p "$(CHEZMOI_CONFIG_DIR)" && \
		ln -sf "$(CHEZMOI_TOML)" "$(CHEZMOI_CONFIG_DIR)/chezmoi.toml"; \
	fi
	@echo "Chezmoi update complete."

# ============================================
# REPOSITORIES
# ============================================

.PHONY: clone-dev-setup
clone-dev-setup:
ifeq ($(DEV_SETUP_REPO),)
	@echo "DEV_SETUP_REPO not set, skipping."
else
	@REPO_NAME=$$(basename $(DEV_SETUP_REPO) .git); \
	if [ ! -d $(HOME)/$$REPO_NAME ]; then \
		echo "Cloning dev_setup..." && git clone $(DEV_SETUP_REPO) $(HOME)/$$REPO_NAME; \
	else \
		echo "dev_setup already cloned."; \
	fi
endif

.PHONY: setup-notes
setup-notes:
ifeq ($(OBSIDIAN_NOTES_REPO),)
	@echo "OBSIDIAN_NOTES_REPO not set, skipping."
else
	@REPO_NAME=$$(basename $(OBSIDIAN_NOTES_REPO) .git); \
	if [ ! -d $(HOME)/$$REPO_NAME ]; then \
		echo "Cloning notes..." && git clone $(OBSIDIAN_NOTES_REPO) $(HOME)/$$REPO_NAME; \
	else \
		echo "Notes repo already cloned."; \
	fi
endif

.PHONY: update-repos
update-repos:
	@echo "Updating repositories..."
ifneq ($(DEV_SETUP_REPO),)
	@REPO_NAME=$$(basename $(DEV_SETUP_REPO) .git); \
	if [ -d $(HOME)/$$REPO_NAME ]; then \
		echo "Pulling dev_setup..." && cd $(HOME)/$$REPO_NAME && git pull --rebase; \
	else \
		echo "dev_setup not found, skipping."; \
	fi
endif
ifneq ($(OBSIDIAN_NOTES_REPO),)
	@REPO_NAME=$$(basename $(OBSIDIAN_NOTES_REPO) .git); \
	if [ -d $(HOME)/$$REPO_NAME ]; then \
		echo "Pulling notes..." && cd $(HOME)/$$REPO_NAME && git pull --rebase; \
	else \
		echo "Notes repo not found, skipping."; \
	fi
endif
	@echo "Repositories update complete."

# ============================================
# SHELL (Oh My Zsh)
# ============================================

.PHONY: setup-shell
setup-shell: setup-zsh
ifeq ($(UNAME_S), Darwin)
	@command -v zsh > /dev/null 2>&1 || (echo "Installing zsh..." && brew install zsh)
else ifeq ($(UNAME_S), Linux)
	@command -v zsh > /dev/null 2>&1 || (echo "Installing zsh..." && apt install zsh)
endif
	@chsh -s $$(which zsh) 2>/dev/null || true
	@echo "Shell setup complete."

.PHONY: setup-zsh
setup-zsh: install-oh-my-zsh-plugins
	@if [ ! -d $(HOME)/.oh-my-zsh ]; then \
		echo "Installing Oh My Zsh..." && \
		sh -c "$$(curl -fsSL $(OH_MY_ZSH_INSTALL_SCRIPT))"; \
	else \
		echo "Oh My Zsh already installed."; \
	fi

.PHONY: install-oh-my-zsh-plugins
install-oh-my-zsh-plugins:
	@echo "Installing Oh My Zsh plugins..."
	@for url in $(ZSH_PLUGIN_URLS); do \
		plugin_name=$$(basename $$url .git); \
		plugin_dir=$${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/$$plugin_name; \
		if [ ! -d "$$plugin_dir" ]; then \
			echo "Installing $$plugin_name..." && git clone $$url "$$plugin_dir"; \
		else \
			echo "$$plugin_name already installed."; \
		fi; \
	done

.PHONY: update-oh-my-zsh-plugins
update-oh-my-zsh-plugins:
	@echo "Updating Oh My Zsh plugins..."
	@for url in $(ZSH_PLUGIN_URLS); do \
		plugin_name=$$(basename $$url .git); \
		plugin_dir=$${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/$$plugin_name; \
		if [ -d "$$plugin_dir" ]; then \
			echo "Updating $$plugin_name..." && cd "$$plugin_dir" && git pull --rebase; \
		else \
			echo "Installing $$plugin_name..." && git clone $$url "$$plugin_dir"; \
		fi; \
	done

# ============================================
# TMUX
# ============================================

.PHONY: setup-tmux
setup-tmux:
	@echo "Setting up TPM (Tmux Plugin Manager)..."
	@if [ ! -d "$(TPM_DIR)" ]; then \
		echo "Cloning TPM..." && git clone $(TPM_REPO) $(TPM_DIR); \
	else \
		echo "TPM already installed."; \
	fi
	@echo "Installing tmux plugins..."
	@if [ -x "$(TPM_DIR)/bin/install_plugins" ]; then \
		tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$(HOME)/.tmux/plugins" \; source-file "$(HOME)/.tmux.conf" 2>/dev/null || true; \
		$(TPM_DIR)/bin/install_plugins; \
		echo "Tmux plugins installed."; \
	else \
		echo "TPM install script not found, skipping."; \
	fi

.PHONY: update-tmux-plugins
update-tmux-plugins:
	@echo "Updating tmux plugins..."
	@if [ ! -x "$(TPM_DIR)/bin/update_plugins" ]; then \
		echo "TPM not installed. Run 'make setup-tmux' first." && exit 1; \
	fi
	@tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$(HOME)/.tmux/plugins" \; source-file "$(HOME)/.tmux.conf" 2>/dev/null || true
	@$(TPM_DIR)/bin/install_plugins
	@$(TPM_DIR)/bin/update_plugins all

# ============================================
# HOMEBREW (macOS only)
# ============================================

.PHONY: install-homebrew
install-homebrew:
ifeq ($(UNAME_S), Darwin)
	@which brew > /dev/null 2>&1 || (echo "Installing Homebrew..." && /bin/bash -c "$$(curl -fsSL $(HOMEBREW_URL))")
	@eval "$$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
	@echo "Homebrew ready."
else
	@echo "Skipping Homebrew (not macOS)."
endif

.PHONY: brew-bundle-default
brew-bundle-default:
ifeq ($(UNAME_S), Darwin)
	@if [ ! -f "$(BREWFILE_DEFAULT)" ]; then \
		echo "Error: $(BREWFILE_DEFAULT) not found." && exit 1; \
	fi
	@echo "Running Brewfile (default)..."
	@brew bundle --file=$(BREWFILE_DEFAULT)
else
	@echo "Skipping Brewfile (not macOS)."
endif

.PHONY: setup-brewfile
setup-brewfile:
ifeq ($(UNAME_S), Darwin)
	@if [ -f "$(BREWFILE_PROFILE)" ]; then \
		echo "Running Brewfile ($(PROFILE))..." && brew bundle --file=$(BREWFILE_PROFILE); \
	else \
		echo "No profile Brewfile at $(BREWFILE_PROFILE), skipping."; \
	fi
else
	@echo "Skipping profile Brewfile (not macOS)."
endif

# ============================================
# DEVBOX
# ============================================

.PHONY: install-devbox
install-devbox:
	@command -v devbox > /dev/null 2>&1 || (echo "Installing Devbox..." && curl -fsSL $(DEVBOX_INSTALL_SCRIPT) | bash)
	@echo "Devbox ready."

.PHONY: install-direnv
install-direnv:
	@command -v direnv > /dev/null 2>&1 || (echo "Installing Direnv..." && curl -fsSL $(DIRENV_INSTALL_SCRIPT) | bash)
	@echo "Direnv ready."

.PHONY: setup-devbox-config
setup-devbox-config:
	@if [ -d "$(DEVBOX_PROFILE_DIR)" ]; then \
		echo "Setting up Devbox config for profile '$(PROFILE)'..." && \
		mkdir -p $(DEVBOX_GLOBAL_CONFIG) && \
		rm -f $(DEVBOX_GLOBAL_CONFIG)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.lock && \
		ln -sf $(DEVBOX_PROFILE_DIR)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.json && \
		ln -sf $(DEVBOX_PROFILE_DIR)/devbox.lock $(DEVBOX_GLOBAL_CONFIG)/devbox.lock && \
		echo "Devbox config linked."; \
	else \
		echo "No Devbox profile dir at $(DEVBOX_PROFILE_DIR), skipping."; \
	fi

.PHONY: refresh-devbox-config
refresh-devbox-config:
	@if [ -d "$(DEVBOX_PROFILE_DIR)" ]; then \
		echo "Refreshing Devbox config..." && \
		mkdir -p $(DEVBOX_GLOBAL_CONFIG) && \
		rm -f $(DEVBOX_GLOBAL_CONFIG)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.lock && \
		ln -sf $(DEVBOX_PROFILE_DIR)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.json && \
		echo "Regenerating devbox.lock..." && \
		cd $(DEVBOX_GLOBAL_CONFIG) && devbox install --refresh 2>/dev/null || devbox install && \
		eval "$$(devbox global shellenv --preserve-path-stack -r)" && hash -r 2>/dev/null || true && \
		echo "Devbox config refreshed."; \
	else \
		echo "No Devbox profile dir at $(DEVBOX_PROFILE_DIR), skipping."; \
	fi

# ============================================
# CLAUDE
# ============================================

.PHONY: setup-claude-config
setup-claude-config:
	@echo "Setting up Claude Code configuration..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)
	@# Link settings if dev_setup is available
	@if [ -n "$(DEV_SETUP_REPO)" ] && [ -d "$(DEV_SETUP_CLAUDE_DIR)" ]; then \
		CLAUDE_SRC="$(DEV_SETUP_CLAUDE_DIR)/claude_settings_local_$(PROFILE).json"; \
		if [ -f "$$CLAUDE_SRC" ]; then \
			echo "Linking Claude settings from $$CLAUDE_SRC..." && \
			ln -sf "$$CLAUDE_SRC" "$(CLAUDE_CONFIG_DIR)/settings.json" && \
			ln -sf "$$CLAUDE_SRC" "$(CLAUDE_CONFIG_DIR)/settings.local.json"; \
		else \
			echo "Warning: $$CLAUDE_SRC not found, skipping settings link."; \
		fi; \
	else \
		echo "dev_setup not available, skipping Claude settings link."; \
	fi
	@# Symlink agents and commands
	@echo "Setting up custom agents and commands..."
	@mkdir -p "$(CLAUDE_CONFIG_DIR)/agents" "$(CLAUDE_CONFIG_DIR)/commands"
	@rm -f "$(CLAUDE_CONFIG_DIR)/agents/"*.md "$(CLAUDE_CONFIG_DIR)/commands/"*.md
	@for dir in \
		"$(CHEZMOI_DIR)/claude/agents" \
		"$(DEV_SETUP_CLAUDE_DIR)/agents" \
		"$(DEV_SETUP_CLAUDE_DIR)/agents_$(PROFILE)"; do \
		if [ -d "$$dir" ]; then \
			for f in "$$dir"/*.md; do \
				[ -f "$$f" ] && ln -sf "$$f" "$(CLAUDE_CONFIG_DIR)/agents/$$(basename $$f)"; \
			done; \
		fi; \
	done
	@for dir in \
		"$(CHEZMOI_DIR)/claude/commands" \
		"$(DEV_SETUP_CLAUDE_DIR)/commands" \
		"$(DEV_SETUP_CLAUDE_DIR)/commands_$(PROFILE)"; do \
		if [ -d "$$dir" ]; then \
			for f in "$$dir"/*.md; do \
				[ -f "$$f" ] && ln -sf "$$f" "$(CLAUDE_CONFIG_DIR)/commands/$$(basename $$f)"; \
			done; \
		fi; \
	done
	@echo "Claude config setup complete."

# ============================================
# SYSTEM TOOLS
# ============================================

.PHONY: install-xcode
install-xcode:
ifeq ($(UNAME_S), Darwin)
	@xcode-select -p > /dev/null 2>&1 || (echo "Installing Xcode Command Line Tools..." && xcode-select --install)
	@echo "Xcode Command Line Tools ready."
else
	@echo "Skipping Xcode (not macOS)."
endif

.PHONY: install-powerline-fonts
install-powerline-fonts:
ifeq ($(UNAME_S), Darwin)
	@if [ ! "$$(find ~/Library/Fonts -name '*Powerline*' 2>/dev/null | head -1)" ]; then \
		echo "Installing Powerline fonts..." && \
		git clone https://github.com/powerline/fonts.git --depth=1 /tmp/pl-fonts && \
		/tmp/pl-fonts/install.sh && \
		rm -rf /tmp/pl-fonts; \
	else \
		echo "Powerline fonts already installed."; \
	fi
else ifeq ($(UNAME_S), Linux)
	@if [ ! "$$(find ~/.local/share/fonts -name '*Powerline*' 2>/dev/null | head -1)" ]; then \
		echo "Installing Powerline fonts..." && \
		git clone https://github.com/powerline/fonts.git --depth=1 /tmp/pl-fonts && \
		/tmp/pl-fonts/install.sh && \
		rm -rf /tmp/pl-fonts; \
	else \
		echo "Powerline fonts already installed."; \
	fi
endif

.PHONY: setup-iterm2-shell-integration
setup-iterm2-shell-integration:
ifeq ($(UNAME_S), Darwin)
	@if [ ! -f ~/.iterm2_shell_integration.zsh ]; then \
		echo "Installing iTerm2 shell integration..." && \
		curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh; \
	else \
		echo "iTerm2 shell integration already installed."; \
	fi
else
	@echo "Skipping iTerm2 integration (not macOS)."
endif

# ============================================
# macOS DEFAULTS
# ============================================

.PHONY: setup-macos-defaults
setup-macos-defaults:
ifeq ($(UNAME_S), Darwin)
	@echo "Applying macOS defaults..."
	@chmod +x $(DOTFILES_DIR)/macos/defaults.sh && $(DOTFILES_DIR)/macos/defaults.sh
else
	@echo "Skipping macOS defaults (not macOS)."
endif

# ============================================
# IDE / ZED
# ============================================

.PHONY: select-ide
select-ide:
	@echo "Select your preferred IDE:"
	@echo "  1) VS Code  2) Cursor  3) Zed  4) Sublime Text"
	@read -p "Enter choice [1-4]: " choice; \
	mkdir -p $(HOME)/.config/dotfiles; \
	case $$choice in \
		1) echo "vscode"   > $(HOME)/.config/dotfiles/ide ;; \
		2) echo "cursor"   > $(HOME)/.config/dotfiles/ide ;; \
		3) echo "zed"      > $(HOME)/.config/dotfiles/ide ;; \
		4) echo "sublime"  > $(HOME)/.config/dotfiles/ide ;; \
		*) echo "Invalid choice" ;; \
	esac
	@echo "IDE preference saved."

.PHONY: setup-zed-config
setup-zed-config:
	@mkdir -p $(HOME)/.config/zed
	@echo "Zed config directory ready."

# ============================================
# UTILITIES
# ============================================

.PHONY: print-variables
print-variables:
	@echo "=== .env ==="
	@echo "  PROFILE:              $(PROFILE)"
	@echo "  GIT_USER:             $(GIT_USER)"
	@echo "  DEV_SETUP_REPO:       $(if $(DEV_SETUP_REPO),$(DEV_SETUP_REPO),(not set - skipped))"
	@echo "  OBSIDIAN_NOTES_REPO:  $(if $(OBSIDIAN_NOTES_REPO),$(OBSIDIAN_NOTES_REPO),(not set - skipped))"
	@echo "=== System ==="
	@echo "  OS:     $(UNAME_S)"
	@echo "  SHELL:  $(SHELL)"
	@echo ""

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
	@echo "  setup-brewfile         Install profile Brewfile"
	@echo "  setup-macos-defaults   Apply macOS system preferences"
	@echo "  setup-shell            Install/configure Zsh + Oh My Zsh"
	@echo "  setup-notes            Clone Obsidian notes repo"
	@echo "  clone-dev-setup        Clone private dev_setup repo"
	@echo "  select-ide             Choose default IDE"
	@echo "  print-variables        Show resolved config values"
	@echo "  check-env              Validate .env is configured correctly"
	@echo "  help                   Show this message"
