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

# sudo -A asks for the password in a dialog, so Claude Code can run sudo without a terminal.
export SUDO_ASKPASS=${${(%):-%x}:A:h}/bin/sudo-askpass
