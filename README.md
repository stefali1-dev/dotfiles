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
- Changing a config Omarchy ships: use its override file if it has one (like `hypr/bindings.lua`). If not, track a copy in `omarchy/` and keep Omarchy's verbatim copy beside it as the baseline; the diff is the list of changes.
- Temporary changes: mark the comment `HACK:` (workaround for an upstream bug) or `TODO:` (to undo later), and say when to remove it. `grep -rnE '(HACK|TODO):' ~/dotfiles` lists them.

| Folder | Installs to | OS |
|---|---|---|
| `claude/` | `~/.claude/` (per item; skills per folder, rules per file) | any |
| `claude/hooks/herdr-agent-state.sh`, `claude/skills/herdr/` | herdr's Claude integration (written by `herdr integration install claude`) and herdr's upstream skill. The hook lets herdr resume Claude sessions after a restart. `settings.json` runs it through `hooks/session-state.sh`, which calls it only inside herdr: the work Mac's CrowdStrike Falcon kills any process whose command line names herdr, so the Mac never runs it and `install.sh` skips the herdr skill there. Re-running `herdr integration install claude` adds its direct entry back: remove it | any |
| `git/ignore` | `~/.config/git/ignore` (global gitignore) | any |
| `starship/starship.toml` | `~/.config/starship.toml`: Omarchy's prompt on both machines | any |
| `zsh/zshrc` | `~/.zshrc`: history, aliases, Claude folder trust; then loads `<os>/zsh.zsh` and the untracked `~/.zshrc.local` (machine-only env and secrets). `cheatsheet` prints `nvim/cheatsheet.md` and needs `glow` (`pacman -S glow`, `brew install glow`) | any |
| `nvim/` | `~/.config/nvim`: Omarchy's LazyVim config, shared. `lua/plugins/theme.lua` is untracked: on Omarchy it links the current theme, on macOS it's absent (LazyVim's tokyonight). Omarchy migrations edit files here; commit what they change. `omarchy-nvim-refresh` replaces the link, so re-run `install.sh nvim` after it | any |
| `voxtype/` | Dictation with `small.en`, word hints and replacements for terms Whisper mishears. Same file on both machines: Voxtype's own hotkey is off, and hold F9 runs `voxtype record start/stop` (Hyprland on Omarchy, Karabiner on the Mac). `install.sh` downloads the model. Omarchy: links the whole folder as `~/.config/voxtype` (`voxtype config set` replaces `config.toml` rather than writing through a link) and switches Whisper to the GPU (Vulkan); install Voxtype with `omarchy voxtype install` before `install.sh omarchy`, since run afterwards it copies Omarchy's default over this file (`git checkout` it back). Mac: first drag `Voxtype.app` to Applications from the latest release `.dmg` (the Homebrew cask is stuck at 0.7.5, whose Whisper sometimes turns a whole take into "."); `install.sh` links only `config.toml` into `~/Library/Application Support/voxtype/` (the models live beside it), signs the app (the `.dmg` leaves it unsigned, so macOS asks for the Microphone on every take), links the `voxtype` command into `/opt/homebrew/bin` (Karabiner calls it there) and adds `/Applications/Voxtype.app` as a login item, the only way it gets the Microphone and Accessibility permissions (Input Monitoring isn't needed: Karabiner handles F9). After granting Accessibility, restart Voxtype.app; until then it only copies the text to the clipboard. If it still does, the entry is stale (the app is ad-hoc signed): `tccutil reset Accessibility io.voxtype.daemon`, restart the app and grant it again. The Mac build's Whisper runs on the GPU (Metal) | any |
| `voxtype/overlay/` | Mac only: `install.sh` compiles `main.swift` to `~/.local/bin/voxtype-overlay` (needs the Xcode Command Line Tools), which AeroSpace starts. The waveform strip Omarchy shows while dictating (a port of Voxtype's GTK4 OSD, which needs Wayland), plus a sound and "No mic signal" when the first second of a take is silent. One line per take in `~/Library/Logs/voxtype/overlay.log`. `voxtype-overlay --snapshot <dir>` draws it to PNGs; `fake-daemon.py` plays takes without a mic (`--socket` points the strip at it) | macOS |
| `zcode/`, `claude/skills/zcode/` | `~/.local/bin/zcode` and `zcode-update` (linked by `install.sh claude`): Z.ai's ZCode TUI built from source on the desktop app's version, using its GLM Coding Plan login. Needs `mise`. Run `zcode-update` once after installing, then pick a model once in the TUI (`/model`): headless runs fail with "Select a model" until then. The skill tells Claude how to drive it in herdr panes. Details: its README | any |
| `.githooks/` | Used by this repo (`install.sh` sets `core.hooksPath` and the repo's personal `user.email`): `commit-msg` adds a `Machine: mac` or `Machine: omarchy` trailer to every commit; `post-merge` applies a pulled `theme/` to this Mac | any |
| `theme/` | Not installed: the current Omarchy theme's palette, generated app configs and wallpaper, written by `omarchy/theme-export.sh`. Commit it after a theme switch | any |
| `brave/theme.sh` | `~/.config/omarchy/hooks/theme-set.d/brave-theme.sh`: on each Omarchy theme switch, writes a Brave theme from the theme's `colors.toml` to `~/.local/share/brave-omarchy-theme` (applies on Brave's next start). Replaces Omarchy's one-color browser policy, whose tones came out a washed gray: `install.sh` deletes `/etc/brave/policies/managed` (needs sudo) so Omarchy skips Brave. If an Omarchy update brings the gray back, re-run `install.sh omarchy` | Omarchy Linux |
| `brave/web-theme/` | A Brave extension (loaded by `brave-flags.conf`) that recolors YouTube, ChatGPT, GitHub, X and Grok's dark modes with the current Omarchy theme. `generate.sh` writes its palette and is linked as `~/.config/omarchy/hooks/theme-set.d/web-theme.sh`. Tests and how to add a site: its README | Omarchy Linux |
| `mac/zsh.zsh` | Loaded by `~/.zshrc`: Oh My Zsh, Option-key word editing, `SUDO_ASKPASS`, and Omarchy's prompt and shell tools (Starship, `eza` as `ls`, `zoxide` behind `cd`, fzf). `shutdown-when-agents-done [3h]` powers off once no Claude Code session has worked for 10 minutes, from the undocumented `status` in `~/.claude/sessions/<pid>.json` (check there first if it stops noticing work) | macOS |
| `mac/aerospace.toml` | `~/.config/aerospace/aerospace.toml`: AeroSpace tiling with Omarchy's Cmd shortcuts (workspaces, moves, resize, Cmd + Enter for a Ghostty window). Starts `borders` | macOS |
| `mac/karabiner/` | `~/.config/karabiner` (the whole folder: Karabiner rewrites `karabiner.json` and won't follow a linked file). Caps Lock and right Option as Ctrl, hold F9 to dictate (Voxtype), plus Cmd + B (Brave) and Cmd + Shift + F (Yazi), skipped in apps where those keys already mean something, and Ctrl + J/K for the next/previous tab (down/up, as in Vim) and Ctrl + 1–9 for the 1st–9th tab, in Chrome only | macOS |
| `mac/ghostty/config` | `~/.config/ghostty/config`: Ghostty set up like Omarchy's foot — JetBrainsMono Nerd Font, 14px padding, no title bar, colors from `theme/`. `font-size = 15` matches foot's 9pt at Omarchy's 125%, since the Mac runs its screens at 1x | macOS |
| `mac/borders/bordersrc` | `~/.config/borders/bordersrc`: JankyBorders draws the accent-colored border Hyprland draws on Omarchy. Started by AeroSpace | macOS |
| `mac/theme-set.sh` | Not linked; run by `install.sh` and by `.githooks/post-merge` when a pull changes `theme/`: applies the theme to Brave, Ghostty, VS Code, Obsidian, btop, the border, the wallpaper and the text-selection color | macOS |
| `mac/yazi.applescript` | Compiled by `install.sh` into `~/Applications/Yazi.app`: opens Yazi in a Ghostty window, on a folder if it gets one. Reachable from Cmd + Shift + F, Spotlight, a folder's "Open With" and `open -a Yazi <dir>`. It can't become the default for folders: macOS 26 refuses to reassign `public.folder` or the `file:` scheme, even to Finder itself, so double-clicking a folder and "Show in folder" stay Finder. First use asks to let Yazi control Ghostty | macOS |
| `mac/bin/sudo-askpass` | Used by `sudo -A`: a password dialog showing the command | macOS |
| `mac/claude-rules.md` | `~/.claude/rules/mac.md`: Claude Code rules for macOS only (root via `sudo -A`) | macOS |
| `mac/defaults.sh` | Run by `install.sh`: turns off the macOS shortcuts AeroSpace replaces — Ctrl+←/→ (switch space), Ctrl+↑ (Mission Control), Ctrl+↓ (App Exposé) and Switch to Desktop 1–5, which would take the Cmd+1–4 used for workspaces. Also Omarchy's key repeat: ~250 ms delay, then ~33/s (macOS can't express Omarchy's 40/s), with press-and-hold off in VS Code so a held letter repeats instead of offering accents. Also Shottr's OCR shortcut, Cmd+Shift+1 | macOS |
| `omarchy/zsh.zsh` | Loaded by `~/.zshrc`: Omarchy's bash aliases and tools in zsh, plus autosuggestions and syntax highlighting. `claude` updates Claude Code through mise before it starts. `ide [dir]` replaces every window on the current workspace (including its own terminal) with small terminal, Neovim, small terminal side by side. Needs `zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions` and `chsh -s /usr/bin/zsh` | Omarchy Linux |
| `omarchy/herdr/config.toml` | `~/.config/herdr/config.toml`: Omarchy's herdr config with tab keys on Ctrl + ←/→ (Ctrl + Shift moves the tab), so Alt + arrows stay word editing. Its own sound is off: it rang for every orchestrator worker, so `claude/hooks/agent-sound.sh` rings instead. `omarchy-default.toml` beside it is Omarchy's verbatim copy, refreshed by `install.sh omarchy`: `diff omarchy/herdr/omarchy-default.toml omarchy/herdr/config.toml` lists the changes; when `git diff omarchy/herdr/omarchy-default.toml` shows an Omarchy update, merge it in by hand | Omarchy Linux |
| `omarchy/hypr/` | `~/.config/hypr/{input,bindings,monitors}.lua`. With an external monitor, workspace 1 stays on the laptop and 2–5 go to the monitor. The AOC ultrawide runs at 120 Hz with the laptop centred below it | Omarchy Linux |
| `omarchy/brave-flags.conf` | `~/.config/brave-flags.conf`: Omarchy's Chromium flags plus `--force-device-scale-factor=0.9`, so Brave (tabs and pages) is smaller while screens stay at 125%. Also loads the theme `brave/theme.sh` writes, and the `brave/web-theme` extension | Omarchy Linux |
| `omarchy/theme-export.sh` | `~/.config/omarchy/hooks/theme-set.d/theme-export.sh`: on each Omarchy theme switch, copies the files other machines use from the current theme into `theme/` (video wallpapers stay out) | Omarchy Linux |
| `omarchy/mpv/scripts/onepiece.lua` | `~/.config/mpv/scripts/onepiece.lua`: for the `onepiece` command in `omarchy/zsh.zsh`, remembers the last episode and its position, only in mpv windows that command opened, not ones opened from the file manager (`onepiece` resumes, `onepiece <file or folder>` starts there) | Omarchy Linux |
| `omarchy/wireplumber/internal-mic.conf` | `~/.config/wireplumber/wireplumber.conf.d/` (only this file: Omarchy puts its own there): the Lenovo's sound card uses the plain HDA profile instead of UCM, whose "Digital Microphone" is dead and whose working mic WirePlumber never picks as default | Omarchy Linux |
| `omarchy/applications/` | `~/.local/share/applications/`: Yazi replaces Nautilus as the file manager. `yazi.desktop` is "Files" in the launcher (first for "file") and opens folders (`install.sh` sets it for `inode/directory`); `org.gnome.Nautilus.desktop` hides Nautilus from the launcher. "Show in folder" in browsers still opens Nautilus | Omarchy Linux |
| `omarchy/zcode/` | zcode's Omarchy-only parts: its hooks report its state to herdr (Agents list, `herdr agent wait`), and a timer runs `agent-usage --omarchy-record` to show the plan's limits as a ZCode tab in Omarchy's agents panel. Details: `zcode/README.md` | Omarchy Linux |
| `omarchy/claude-rules.md` | `~/.claude/rules/omarchy.md`: Claude Code rules for Omarchy only (root via `pkexec`) | Omarchy Linux |
| `omarchy/keyd/` | `/etc/keyd/default.conf` (copied, needs sudo) | Omarchy Linux |
| `omarchy/modprobe/` | `/etc/modprobe.d/hid_apple.conf` (copied, needs sudo; rebuilds the boot image): the US Magic Keyboard's `` ` `` `~` key types `<` `>` without it | Omarchy Linux |
| `omarchy/libinput/` | `/etc/libinput/local-overrides.quirks` (copied, needs sudo): keeps touchpad disable-while-typing working through keyd | Omarchy Linux |
| (no file) | `~/.local/state/omarchy/toggles/screensaver-off`: an empty marker `install.sh` creates to keep Omarchy's screensaver off | Omarchy Linux |

## Before installing, check

- `~/agent-docs/` holds plans and notes (see `claude/CLAUDE.md`). It isn't in this repo. Create it with `mkdir ~/agent-docs`; the SessionStart hook does nothing until a `~/agent-docs/<repo>/` exists.
- `omarchy/keyd/default.conf` has an `[ids]` line for one laptop's built-in keyboard. On new hardware, find the ID with `sudo keyd monitor`, press the Copilot key, and update the line.
- Don't commit anything from `~/.claude` except the items listed in `install.sh`. The rest is state: history, sessions and credentials.

## macOS: the Omarchy look

The Mac follows whichever theme Omarchy exported into `theme/`. `install.sh mac` links that folder as
`~/.local/state/omarchy/current/theme`, the path both machines read, and runs `mac/theme-set.sh`.
After a theme switch on Omarchy: commit `theme/` there, `git pull` here, and `.githooks/post-merge`
retints everything.

Screens run at 1x (no HiDPI scaling) so text stays crisp, and each app is sized to match Omarchy's
125% instead: Ghostty's `font-size = 15` gives the same 9px-wide cell as foot, and VS Code uses
`window.zoomLevel` 1.2. Brave, Slack and Obsidian are set below.

Before `install.sh` on a fresh Mac:

- [Homebrew](https://brew.sh), then the packages below.
- Oh My Zsh, with its two plugins: `git clone https://github.com/zsh-users/zsh-autosuggestions
  ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions` and the same for
  `https://github.com/zsh-users/zsh-syntax-highlighting`.
- Permissions, or the keyboard and tiling silently do nothing: AeroSpace needs Accessibility
  (System Settings → Privacy & Security → Accessibility), and Karabiner-Elements needs Input
  Monitoring plus its driver extension, which it prompts for on first launch.

Packages:

```sh
brew install yazi ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick \
  eza starship btop glow neovim tree-sitter-cli mise FelixKratz/formulae/borders
brew install --cask ghostty aerospace karabiner-elements font-jetbrains-mono-nerd-font \
  peteonrails/voxtype/voxtype
```

Set by hand, once (the rest is `install.sh`):

- **Brave** — macOS has no `brave-flags.conf`, so the two extensions are loaded by hand once:
  `brave://extensions` → **Developer mode** on (top right) → **Load unpacked** (top left) → in the
  picker press Cmd + Shift + G and paste the path, twice:
  `~/.local/share/brave-omarchy-theme` (the tab strip) and `~/dotfiles/brave/web-theme/extension`
  (site colors). **Developer mode has to stay on**: since Chromium 134 an unpacked extension is
  disabled while it is off ("Developer Mode Off. Some extensions were disabled."). They survive
  restarts and re-read their files each start, so a new theme needs only a Brave restart.
  Then Settings → Appearance → Fonts → Fixed-width: JetBrainsMono Nerd Font, and Page zoom 110%.
- **Slack** — Preferences → Appearance → Dark, then Custom theme → paste the string from the current
  palette, and turn the window gradient off. Slack maps these onto its own colors, so the message
  area stays its own gray; there is no way around that. Print the string with:

  ```sh
  sed -n 's/^\([a-z_]*\) *= *"\(#[0-9a-fA-F]\{6\}\)".*/\1 \2/p' ~/dotfiles/theme/colors.toml |
    awk '{ c[$1]=$2 } END { printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
      c["dark_background"], c["lighter_background"], c["accent"], c["background"], c["selection"],
      c["foreground"], c["green"], c["red"], c["background"], c["bright_foreground"] }'
  ```

- **VS Code** — set `editor.fontFamily` and `terminal.integrated.fontFamily` to
  `JetBrainsMono Nerd Font`, and `window.zoomLevel` to `1.2`. The color theme is automatic, these are
  not: `settings.json` stays untracked (work extension settings), and Neovim is replacing it anyway.
- **Yazi's first launch** asks to let it control Ghostty; allow it.
- **Log out and back in** once, so the key repeat settings take effect.

## Keyboard

The goal is Mac-style muscle memory on both machines: on Omarchy the key next to Space acts as Cmd,
and the Mac keeps macOS's own Cmd.

| Physical key | Acts as | Set in |
|---|---|---|
| Caps Lock | Ctrl | `hypr/input.lua` (`ctrl:nocaps`) |
| Win (left of Alt) | Alt | `hypr/input.lua` (`altwin:swap_lalt_lwin`) |
| Left Alt (next to Space) | Super = Cmd | same |
| Copilot | Ctrl | `keyd/default.conf` |
| Magic Keyboard: right Option | Ctrl | `hypr/input.lua` (`ctrl:ralt_rctrl`, this keyboard only; no Alt/Super swap, Cmd is already next to Space) |
| macOS: Caps Lock and right Option | Ctrl | `mac/karabiner/karabiner.json`, so System Settings → Keyboard → Modifier Keys can stay at its defaults |

Window and app shortcuts, and how far the Mac follows. On the Mac they come from
`mac/aerospace.toml`, except Cmd + B and Cmd + Shift + F, which are Karabiner rules so that apps
where those keys already mean something (bold, Find in Files) keep them.

| Action | Omarchy | macOS |
|---|---|---|
| Switch workspace | Cmd + 1–9 | Cmd + 1–4 |
| Move window to workspace | Cmd + Ctrl + 1–0 | Cmd + Ctrl + 1–4 |
| Move window silently | Cmd + Ctrl + Alt + 1–0 | – |
| Focus/move window in a direction | Cmd + arrows, Cmd + Shift + arrows | same |
| Resize window | Cmd + - / = (held) | Cmd + - / = |
| New terminal | Cmd + Enter | same (a Ghostty window) |
| Browser | Cmd + B | same |
| File manager (Yazi) | Cmd + Shift + F | same |
| Yazi in the terminal's folder | Cmd + Alt + Shift + F | – |
| Full screen | Cmd + Ctrl + F | same (AeroSpace's, not macOS's own Space) |
| Tiled full screen | Cmd + Ctrl + Shift + F | – |
| Toggle floating | Cmd + Alt + T | same |
| Close window | Cmd + Q | Cmd + Q quits the app, except in Ghostty, where it closes the window (Cmd + Shift + Q quits it) |
| Launcher | Cmd + Space | Cmd + Space (Spotlight) |
| Scratchpad, and moving a window to it | Cmd + Alt + S, Cmd + Shift + Alt + S | – |
| List all bindings | Cmd + K | – |
| Service mode (reload, flatten, layout) | – | Cmd + Shift + ; |

On Omarchy, Cmd + C/V/X/A/Z/Shift+Z/S/F/R/N/T/Shift+T/W send the matching Ctrl shortcut to the app
(terminals get a terminal-safe action instead); macOS apps already use Cmd for these. Cmd + 0 is
unbound on Omarchy so workspace 10 can't be opened by accident, and Cmd + Ctrl + 1–9 no longer opens
bar panels there — those keep their letter shortcuts (Cmd + Ctrl + A, B, D, W, P, T).

Two macOS shortcuts are given up to AeroSpace: Cmd + ←/→ no longer jump to the start and end of a
line (Ctrl + A and Ctrl + E still do), and Cmd + - / = no longer zoom in apps.

Screenshots on Omarchy use Omasnap (installed by `install.sh`); macOS keeps its own Cmd + Shift + 3/4/5:

| Shortcut | Does |
|---|---|
| Cmd + Shift + 1 | Copy text from a region (OCR) |
| Print, Cmd + Shift + 2 | Region or window, then annotate |
| Cmd + Shift + 3 | Scrolling capture |

## Claude Code

`claude/` holds the personal Claude Code config that applies to every project:

| Path | What it does |
|---|---|
| `CLAUDE.md` | Working style instructions; on Omarchy also zcode's `~/.zcode/AGENTS.md` |
| `settings.json` | Hooks, `@` file suggestions, `~/agent-docs` access, worktree base |
| `hooks/agent-docs.sh` | SessionStart hook: links `~/agent-docs/<repo>` into the checkout |
| `hooks/agent-sound.sh` | Stop, permission and question hooks (and zcode's state hook): herdr's done/request sound for the agent tab you're not looking at. Silent in orchestrator worker tabs (`ORCH_WORKER=1`), and wherever herdr's own sound is still on, so nothing rings twice |
| `hooks/session-state.sh` | SessionStart hook: runs herdr's `hooks/herdr-agent-state.sh` only inside herdr (see the herdr row above) |
| `agent-usage.mjs` | `~/.local/bin/agent-usage`: Claude and Z.ai (zcode) plan usage in one shape: 5-hour and weekly used % and reset time; `agent-usage claude` or `agent-usage zcode` for one; `--json` for orchestrator agents. Claude is live from the endpoint behind `/usage` (reads the login token, never refreshes it). zcode decrypts the desktop login's API key from `~/.zcode/v2/credentials.json` with zcode's own cipher (same file format on macOS) and asks Z.ai. `--omarchy-record` writes zcode's for Omarchy's agents panel |
| `ccswitch` | `~/.local/bin/ccswitch`: switch the Claude Code login between saved accounts in `~/.claude-accounts/` (machine-local, never committed): `add <name>` captures the current login, `ccswitch [name]` saves-then-switches (fzf picker), `list` shows refresh-token days left. Refuses while a claude session runs (`--force` overrides). Swaps `~/.claude/.credentials.json` on Linux, the Keychain on macOS | any |
| `file-suggestion.sh` | `@` picker: tracked files plus agent docs and local notes |
| `skills/` | `review-comments`, `decision-questions`, `caveman`, `orchestrator` (`/orchestrator`: hands tasks to Claude and zcode workers in their own worktree and herdr tab; decisions in `~/agent-docs/orchestrator/`) |
| `rules/comments.md` | Comment standard for `.ts`/`.tsx` files |
| `agents/reviewer.md` | Fresh-context reviewer used by `review-comments` |
| `commands/q.md` | `/q` queues a follow-up |
