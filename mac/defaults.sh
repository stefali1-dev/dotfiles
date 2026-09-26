#!/usr/bin/env bash
# macOS settings that live in preferences, not in a file we can link. Safe to re-run.
set -euo pipefail

# Keyboard > Mission Control: turn off Ctrl+Left/Right switching spaces (79, 81),
# so the keys reach apps. Ctrl+Shift variants (80, 82) stay on.
for arrow in "79 123" "81 124"; do
  set -- $arrow
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>$2</integer><integer>8650752</integer></array><key>type</key><string>standard</string></dict></dict>"
done
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
