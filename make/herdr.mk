# ============================================
# HERDR
# ============================================

.PHONY: setup-herdr
setup-herdr:
	@echo "Setting up Herdr integrations..."
	@if command -v herdr >/dev/null 2>&1; then \
		herdr integration install claude; \
	else \
		echo "Warning: herdr not found, skipping integration install."; \
	fi
	@echo "Herdr setup complete."
