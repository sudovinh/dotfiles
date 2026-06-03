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
