# zsh on Omarchy. Omarchy ships bash config only, so this loads the parts of
# /usr/share/omarchy/default/bash that work in zsh and redoes the rest natively.

# Omarchy environment (OMARCHY_PATH, PATH, EDITOR, BROWSER, pagers)
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap
if [[ -n $OMARCHY_PATH ]]; then
  source "$OMARCHY_PATH/default/bash/envs"

  # Omarchy's aliases and functions (ls/eza, cd/zoxide, g, cx, tdl, ga, ...) are
  # written for bash; ksh emulation gives them bash-like arrays and word splitting.
  emulate ksh -c 'source "$OMARCHY_PATH/default/bash/aliases"'
  for f in "$OMARCHY_PATH"/default/bash/fns/*; do emulate ksh -c 'source "$f"'; done
  unset f
fi

# Completion: menu you can arrow through, case-insensitive
fpath=(/usr/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Emacs-style line editing, with Ctrl+arrows or Alt+arrows jumping words (Alt as
# on macOS; Alt+Backspace is built in), and Home/End/Delete working
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[3;3~' kill-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Tools, as Omarchy sets them up for bash
command -v mise &>/dev/null && eval "$(mise activate zsh)"
[[ $TERM != dumb ]] && command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v fzf &>/dev/null && source <(fzf --zsh)

# One Piece in mpv: resume the last episode, or start at a file or folder (`onepiece .`).
# ~/.config/mpv/scripts/onepiece.lua records the last episode.
onepiece() {
  local last=~/.local/state/onepiece/last
  if [[ -z $1 && ! -f $last ]]; then
    echo "No episode yet. Run: onepiece <file or folder>" >&2
    return 1
  fi
  setsid -f mpv --autocreate-playlist=same --script-opts=onepiece-track=yes "${1:-$(<$last)}" >/dev/null 2>&1
}

# Plugins. Syntax highlighting must be sourced last.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
