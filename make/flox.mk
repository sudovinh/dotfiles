# ============================================
# FLOX
# ============================================

.PHONY: install-flox
install-flox: ## Install flox CLI (via brew cask on macOS, install script on Linux); set FLOX_VERSION in .env to pin a version
	@if command -v flox > /dev/null 2>&1; then \
		echo "Flox ready."; \
	elif command -v brew > /dev/null 2>&1; then \
		if [ -n "$(FLOX_VERSION)" ]; then \
			brew install --cask flox@$(FLOX_VERSION) 2>/dev/null || true; \
		else \
			brew install --cask flox 2>/dev/null || true; \
		fi; \
		FLOX_PKG=$$(find /opt/homebrew/Caskroom/flox -name "*.pkg" 2>/dev/null | sort -V | tail -1); \
		if [ -z "$$FLOX_PKG" ]; then \
			echo "ERROR: No flox pkg found after brew install" && exit 1; \
		fi; \
		echo "Running pkg installer (requires sudo)..."; \
		sudo installer -pkg "$$FLOX_PKG" -target / && echo "Flox ready." || exit 1; \
	else \
		echo "Installing Flox via install script..."; \
		curl -fsSL $(FLOX_INSTALL_SCRIPT) | bash && echo "Flox ready." || exit 1; \
	fi

.PHONY: install-direnv
install-direnv: ## Install direnv if not present
	@command -v direnv > /dev/null 2>&1 || (echo "Installing Direnv..." && curl -fsSL $(DIRENV_INSTALL_SCRIPT) | bash)
	@echo "Direnv ready."

.PHONY: remove-devbox-envrc
remove-devbox-envrc:
	@if [ -f "$(HOME)/.envrc" ] && grep -q "devbox" "$(HOME)/.envrc" 2>/dev/null; then \
		echo "Removing devbox ~/.envrc..."; \
		rm "$(HOME)/.envrc"; \
	fi

.PHONY: setup-flox-config
setup-flox-config: remove-devbox-envrc ## Verify flox environment exists for active profile
	@if [ -d "$(FLOX_PROFILE_DIR)/.flox" ]; then \
		echo "Flox environment found for profile '$(PROFILE)'."; \
	else \
		echo "ERROR: No flox environment at $(FLOX_PROFILE_DIR)/.flox" && exit 1; \
	fi

.PHONY: refresh-flox-config
refresh-flox-config: ## Update packages in the active flox profile
	@if [ -d "$(FLOX_PROFILE_DIR)/.flox" ]; then \
		echo "Updating flox environment for profile '$(PROFILE)'..."; \
		cd $(FLOX_PROFILE_DIR) && flox update; \
		echo "Flox config refreshed."; \
	else \
		echo "ERROR: No flox environment at $(FLOX_PROFILE_DIR)/.flox" && exit 1; \
	fi
