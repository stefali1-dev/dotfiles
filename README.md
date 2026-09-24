# dotfiles

Personal machine setup. The repo is the source of truth: `install.sh` symlinks each file into place, so editing the live file edits the repo.

## Set up a new machine

```sh
git clone git@github.com:stefali1-dev/dotfiles.git ~/dotfiles
~/dotfiles/install.sh              # everything that fits this OS
~/dotfiles/install.sh claude git   # or pick components
```

Existing files are moved to `<file>.bak.<timestamp>`, never deleted. Re-running is a no-op.

| Folder | Installs to | OS |
|---|---|---|
| `claude/` | `~/.claude/` (per item; skills per folder) | any |
| `git/ignore` | `~/.config/git/ignore` (global gitignore) | any |
| `zsh/zshrc` | `~/.zshrc`: Omarchy's bash aliases and tools in zsh, plus autosuggestions and syntax highlighting. Needs `zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions` and `chsh -s /usr/bin/zsh` | Omarchy Linux |
| `omarchy/hypr/` | `~/.config/hypr/{input,bindings,monitors}.lua`. With an external monitor, workspace 1 stays on the laptop and 2–5 go to the monitor | Omarchy Linux |
| `omarchy/keyd/` | `/etc/keyd/default.conf` (copied, needs sudo) | Omarchy Linux |
| `omarchy/libinput/` | `/etc/libinput/local-overrides.quirks` (copied, needs sudo): keeps touchpad disable-while-typing working through keyd | Omarchy Linux |

## Before installing, check

- **Work Mac:** run `CLAUDE_PROFILE=work ./install.sh claude`. It merges `claude/settings.work.json` (`autoMode` context and CDK permissions) into `~/.claude/settings.json`. That file is a copy, not a link, so edit the repo files and re-run. Everywhere else, `settings.json` is a symlink to the portable shared file.
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

`mac/` doesn't exist yet. To get the same layout on macOS, remap Caps Lock to Control in System Settings → Keyboard → Modifier Keys.

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
