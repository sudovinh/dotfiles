# ============================================
# VALIDATION
# ============================================

.PHONY: check-env
check-env:
	@if [ ! -f .env ]; then \
		echo ""; \
		echo "ERROR: .env file not found."; \
		echo "  Copy the example and fill in your values:"; \
		echo "    cp .env.example .env"; \
		echo ""; \
		exit 1; \
	fi
	@if [ -z "$(GIT_USER)" ]; then \
		echo "ERROR: GIT_USER is not set in .env"; exit 1; \
	fi
	@if [ "$(PROFILE)" != "main" ] && [ "$(PROFILE)" != "work" ]; then \
		echo "ERROR: PROFILE must be 'main' or 'work' in .env (got: '$(PROFILE)')"; exit 1; \
	fi
	@echo "Config: profile=$(PROFILE) git_user=$(GIT_USER)"

.PHONY: print-variables
print-variables:
	@echo "=== .env ==="
	@echo "  PROFILE:              $(PROFILE)"
	@echo "  GIT_USER:             $(GIT_USER)"
	@echo "  DEV_SETUP_REPO:       $(if $(DEV_SETUP_REPO),$(DEV_SETUP_REPO),(not set - skipped))"
	@echo "  OBSIDIAN_NOTES_REPO:  $(if $(OBSIDIAN_NOTES_REPO),$(OBSIDIAN_NOTES_REPO),(not set - skipped))"
	@echo "=== System ==="
	@echo "  OS:     $(UNAME_S)"
	@echo "  SHELL:  $(SHELL)"
	@echo ""
