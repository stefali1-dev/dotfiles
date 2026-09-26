#!/usr/bin/env bash
# Omarchy theme-set hook: copies the files the Mac uses from the current theme into the repo's theme/.
# The Mac links theme/ as its current theme, so commit theme/ after a switch.
set -euo pipefail

current="$HOME/.local/state/omarchy/current"
out="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../theme"

# Emptied first, so a file one theme has and the next lacks (vscode.json) doesn't linger.
mkdir -p "$out"
rm -f "$out"/*

for file in colors.toml ghostty.conf vscode.json vscode-theme.json claude.json btop.theme obsidian.css neovim.lua; do
  if [ -f "$current/theme/$file" ]; then
    cp "$current/theme/$file" "$out/"
  fi
done
cp "$current/theme.name" "$out/"

# Videos stay out: too big for git, and the Mac can't use them as wallpaper.
background=$(readlink -f "$current/background" || true)
shopt -s nocasematch
if [ -f "$background" ] && ! [[ $background =~ \.(mp4|m4v|mov|webm|mkv|avi)$ ]]; then
  cp "$background" "$out/background.${background##*.}"
fi
