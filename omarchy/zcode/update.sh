#!/bin/bash
# Puts the ZCode desktop app and a TUI built from Z.ai's source on the same version. install.sh links the launchers.
# Usage: update.sh [version]   (default: the newest v* tag of zai-org/ZCode)
set -euo pipefail

repo=https://github.com/zai-org/ZCode.git
app=~/Applications/zcode
tui=~/.local/share/zcode-tui

version=${1:-$(git ls-remote --tags --refs "$repo" 'v*' | sed -n 's|.*refs/tags/v\([0-9.]*\)$|\1|p' | sort -V | tail -n 1)}
version=${version#v}

# Desktop app. The AppImage version has a build number (3.14.3.7762); the tag doesn't.
installed=$(sed -n 's/^X-AppImage-Version=//p' "$app/zcode.desktop" 2>/dev/null | cut -d. -f1-3) || true
installed=${installed:-none}
if [[ $installed == "$version" ]]; then
  echo "Desktop: $version already installed"
elif pgrep -f "^$app/zcode" >/dev/null; then
  echo "Desktop: quit the ZCode app first ($installed is running, updating to $version)" >&2
  exit 1
else
  echo "Desktop: $installed -> $version"
  # Next to the install, so the final mv is a rename.
  mkdir -p ~/Applications
  tmp=$(mktemp -d ~/Applications/.zcode-update.XXXXXX)
  trap 'rm -rf "$tmp"' EXIT
  curl -fL --progress-bar -o "$tmp/ZCode.AppImage" \
    "https://cdn-zcode.z.ai/zcode/electron/releases/$version/linux-x64/ZCode-$version-linux-x64.AppImage"
  chmod +x "$tmp/ZCode.AppImage"
  # Extracted, so it runs without FUSE2 (which Omarchy, for one, lacks).
  (cd "$tmp" && ./ZCode.AppImage --appimage-extract >/dev/null)
  rm "$tmp/ZCode.AppImage"
  # Same path as before: the app's own .desktop launcher points here.
  [[ -d $app ]] && mv "$app" "$tmp/old"
  mv "$tmp/squashfs-root" "$app"
fi

# TUI, built from the tag that matches the desktop app.
dir=$tui/$version
if [[ -f $dir/.built ]]; then
  echo "TUI: $version already built"
else
  echo "TUI: building $version in $dir"
  rm -rf "$dir"
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v$version" "$repo" "$dir"
  (
    cd "$dir"
    mise trust --quiet
    mise install --quiet
    ELECTRON_SKIP_BINARY_DOWNLOAD=1 HUSKY=0 mise exec -- pnpm install --frozen-lockfile
    # Not `pnpm build:zcode`: its packaging step is broken at v3.14.3.
    mise exec -- pnpm --filter '@zcode/cli...' build
  )
  touch "$dir/.built"
fi

previous=$(readlink "$tui/current" || true)
if [[ $previous == "$version" ]]; then
  echo "TUI: $version already current"
else
  ln -sfn "$version" "$tui/current"
  echo "TUI: current -> $version"
  # Keep the previous version for rollback.
  for old in "$tui"/*; do
    case ${old##*/} in
      current | "$version" | "$previous") ;;
      *)
        echo "TUI: removing ${old##*/}"
        rm -rf "$old"
        ;;
    esac
  done
fi
