# Dotfiles

This repository automates the configuration of macOS and Linux environments with tools and configurations for productivity. The setup is designed to be idempotent and modular.

## Features

work-in-progress

- **Environment Detection**: Automatically detects macOS or Linux and runs relevant setup steps.
- **Profile Support**: Allows selection of `Main` (Personal) or `Work` profiles for environment-specific configurations.
- **Tool Installations**:
  - Homebrew (macOS)
  - Powerline Fonts
  - Devbox
  - Direnv
  - Oh My Zsh and plugins
- **Configuration Management**:
  - Chezmoi for dotfile syncing
  - Obsidian notes repository
  - Brewfile/Devbox installations based on profiles
- **Clean-Up**: Removes temporary files post-setup.

## Getting Started

1. Clone this repository:

```bash
   git clone https://github.com/sudovinh/dotfiles.git
   cd dotfiles
   make initialize
```
