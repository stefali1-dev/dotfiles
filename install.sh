#!/usr/bin/env bash
# Symlink this repo's config into place. Safe to re-run.
# Usage: ./install.sh [claude] [git] [zsh] [nvim] [yazi] [mac] [omarchy]   (no args: everything that fits this OS)
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

  link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  link "$DOTFILES/claude/agent-usage.mjs" "$HOME/.local/bin/agent-usage"
  link "$DOTFILES/claude/ccswitch" "$HOME/.local/bin/ccswitch"
  # ZCode's global instructions file: the same rules as Claude Code.
  link "$DOTFILES/claude/CLAUDE.md" "$HOME/.zcode/AGENTS.md"
  # ZCode reads ~/.zcode/skills and follows links. Only the skills that work for a GLM agent.
  for item in zcode decision-questions caveman; do
    link "$DOTFILES/claude/skills/$item" "$HOME/.zcode/skills/$item"
  done

  # zbridge: agents drive the ZCode desktop app with it (skills/zcode). The checkout you edit is the one installed.
  local bridge="$HOME/git/zcode-bridge"
  [ -d "$bridge" ] || git clone --quiet https://github.com/stefali1-dev/zcode-bridge.git "$bridge"
  [ -f "$bridge/dist/index.js" ] || (cd "$bridge" && npm ci --silent && npm run build --silent)
  link "$bridge/dist/index.js" "$HOME/.local/bin/zbridge"

  # Per skill, so skills installed by other tools (e.g. Omarchy's) stay alongside.
  for item in "$DOTFILES"/claude/skills/*/; do
    item="${item%/}"
    # The work Mac's Falcon kills any process whose arguments name herdr, which would stop this script. herdr isn't used there.
    [ "$(uname -s)" = Darwin ] && [ "${item##*/}" = herdr ] && continue
    link "$item" "$HOME/.claude/skills/$(basename "$item")"
  done
}

install_git() {
  echo "git -> ~/.config/git/ignore, lazygit config"
  link "$DOTFILES/git/ignore" "$HOME/.config/git/ignore"
  if [ "$(uname -s)" = Darwin ]; then
    link "$DOTFILES/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
  else
    link "$DOTFILES/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
  fi
  command -v delta >/dev/null || echo "  delta not installed; lazygit needs it for diffs (brew install git-delta, or omarchy-pkg-add git-delta)"
}

install_zsh() {
  echo "zsh -> ~/.zshrc, ~/.config/starship.toml"
  link "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
  link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
}

install_nvim() {
  echo "nvim -> ~/.config/nvim"
  link "$DOTFILES/nvim" "$HOME/.config/nvim"
}

install_yazi() {
  echo "yazi -> ~/.config/yazi"
  link "$DOTFILES/yazi" "$HOME/.config/yazi"
}

