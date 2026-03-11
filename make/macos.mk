# ============================================
# macOS DEFAULTS / IDE / ZED
# ============================================

.PHONY: setup-macos-defaults
setup-macos-defaults:
ifeq ($(UNAME_S), Darwin)
	@echo "Applying macOS defaults..."
	@chmod +x $(DOTFILES_DIR)/macos/defaults.sh && $(DOTFILES_DIR)/macos/defaults.sh
else
	@echo "Skipping macOS defaults (not macOS)."
endif

.PHONY: select-ide
select-ide:
	@echo "Select your preferred IDE:"
	@echo "  1) VS Code  2) Cursor  3) Zed  4) Sublime Text"
	@read -p "Enter choice [1-4]: " choice; \
	mkdir -p $(HOME)/.config/dotfiles; \
	case $$choice in \
		1) echo "vscode"   > $(HOME)/.config/dotfiles/ide ;; \
		2) echo "cursor"   > $(HOME)/.config/dotfiles/ide ;; \
		3) echo "zed"      > $(HOME)/.config/dotfiles/ide ;; \
		4) echo "sublime"  > $(HOME)/.config/dotfiles/ide ;; \
		*) echo "Invalid choice" ;; \
	esac
	@echo "IDE preference saved."

.PHONY: setup-zed-config
setup-zed-config:
	@mkdir -p $(HOME)/.config/zed
	@echo "Zed config directory ready."
