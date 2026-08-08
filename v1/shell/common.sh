# ================================================================
# Shared interactive shell configuration
# Used by Bash and Zsh.
# ================================================================

# User-local executables.
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi

export PATH

# Preserve Rust/rustup environment when present.
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Common aliases.
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Neovim v1.
alias v='NVIM_APPNAME=nvim-v1 nvim'
alias nvim-v1='NVIM_APPNAME=nvim-v1 nvim'

# Debian/Ubuntu package installs bat as "batcat".
if ! command -v bat >/dev/null 2>&1 &&
   command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi

# Git TUI.
if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi
