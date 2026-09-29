# zsh on the Mac: Oh My Zsh with git, autosuggestions and syntax highlighting,
# and Omarchy's prompt, ls and cd. The two plugins are clones in ~/.oh-my-zsh/custom/plugins.

export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:$(python3 -m site --user-base)/bin"
export PATH="$HOME/.local/bin:$PATH"

# Starship draws the prompt, as on Omarchy.
ZSH_THEME=""
COMPLETION_WAITING_DOTS="true"
GIT_PAGER=cat
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

# macOS-style Option word navigation/editing in the terminal.
bindkey '^[[1;3D' backward-word        # Option + Left
bindkey '^[[1;3C' forward-word         # Option + Right
bindkey '^[b' backward-word            # Option + b
bindkey '^[f' forward-word             # Option + f
bindkey '^[^?' backward-kill-word      # Option + Backspace
bindkey '^[d' kill-word                # Option + d

select-backward-word() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle backward-word
}

select-forward-word() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle forward-word
}

zle -N select-backward-word
zle -N select-forward-word
bindkey '^[[1;4D' select-backward-word # Shift + Option + Left
bindkey '^[[1;4C' select-forward-word  # Shift + Option + Right

# Aliases
alias drm="docker ps -aq | xargs docker rm -f"
alias diffp="diff2html -i stdin -o preview"
alias lg="lazygit"

# As Omarchy's bash aliases: eza for ls, zoxide behind cd, bat in the terminal's colors.
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
export BAT_THEME=ansi

alias cd="zd"
zd() {
  if (( $# == 0 )); then
    builtin cd ~ || return
  elif [[ -d $1 ]]; then
    builtin cd "$1" || return
  else
    if ! z "$@"; then
      echo "Error: Directory not found"
      return 1
    fi

    printf "\U000F17A9 "
    pwd
  fi
}

# Neovim workspace: replaces every window on this AeroSpace workspace, including this
# terminal, with two Ghostty windows: Neovim (2/3) | claude (1/3), both in a directory
# (`ide`, `ide git/app`, `ide app` via zoxide). Detached, so it survives closing this
# terminal. Each window is a shell that starts its program, so quitting one leaves a shell.
ide() {
  local dir
  if (( $# == 0 )); then
    dir=$PWD
  elif [[ -d $1 ]]; then
    dir=${1:a}
  else
    dir=$(zoxide query -- "$@") || { echo "Error: Directory not found"; return 1 }
  fi

  (
    # Closing this terminal moves focus to another workspace, so the workspace is fixed up front.
    workspace=$(aerospace list-workspaces --focused)
    windows() { aerospace list-windows --workspace $workspace --format '%{window-id}' }

    # Opens a Ghostty window running $1 and waits until AeroSpace tiles it, so the windows open in order.
    open_tile() {
      aerospace workspace $workspace
      osascript - "$dir" "$1" <<'EOF'
on run argv
	tell application "Ghostty"
		set tileConfig to new surface configuration
		set initial working directory of tileConfig to item 1 of argv
		set command of tileConfig to "/bin/zsh -lic '" & item 2 of argv & "; exec zsh'"
		new window with configuration tileConfig
		activate
	end tell
end run
EOF
      until (( $(windows | wc -l) == $2 )); do sleep 0.05; done
    }

    for id in $(windows); do aerospace close --window-id $id; done
    # An app can refuse to close, e.g. to ask about unsaved work.
    for i in {1..60}; do [[ -z $(windows) ]] && break; sleep 0.05; done
    if [[ -n $(windows) ]]; then
      osascript -e 'display notification "A window on this workspace didn'\''t close" with title "ide"'
      exit 1
    fi

    open_tile "nvim ." 1
    editor=$(windows)
    open_tile claude 2

    # Two even tiles of width w: grow Neovim by a third of one to make it 2/3.
    width=$(osascript -e 'tell application "System Events" to get item 1 of (get size of front window of process "Ghostty")')
    aerospace resize --window-id $editor width +$(( width / 3 ))
    aerospace focus --window-id $editor
  ) &>/dev/null &!
}

# Shut down once no Claude Code session has worked for 10 minutes, or at a time limit either way
# (`shutdown-when-agents-done 90m`, default 3h). Omarchy's version asks herdr, which this Mac can't run;
# this reads ~/.claude/sessions/<pid>.json, where Claude Code (undocumented) keeps "status": "busy" while
# it works. A session waiting for approval counts as done: it won't move until morning anyway.
shutdown-when-agents-done() {
  local limit=${1:-3h} seconds quiet=0 busy file
  case $limit in
    <->h) seconds=$(( ${limit%h} * 3600 )) ;;
    <->m) seconds=$(( ${limit%m} * 60 )) ;;
    *) echo "Usage: shutdown-when-agents-done [<hours>h | <minutes>m]" >&2; return 1 ;;
  esac
  local deadline=$(( SECONDS + seconds ))
  # Keeps the Mac awake until then. The EXIT trap also runs on Ctrl+C; -w ends it if the terminal closes.
  caffeinate -i -w $$ &!
  trap "kill $!" EXIT
  echo "Shutting down once no Claude session has worked for 10 minutes, or at $(date -v+${seconds}S +%H:%M). Ctrl+C cancels."

  while (( SECONDS < deadline && quiet < 10 )); do
    busy=0
    for file in ~/.claude/sessions/*.json(N); do
      # Skips files a crashed session left behind.
      kill -0 ${file:t:r} 2>/dev/null && [[ $(jq -r .status $file) == busy ]] && busy=1
    done
    if (( busy )); then quiet=0; else (( quiet++ )); fi
    sleep 60
  done

  osascript -e 'display notification "Ctrl+C in the terminal running shutdown-when-agents-done cancels" with title "Shutting down in 60 seconds"'
  echo "Shutting down in 60 seconds. Ctrl+C cancels."
  sleep 60
  # Needs no password, unlike `shutdown`. An app with unsaved work can still stop it.
  osascript -e 'tell application "loginwindow" to «event aevtrsdn»'
}

# sudo -A asks for the password in a dialog, so Claude Code can run sudo without a terminal.
export SUDO_ASKPASS=${${(%):-%x}:A:h}/bin/sudo-askpass
