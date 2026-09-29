#!/usr/bin/env bash
# The Web Store extensions both machines' Brave should have, listed in extensions.txt.
#   export: rewrites extensions.txt from what this Brave has installed. Start Brave once after a
#           pull first, or extensions it hasn't installed yet drop out of the list.
#   apply:  one Chromium "external extension" file per listed id; Brave installs new ones (disabled,
#           with a prompt to enable) and uninstalls ones whose file is gone, on its next start.
# Unpacked extensions (Omarchy's, the theme ones) have no Web Store update URL, so they stay out.
set -euo pipefail

list="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/extensions.txt"
webstore=https://clients2.google.com/service/update2/crx
file_content="{\"external_update_url\": \"$webstore\"}"

if [ "$(uname -s)" = Darwin ]; then
  profile="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default"
  dir="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/External Extensions"
  sudo=
else
  profile="$HOME/.config/BraveSoftware/Brave-Browser/Default"
  # Brave on Linux keeps Chromium's path, so Chromium (if installed) reads these too.
  dir=/usr/share/chromium/extensions
  sudo=sudo
fi

case "${1:-}" in
  export)
    # macOS keeps extension settings in Secure Preferences, Linux in Preferences.
    jq -rs --arg url "$webstore" '
      map(.extensions.settings // {}) | add | to_entries[]
      | select(.value.manifest.update_url == $url)
      | "\(.key)  # \(.value.manifest.name)"' \
      "$profile/Preferences" "$profile/Secure Preferences" |
      sort -t'#' -k2 -f >"$list"
    echo "wrote $list ($(wc -l <"$list" | tr -d ' ') extensions)"
    ;;
  apply)
    $sudo mkdir -p "$dir"
    ids=$(sed 's/#.*//' "$list" | tr -d ' ' | grep . || true)
    for f in "$dir"/*.json; do
      [ -e "$f" ] || continue
      id=$(basename "$f" .json)
      # Only remove files this script wrote.
      if [ "$(cat "$f")" = "$file_content" ] && ! grep -qx "$id" <<<"$ids"; then
        $sudo rm "$f"
        echo "  removed $id"
      fi
    done
    for id in $ids; do
      [ -e "$dir/$id.json" ] && continue
      echo "$file_content" | $sudo tee "$dir/$id.json" >/dev/null
      echo "  added $id"
    done
    ;;
  *)
    echo "usage: $0 export|apply" >&2
    exit 1
    ;;
esac
