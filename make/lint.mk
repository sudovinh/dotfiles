# ============================================
# LINT + TEST
# ============================================

.PHONY: lint
lint:
	@echo "--- Makefile syntax check ---"
	@$(MAKE) -n all > /dev/null 2>&1 && echo "  Syntax: OK" || (echo "  Syntax: FAIL" && exit 1)
	@echo "--- checkmake analysis (advisory) ---"
	@if command -v checkmake > /dev/null 2>&1; then \
		checkmake Makefile || true; \
	else \
		echo "  checkmake not installed, skipping (brew install checkmake)"; \
	fi
	@echo "Lint passed."

.PHONY: test
test:
	@echo "Testing Makefile targets (dry-run)..."
	@echo ""
	@echo "--- Orchestration chains ---"
	@$(MAKE) -n mac-setup   > /dev/null && echo "  mac-setup:    OK" || (echo "  mac-setup:    FAIL" && exit 1)
	@$(MAKE) -n mac-update  > /dev/null && echo "  mac-update:   OK" || (echo "  mac-update:   FAIL" && exit 1)
	@$(MAKE) -n linux-setup > /dev/null && echo "  linux-setup:  OK" || (echo "  linux-setup:  FAIL" && exit 1)
	@$(MAKE) -n linux-update > /dev/null && echo "  linux-update: OK" || (echo "  linux-update: FAIL" && exit 1)
	@echo ""
	@echo "--- Public target existence ---"
	@for target in \
		setup update \
		mac-setup linux-setup mac-update linux-update \
		setup-chezmoi update-chezmoi \
		brew-bundle-default brew-bundle-profile setup-brewfile \
		setup-shell setup-tmux update-tmux-plugins update-oh-my-zsh-plugins \
		setup-devbox-config refresh-devbox-config install-devbox install-direnv \
		setup-claude-config clone-dev-setup setup-notes update-repos \
		install-xcode install-powerline-fonts setup-iterm2-shell-integration \
		setup-macos-defaults select-ide setup-zed-config \
		check-env print-variables lint help clean; do \
		$(MAKE) -n "$$target" > /dev/null 2>&1 \
			&& echo "  $$target: OK" \
			|| echo "  $$target: MISSING"; \
	done
	@echo ""
	@echo "Test complete."
