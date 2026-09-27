# zcode

Z.ai's official ZCode TUI, built from [source](https://github.com/zai-org/ZCode) at the same tag as the ZCode desktop app. It signs in with the desktop app's login (`~/.zcode/v2/credentials.json`), so it runs on the GLM Coding Plan with no API key. The desktop app ships the agent runtime but not the TUI, and community wrappers break on each desktop update.

| File | Installs to |
|---|---|
| `update.sh` | `~/.local/bin/zcode-update` |
| `zcode` | `~/.local/bin/zcode`: runs the current build with the Node version its checkout pins |
| `claude/agent-usage.mjs` | `agent-usage zcode`: the plan's 5-hour and weekly limits, as the desktop app shows them (`--json` adds used, total and per-model detail) |
| `omarchy/zcode/herdr-agent-state.sh` | Omarchy only: `~/.local/bin/zcode-herdr-agent-state`, reports zcode's state to herdr (see below). The launcher skips it where it isn't installed |
| `omarchy/zcode/zcode-usage.service`, `.timer` | Omarchy only: `~/.config/systemd/user/`: every 15 minutes, `agent-usage --omarchy-record` writes `~/.local/state/omarchy/agents/usage/zcode.json`, which gives Omarchy's agents panel (bar) a ZCode tab. The panel's own refresh (`r`) doesn't update it. If an Omarchy update changes the panel's record format, the tab breaks: compare with Claude's record in that folder |
| `omarchy/zcode/hooks.json` | Omarchy only: the `hooks` block of `~/.zcode/cli/config.json`, merged in by `install.sh` (zcode rewrites that file, so it can't be a link) |

Driving it from Claude in herdr panes: the `zcode` skill (`claude/skills/zcode/`).

## Use

- First time: `install.sh claude` (and `install.sh omarchy` there), then `zcode-update`. Needs `mise`, `git`, `curl`. Omarchy: with no desktop app in `~/Applications/zcode`, it installs one; start it once (`~/Applications/zcode/AppRun`) and sign in. Mac: install ZCode.app from z.ai and sign in first.
- Then open `zcode` once and pick a model with `/model`: until then headless runs fail with "Select a model before continuing".
- `zcode`: TUI in the current folder, Build mode (asks before edits and commands). Quit with Ctrl+C.
- `zcode -c`: resume the last session in this folder.
- `zcode -p "..." --mode plan`: headless, prints only the answer. **Without `--mode` it's yolo** (every tool, no approval).
- If `zcode` runs something else: `command -v zcode`. `~/.local/bin` is late in `$PATH`, so an npm-global `zcode` wins.

## herdr

Inside herdr, zcode shows in the Agents list as idle, working or blocked (approval dialog), and `herdr agent wait|get|read` work on it. zcode's hooks (`hooks.json`) call `herdr-agent-state.sh`; the `zcode` launcher reports idle at start and releases the pane on exit. Headless runs and subcommands don't report, so `zcode -p` from Claude's pane leaves Claude's state alone. Outside herdr it does nothing.

- Esc (interrupt) fires no zcode hook, so the pane stays "working" until the next prompt.
- `herdr agent prompt` and `agent start` only take agent kinds herdr knows; type with `herdr pane send-text` and `send-keys enter`.
- Plan usage isn't in the TUI (the footer only shows context use): run `agent-usage zcode`. It decrypts the desktop login's API key from `~/.zcode/v2/credentials.json` with zcode's own cipher and calls `api.z.ai/api/monitor/usage/quota/limit`. Limits come back as credits; an entry it doesn't know (like a token bundle) prints with its raw type and unit.

## Update and roll back

`zcode-update [version]` (default: newest `v*` tag on Omarchy, ZCode.app's version on the Mac). On Omarchy, quit the desktop app first; it refuses while it runs. One line per step, nothing done if already on that version:

1. Desktop, Omarchy only (ZCode.app updates itself on the Mac): downloads that version's AppImage from Z.ai's CDN, extracts it (no FUSE2 needed) and swaps it into `~/Applications/zcode`, the path the app's own launcher uses.
2. TUI: clones the tag to `~/.local/share/zcode-tui/<version>` and runs `pnpm --filter '@zcode/cli...' build` (about a minute, 3.3 GB).
3. Points `~/.local/share/zcode-tui/current` at it; keeps the previous build, deletes older ones.

Roll back the TUI only: `ln -sfn <previous> ~/.local/share/zcode-tui/current`. Both: `zcode-update <previous>`.

## Known limits

- Upstream TUI at 3.14.3: one Ctrl+C quits, even with text in the prompt (no Ctrl+D, no quit command). `zcode -c` resumes but starts blank (footer `- - | -` until the first prompt). Transcript scrolls only with the mouse wheel.
- `pnpm build:zcode` (a single binary) fails at v3.14.3 (`Missing @zcode/shared dist files`), so `zcode` runs `dist/zcode.cjs` from the checkout.
- Login: if the TUI is signed out, sign in again in the desktop app. Never `zcode logout` or `/logout`: they remove the desktop's login too. Browser `/login` fails on Linux ("requires macOS").
- Assumes tags `v<version>` and the same version on the CDN; if the CDN lacks it, `zcode-update` fails before changing anything.
