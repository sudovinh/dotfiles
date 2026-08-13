# ============================================
# FLOX
# ============================================

.PHONY: install-flox
install-flox: ## Install flox CLI (official .pkg installer on macOS, apt repo on Linux); set FLOX_VERSION in .env to pin a version
	@export PATH="/opt/homebrew/bin:$$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$$PATH"; \
	if command -v flox > /dev/null 2>&1; then \
		echo "Flox ready."; \
	elif [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Installing Flox via official pkg installer ($(FLOX_OSX_PKG_URL))..."; \
		FLOX_PKG=$$(mktemp "$${TMPDIR:-/tmp}/flox-install-pkg.XXXXXXXX.pkg"); \
		curl -fsSL -o "$$FLOX_PKG" "$(FLOX_OSX_PKG_URL)" || exit 1; \
		echo "Running pkg installer (requires sudo)..."; \
		sudo installer -pkg "$$FLOX_PKG" -target / || exit 1; \
		rm -f "$$FLOX_PKG"; \
		export PATH="/opt/homebrew/bin:$$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$$PATH"; \
		if command -v flox > /dev/null 2>&1; then \
			echo "Flox ready."; \
		else \
			echo "ERROR: flox not on PATH after pkg install; open a new shell and re-run." && exit 1; \
		fi; \
	else \
		echo "Installing Flox via apt repository (downloads.flox.dev)..."; \
		wget -qO - "$(FLOX_DEB_KEYRING_URL)" | sudo tee /usr/share/keyrings/flox-archive-keyring.gpg >/dev/null || exit 1; \
		echo "deb [signed-by=/usr/share/keyrings/flox-archive-keyring.gpg] $(FLOX_DEB_REPO_URL) stable/" \
			| sudo tee /etc/apt/sources.list.d/flox.list >/dev/null || exit 1; \
		sudo apt-get update || exit 1; \
		if [ -n "$(FLOX_VERSION)" ]; then \
			sudo apt-get install -y flox=$(FLOX_VERSION) || exit 1; \
		else \
			sudo apt-get install -y flox || exit 1; \
		fi; \
		if command -v flox > /dev/null 2>&1; then \
			echo "Flox ready."; \
		else \
			echo "ERROR: flox not on PATH after install; open a new shell and re-run." && exit 1; \
		fi; \
	fi

.PHONY: upgrade-flox
upgrade-flox: ## Upgrade the flox CLI itself (official .pkg installer on macOS, apt on Linux); set FLOX_VERSION in .env to pin a version
	@export PATH="/opt/homebrew/bin:$$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$$PATH"; \
	if [ "$(UNAME_S)" = "Darwin" ]; then \
		echo "Upgrading Flox via official pkg installer ($(FLOX_OSX_PKG_URL))..."; \
		FLOX_PKG=$$(mktemp "$${TMPDIR:-/tmp}/flox-upgrade-pkg.XXXXXXXX.pkg"); \
		curl -fsSL -o "$$FLOX_PKG" "$(FLOX_OSX_PKG_URL)" || exit 1; \
		echo "Running pkg installer (requires sudo)..."; \
		sudo installer -pkg "$$FLOX_PKG" -target / || exit 1; \
		rm -f "$$FLOX_PKG"; \
	else \
		echo "Upgrading Flox via apt..."; \
		sudo apt-get update || exit 1; \
		if [ -n "$(FLOX_VERSION)" ]; then \
			sudo apt-get install -y flox=$(FLOX_VERSION) || exit 1; \
		else \
			sudo apt-get install --only-upgrade -y flox || exit 1; \
		fi; \
	fi; \
	export PATH="/opt/homebrew/bin:$$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$$PATH"; \
	flox --version

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
