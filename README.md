# dotfiles

Personal machine setup. The repo is the source of truth: `install.sh` symlinks each file into place, so editing the live file edits the repo.

## Set up a new machine

```sh
git clone git@github.com:stefali1-dev/dotfiles.git ~/dotfiles
~/dotfiles/install.sh              # everything that fits this OS
~/dotfiles/install.sh claude git   # or pick components
```

Existing files are moved to `<file>.bak.<timestamp>`, never deleted. Re-running is a no-op.

## Editing this repo

- Change only what the task needs. Keep it small.
- Top-level folders are shared by both machines; `mac/` and `omarchy/` hold config for one OS only. OS-only config goes in its folder, and OS differences go in `<os>/zsh.zsh` (env) or `<os>/claude-rules.md`, not in `claude/settings.json`.
- New config: wire it into `install.sh` and add one table row here. Nothing else.
- README: tables and bullets, blunt. No history, no changelog, no restating what a file says.
- Comments: only a non-obvious why, one or two short lines.
- Temporary changes: mark the comment `HACK:` (workaround for an upstream bug) or `TODO:` (to undo later), and say when to remove it. `grep -rnE '(HACK|TODO):' ~/dotfiles` lists them.

| Folder | Installs to | OS |
|---|---|---|
| `claude/` | `~/.claude/` (per item; skills per folder, rules per file) | any |
| `git/ignore` | `~/.config/git/ignore` (global gitignore) | any |
| `zsh/zshrc` | `~/.zshrc`: history, aliases, Claude folder trust; then loads `<os>/zsh.zsh` and the untracked `~/.zshrc.local` (machine-only env and secrets) | any |
| `nvim/` | `~/.config/nvim`: Omarchy's LazyVim config, shared. `lua/plugins/theme.lua` is untracked: on Omarchy it links the current theme, on macOS it's absent (LazyVim's tokyonight). Omarchy migrations edit files here; commit what they change. `omarchy-nvim-refresh` replaces the link, so re-run `install.sh nvim` after it. macOS needs `brew install neovim ripgrep fd` and a Nerd Font | any |
| `.githooks/` | Used by this repo (`install.sh` sets `core.hooksPath` and the repo's personal `user.email`): adds a `Machine: mac` or `Machine: omarchy` trailer to every commit | any |
| `mac/zsh.zsh` | Loaded by `~/.zshrc`: Oh My Zsh, Option-key word editing, `SUDO_ASKPASS`. Needs Oh My Zsh with `zsh-autosuggestions` and `zsh-syntax-highlighting` cloned into `~/.oh-my-zsh/custom/plugins` | macOS |
| `mac/bin/sudo-askpass` | Used by `sudo -A`: a password dialog showing the command | macOS |
| `mac/claude-rules.md` | `~/.claude/rules/mac.md`: Claude Code rules for macOS only (root via `sudo -A`) | macOS |
| `mac/defaults.sh` | Run by `install.sh`: Ctrl+←/→ no longer switch spaces | macOS |
| `omarchy/zsh.zsh` | Loaded by `~/.zshrc`: Omarchy's bash aliases and tools in zsh, plus autosuggestions and syntax highlighting. `ide [dir]` replaces every window on the current workspace (including its own terminal) with small terminal, Neovim, small terminal side by side. Needs `zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions` and `chsh -s /usr/bin/zsh` | Omarchy Linux |
| `omarchy/hypr/` | `~/.config/hypr/{input,bindings,monitors}.lua`. With an external monitor, workspace 1 stays on the laptop and 2–5 go to the monitor. The AOC ultrawide runs at 120 Hz with the laptop centred below it | Omarchy Linux |
| `omarchy/brave-flags.conf` | `~/.config/brave-flags.conf`: Omarchy's Chromium flags plus `--force-device-scale-factor=0.9`, so Brave (tabs and pages) is smaller while screens stay at 125% | Omarchy Linux |
| `omarchy/mpv/scripts/onepiece.lua` | `~/.config/mpv/scripts/onepiece.lua`: for the `onepiece` command in `omarchy/zsh.zsh`, remembers the last episode and its position, only in mpv windows that command opened, not ones opened from the file manager (`onepiece` resumes, `onepiece <file or folder>` starts there) | Omarchy Linux |
| `omarchy/claude-rules.md` | `~/.claude/rules/omarchy.md`: Claude Code rules for Omarchy only (root via `pkexec`) | Omarchy Linux |
| `omarchy/keyd/` | `/etc/keyd/default.conf` (copied, needs sudo) | Omarchy Linux |
| `omarchy/modprobe/` | `/etc/modprobe.d/hid_apple.conf` (copied, needs sudo; rebuilds the boot image): the US Magic Keyboard's `` ` `` `~` key types `<` `>` without it | Omarchy Linux |
| `omarchy/libinput/` | `/etc/libinput/local-overrides.quirks` (copied, needs sudo): keeps touchpad disable-while-typing working through keyd | Omarchy Linux |
| (no file) | `~/.local/state/omarchy/toggles/screensaver-off`: an empty marker `install.sh` creates to keep Omarchy's screensaver off | Omarchy Linux |

## Before installing, check

- **Work Mac:** clone over HTTPS (`git clone https://stefali1-dev@github.com/stefali1-dev/dotfiles.git ~/dotfiles`); its SSH key belongs to the work GitHub account. Then run `CLAUDE_PROFILE=work ./install.sh`. It merges `claude/settings.work.json` (`autoMode` context and CDK permissions) into `~/.claude/settings.json`. That file is a copy, not a link, so edit the repo files and re-run. Everywhere else, `settings.json` is a symlink to the portable shared file.
- `~/agent-docs/` holds plans and notes (see `claude/CLAUDE.md`). It isn't in this repo. Create it with `mkdir ~/agent-docs`; the SessionStart hook does nothing until a `~/agent-docs/<repo>/` exists.
- `omarchy/keyd/default.conf` has an `[ids]` line for one laptop's built-in keyboard. On new hardware, find the ID with `sudo keyd monitor`, press the Copilot key, and update the line.
- Don't commit anything from `~/.claude` except the items listed in `install.sh`. The rest is state: history, sessions and credentials.

## Keyboard (Omarchy)

The goal is Mac-style muscle memory, with the key next to Space acting as Cmd.

| Physical key | Acts as | Set in |
|---|---|---|
| Caps Lock | Ctrl | `hypr/input.lua` (`ctrl:nocaps`) |
| Win (left of Alt) | Alt | `hypr/input.lua` (`altwin:swap_lalt_lwin`) |
| Left Alt (next to Space) | Super = Cmd | same |
| Copilot | Ctrl | `keyd/default.conf` |
| Magic Keyboard: right Option | Ctrl | `hypr/input.lua` (`ctrl:ralt_rctrl`, this keyboard only; no Alt/Super swap, Cmd is already next to Space) |

`hypr/bindings.lua` maps Cmd shortcuts:
- **Cmd + C/V/X/A/Z/Shift+Z/S/F/R/N/T/Shift+T/W** sends the matching Ctrl shortcut to the app. Terminals get a terminal-safe action instead.
- **Cmd + Q** closes the window.
- **Cmd + 1–9** switches workspaces.
- **Cmd + Space** opens the launcher.
- **Cmd + K** lists all bindings.

Omarchy actions that moved:

| Action | Shortcut |
|---|---|
| Full screen | Cmd + Ctrl + F |
| Tiled full screen | Cmd + Ctrl + Shift + F |
| Toggle floating | Cmd + Alt + T |
| Toggle scratchpad | Cmd + Alt + S |
| Move window to scratchpad | Cmd + Shift + Alt + S |
| Browser (also Omarchy's Cmd + Shift + B) | Cmd + B |
| Move window to workspace 1–10 | Cmd + Ctrl + 1–0 |
| Move window silently to workspace 1–10 | Cmd + Ctrl + Alt + 1–0 |

Cmd + Ctrl + 1–9 no longer opens bar panels; they keep their letter shortcuts (Cmd + Ctrl + A, B, D, W, P, T).

Screenshots use Omasnap (installed by `install.sh`):

| Shortcut | Does |
|---|---|
| Print, Cmd + Shift + 2 | Region or window, then annotate |
| Cmd + Shift + 1 | Full screen |
| Cmd + Shift + 3 | Scrolling capture |
| Cmd + Shift + 4 | Copy text from a region (OCR) |

On macOS, remap Caps Lock to Control in System Settings → Keyboard → Modifier Keys for the same layout.

## Claude Code

`claude/` holds the personal Claude Code config that applies to every project:

| Path | What it does |
|---|---|
| `CLAUDE.md` | Working style instructions |
| `settings.json` | Hooks, `@` file suggestions, `~/agent-docs` access, worktree base (any machine) |
| `settings.work.json` | Work-Mac layer: auto mode context, CDK permissions |
| `hooks/agent-docs.sh` | SessionStart hook: links `~/agent-docs/<repo>` into the checkout |
| `file-suggestion.sh` | `@` picker: tracked files plus agent docs and local notes |
| `skills/` | `review-comments`, `decision-questions`, `caveman` |
| `rules/comments.md` | Comment standard for `.ts`/`.tsx` files |
| `agents/reviewer.md` | Fresh-context reviewer used by `review-comments` |
| `commands/q.md` | `/q` queues a follow-up |
