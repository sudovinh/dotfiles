# ============================================
# SYSTEM TOOLS
# ============================================

.PHONY: install-xcode
install-xcode:
ifeq ($(UNAME_S), Darwin)
	@xcode-select -p > /dev/null 2>&1 || (echo "Installing Xcode Command Line Tools..." && xcode-select --install)
	@echo "Xcode Command Line Tools ready."
else
	@echo "Skipping Xcode (not macOS)."
endif

define _CLONE_AND_INSTALL_POWERLINE_FONTS
	echo "Installing Powerline fonts..." && \
	git clone https://github.com/powerline/fonts.git --depth=1 /tmp/pl-fonts && \
	/tmp/pl-fonts/install.sh && \
	rm -rf /tmp/pl-fonts
endef

.PHONY: install-powerline-fonts
install-powerline-fonts:
ifeq ($(UNAME_S), Darwin)
	@if [ ! "$$(find ~/Library/Fonts -name '*Powerline*' 2>/dev/null | head -1)" ]; then \
		$(call _CLONE_AND_INSTALL_POWERLINE_FONTS); \
	else \
		echo "Powerline fonts already installed."; \
	fi
else ifeq ($(UNAME_S), Linux)
	@if [ ! "$$(find ~/.local/share/fonts -name '*Powerline*' 2>/dev/null | head -1)" ]; then \
		$(call _CLONE_AND_INSTALL_POWERLINE_FONTS); \
	else \
		echo "Powerline fonts already installed."; \
	fi
endif

.PHONY: setup-iterm2-shell-integration
setup-iterm2-shell-integration:
ifeq ($(UNAME_S), Darwin)
	@if [ ! -f ~/.iterm2_shell_integration.zsh ]; then \
		echo "Installing iTerm2 shell integration..." && \
		curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh; \
	else \
		echo "iTerm2 shell integration already installed."; \
	fi
else
	@echo "Skipping iTerm2 integration (not macOS)."
endif
