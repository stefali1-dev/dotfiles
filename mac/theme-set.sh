#!/usr/bin/env bash
# Applies the current Omarchy theme (theme/ in this repo, exported on Omarchy) to the Mac's apps.
# Run by install.sh and by .githooks/post-merge when a pull changes theme/. Safe to re-run.
set -euo pipefail

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
theme="$HOME/.local/state/omarchy/current/theme"

# Brave: the theme and the site palette, picked up on Brave's next start.
"$dotfiles/brave/theme.sh"
"$dotfiles/brave/web-theme/generate.sh"

# Ghostty rereads its config, which includes the theme's ghostty.conf. killall, not pkill: the process
# name is the full bundle path, and pkill skips its own ancestors — this often runs inside Ghostty.
killall -USR2 ghostty 2>/dev/null || true

# JankyBorders rereads the accent (a running `borders` takes new settings from a second call).
if pgrep -x borders >/dev/null; then
  "$HOME/.config/borders/bordersrc"
fi

# macOS highlight color (text selection): the accent, as "r g b" fractions.
accent=$(sed -n 's/^accent *= *"#\([0-9a-fA-F]\{6\}\)"/\1/p' "$theme/colors.toml")
defaults write -g AppleHighlightColor -string \
  "$(printf '%d %d %d' "0x${accent:0:2}" "0x${accent:2:2}" "0x${accent:4:2}" | awk '{ printf "%.6f %.6f %.6f Other", $1/255, $2/255, $3/255 }')"

# VS Code: the theme's Marketplace theme if it names one, else Omarchy's generated theme as a local
# extension, as omarchy-theme-set-vscode does on Omarchy.
code="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
settings="$HOME/Library/Application Support/Code/User/settings.json"
if [ -x "$code" ] && [ -f "$settings" ]; then
  if [ -f "$theme/vscode.json" ]; then
    name=$(jq -r .name "$theme/vscode.json")
    extension=$(jq -r .extension "$theme/vscode.json")
    "$code" --list-extensions 2>/dev/null | grep -qxF "$extension" ||
      "$code" --install-extension "$extension" >/dev/null 2>&1
  else
    name=Omarchy
    extensions="$HOME/.vscode/extensions"
    dir="$extensions/omarchy-theme"
    # A new version for new colors: VS Code caches a theme until its extension's version changes.
    version="1.0.$(cksum <"$theme/vscode-theme.json" | cut -d' ' -f1)"
    mkdir -p "$dir/themes"
    cp "$theme/vscode-theme.json" "$dir/themes/omarchy-color-theme.json"
    cat >"$dir/package.json" <<EOF
{
  "name": "omarchy-theme",
  "displayName": "Omarchy",
  "publisher": "local",
  "version": "$version",
  "engines": { "vscode": "^1.70.0" },
  "categories": ["Themes"],
  "contributes": {
    "themes": [{ "label": "Omarchy", "uiTheme": "vs-dark", "path": "./themes/omarchy-color-theme.json" }]
  }
}
EOF
    # VS Code only loads extensions listed in extensions.json.
    tmp=$(mktemp)
    jq --arg dir "$dir" --arg version "$version" \
      'map(select(.identifier.id != "local.omarchy-theme")) + [{
        identifier: { id: "local.omarchy-theme" }, version: $version,
        location: { "$mid": 1, fsPath: $dir, external: ("file://" + $dir), path: $dir, scheme: "file" },
        relativeLocation: "omarchy-theme" }]' \
      "$extensions/extensions.json" >"$tmp"
    mv "$tmp" "$extensions/extensions.json"
  fi
  if grep -q '"workbench.colorTheme"' "$settings"; then
    sed -i '' -E "s|(\"workbench.colorTheme\"[[:space:]]*:[[:space:]]*\")[^\"]*(\")|\1$name\2|" "$settings"
  else
    sed -i '' -E "1,/\{/s|\{|{ \"workbench.colorTheme\": \"$name\",|" "$settings"
  fi
fi

# Obsidian: the theme's CSS as the "Omarchy" theme in every vault.
obsidian="$HOME/Library/Application Support/obsidian/obsidian.json"
if [ -f "$obsidian" ]; then
  jq -r '.vaults[].path' "$obsidian" | while read -r vault; do
    [ -d "$vault/.obsidian" ] || continue
    mkdir -p "$vault/.obsidian/themes/Omarchy"
    cp "$theme/obsidian.css" "$vault/.obsidian/themes/Omarchy/theme.css"
    echo '{ "name": "Omarchy", "version": "1.0.0", "minAppVersion": "0.16.0", "author": "Omarchy" }' \
      >"$vault/.obsidian/themes/Omarchy/manifest.json"

    # Select it, in dark mode, at the Mac's matching font size. Obsidian reads this at startup.
    appearance="$vault/.obsidian/appearance.json"
    [ -f "$appearance" ] || echo '{}' >"$appearance"
    tmp=$(mktemp)
    jq '. + { cssTheme: "Omarchy", theme: "obsidian", baseFontSize: 20,
              monospaceFontFamily: "JetBrainsMono Nerd Font" }' "$appearance" >"$tmp"
    mv "$tmp" "$appearance"
  done
fi

# Wallpaper on every screen. AppKit from JXA, not System Events: osascript sets it itself, so this
# needs no Automation permission (System Events would block on a prompt in a script like this).
background=$(ls "$theme"/background.* 2>/dev/null | head -1 || true)
if [ -n "$background" ]; then
  osascript -l JavaScript -e '
    ObjC.import("AppKit");
    function run(argv) {
      var url = $.NSURL.fileURLWithPath(argv[0]);
      var workspace = $.NSWorkspace.sharedWorkspace;
      var screens = $.NSScreen.screens;
      for (var i = 0; i < screens.count; i++) {
        workspace.setDesktopImageURLForScreenOptionsError(url, screens.objectAtIndex(i), $(), $());
      }
    }
  ' "$background" >/dev/null
fi
