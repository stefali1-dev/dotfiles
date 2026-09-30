#!/bin/bash
# Installs or updates the ZCode desktop app (the Mac's ZCode.app updates itself). install.sh links it as zcode-update.
# Usage: update.sh [version]   (default: the newest v* tag of zai-org/ZCode)
set -euo pipefail

repo=https://github.com/zai-org/ZCode.git
app=~/Applications/zcode

version=${1:-$(git ls-remote --tags --refs "$repo" 'v*' | sed -n 's|.*refs/tags/v\([0-9.]*\)$|\1|p' | sort -V | tail -n 1)}
version=${version#v}

# The AppImage version has a build number (3.14.3.7762); the tag doesn't.
installed=$(sed -n 's/^X-AppImage-Version=//p' "$app/zcode.desktop" 2>/dev/null | cut -d. -f1-3) || true
installed=${installed:-none}
if [[ $installed == "$version" ]]; then
  echo "ZCode $version already installed"
  exit 0
fi
# Tags can trail the CDN (3.14.4 shipped while the newest tag was v3.14.3): never downgrade by default.
if [[ -z ${1:-} && $installed != none && $(printf '%s\n' "$installed" "$version" | sort -V | tail -n 1) == "$installed" ]]; then
  echo "ZCode $installed installed, newer than the newest tag ($version); pass a version to change it"
  exit 0
fi
if pgrep -f "^$app/zcode" >/dev/null; then
  echo "Quit the ZCode app first ($installed is running, updating to $version)" >&2
  exit 1
fi

echo "ZCode: $installed -> $version"
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
# Same path as before: the app's own .desktop launcher and zbridge use it.
[[ -d $app ]] && mv "$app" "$tmp/old"
mv "$tmp/squashfs-root" "$app"
