#!/usr/bin/env bash
# macOS settings that live in preferences, not in a file we can link. Safe to re-run.
set -euo pipefail

# Keyboard > Mission Control, as "<id> <key code> <modifiers>". AeroSpace owns the window layout, so
# macOS's own space and exposé shortcuts only get in the way: Ctrl+Left/Right switching spaces
# (79, 81), Ctrl+Up opening Mission Control (32, and 34 for the keyboard's own Mission Control key),
# Ctrl+Down's App Exposé (33), and Switch to Desktop 1-5 (118-122), which would otherwise take the
# Cmd+1-4 that aerospace.toml uses for workspaces.
# Ctrl+Shift+Left/Right (80, 82) stay on.
for shortcut in "79 123 8650752" "81 124 8650752" "32 126 8650752" "34 126 8781824" "33 125 8650752" \
  "118 18 1048576" "119 19 1048576" "120 20 1048576" "121 21 1048576" "122 23 1048576"; do
  set -- $shortcut
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>$2</integer><integer>$3</integer></array><key>type</key><string>standard</string></dict></dict>"
done
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Key repeat as on Omarchy (repeat_delay 250, repeat_rate 40). 15 is the shortest delay the Keyboard
# pane offers, about 250ms; 2 is the closest rate, about 33/s, since macOS can't express 40.
# Takes effect after logging out.
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# Holding a letter that has accents (a, e, s, ...) opens the accent picker instead of repeating, in
# apps that use macOS's own text input. Off for VS Code, where repeating beats typing diacritics, and
# left alone everywhere else so Romanian text still works. Ghostty repeats either way, so it needs
# nothing. Letters without accents, the arrows and Backspace always repeat.
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
