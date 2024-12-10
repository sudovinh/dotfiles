SHELL := /bin/bash
DOTFILES_DIR := $(HOME)/dotfiles
BREW_DIR := $(DOTFILES_DIR)/brew
BREWFILE_DEFAULT := $(BREW_DIR)/default
CHEZMOI_CONFIG_DIR := $(HOME)/.config/chezmoi
CHEZMOI_DIR := $(HOME)/.local/share/chezmoi
CONFIGS_DIR := $(DOTFILES_DIR)/configs
DEVBOX_CONFIG_DIR := $(DOTFILES_DIR)/devbox
DEVBOX_INSTALL_SCRIPT := https://get.jetify.com/devbox
DIRENV_INSTALL_SCRIPT := https://direnv.net/install.sh
DEVBOX_GLOBAL_CONFIG := $(HOME)/.local/share/devbox/global/default
DOTFILE_SCRIPTS := $(DOTFILES_DIR)/scripts
GIT_USER := sudovinh
HOMEBREW_URL := https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
OBSIDIAN_NOTES_REPO := git@github.com:sudovinh/second-brain.git
OH_MY_ZSH_INSTALL_SCRIPT := https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
UNAME_S := $(shell uname -s)
ZSH_PLUGIN_URLS := \
	"https://github.com/zsh-users/zsh-autosuggestions.git" \
	"https://github.com/zsh-users/zsh-syntax-highlighting.git"
PROFILE_CHOICE :=

clean: clean-profile

.PHONY: clean-profile
clean-profile:
	@echo "Cleaning up temporary profile-choice file..."
	@if [ -f .profile-choice ]; then \
		rm .profile-choice; \
		echo "Temporary profile-choice file removed."; \
	else \
		echo "No temporary profile-choice file found. Skipping cleanup."; \
	fi
	@echo "Profile cleanup complete."

.PHONY: print-variables
print-variables:
	@echo "SHELL: $(SHELL)"
	@echo "UNAME_S: $(UNAME_S)"
	@echo "HOMEBREW_URL: $(HOMEBREW_URL)"
	@echo "DOTFILES_DIR: $(DOTFILES_DIR)"
	@echo "DOTFILE_SCRIPTS: $(DOTFILE_SCRIPTS)"
	@echo "BREW_DIR: $(BREW_DIR)"
	@echo "BREWFILE_DEFAULT: $(BREWFILE_DEFAULT)"
	@echo "CONFIGS_DIR: $(CONFIGS_DIR)"
	@echo "DEVBOX_CONFIG_DIR: $(DEVBOX_CONFIG_DIR)"
	@echo "DEVBOX_INSTALL_SCRIPT: $(DEVBOX_INSTALL_SCRIPT)"
	@echo "DEVBOX_GLOBAL_CONFIG: $(DEVBOX_GLOBAL_CONFIG)"
	@echo "DIRENV_INSTALL_SCRIPT: $(DIRENV_INSTALL_SCRIPT)"
	@echo "OH_MY_ZSH_INSTALL_SCRIPT: $(OH_MY_ZSH_INSTALL_SCRIPT)"
	@echo "ZSH_PLUGIN_URLS: $(ZSH_PLUGIN_URLS)"
	@echo "PROFILE_CHOICE: $(PROFILE_CHOICE)"

.PHONY: initialize
initialize: print-variables
ifeq ($(UNAME_S), Darwin)
	@echo "Detected macOS, running pre-setup..."
	$(MAKE) mac-init
else ifeq ($(UNAME_S), Linux)
	@echo "Detected Linux, running pre-setup..."
	$(MAKE) linux-init
else
	@echo "Unsupported OS"
endif

.PHONY: mac-init
mac-init: select-profile install-powerline-fonts install-xcode install-homebrew install-devbox install-direnv brew-bundle-default setup-shell setup-brewfile setup-devbox-config setup-chezmoi setup-notes clean-profile

.PHONY: linux-init
linux-init: select-profile install-powerline-fonts install-devbox install-direnv setup-shell setup-devbox-config setup-chezmoi setup-notes clean-profile
	@echo "Setting up for Linux..."
	# Add additional Linux setup steps here, such as package manager commands.

.PHONE: configure
configure: select-profile
	@echo "tbd..."

.PHONY: select-profile
select-profile: set-profile

.PHONY: set-profile
set-profile:
	@echo "Is this setup for (1) Main (Personal) or (2) Work? Enter 1 or 2: "
	@read CHOICE; \
	case $$CHOICE in \
		1) echo "Using Main profile"; PROFILE_CHOICE=main;; \
		2) echo "Using Work profile"; PROFILE_CHOICE=work;; \
		*) echo "Invalid choice. Skipping profile-specific setup."; PROFILE_CHOICE=none;; \
	esac; \
	echo $$PROFILE_CHOICE > .profile-choice

.PHONY: install-powerline-fonts
install-powerline-fonts:
	@echo "Checking for existing Powerline fonts..."
