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
		sh -c "$$(curl -fsSL $(OH_MY_ZSH_INSTALL_SCRIPT))"; \
	else \
		echo "Oh My Zsh already installed."; \
	fi

.PHONY: setup-shell
setup-shell: _setup-omz
ifeq ($(UNAME_S), Darwin)
	@command -v zsh > /dev/null 2>&1 || (echo "Installing zsh..." && brew install zsh)
else ifeq ($(UNAME_S), Linux)
	@command -v zsh > /dev/null 2>&1 || (echo "Installing zsh..." && apt install zsh)
endif
	@chsh -s $$(which zsh) 2>/dev/null || true
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
