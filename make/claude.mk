# ============================================
# CLAUDE
# ============================================

.PHONY: setup-claude-config
setup-claude-config:
	@echo "Setting up Claude Code configuration..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)
	@# Link settings if dev_setup is available
	@if [ -n "$(DEV_SETUP_REPO)" ] && [ -d "$(DEV_SETUP_CLAUDE_DIR)" ]; then \
		CLAUDE_SRC="$(DEV_SETUP_CLAUDE_DIR)/claude_settings_local_$(PROFILE).json"; \
		if [ -f "$$CLAUDE_SRC" ]; then \
			echo "Linking Claude settings from $$CLAUDE_SRC..." && \
			ln -sf "$$CLAUDE_SRC" "$(CLAUDE_CONFIG_DIR)/settings.json" && \
			ln -sf "$$CLAUDE_SRC" "$(CLAUDE_CONFIG_DIR)/settings.local.json"; \
		else \
			echo "Warning: $$CLAUDE_SRC not found, skipping settings link."; \
		fi; \
	else \
		echo "dev_setup not available, skipping Claude settings link."; \
	fi
	@# Merge MCP servers from profile config into ~/.claude.json
	@if [ -n "$(DEV_SETUP_REPO)" ] && [ -d "$(DEV_SETUP_CLAUDE_DIR)" ]; then \
		MCP_SRC="$(DEV_SETUP_CLAUDE_DIR)/claude_mcp_$(PROFILE).json"; \
		CLAUDE_USER_CFG="$(HOME)/.claude.json"; \
		if [ -f "$$MCP_SRC" ] && [ -f "$$CLAUDE_USER_CFG" ] && command -v jq >/dev/null 2>&1; then \
			echo "Merging MCP servers from $$MCP_SRC into $$CLAUDE_USER_CFG..." && \
			jq -s '.[0].mcpServers = (.[0].mcpServers // {} ) * .[1].mcpServers | .[0]' \
				"$$CLAUDE_USER_CFG" "$$MCP_SRC" > "$$CLAUDE_USER_CFG.tmp" && \
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
		if [ -d "$$dir" ]; then \
			for f in "$$dir"/*.md; do \
				[ -f "$$f" ] && ln -sf "$$f" "$(CLAUDE_CONFIG_DIR)/agents/$$(basename $$f)"; \
			done; \
		fi; \
	done
	@for dir in \
		"$(CHEZMOI_DIR)/claude/commands" \
		"$(DEV_SETUP_CLAUDE_DIR)/commands" \
		"$(DEV_SETUP_CLAUDE_DIR)/commands_$(PROFILE)"; do \
		if [ -d "$$dir" ]; then \
			for f in "$$dir"/*.md; do \
				[ -f "$$f" ] && ln -sf "$$f" "$(CLAUDE_CONFIG_DIR)/commands/$$(basename $$f)"; \
			done; \
		fi; \
	done
	@echo "Claude config setup complete."