install_mac() {
  echo "mac -> ~/.claude/rules, ~/.config/{aerospace,karabiner,ghostty}, ~/Applications/Yazi.app, macOS preferences"
  link "$DOTFILES/mac/claude-rules.md" "$HOME/.claude/rules/mac.md"
  link "$DOTFILES/mac/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  # The whole folder: Karabiner rewrites karabiner.json and doesn't follow a symlinked file.
  link "$DOTFILES/mac/karabiner" "$HOME/.config/karabiner"
  link "$DOTFILES/mac/ghostty/config" "$HOME/.config/ghostty/config"
  # macOS keeps Voxtype's models beside its config, so only the file is linked.
  link "$DOTFILES/voxtype/config.toml" "$HOME/Library/Application Support/voxtype/config.toml"
  # Voxtype 1.x ships as an app in the release .dmg; the Homebrew cask is stuck at 0.7.5. Karabiner's F9 calls this path.
  # HACK: back to the cask once peteonrails/voxtype/voxtype passes 0.7.5 (check on each upgrade).
  if [ -d /Applications/Voxtype.app ]; then
    # The release .dmg leaves the bundle unsigned, so macOS forgets its Microphone grant and asks on every take.
    # HACK: signed as `voxtype setup app-bundle` does, until peteonrails/voxtype#810 is fixed; grant Microphone and Accessibility again afterwards.
    if ! codesign -v /Applications/Voxtype.app 2>/dev/null; then
      codesign --force --sign - /Applications/Voxtype.app/Contents/MacOS/voxtype-bin
      codesign --force --deep --sign - /Applications/Voxtype.app
    fi
    ln -sf /Applications/Voxtype.app/Contents/MacOS/voxtype-bin /opt/homebrew/bin/voxtype
    voxtype setup --download --model small.en --quiet
    # A login item, not launchd: only an app gets the microphone and Accessibility permissions.
    osascript -e 'tell application "System Events" to if not (exists login item "Voxtype") then make login item at end with properties {path:"/Applications/Voxtype.app", hidden:true}' >/dev/null
  else
    echo "  Voxtype.app not installed; skipping its model and login item (drag it to Applications from the .dmg at github.com/peteonrails/voxtype/releases/latest, then re-run)"
  fi
  # BetterCapture has no "open at login" of its own, and its Cmd+Shift+3 (set in defaults.sh) only works while it runs.
  if [ -d /Applications/BetterCapture.app ]; then
    osascript -e 'tell application "System Events" to if not (exists login item "BetterCapture") then make login item at end with properties {path:"/Applications/BetterCapture.app", hidden:true}' >/dev/null
  else
    echo "  BetterCapture.app not installed; skipping its login item (brew install --cask bettercapture, then re-run)"
  fi
  # The waveform strip Voxtype only draws on Linux; AeroSpace starts it.
  if [ "$DOTFILES/voxtype/overlay/main.swift" -nt "$HOME/.local/bin/voxtype-overlay" ]; then
    mkdir -p "$HOME/.local/bin"
    swiftc -O "$DOTFILES/voxtype/overlay/main.swift" -o "$HOME/.local/bin/voxtype-overlay"
    pkill -x voxtype-overlay || true
    nohup "$HOME/.local/bin/voxtype-overlay" >/dev/null 2>&1 &
  fi

  # Yazi.app, rebuilt when its script changes. Opening folders makes it a folder handler (set in defaults.sh).
  local app="$HOME/Applications/Yazi.app"
  if [ "$DOTFILES/mac/yazi.applescript" -nt "$app/Contents/Resources/Scripts/main.scpt" ]; then
    # osacompile won't create the folder, and a fresh Mac has no ~/Applications.
    mkdir -p "$HOME/Applications"
    rm -rf "$app"
    osacompile -o "$app" "$DOTFILES/mac/yazi.applescript"
    /usr/libexec/PlistBuddy \
      -c "Add :CFBundleIdentifier string local.yazi" \
      -c "Delete :CFBundleDocumentTypes" \
      -c "Add :CFBundleDocumentTypes array" \
      -c "Add :CFBundleDocumentTypes:0 dict" \
      -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer" \
      -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" \
      -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string public.folder" \
      "$app/Contents/Info.plist"
    # Editing Info.plist breaks the signature osacompile made.
    codesign --force --sign - "$app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
    echo "  built $app"
  fi

  # The Mac follows the theme Omarchy exported into theme/, through the same path Omarchy uses.
  mkdir -p "$HOME/.local/state/omarchy/current"
  ln -snf "$DOTFILES/theme" "$HOME/.local/state/omarchy/current/theme"
  ln -snf "$DOTFILES/theme/theme.name" "$HOME/.local/state/omarchy/current/theme.name"
  link "$DOTFILES/mac/borders/bordersrc" "$HOME/.config/borders/bordersrc"
  link "$DOTFILES/theme/claude.json" "$HOME/.claude/themes/omarchy.json"
  # btop rewrites btop.conf on exit, so only the theme is linked; the setting is written once.
  link "$DOTFILES/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"
  if ! grep -qs '^color_theme = "current"' "$HOME/.config/btop/btop.conf"; then
    printf 'color_theme = "current"\ntheme_background = False\n' >>"$HOME/.config/btop/btop.conf"
  fi
  "$DOTFILES/mac/theme-set.sh"
  "$DOTFILES/brave/extensions.sh" apply

  "$DOTFILES/mac/defaults.sh"
}

