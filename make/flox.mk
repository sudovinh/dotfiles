# ============================================
# FLOX
# ============================================

.PHONY: install-flox
install-flox: ## Install flox CLI (via brew cask on macOS, install script on Linux)
	@echo "Installing Flox..."
	@if command -v brew > /dev/null 2>&1; then \
		brew install --cask flox 2>/dev/null || brew upgrade --cask flox; \
	else \
		command -v flox > /dev/null 2>&1 || curl -fsSL $(FLOX_INSTALL_SCRIPT) | bash; \
	fi
	@echo "Flox ready."

.PHONY: install-direnv
install-direnv: ## Install direnv if not present
	@command -v direnv > /dev/null 2>&1 || (echo "Installing Direnv..." && curl -fsSL $(DIRENV_INSTALL_SCRIPT) | bash)
	@echo "Direnv ready."

.PHONY: setup-flox-config
setup-flox-config: ## Verify flox environment exists for active profile
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
