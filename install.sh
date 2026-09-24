#!/usr/bin/env bash
# Symlink this repo's config into place. Safe to re-run.
# Usage: ./install.sh [claude] [git] [omarchy]   (no args: everything that fits this OS)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Link $2 -> $1. An existing file that isn't already our link is moved aside, never deleted.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$dest.bak.$(date +%s)"
    mv "$dest" "$backup"
    echo "  backed up $dest -> $backup"
  fi
  ln -s "$src" "$dest"
  echo "  linked $dest"
}

install_claude() {
  echo "claude -> ~/.claude"
  local item
  for item in CLAUDE.md file-suggestion.sh hooks agents rules commands; do
    link "$DOTFILES/claude/$item" "$HOME/.claude/$item"
  done

  # CLAUDE_PROFILE=work layers settings.work.json on top. autoMode is only read from
  # user settings, so that layer can't live in a project file; the merge is a copy.
  if [ -z "${CLAUDE_PROFILE:-}" ]; then
    link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  else
    local dest="$HOME/.claude/settings.json" merged
    merged=$(jq -s '.[0] * .[1]' "$DOTFILES/claude/settings.json" "$DOTFILES/claude/settings.$CLAUDE_PROFILE.json")
    if [ -L "$dest" ] || ! printf '%s\n' "$merged" | cmp -s - "$dest"; then
      if [ -e "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "$dest.bak.$(date +%s)"
        echo "  backed up $dest"
      fi
      printf '%s\n' "$merged" > "$dest"
      echo "  wrote $dest (settings.json + settings.$CLAUDE_PROFILE.json)"
    fi
  fi
  # Per skill, so skills installed by other tools (e.g. Omarchy's) stay alongside.
  for item in "$DOTFILES"/claude/skills/*/; do
    item="${item%/}"
    link "$item" "$HOME/.claude/skills/$(basename "$item")"
  done
}

install_git() {
  echo "git -> ~/.config/git/ignore"
  link "$DOTFILES/git/ignore" "$HOME/.config/git/ignore"
}

install_omarchy() {
  echo "omarchy -> ~/.config/hypr, /etc/keyd"
  link "$DOTFILES/omarchy/hypr/input.lua" "$HOME/.config/hypr/input.lua"
  link "$DOTFILES/omarchy/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"

  # keyd runs as root and reads /etc, so this one is copied, not linked.
  if ! command -v keyd >/dev/null; then
    echo "  keyd not installed; skipping Copilot key (sudo pacman -S keyd, then re-run)"
  elif ! cmp -s "$DOTFILES/omarchy/keyd/default.conf" /etc/keyd/default.conf; then
    sudo install -Dm644 "$DOTFILES/omarchy/keyd/default.conf" /etc/keyd/default.conf
    sudo systemctl enable --now keyd
    sudo keyd reload
    echo "  installed /etc/keyd/default.conf"
  fi

  if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null
  fi
}

if [ $# -eq 0 ]; then
  set -- claude git
  if [ "$(uname -s)" = Linux ] && [ -d /usr/share/omarchy ]; then
    set -- "$@" omarchy
  fi
fi

for component in "$@"; do
  case "$component" in
    claude | git | omarchy) "install_$component" ;;
    *) echo "unknown component: $component" >&2; exit 1 ;;
  esac
done