install_omarchy() {
  echo "omarchy -> ~/.config/hypr, ~/.config/herdr, ~/.config/voxtype, ~/.config/brave-flags.conf, Brave and theme-export hooks, ~/.config/mpv, ~/.config/wireplumber, ~/.local/share/applications, nvim theme, ~/.claude/rules, /etc/keyd"
  link "$DOTFILES/omarchy/hypr/input.lua" "$HOME/.config/hypr/input.lua"
  link "$DOTFILES/omarchy/hypr/bindings.lua" "$HOME/.config/hypr/bindings.lua"
  link "$DOTFILES/omarchy/hypr/monitors.lua" "$HOME/.config/hypr/monitors.lua"
  link "$DOTFILES/omarchy/hypr/autostart.lua" "$HOME/.config/hypr/autostart.lua"
  link "$DOTFILES/omarchy/hypr/hyprsunset.conf" "$HOME/.config/hypr/hyprsunset.conf"
  link "$DOTFILES/omarchy/claude-rules.md" "$HOME/.claude/rules/omarchy.md"
  link "$DOTFILES/omarchy/brave-flags.conf" "$HOME/.config/brave-flags.conf"
  link "$DOTFILES/brave/theme.sh" "$HOME/.config/omarchy/hooks/theme-set.d/brave-theme.sh"
  "$DOTFILES/brave/theme.sh"
  link "$DOTFILES/brave/web-theme/generate.sh" "$HOME/.config/omarchy/hooks/theme-set.d/web-theme.sh"
  "$DOTFILES/brave/web-theme/generate.sh"
  "$DOTFILES/brave/extensions.sh" apply
  link "$DOTFILES/omarchy/theme-export.sh" "$HOME/.config/omarchy/hooks/theme-set.d/theme-export.sh"
  "$DOTFILES/omarchy/theme-export.sh"
  # Omarchy's herdr config verbatim: the baseline omarchy/herdr/config.toml diffs against. Commit what this changes.
  install -Dm644 /usr/share/omarchy/config/herdr/config.toml "$DOTFILES/omarchy/herdr/omarchy-default.toml"
  link "$DOTFILES/omarchy/herdr/config.toml" "$HOME/.config/herdr/config.toml"

  # Without this folder, Omarchy's theme switch stops forcing its one-color (gray) policy on Brave, which would block the theme above.
  if [ -d /etc/brave/policies/managed ]; then
    sudo rm -rf /etc/brave/policies/managed
    echo "  removed /etc/brave/policies/managed"
  fi
  link "$DOTFILES/omarchy/mpv/scripts/onepiece.lua" "$HOME/.config/mpv/scripts/onepiece.lua"
  link "$DOTFILES/omarchy/wireplumber/internal-mic.conf" "$HOME/.config/wireplumber/wireplumber.conf.d/internal-mic.conf"
  # The whole folder: `voxtype config set` replaces config.toml instead of writing through a link.
  link "$DOTFILES/voxtype" "$HOME/.config/voxtype"
  if command -v voxtype >/dev/null; then
    voxtype setup --download --model small.en --quiet
    # Whisper on the Radeon (Vulkan): ~1 s per dictation instead of 3-6 s. A Voxtype reinstall resets it.
    [ "$(readlink /usr/bin/voxtype)" = /usr/lib/voxtype/voxtype-vulkan ] || sudo voxtype setup gpu --enable
  else
    echo "  voxtype not installed; skipping its model and GPU (omarchy voxtype install, then re-run)"
  fi
  link "$DOTFILES/omarchy/applications/yazi.desktop" "$HOME/.local/share/applications/yazi.desktop"
  link "$DOTFILES/omarchy/applications/org.gnome.Nautilus.desktop" "$HOME/.local/share/applications/org.gnome.Nautilus.desktop"
  link "$DOTFILES/omarchy/zcode/update.sh" "$HOME/.local/bin/zcode-update"
  # Puts ZCode in Omarchy's agents panel; omarchy-agent-usage-update only runs Omarchy's own collectors.
  link "$DOTFILES/omarchy/zcode/zcode-usage.service" "$HOME/.config/systemd/user/zcode-usage.service"
  link "$DOTFILES/omarchy/zcode/zcode-usage.timer" "$HOME/.config/systemd/user/zcode-usage.timer"
  systemctl --user daemon-reload
  systemctl --user enable --now zcode-usage.timer
  # Deprecated terminal ZCode (replaced by zbridge), kept for now; its herdr hooks are cleared out.
  link "$DOTFILES/zcode/zcode" "$HOME/.local/bin/zcode"
  rm -f "$HOME/.local/bin/zcode-herdr-agent-state"
  zcode_config="$HOME/.zcode/cli/config.json"
  if [ -f "$zcode_config" ] && jq -e '.hooks' "$zcode_config" >/dev/null; then
    jq 'del(.hooks)' "$zcode_config" >"$zcode_config.tmp" && mv "$zcode_config.tmp" "$zcode_config"
  fi

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
  set -- claude git zsh nvim yazi
  if [ "$(uname -s)" = Darwin ]; then
    set -- "$@" mac
  elif [ "$(uname -s)" = Linux ] && [ -d /usr/share/omarchy ]; then
    set -- "$@" omarchy
  fi
fi

for component in "$@"; do
  case "$component" in
    claude | git | zsh | nvim | yazi | mac | omarchy) "install_$component" ;;
    *) echo "unknown component: $component" >&2; exit 1 ;;
  esac
done