ifeq ($(UNAME_S), Darwin)
	@if [ ! "$(shell find ~/Library/Fonts -name '*Powerline*' | head -n 1)" ]; then \
		echo "No Powerline fonts found. Installing..."; \
		git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts; \
		cd /tmp/fonts && ./install.sh; \
		cd .. && rm -rf /tmp/fonts; \
		echo "Powerline fonts installed successfully."; \
	else \
		echo "Powerline fonts already installed on macOS."; \
	fi
else ifeq ($(UNAME_S), Linux)
	@if [ ! "$(shell find ~/.local/share/fonts -name '*Powerline*' | head -n 1)" ]; then \
		echo "No Powerline fonts found. Installing..."; \
		git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts; \
		cd /tmp/fonts && ./install.sh; \
		cd .. && rm -rf /tmp/fonts; \
		echo "Powerline fonts installed successfully."; \
	else \
		echo "Powerline fonts already installed on Linux."; \
	fi
endif

.PHONY: install-xcode
install-xcode:
	@echo "Checking for Xcode Command Line Tools..."
	@xcode-select -p > /dev/null 2>&1 || (echo "Installing Xcode Command Line Tools..." && xcode-select --install)

.PHONY: install-homebrew
install-homebrew:
	@echo "Checking for Homebrew..."
	@which brew > /dev/null 2>&1 || (echo "Installing Homebrew..." && /bin/bash -c "$$(curl -fsSL $(HOMEBREW_URL))")
	@eval "$$(/opt/homebrew/bin/brew shellenv)"
	@echo "Homebrew installation complete."

.PHONY: install-devbox
install-devbox:
	@echo "Checking for Devbox..."
	@command -v devbox > /dev/null 2>&1 || (echo "Devbox not found. Installing..." && curl -fsSL $(DEVBOX_INSTALL_SCRIPT) | bash)
	@echo "Devbox installation complete or already exists."

.PHONY: install-direnv
install-direnv:
	@echo "Checking for Direnv..."
	@command -v direnv > /dev/null 2>&1 || (echo "Direnv not found. Installing..." && curl -fsSL $(DIRENV_INSTALL_SCRIPT) | bash)
	@echo "Direnv installation complete or already exists."

.PHONY: brew-bundle-default
brew-bundle-default:
	@echo "Installing default Brewfile..."
	@if [ ! -f "$(BREWFILE_DEFAULT)" ]; then \
		echo "Error: Default Brewfile not found at $(BREWFILE_DEFAULT). Make sure the dotfiles repo is cloned correctly."; \
		exit 1; \
	fi
	@brew bundle --file=$(BREWFILE_DEFAULT)

.PHONY: setup-brewfile
setup-brewfile:
	@if [ -f .profile-choice ]; then \
		PROFILE_CHOICE=$$(cat .profile-choice); \
		if [ "$$PROFILE_CHOICE" = "main" ]; then \
			BREWFILE=$(BREW_DIR)/main; \
		elif [ "$$PROFILE_CHOICE" = "work" ]; then \
			BREWFILE=$(BREW_DIR)/work; \
		else \
			BREWFILE=""; \
		fi; \
		if [ -n "$$BREWFILE" ] && [ -f "$$BREWFILE" ]; then \
			echo "Installing additional Brewfile: $$BREWFILE..."; \
			brew bundle --file=$$BREWFILE; \
		elif [ -n "$$BREWFILE" ]; then \
			echo "Error: Brewfile not found at $$BREWFILE"; \
			exit 1; \
		else \
			echo "No additional Brewfile selected. Skipping."; \
		fi; \
	else \
		echo "No profile selected. Skipping Brewfile setup."; \
	fi

.PHONY: setup-devbox-config
setup-devbox-config:
	@if [ -f .profile-choice ]; then \
		PROFILE_CHOICE=$$(cat .profile-choice); \
		if [ "$$PROFILE_CHOICE" = "main" ]; then \
			DEVBOX_PROFILE=$(DEVBOX_CONFIG_DIR)/main; \
		elif [ "$$PROFILE_CHOICE" = "work" ]; then \
			DEVBOX_PROFILE=$(DEVBOX_CONFIG_DIR)/work; \
		else \
			DEVBOX_PROFILE=""; \
		fi; \
		if [ -n "$$DEVBOX_PROFILE" ] && [ -d "$$DEVBOX_PROFILE" ]; then \
			echo "Setting up Devbox config from $$DEVBOX_PROFILE..."; \
			mkdir -p $(DEVBOX_GLOBAL_CONFIG); \
			rm -f $(DEVBOX_GLOBAL_CONFIG)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.lock; \
			ln -s $$DEVBOX_PROFILE/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.json; \
			ln -s $$DEVBOX_PROFILE/devbox.lock $(DEVBOX_GLOBAL_CONFIG)/devbox.lock; \
			echo "Devbox config linked to $$DEVBOX_PROFILE"; \
			eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r; \
			echo "Devbox config refreshed."; \
		else \
			echo "Skipping Devbox config setup. Invalid or missing directory."; \
		fi; \
	else \
		echo "No profile selected. Skipping Devbox config setup."; \
	fi

