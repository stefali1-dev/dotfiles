#!/usr/bin/env bash
# Symlink this repo's config into place. Safe to re-run.
# Usage: ./install.sh [claude] [git] [zsh] [nvim] [mac] [omarchy]   (no args: everything that fits this OS)
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
  for item in CLAUDE.md file-suggestion.sh hooks agents commands; do
    link "$DOTFILES/claude/$item" "$HOME/.claude/$item"
  done

  # Per file, so each OS adds its own rules file alongside.
  for item in "$DOTFILES"/claude/rules/*.md; do
    link "$item" "$HOME/.claude/rules/$(basename "$item")"
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

install_zsh() {
  echo "zsh -> ~/.zshrc"
  link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
}

install_nvim() {
  echo "nvim -> ~/.config/nvim"
  link "$DOTFILES/nvim" "$HOME/.config/nvim"
}

install_mac() {
  echo "mac -> ~/.claude/rules, macOS preferences"
  link "$DOTFILES/mac/claude-rules.md" "$HOME/.claude/rules/mac.md"
  "$DOTFILES/mac/defaults.sh"
}

install_omarchy() {
  echo "omarchy -> ~/.config/hypr, ~/.config/brave-flags.conf, Brave theme hooks, ~/.config/mpv, ~/.local/share/applications, nvim theme, ~/.claude/rules, /etc/keyd"
  link "$DOTFILES/omarchy/hypr/input.lua" "$HOME/.config/hypr/input.lua"
  link "$DOTFILES/omarchy/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
  link "$DOTFILES/omarchy/hypr/monitors.lua" "$HOME/.config/hypr/monitors.lua"
  link "$DOTFILES/omarchy/claude-rules.md" "$HOME/.claude/rules/omarchy.md"
  link "$DOTFILES/omarchy/brave-flags.conf" "$HOME/.config/brave-flags.conf"
  link "$DOTFILES/omarchy/brave-theme.sh" "$HOME/.config/omarchy/hooks/theme-set.d/brave-theme.sh"
  "$DOTFILES/omarchy/brave-theme.sh"
  link "$DOTFILES/omarchy/web-theme/generate.sh" "$HOME/.config/omarchy/hooks/theme-set.d/web-theme.sh"
  "$DOTFILES/omarchy/web-theme/generate.sh"

  # Without this folder, Omarchy's theme switch stops forcing its one-color (gray) policy on Brave, which would block the theme above.
  if [ -d /etc/brave/policies/managed ]; then
    sudo rm -rf /etc/brave/policies/managed
    echo "  removed /etc/brave/policies/managed"
  fi
  link "$DOTFILES/omarchy/mpv/scripts/onepiece.lua" "$HOME/.config/mpv/scripts/onepiece.lua"
  link "$DOTFILES/omarchy/applications/yazi.desktop" "$HOME/.local/share/applications/yazi.desktop"
  link "$DOTFILES/omarchy/applications/org.gnome.Nautilus.desktop" "$HOME/.local/share/applications/org.gnome.Nautilus.desktop"

  # Neovim follows the Omarchy theme. Untracked (it would dangle on macOS) and relinked by Omarchy migrations, so not link().
  ln -snf "$HOME/.local/state/omarchy/current/theme/neovim.lua" "$DOTFILES/nvim/lua/plugins/theme.lua"

  # Screenshot tool bound in hypr/bindings.lua; from Omarchy's package repo.
  omarchy-pkg-add omasnap

  # Yazi replaces Nautilus as the file manager: bound in hypr/bindings.lua, and opens folders.
  omarchy-pkg-add yazi
  xdg-mime default yazi.desktop inode/directory

  # Omarchy reads this marker to keep the screensaver off. Not omarchy-toggle-screensaver: it flips on each run.
  mkdir -p "$HOME/.local/state/omarchy/toggles"
  touch "$HOME/.local/state/omarchy/toggles/screensaver-off"

  # keyd runs as root and reads /etc, so this one is copied, not linked.
  if ! command -v keyd >/dev/null; then
    echo "  keyd not installed; skipping Copilot key (sudo pacman -S keyd, then re-run)"
  elif ! cmp -s "$DOTFILES/omarchy/keyd/default.conf" /etc/keyd/default.conf; then
    sudo install -Dm644 "$DOTFILES/omarchy/keyd/default.conf" /etc/keyd/default.conf
    sudo systemctl enable --now keyd
    sudo keyd reload
    echo "  installed /etc/keyd/default.conf"
  fi

  # Read by libinput when the session starts; takes effect after logging in again.
  if ! cmp -s "$DOTFILES/omarchy/libinput/local-overrides.quirks" /etc/libinput/local-overrides.quirks; then
    sudo install -Dm644 "$DOTFILES/omarchy/libinput/local-overrides.quirks" /etc/libinput/local-overrides.quirks
    echo "  installed /etc/libinput/local-overrides.quirks (log out and back in)"
  fi

  # The boot image carries its own copy of modprobe.d, so rebuild it too.
  if ! cmp -s "$DOTFILES/omarchy/modprobe/hid_apple.conf" /etc/modprobe.d/hid_apple.conf; then
    sudo install -Dm644 "$DOTFILES/omarchy/modprobe/hid_apple.conf" /etc/modprobe.d/hid_apple.conf
    sudo limine-mkinitcpio
    echo "  installed /etc/modprobe.d/hid_apple.conf (reboot)"
  fi

  if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null
  fi
}

# Commits from either machine: personal email, and a Machine trailer from .githooks.
git -C "$DOTFILES" config core.hooksPath .githooks
git -C "$DOTFILES" config user.email stefanleustean56@gmail.com

if [ $# -eq 0 ]; then
  set -- claude git zsh nvim
  if [ "$(uname -s)" = Darwin ]; then
    set -- "$@" mac
  elif [ "$(uname -s)" = Linux ] && [ -d /usr/share/omarchy ]; then
    set -- "$@" omarchy
  fi
fi

for component in "$@"; do
  case "$component" in
    claude | git | zsh | nvim | mac | omarchy) "install_$component" ;;
    *) echo "unknown component: $component" >&2; exit 1 ;;
  esac
done
