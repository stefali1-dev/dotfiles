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

# Folders opened from other apps (`open ~/Downloads`, "Show in folder") go to Yazi.app, built by install.sh.
# Finder itself stays for the Desktop, Dock stacks and file dialogs. Takes effect after logging out.
defaults write -g NSFileViewer -string local.yazi
if ! defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -q '"local.yazi"'; then
  defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \
    '{LSHandlerContentType="public.folder";LSHandlerRoleAll="local.yazi";}'
fi
