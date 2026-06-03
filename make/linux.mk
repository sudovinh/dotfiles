# ============================================
# LINUX TOOL INSTALLERS
# ============================================
# Tools that macOS gets from Homebrew but that have no equivalent package
# layer on Linux. Installed via official scripts/releases into $(LOCAL_BIN),
# which is already on PATH (see dot_zshrc.tmpl). All targets are idempotent.

.PHONY: install-chezmoi
install-chezmoi: ## Install chezmoi into $(LOCAL_BIN) on Linux (no-op if present)
ifeq ($(UNAME_S), Linux)
	@if command -v chezmoi > /dev/null 2>&1; then \
		echo "chezmoi ready."; \
	else \
		echo "Installing chezmoi..." && \
		mkdir -p "$(LOCAL_BIN)" && \
		sh -c "$$(curl -fsSL get.chezmoi.io)" -- -b "$(LOCAL_BIN)" && \
		echo "chezmoi ready."; \
	fi
else
	@echo "Skipping chezmoi install (handled by Homebrew on macOS)."
endif

.PHONY: install-zellij
install-zellij: ## Install zellij into $(LOCAL_BIN) on Linux (no-op if present)
ifeq ($(UNAME_S), Linux)
	@if command -v zellij > /dev/null 2>&1; then \
		echo "zellij ready."; \
	else \
		echo "Installing zellij..." && \
		mkdir -p "$(LOCAL_BIN)" && \
		curl -fsSL "$(ZELLIJ_RELEASE_URL)" \
			| tar -xz -C "$(LOCAL_BIN)" zellij && \
		chmod +x "$(LOCAL_BIN)/zellij" && \
		echo "zellij ready."; \
	fi
else
	@echo "Skipping zellij install (handled by Homebrew on macOS)."
endif

.PHONY: install-orion
install-orion: ## Install Orion browser on Linux via Flatpak (macOS uses the brew cask)
ifeq ($(UNAME_S), Linux)
	@if command -v flatpak > /dev/null 2>&1 && flatpak list --app 2>/dev/null | grep -qi orion; then \
		echo "Orion ready."; \
	else \
		echo "Installing Orion browser (Flatpak beta v$(ORION_VERSION); pulls the GNOME runtime on first install)..."; \
		command -v flatpak > /dev/null 2>&1 || (echo "Installing flatpak..." && sudo apt-get install -y flatpak); \
		flatpak remote-add --user --if-not-exists flathub "$(FLATHUB_REPO_URL)"; \
		case "$(UNAME_M)" in \
			aarch64|arm64) ARCH_SFX=".arm" ;; \
			*) ARCH_SFX="" ;; \
		esac; \
		TMP_FP="$$(mktemp -d)/orion.flatpak"; \
		echo "Downloading Orion v$(ORION_VERSION) ($(UNAME_M))..." && \
		curl -fsSL "https://orionbrowser.com/download/oriongtk.$(ORION_VERSION)$$ARCH_SFX.flatpak" -o "$$TMP_FP" || exit 1; \
		flatpak install --user -y "$$TMP_FP" || exit 1; \
		rm -f "$$TMP_FP"; \
		echo "Orion ready."; \
		echo "  NOTE: log out and back in (or reboot) for Orion to appear in your app launcher."; \
		echo "        To launch it now: flatpak run com.kagi.OrionGtk"; \
	fi
else
	@echo "Skipping Orion install (handled by Homebrew cask on macOS)."
endif
