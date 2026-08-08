# ================================================================
# Zsh v1
# ================================================================

# ------------------------------------------------
# History
# ------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000

setopt append_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify

# ------------------------------------------------
# Interactive behaviour
# ------------------------------------------------

setopt interactivecomments
setopt numericglobsort

bindkey -e

# ------------------------------------------------
# Completion
# ------------------------------------------------

autoload -Uz compinit

mkdir -p "$HOME/.cache"

compinit -d "$HOME/.cache/zcompdump-v1"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ------------------------------------------------
# Shared Bash/Zsh configuration
# ------------------------------------------------

if [ -f "$HOME/dotfiles/v1/shell/common.sh" ]; then
    . "$HOME/dotfiles/v1/shell/common.sh"
fi

# ------------------------------------------------
# fzf
# ------------------------------------------------

if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

# ------------------------------------------------
# zoxide
# ------------------------------------------------

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# ------------------------------------------------
# Autosuggestions
# ------------------------------------------------

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ------------------------------------------------
# Starship prompt
# ------------------------------------------------

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ------------------------------------------------
# Syntax highlighting
# Keep this near the end of .zshrc.
# ------------------------------------------------

if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
