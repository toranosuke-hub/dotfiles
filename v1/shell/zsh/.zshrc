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

# -- Nord shell colors -------------------------------------------------------
# Visual styling only. No shell behavior is changed.

# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4C566A'

# zsh-syntax-highlighting
ZSH_HIGHLIGHT_STYLES[default]='fg=#D8DEE9'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#BF616A'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#81A1C1,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#88C0D0'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#88C0D0'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#88C0D0'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#81A1C1'
ZSH_HIGHLIGHT_STYLES[function]='fg=#88C0D0'
ZSH_HIGHLIGHT_STYLES[command]='fg=#88C0D0'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#B48EAD'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#88C0D0'
ZSH_HIGHLIGHT_STYLES[path]='fg=#A3BE8C'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#4C566A'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#EBCB8B'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#B48EAD'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#EBCB8B'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#EBCB8B'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#A3BE8C'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#A3BE8C'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#A3BE8C'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#B48EAD'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#81A1C1'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#D08770'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#4C566A'
