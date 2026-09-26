#!/usr/bin/env bash
# macOS settings that live in preferences, not in a file we can link. Safe to re-run.
set -euo pipefail

# Keyboard > Mission Control, as "<id> <key code> <modifiers>": turn off Ctrl+Left/Right switching
# spaces (79, 81) so the keys reach apps, and Ctrl+Up opening Mission Control (32, and 34 for the
# keyboard's own Mission Control key), which only muddles AeroSpace's tiling.
# Ctrl+Shift+Left/Right (80, 82) stay on.
for shortcut in "79 123 8650752" "81 124 8650752" "32 126 8650752" "34 126 8781824"; do
  set -- $shortcut
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>$2</integer><integer>$3</integer></array><key>type</key><string>standard</string></dict></dict>"
done
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
