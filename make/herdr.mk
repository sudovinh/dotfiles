# ============================================
# HERDR
# ============================================

# Community plugins to install via `herdr plugin install`.
# Add one repo slug per line to pick up a new plugin.
HERDR_PLUGINS := \
	iurysza/herdr-tab-smart-rename

.PHONY: setup-herdr
setup-herdr: install-herdr-plugins
	@echo "Setting up Herdr integrations..."
	@if command -v herdr >/dev/null 2>&1; then \
		herdr integration install claude; \
	else \
		echo "Warning: herdr not found, skipping integration install."; \
	fi
	@echo "Herdr setup complete."

.PHONY: install-herdr-plugins
install-herdr-plugins:
	@if command -v herdr >/dev/null 2>&1; then \
		for plugin in $(HERDR_PLUGINS); do \
			echo "Installing Herdr plugin: $$plugin"; \
			herdr plugin install $$plugin --yes; \
		done; \
	else \
		echo "Warning: herdr not found, skipping plugin install."; \
	fi