.PHONY: setup-shell
setup-shell: setup-zsh
	@echo "Setting up Zsh..."
	@echo "Checking for Zsh..."
ifeq ($(UNAME_S), Darwin)
	@command -v zsh > /dev/null 2>&1 || (echo "Zsh not found. Installing..." && brew install zsh)
else ifeq ($(UNAME_S), Linux)
	@command -v zsh > /dev/null 2>&1 || (echo "Zsh not found. Installing..." && apt install zsh)
endif
	@command -v chsh -s $(which zsh)
	@echo "Shell setup complete. Using Zsh as the default shell."

.PHONY: setup-zsh
setup-zsh: install-oh-my-zsh-plugins
	@echo "Checking for Oh My Zsh installation..."
	@if [ ! -d $(HOME)/.oh-my-zsh ]; then \
		echo "Oh My Zsh not found. Installing..."; \
		sh -c "$$(curl -fsSL $(OH_MY_ZSH_INSTALL_SCRIPT))"; \
		echo "Oh My Zsh installation complete."; \
	else \
		echo "Oh My Zsh already installed."; \
	fi

.PHONY: install-oh-my-zsh-plugins
install-oh-my-zsh-plugins:
	@echo "Installing Oh My Zsh plugins..."
	@for url in $(ZSH_PLUGIN_URLS); do \
		plugin_name=$$(basename $$url .git); \
		if [ ! -d $${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/$$plugin_name ]; then \
			echo "Installing $$plugin_name..."; \
			git clone $$url $${ZSH_CUSTOM:-$(HOME)/.oh-my-zsh/custom}/plugins/$$plugin_name; \
		else \
			echo "$$plugin_name already installed."; \
		fi; \
	done
	@echo "Oh My Zsh plugins installation complete."

.PHONY: setup-chezmoi
setup-chezmoi:
	@echo "Configuring chezmoi..."
	@if [ ! -d "$(CHEZMOI_DIR)" ]; then \
		echo "Initializing chezmoi for the first time..." && \
		chezmoi init --apply $(GIT_USER); \
	else \
		echo "Chezmoi already initialized. Pulling updates from the repository..." && \
		chezmoi git pull; \
	fi
	@echo "Copying chezmoi toml config..."
	@bash -c 'if [ -f .profile-choice ]; then \
		PROFILE_CHOICE=$$(cat .profile-choice); \
		if [ "$$PROFILE_CHOICE" = "main" ]; then \
			CHEZMOI_TOML="$(CONFIGS_DIR)/chezmoi/main.toml"; \
		elif [ "$$PROFILE_CHOICE" = "work" ]; then \
			CHEZMOI_TOML="$(CONFIGS_DIR)/chezmoi/work.toml"; \
		else \
			CHEZMOI_TOML=""; \
		fi; \
		CHEZMOI_ROOT="$(CONFIGS_DIR)/chezmoi/.chezmoiroot"; \
		if [ -n "$$CHEZMOI_TOML" ] && [ -f "$$CHEZMOI_TOML" ]; then \
			echo "Setting up Chezmoi toml config from $$CHEZMOI_TOML" && \
			mkdir -p "$(CHEZMOI_CONFIG_DIR)" && \
			ln -sf "$$CHEZMOI_TOML" "$(CHEZMOI_CONFIG_DIR)/chezmoi.toml" && \
			ln -sf "$$CHEZMOI_ROOT" "$(CHEZMOI_DIR)/.chezmoiroot" && \
			echo "Chezmoi toml config linked to $$CHEZMOI_TOML"; \
		else \
			echo "Skipping Chezmoi toml config setup. Invalid or missing file."; \
		fi; \
	else \
		echo "No profile selected. Skipping Chezmoi toml config setup."; \
	fi'
	@echo "Chezmoi setup complete."

.PHONE: setup-notes
setup-notes:
	@echo "Setting up Obsidian notes..."
	@REPO_NAME=$$(basename $(OBSIDIAN_NOTES_REPO) .git); \
	if [ ! -d $(HOME)/$$REPO_NAME ]; then \
		echo "Cloning Obsidian notes repository..."; \
		git clone $(OBSIDIAN_NOTES_REPO) $(HOME)/$$REPO_NAME; \
		echo "Obsidian notes setup complete."; \
	else \
		echo "Obsidian notes repository already cloned."; \
	fi

.PHONY: help
help:
	@echo "Makefile for dotfiles setup"
	@echo ""
	@echo "Targets:"
	@echo "  initialize: Run pre-setup checks and install necessary tools"
	@echo "  configure: other setup steps tbd"
	@echo "  print-variables: Print Makefile variables"
	@echo "  clean: Clean up temporary files"
	@echo "  help: Display this help message"
