# ============================================
# CLAUDE
# ============================================

.PHONY: setup-claude-config
setup-claude-config:
	@echo "Setting up Claude Code configuration..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)
	@# Write settings as real file (not symlink) to prevent repo drift from session changes
	@if [ -n "$(DEV_SETUP_REPO)" ] && [ -d "$(DEV_SETUP_CLAUDE_DIR)" ]; then \
		PROFILE_SRC="$(DEV_SETUP_CLAUDE_DIR)/claude_settings_local_$(PROFILE).json"; \
		LIVE="$(CLAUDE_CONFIG_DIR)/settings.json"; \
		if [ -f "$$PROFILE_SRC" ]; then \
			echo "Syncing Claude settings from $$PROFILE_SRC..."; \
			if [ -f "$$LIVE" ] && [ ! -L "$$LIVE" ] && command -v jq >/dev/null 2>&1; then \
				echo "Merging safe fields from live settings..." && \
				jq -s '.[0] as $$p | .[1] as $$l | $$p | .permissions.allow = (($$p.permissions.allow // []) + ($$l.permissions.allow // []) | unique)' \
					"$$PROFILE_SRC" "$$LIVE" > "$$LIVE.tmp" && \
				mv "$$LIVE.tmp" "$$LIVE" && \
				cp "$$LIVE" "$$PROFILE_SRC"; \
			else \
				rm -f "$$LIVE" && cp "$$PROFILE_SRC" "$$LIVE"; \
			fi; \
		else \
			echo "Warning: $$PROFILE_SRC not found, skipping settings sync."; \
		fi; \
		rm -f "$(CLAUDE_CONFIG_DIR)/settings.local.json"; \
	else \
		echo "dev_setup not available, skipping Claude settings sync."; \
	fi
	@# Merge MCP servers from profile config into ~/.claude.json
	@if [ -n "$(DEV_SETUP_REPO)" ] && [ -d "$(DEV_SETUP_CLAUDE_DIR)" ]; then \
		MCP_SRC="$(DEV_SETUP_CLAUDE_DIR)/claude_mcp_$(PROFILE).json"; \
		CLAUDE_USER_CFG="$(HOME)/.claude.json"; \
		if [ -f "$$MCP_SRC" ] && [ -f "$$CLAUDE_USER_CFG" ] && command -v jq >/dev/null 2>&1; then \
			STRIPPED=$$(sed 's|^\s*//.*||' "$$MCP_SRC"); \
			if ! echo "$$STRIPPED" | jq empty >/dev/null 2>&1; then \
				STRIPPED='{"mcpServers": {}}'; \
			fi; \
			echo "Merging MCP servers from $$MCP_SRC into $$CLAUDE_USER_CFG..." && \
			echo "$$STRIPPED" | jq -s '.[0].mcpServers = (.[1].mcpServers // {}) | .[0]' \
				"$$CLAUDE_USER_CFG" - > "$$CLAUDE_USER_CFG.tmp" && \
			mv "$$CLAUDE_USER_CFG.tmp" "$$CLAUDE_USER_CFG"; \
		elif [ -f "$$MCP_SRC" ] && ! command -v jq >/dev/null 2>&1; then \
			echo "Warning: jq not found, skipping MCP server merge."; \
		else \
			echo "Warning: $$MCP_SRC or $$CLAUDE_USER_CFG not found, skipping MCP server merge."; \
		fi; \
	fi
	@# Symlink agents and commands
	@echo "Setting up custom agents and commands..."
	@mkdir -p "$(CLAUDE_CONFIG_DIR)/agents" "$(CLAUDE_CONFIG_DIR)/commands"
	@rm -f "$(CLAUDE_CONFIG_DIR)/agents/"*.md "$(CLAUDE_CONFIG_DIR)/commands/"*.md
	@for dir in \
		"$(CHEZMOI_DIR)/claude/agents" \
		"$(DEV_SETUP_CLAUDE_DIR)/agents" \
		"$(DEV_SETUP_CLAUDE_DIR)/agents_$(PROFILE)"; do \
		if [ -d "$$dir" ] && ls "$$dir"/*.md >/dev/null 2>&1; then \
			for f in "$$dir"/*.md; do \
				ln -sf "$$f" "$(CLAUDE_CONFIG_DIR)/agents/$$(basename $$f)"; \
			done; \
		fi; \
	done
	@for dir in \
		"$(CHEZMOI_DIR)/claude/commands" \
		"$(DEV_SETUP_CLAUDE_DIR)/commands" \
		"$(DEV_SETUP_CLAUDE_DIR)/commands_$(PROFILE)"; do \
		if [ -d "$$dir" ] && ls "$$dir"/*.md >/dev/null 2>&1; then \
			for f in "$$dir"/*.md; do \
				ln -sf "$$f" "$(CLAUDE_CONFIG_DIR)/commands/$$(basename $$f)"; \
			done; \
		fi; \
	done
	@echo "Claude config setup complete."
