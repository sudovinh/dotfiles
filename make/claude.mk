# ============================================
# CLAUDE
# ============================================

# Skill packages installed globally via the skills CLI (copied into
# ~/.claude/skills, so they survive the symlink cleanup below).
# obra/superpowers is NOT here: it's installed as the official Claude Code
# plugin (superpowers@claude-plugins-official).
SKILL_PACKAGES := DietrichGebert/ponytail q-qp-p/pstack kunchenguid/no-mistakes vercel-labs/skills
# Personal-profile-only packages (skipped and cleaned up on PROFILE=work).
# When adding one, also add its installed skill dirs to MAIN_ONLY_SKILL_DIRS.
SKILL_PACKAGES_MAIN := latent-spaces/brag
MAIN_ONLY_SKILL_DIRS := brag brag-slim

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
				jq -s '.[0] as $$p | .[1] as $$l | $$p | .permissions.allow = (($$p.permissions.allow // []) + ($$l.permissions.allow // []) | unique) | .enabledPlugins = (($$p.enabledPlugins // {}) + ($$l.enabledPlugins // {}))' \
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
	@# Generate global memory (CLAUDE.md) from base + profile-specific overlay
	@if [ -n "$(DEV_SETUP_REPO)" ] && [ -f "$(DEV_SETUP_CLAUDE_DIR)/claude_memory.md" ]; then \
		echo "Generating CLAUDE.md from $(DEV_SETUP_CLAUDE_DIR)/claude_memory.md + profile overlay..."; \
		rm -f "$(CLAUDE_CONFIG_DIR)/CLAUDE.md"; \
		PROFILE_MEMORY="$(DEV_SETUP_CLAUDE_DIR)/claude_memory_$(PROFILE).md"; \
		if [ -f "$$PROFILE_MEMORY" ]; then \
			cat "$(DEV_SETUP_CLAUDE_DIR)/claude_memory.md" "$$PROFILE_MEMORY" > "$(CLAUDE_CONFIG_DIR)/CLAUDE.md"; \
		else \
			cp "$(DEV_SETUP_CLAUDE_DIR)/claude_memory.md" "$(CLAUDE_CONFIG_DIR)/CLAUDE.md"; \
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
	@# Symlink skills (each skill is a directory, not a flat file)
	@echo "Setting up custom skills..."
	@mkdir -p "$(CLAUDE_CONFIG_DIR)/skills"
	@find "$(CLAUDE_CONFIG_DIR)/skills" -maxdepth 1 -type l -delete
	@for dir in \
		"$(CHEZMOI_DIR)/claude/skills" \
		"$(DEV_SETUP_CLAUDE_DIR)/skills" \
		"$(DEV_SETUP_CLAUDE_DIR)/skills_$(PROFILE)"; do \
		if [ -d "$$dir" ]; then \
			for skill in "$$dir"/*/; do \
				[ -d "$$skill" ] || continue; \
				ln -sfn "$${skill%/}" "$(CLAUDE_CONFIG_DIR)/skills/$$(basename $$skill)"; \
			done; \
		fi; \
	done
	@# Refresh the REA workflow skill in ~/.claude/skills — personal profile only
	@# (MCP entry lives in claude_mcp_main.json; work machines get neither).
	@# Setup exits nonzero over optional Hopper/pinning advice even when the skill installs,
	@# so verify the skill directory instead of the exit code.
	@if [ "$(PROFILE)" != "main" ]; then \
		echo "Skipping REA skill (profile '$(PROFILE)', personal-only)."; \
		rm -rf "$(CLAUDE_CONFIG_DIR)/skills/reverse-engineer-anything"; \
	elif command -v npx >/dev/null 2>&1; then \
		echo "Refreshing REA skill..."; \
		npx -y rea-agents@latest setup --skill-client claude_code --yes --json >/dev/null 2>&1 || true; \
		if [ -d "$(CLAUDE_CONFIG_DIR)/skills/reverse-engineer-anything" ]; then \
			echo "REA skill installed."; \
		else \
			echo "Warning: REA skill missing after refresh (offline?)."; \
		fi; \
	else \
		echo "Warning: npx not found, skipping REA skill refresh."; \
	fi
	@# Install/refresh skill packages from the open ecosystem (see SKILL_PACKAGES above).
	@# CLAUDECODE=1 makes the skills CLI treat this as an agent run (fully
	@# non-interactive); without it the CLI tries to render prompts and fails
	@# when output is redirected. Errors are logged and shown on failure.
	@if command -v npx >/dev/null 2>&1; then \
		PKGS="$(SKILL_PACKAGES)"; \
		if [ "$(PROFILE)" = "main" ]; then \
			PKGS="$$PKGS $(SKILL_PACKAGES_MAIN)"; \
		else \
			echo "Skipping personal-only skill packages (profile '$(PROFILE)')."; \
			for d in $(MAIN_ONLY_SKILL_DIRS); do \
				rm -rf "$(CLAUDE_CONFIG_DIR)/skills/$$d"; \
			done; \
		fi; \
		for pkg in $$PKGS; do \
			echo "Installing skills from $$pkg..."; \
			if ! CLAUDECODE=1 npx -y skills@latest add "$$pkg" -g -y -a claude-code -s '*' >/tmp/skills-add.log 2>&1; then \
				echo "Warning: skills add $$pkg failed:"; \
				tail -5 /tmp/skills-add.log | sed 's/^/    /'; \
			fi; \
		done; \
	else \
		echo "Warning: npx not found, skipping skill package install."; \
	fi
	@# Skill prerequisites. The no-mistakes skill needs its CLI on PATH, but
	@# `npm install -g` can't write to the read-only nix store under flox,
	@# so install a shim in ~/.local/bin that runs it via npx (cached).
	@mkdir -p "$(HOME)/.local/bin"
	@printf '#!/bin/sh\n# Managed by dotfiles make setup-claude-config.\nexec npx -y no-mistakes@latest "$$@"\n' > "$(HOME)/.local/bin/no-mistakes"
	@chmod +x "$(HOME)/.local/bin/no-mistakes"
	@echo "no-mistakes CLI shim installed."
	@echo "Claude config setup complete."
