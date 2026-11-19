# ============================================
# HERDR
# ============================================

.PHONY: setup-herdr
setup-herdr: install-herdr-app
	@echo "Setting up Herdr integrations..."
	@if command -v herdr >/dev/null 2>&1; then \
		herdr integration install claude; \
	else \
		echo "Warning: herdr not found, skipping integration install."; \
	fi
	@echo "Herdr setup complete."

# Optional: set HERDR_APP=true in .env to install the Herdr desktop app.
.PHONY: install-herdr-app
install-herdr-app:
ifeq ($(UNAME_S), Darwin)
	@if [ "$(HERDR_APP)" != "true" ]; then \
		echo "HERDR_APP not set, skipping Herdr app."; \
	elif [ -d /Applications/Herdr.app ]; then \
		echo "Herdr app already installed."; \
	else \
		brew install --cask herdr-app; \
	fi
else
	@echo "Skipping Herdr app (macOS only)."
endif
