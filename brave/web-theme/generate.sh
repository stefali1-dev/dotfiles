#!/usr/bin/env bash
# Writes extension/palette.css from the current Omarchy theme: `accent = "#7aa2f7"` becomes `--omarchy-accent: #7aa2f7;`.
# Also the Omarchy theme-set hook; Brave picks up a new palette on its next start.
set -euo pipefail

dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
colors="$HOME/.local/state/omarchy/current/theme/colors.toml"

{
  echo ":root {"
  sed -n 's/^\([a-z_]*\) *= *"\(#[0-9a-fA-F]\{6\}\)"/  --omarchy-\1: \2;/p' "$colors" | tr _ -
  echo "}"
} >"$dir/extension/palette.css"
