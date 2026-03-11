# ============================================
# TMUX
# ============================================

.PHONY: setup-tmux
setup-tmux:
	@echo "Setting up TPM (Tmux Plugin Manager)..."
	@if [ ! -d "$(TPM_DIR)" ]; then \
		echo "Cloning TPM..." && git clone $(TPM_REPO) $(TPM_DIR); \
	else \
		echo "TPM already installed."; \
	fi
	@echo "Installing tmux plugins..."
	@if [ -x "$(TPM_DIR)/bin/install_plugins" ]; then \
		tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$(HOME)/.tmux/plugins" \; source-file "$(HOME)/.tmux.conf" 2>/dev/null || true; \
		$(TPM_DIR)/bin/install_plugins; \
		echo "Tmux plugins installed."; \
	else \
		echo "TPM install script not found, skipping."; \
	fi

.PHONY: update-tmux-plugins
update-tmux-plugins:
	@echo "Updating tmux plugins..."
	@if [ ! -x "$(TPM_DIR)/bin/update_plugins" ]; then \
		echo "TPM not installed. Run 'make setup-tmux' first." && exit 1; \
	fi
	@tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$(HOME)/.tmux/plugins" \; source-file "$(HOME)/.tmux.conf" 2>/dev/null || true
	@$(TPM_DIR)/bin/install_plugins
	@$(TPM_DIR)/bin/update_plugins all
