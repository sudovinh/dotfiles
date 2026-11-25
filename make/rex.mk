# ============================================
# REX (appearance settings; keybindings live in dot/private_dot_config/rex)
# ============================================

REX_DEFAULTS := $(DOTFILE_SCRIPTS)/rex-defaults.sh

.PHONY: rex-check
rex-check: ## Report drift between Rex's settings and configs/rex/defaults
	@$(REX_DEFAULTS) check

.PHONY: rex-pull
rex-pull: ## Copy Rex's current settings into configs/rex/defaults
	@$(REX_DEFAULTS) pull

.PHONY: rex-apply
rex-apply: ## Write configs/rex/defaults to Rex
	@$(REX_DEFAULTS) apply

# Advisory: runs before update-chezmoi so you see local changes before an apply.
.PHONY: _rex-check-advisory
_rex-check-advisory:
	@$(REX_DEFAULTS) check || true
