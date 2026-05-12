# ============================================
# ZELLIJ
# ============================================

.PHONY: setup-zellij
setup-zellij:
	@echo "Checking Zellij installation..."
	@command -v zellij &>/dev/null \
		&& echo "Zellij installed: $$(zellij --version)" \
		|| echo "Warning: zellij not found — run 'brew install zellij'"
