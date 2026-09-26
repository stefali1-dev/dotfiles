#!/usr/bin/env bash
# Omarchy theme-set hook: writes a Brave theme extension from the current theme's colors.
# brave-flags.conf loads it; Brave picks up a new theme on its next start.
set -euo pipefail

colors="$HOME/.local/state/omarchy/current/theme/colors.toml"
out="$HOME/.local/share/brave-omarchy-theme"

# "#1a1b26" in colors.toml -> [26, 27, 38]
rgb() {
  local hex
  hex=$(sed -n "s/^$1 *= *\"#\([0-9a-fA-F]\{6\}\)\"/\1/p" "$colors")
  printf '[%d, %d, %d]' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

mkdir -p "$out"
cat >"$out/manifest.json" <<EOF
{
  "manifest_version": 3,
  "name": "Omarchy $(<"$HOME/.local/state/omarchy/current/theme.name")",
  "version": "1.0",
  "theme": {
    "colors": {
      "frame": $(rgb dark_background),
      "frame_inactive": $(rgb dark_background),
      "toolbar": $(rgb background),
      "tab_text": $(rgb bright_foreground),
      "tab_background_text": $(rgb foreground),
      "tab_background_text_inactive": $(rgb dark_foreground),
      "bookmark_text": $(rgb foreground),
      "toolbar_text": $(rgb bright_foreground),
      "toolbar_button_icon": $(rgb foreground),
      "omnibox_background": $(rgb dark_background),
      "omnibox_text": $(rgb bright_foreground),
      "ntp_background": $(rgb background),
      "ntp_text": $(rgb foreground),
      "ntp_link": $(rgb accent),
      "button_background": [0, 0, 0, 0]
    }
  }
}
EOF
