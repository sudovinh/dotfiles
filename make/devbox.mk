# ============================================
# DEVBOX
# ============================================

.PHONY: install-devbox
install-devbox:
	@command -v devbox > /dev/null 2>&1 || (echo "Installing Devbox..." && curl -fsSL $(DEVBOX_INSTALL_SCRIPT) | bash)
	@echo "Devbox ready."

.PHONY: install-direnv
install-direnv:
	@command -v direnv > /dev/null 2>&1 || (echo "Installing Direnv..." && curl -fsSL $(DIRENV_INSTALL_SCRIPT) | bash)
	@echo "Direnv ready."

.PHONY: _link-devbox
_link-devbox:
	@if [ -d "$(DEVBOX_PROFILE_DIR)" ]; then \
		echo "Linking Devbox config for profile '$(PROFILE)'..." && \
		mkdir -p $(DEVBOX_GLOBAL_CONFIG) && \
		rm -f $(DEVBOX_GLOBAL_CONFIG)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.lock && \
		ln -sf $(DEVBOX_PROFILE_DIR)/devbox.json $(DEVBOX_GLOBAL_CONFIG)/devbox.json && \
		ln -sf $(DEVBOX_PROFILE_DIR)/devbox.lock $(DEVBOX_GLOBAL_CONFIG)/devbox.lock && \
		echo "Devbox config linked."; \
	else \
		echo "No Devbox profile dir at $(DEVBOX_PROFILE_DIR), skipping."; \
	fi

.PHONY: setup-devbox-config
setup-devbox-config: _link-devbox

.PHONY: refresh-devbox-config
refresh-devbox-config: _link-devbox
	@if [ -d "$(DEVBOX_PROFILE_DIR)" ]; then \
		echo "Regenerating devbox.lock..." && \
		cd $(DEVBOX_GLOBAL_CONFIG) && devbox install --refresh 2>/dev/null || devbox install && \
		eval "$$(devbox global shellenv --preserve-path-stack -r)" && hash -r 2>/dev/null || true && \
		echo "Devbox config refreshed."; \
	fi
