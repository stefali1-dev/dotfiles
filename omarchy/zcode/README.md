# zcode

Z.ai's official ZCode TUI, built from [source](https://github.com/zai-org/ZCode) at the same tag as the ZCode desktop app. It signs in with the desktop app's login (`~/.zcode/v2/credentials.json`), so it runs on the GLM Coding Plan with no API key. The desktop app ships the agent runtime but not the TUI, and community wrappers break on each desktop update.

| File | Installs to |
|---|---|
| `update.sh` | `~/.local/bin/zcode-update` |
| `zcode` | `~/.local/bin/zcode`: runs the current build with the Node version its checkout pins |

Driving it from Claude in herdr panes: the `zcode` skill (`claude/skills/zcode/`).

## Use

- First time: `install.sh omarchy`, then `zcode-update`. Needs `mise`, `git`, `curl`. With no desktop app in `~/Applications/zcode`, it installs one; start it once (`~/Applications/zcode/AppRun`) and sign in.
- `zcode`: TUI in the current folder, Build mode (asks before edits and commands). Quit with Ctrl+C.
- `zcode -c`: resume the last session in this folder.
- `zcode -p "..." --mode plan`: headless, prints only the answer. **Without `--mode` it's yolo** (every tool, no approval).
- If `zcode` runs something else: `command -v zcode`. `~/.local/bin` is late in `$PATH`, so an npm-global `zcode` wins.

## Update and roll back

`zcode-update [version]` (default: newest `v*` tag). Quit the desktop app first; it refuses while it runs. One line per step, nothing done if already on that version:

1. Desktop: downloads that version's AppImage from Z.ai's CDN, extracts it (no FUSE2 needed) and swaps it into `~/Applications/zcode`, the path the app's own launcher uses.
2. TUI: clones the tag to `~/.local/share/zcode-tui/<version>` and runs `pnpm --filter '@zcode/cli...' build` (about a minute, 3.3 GB).
3. Points `~/.local/share/zcode-tui/current` at it; keeps the previous build, deletes older ones.

Roll back the TUI only: `ln -sfn <previous> ~/.local/share/zcode-tui/current`. Both: `zcode-update <previous>`.

## Known limits

- Upstream TUI at 3.14.3: one Ctrl+C quits, even with text in the prompt (no Ctrl+D, no quit command). `zcode -c` resumes but starts blank (footer `- - | -` until the first prompt). Transcript scrolls only with the mouse wheel.
- `pnpm build:zcode` (a single binary) fails at v3.14.3 (`Missing @zcode/shared dist files`), so `zcode` runs `dist/zcode.cjs` from the checkout.
- Login: if the TUI is signed out, sign in again in the desktop app. Never `zcode logout` or `/logout`: they remove the desktop's login too. Browser `/login` fails on Linux ("requires macOS").
- Assumes tags `v<version>` and the same version on the CDN; if the CDN lacks it, `zcode-update` fails before changing anything.
