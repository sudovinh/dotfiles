# ============================================
# REPOSITORIES
# ============================================

.PHONY: clone-dev-setup
clone-dev-setup:
ifeq ($(DEV_SETUP_REPO),)
	@echo "DEV_SETUP_REPO not set, skipping."
else
	@REPO_NAME=$$(basename $(DEV_SETUP_REPO) .git); \
	if [ ! -d $(HOME)/$$REPO_NAME ]; then \
		echo "Cloning dev_setup..." && git clone $(DEV_SETUP_REPO) $(HOME)/$$REPO_NAME; \
	else \
		echo "dev_setup already cloned."; \
	fi
endif

.PHONY: setup-notes
setup-notes:
ifeq ($(OBSIDIAN_NOTES_REPO),)
	@echo "OBSIDIAN_NOTES_REPO not set, skipping."
else
	@REPO_NAME=$$(basename $(OBSIDIAN_NOTES_REPO) .git); \
	if [ ! -d $(HOME)/$$REPO_NAME ]; then \
		echo "Cloning notes..." && git clone $(OBSIDIAN_NOTES_REPO) $(HOME)/$$REPO_NAME; \
	else \
		echo "Notes repo already cloned."; \
	fi
endif

.PHONY: update-repos
update-repos:
	@echo "Updating repositories..."
ifneq ($(DEV_SETUP_REPO),)
	@REPO_NAME=$$(basename $(DEV_SETUP_REPO) .git); \
	if [ -d $(HOME)/$$REPO_NAME ]; then \
		echo "Pulling dev_setup..." && cd $(HOME)/$$REPO_NAME && git pull --rebase; \
	else \
		echo "dev_setup not found, skipping."; \
	fi
endif
ifneq ($(OBSIDIAN_NOTES_REPO),)
	@REPO_NAME=$$(basename $(OBSIDIAN_NOTES_REPO) .git); \
	if [ -d $(HOME)/$$REPO_NAME ]; then \
		echo "Pulling notes..." && cd $(HOME)/$$REPO_NAME && git pull --rebase; \
	else \
		echo "Notes repo not found, skipping."; \
	fi
endif
	@echo "Repositories update complete."
