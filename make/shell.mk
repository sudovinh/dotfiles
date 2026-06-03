# ============================================
# SHELL (Oh My Zsh)
# ============================================

.PHONY: _install-omz-plugins
_install-omz-plugins:
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

.PHONY: _setup-omz
_setup-omz: _install-omz-plugins
	@if [ ! -d $(HOME)/.oh-my-zsh ]; then \
		echo "Installing Oh My Zsh..." && \
		RUNZSH=no CHSH=no sh -c "$$(curl -fsSL $(OH_MY_ZSH_INSTALL_SCRIPT))" "" --unattended; \
	else \
		echo "Oh My Zsh already installed."; \
	fi

.PHONY: setup-shell
setup-shell: _setup-omz
ifeq ($(UNAME_S), Darwin)
	@command -v zsh > /dev/null 2>&1 || (echo "Installing zsh..." && brew install zsh)
	@if [ "$$(dscl . -read /Users/$(USER) UserShell 2>/dev/null | awk '{print $$2}')" != "$$(command -v zsh)" ]; then \
		echo "Setting zsh as default shell..." && \
		sudo dscl . -create /Users/$(USER) UserShell $$(command -v zsh); \
	fi
else ifeq ($(UNAME_S), Linux)
	@command -v zsh > /dev/null 2>&1 || (echo "Installing zsh..." && sudo apt-get install -y zsh)
	@if [ "$$SHELL" != "$$(command -v zsh)" ]; then \
		echo "Setting zsh as default shell..." && \
		sudo chsh -s "$$(command -v zsh)" "$(USER)"; \
	fi
endif
	@echo "Shell setup complete."

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
