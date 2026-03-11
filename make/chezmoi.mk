# ============================================
# CHEZMOI
# ============================================

.PHONY: _link-chezmoi-toml
_link-chezmoi-toml:
	@echo "Linking chezmoi toml config for profile '$(PROFILE)'..."
	@if [ -f "$(CHEZMOI_TOML)" ]; then \
		mkdir -p "$(CHEZMOI_CONFIG_DIR)" && \
		ln -sf "$(CHEZMOI_TOML)" "$(CHEZMOI_CONFIG_DIR)/chezmoi.toml" && \
		ln -sf "$(CONFIGS_DIR)/chezmoi/chezmoiroot" "$(CHEZMOI_DIR)/.chezmoiroot" && \
		echo "Chezmoi toml linked: $(CHEZMOI_TOML)"; \
	else \
		echo "Warning: $(CHEZMOI_TOML) not found, skipping toml link."; \
	fi

.PHONY: setup-chezmoi
setup-chezmoi:
ifeq ($(GIT_USER),)
	@echo "Error: GIT_USER not set." && exit 1
else
	@echo "Configuring chezmoi..."
	@if [ ! -d "$(CHEZMOI_DIR)" ]; then \
		echo "Initializing chezmoi..." && \
		chezmoi init --apply $(GIT_USER); \
	else \
		echo "Chezmoi already initialized. Pulling updates..." && \
		chezmoi git pull; \
	fi
endif
	@$(MAKE) _link-chezmoi-toml
	@echo "Chezmoi setup complete."

.PHONY: update-chezmoi
update-chezmoi:
	@echo "Updating chezmoi..."
	@if [ ! -d "$(CHEZMOI_DIR)" ]; then \
		echo "Chezmoi not initialized. Run 'make setup' first." && exit 1; \
	fi
	@chezmoi update --apply
	@$(MAKE) _link-chezmoi-toml
	@echo "Chezmoi update complete."
