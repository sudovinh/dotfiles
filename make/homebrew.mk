# ============================================
# HOMEBREW (macOS only)
# ============================================

.PHONY: install-homebrew
install-homebrew:
ifeq ($(UNAME_S), Darwin)
	@which brew > /dev/null 2>&1 || (echo "Installing Homebrew..." && /bin/bash -c "$$(curl -fsSL $(HOMEBREW_URL))")
	@eval "$$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
	@echo "Homebrew ready."
else
	@echo "Skipping Homebrew (not macOS)."
endif

.PHONY: brew-bundle-default
brew-bundle-default:
ifeq ($(UNAME_S), Darwin)
	@if [ ! -f "$(BREWFILE_DEFAULT)" ]; then \
		echo "Error: $(BREWFILE_DEFAULT) not found." && exit 1; \
	fi
	@echo "Running Brewfile (default)..."
	@brew bundle --file=$(BREWFILE_DEFAULT) || \
		echo "Warning: Some Brewfile (default) packages failed to install. Review output above."
else
	@echo "Skipping Brewfile (not macOS)."
endif

.PHONY: brew-bundle-profile
brew-bundle-profile:
ifeq ($(UNAME_S), Darwin)
	@if [ -f "$(BREWFILE_PROFILE)" ]; then \
		echo "Running Brewfile ($(PROFILE))..." && \
		(brew bundle --file=$(BREWFILE_PROFILE) || \
		echo "Warning: Some Brewfile ($(PROFILE)) packages failed to install. Review output above."); \
	else \
		echo "No profile Brewfile at $(BREWFILE_PROFILE), skipping."; \
	fi
else
	@echo "Skipping profile Brewfile (not macOS)."
endif

.PHONY: brew-trust-taps
brew-trust-taps:
ifeq ($(UNAME_S), Darwin)
	@echo "Trusting third-party Homebrew taps..."
	@for tap in \
		argoproj/tap \
		cloudquery/tap \
		common-fate/granted \
		cue-lang/tap \
		databricks/tap \
		derailed/k9s \
		kreuzwerker/taps \
		nikitabobko/tap \
		oktadeveloper/tap \
		peonping/tap; do \
		brew tap $$tap 2>/dev/null || true; \
		brew trust $$tap 2>/dev/null || true; \
	done
else
	@echo "Skipping brew trust (not macOS)."
endif

# Backwards-compatible alias
.PHONY: setup-brewfile
setup-brewfile: brew-bundle-profile
