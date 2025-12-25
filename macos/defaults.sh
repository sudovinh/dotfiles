#!/usr/bin/env bash
# macOS defaults - sensible hacker defaults
# Inspired by mathiasbynens/dotfiles (31k stars)
# Run: make setup-macos-defaults
# Override settings via .env file
# Some changes require logout/restart to take effect

set -e

# Load .env if available (from dotfiles directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Defaults (can be overridden in .env)
MACOS_DOCK_AUTOHIDE="${MACOS_DOCK_AUTOHIDE:-true}"
MACOS_DOCK_ICON_SIZE="${MACOS_DOCK_ICON_SIZE:-48}"
MACOS_FINDER_SHOW_HIDDEN="${MACOS_FINDER_SHOW_HIDDEN:-true}"
MACOS_KEYBOARD_REPEAT_RATE="${MACOS_KEYBOARD_REPEAT_RATE:-2}"
MACOS_KEYBOARD_INITIAL_DELAY="${MACOS_KEYBOARD_INITIAL_DELAY:-15}"
MACOS_SCREENSHOT_LOCATION="${MACOS_SCREENSHOT_LOCATION:-${HOME}/Screenshots}"
MACOS_DISABLE_BOOT_SOUND="${MACOS_DISABLE_BOOT_SOUND:-true}"
MACOS_DISABLE_AUTOCORRECT="${MACOS_DISABLE_AUTOCORRECT:-true}"
MACOS_TAP_TO_CLICK="${MACOS_TAP_TO_CLICK:-true}"
MACOS_THREE_FINGER_DRAG="${MACOS_THREE_FINGER_DRAG:-true}"

echo "Setting macOS defaults..."
echo "Override any setting via .env file"

# Close System Preferences to prevent conflicts
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# Ask for administrator password upfront
sudo -v

# Keep-alive: update sudo timestamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

if [ "$MACOS_DISABLE_BOOT_SOUND" = "true" ]; then
    echo "  Disabling boot sound..."
    sudo nvram SystemAudioVolume=" "
fi

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

###############################################################################
# Keyboard                                                                    #
###############################################################################

echo "  Keyboard: repeat rate=$MACOS_KEYBOARD_REPEAT_RATE, initial delay=$MACOS_KEYBOARD_INITIAL_DELAY"

# Enable full keyboard access for all controls (Tab in dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set keyboard repeat rate (configurable)
defaults write NSGlobalDomain KeyRepeat -int "$MACOS_KEYBOARD_REPEAT_RATE"
defaults write NSGlobalDomain InitialKeyRepeat -int "$MACOS_KEYBOARD_INITIAL_DELAY"

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

if [ "$MACOS_DISABLE_AUTOCORRECT" = "true" ]; then
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
fi

###############################################################################
# Trackpad & Mouse                                                            #
###############################################################################

if [ "$MACOS_TAP_TO_CLICK" = "true" ]; then
    echo "  Enabling tap to click..."
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
fi

if [ "$MACOS_THREE_FINGER_DRAG" = "true" ]; then
    echo "  Enabling three-finger drag..."
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
fi

###############################################################################
# Finder                                                                      #
###############################################################################

echo "  Finder: show hidden=$MACOS_FINDER_SHOW_HIDDEN"

defaults write com.apple.finder AppleShowAllFiles -bool "$MACOS_FINDER_SHOW_HIDDEN"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
chflags nohidden ~/Library 2>/dev/null || true

###############################################################################
# Dock                                                                        #
###############################################################################

echo "  Dock: autohide=$MACOS_DOCK_AUTOHIDE, icon size=$MACOS_DOCK_ICON_SIZE"

defaults write com.apple.dock tilesize -int "$MACOS_DOCK_ICON_SIZE"
defaults write com.apple.dock autohide -bool "$MACOS_DOCK_AUTOHIDE"
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true

###############################################################################
# Screenshots                                                                 #
###############################################################################

echo "  Screenshots: location=$MACOS_SCREENSHOT_LOCATION"

mkdir -p "$MACOS_SCREENSHOT_LOCATION"
defaults write com.apple.screencapture location -string "$MACOS_SCREENSHOT_LOCATION"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Safari                                                                      #
###############################################################################

defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari AutoFillPasswords -bool false

###############################################################################
# Terminal                                                                    #
###############################################################################

defaults write com.apple.terminal StringEncodings -array 4
defaults write com.apple.terminal SecureKeyboardEntry -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Mac App Store                                                               #
###############################################################################

defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

###############################################################################
# Kill affected applications                                                  #
###############################################################################

echo "Restarting affected applications..."

for app in "Activity Monitor" \
    "Dock" \
    "Finder" \
    "Safari" \
    "SystemUIServer"; do
    killall "${app}" &> /dev/null || true
done

echo "Done. Some changes require logout/restart to take effect."
echo "Customize settings by adding MACOS_* variables to .env"
