#!/usr/bin/env bash

set -uo pipefail

# ================================================================
# dotfiles v1 read-only health check
#
# This script performs diagnostics only.
#
# It intentionally does NOT:
#   - use sudo
#   - install/remove packages
#   - create or replace symlinks
#   - modify shell configuration
#   - modify ~/.profile or ~/.zprofile
#   - run chsh
#   - initialize/update Neovim plugins
#   - print secret values
#   - scan research/sample directories
# ================================================================

EXPECTED_NEOVIM_VERSION="0.12.4"
EXPECTED_STARSHIP_VERSION="1.22.1"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null &&
    pwd -P
)"

REPO_DIR="$(
    cd -- "${SCRIPT_DIR}/.." 2>/dev/null &&
    pwd -P
)"

ok() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '[OK]   %s\n' "$*"
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    printf '[WARN] %s\n' "$*"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '[FAIL] %s\n' "$*"
}

section() {
    printf '\n===== %s =====\n' "$*"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_command() {
    local command_name="$1"

    if command_exists "$command_name"; then
        ok "${command_name}: $(command -v "$command_name")"
    else
        fail "Missing command: ${command_name}"
    fi
}

check_any_command() {
    local display_name="$1"
    shift

    local candidate=""

    for candidate in "$@"; do
        if command_exists "$candidate"; then
            ok "${display_name}: ${candidate} ($(command -v "$candidate"))"
            return
        fi
    done

    fail "Missing command: ${display_name} ($*)"
}

check_symlink() {
    local source_path="$1"
    local target_path="$2"

    if [ ! -L "$target_path" ]; then
        if [ -e "$target_path" ]; then
            fail "${target_path}: exists but is not a symlink"
        else
            fail "${target_path}: missing"
        fi
        return
    fi

    local current_target=""

    current_target="$(readlink "$target_path" 2>/dev/null || true)"

    if [ "$current_target" = "$source_path" ]; then
        ok "${target_path} -> ${source_path}"
    else
        fail "${target_path} -> ${current_target:-unknown}"
        printf '       expected: %s\n' "$source_path"
    fi
}

path_contains() {
    local wanted="$1"
    local entry=""

    local old_ifs="$IFS"
    IFS=':'

    for entry in ${PATH:-}; do
        if [ "$entry" = "$wanted" ]; then
            IFS="$old_ifs"
            return 0
        fi
    done

    IFS="$old_ifs"
    return 1
}

# ------------------------------------------------
# Basic repository
# ------------------------------------------------

section "dotfiles v1"

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR" ]; then
    ok "v1 root: ${SCRIPT_DIR}"
else
    fail "Cannot determine v1 root"
fi

if [ -n "$REPO_DIR" ] && [ -d "${REPO_DIR}/.git" ]; then
    ok "Git repository: ${REPO_DIR}"
else
    fail "Git repository not found: ${REPO_DIR}"
fi

if [ -x "${SCRIPT_DIR}/bootstrap.sh" ]; then
    ok "bootstrap.sh exists and is executable"
else
    fail "bootstrap.sh missing or not executable"
fi

if [ -x "${SCRIPT_DIR}/check.sh" ]; then
    ok "check.sh exists and is executable"
else
    fail "check.sh is not executable"
fi

# ------------------------------------------------
# OS
# ------------------------------------------------

section "OS"

DISTRO="unknown"
IS_WSL="no"

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release

    DISTRO="${ID:-unknown}"

    case "$DISTRO" in
        kali|ubuntu)
            ok "Distribution: ${PRETTY_NAME:-$DISTRO}"
            ;;
        *)
            fail "Unsupported distribution: ${DISTRO}"
            ;;
    esac
else
    fail "/etc/os-release is not readable"
fi

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    IS_WSL="yes"
    ok "Environment: WSL"
else
    ok "Environment: native Linux / VM"
fi

ARCH="$(uname -m 2>/dev/null || printf unknown)"

case "$ARCH" in
    x86_64|aarch64|arm64)
        ok "Architecture: ${ARCH}"
        ;;
    *)
        warn "Unverified architecture: ${ARCH}"
        ;;
esac

# ------------------------------------------------
# Git
# ------------------------------------------------

section "Git"

if command_exists git && [ -d "${REPO_DIR}/.git" ]; then
    GIT_BRANCH="$(
        git -C "$REPO_DIR" branch --show-current 2>/dev/null || true
    )"

    if [ "$GIT_BRANCH" = "main" ]; then
        ok "Branch: main"
    else
        warn "Current branch: ${GIT_BRANCH:-unknown}"
    fi

    GIT_STATUS="$(
        git -C "$REPO_DIR" status --short 2>/dev/null || true
    )"

    if [ -z "$GIT_STATUS" ]; then
        ok "Working tree: clean"
    else
        warn "Working tree has uncommitted changes"
        printf '%s\n' "$GIT_STATUS" |
            sed 's/^/       /'
    fi

    UPSTREAM="$(
        git -C "$REPO_DIR" \
            rev-parse \
            --abbrev-ref \
            --symbolic-full-name \
            '@{upstream}' \
            2>/dev/null || true
    )"

    if [ "$UPSTREAM" = "origin/main" ]; then
        ok "Upstream: origin/main"
    elif [ -n "$UPSTREAM" ]; then
        warn "Upstream: ${UPSTREAM}"
    else
        warn "No upstream configured"
    fi
else
    fail "Git command/repository unavailable"
fi

# ------------------------------------------------
# Core commands
# ------------------------------------------------

section "Commands"

check_command bash
check_command zsh
check_command tmux
check_command git
check_command curl
check_command fzf
check_command zoxide
check_command rg
check_command lazygit
check_command tree-sitter

check_any_command "bat" bat batcat
check_any_command "fd" fd fdfind

# ------------------------------------------------
# Versions
# ------------------------------------------------

section "Pinned versions"

if [ -x /usr/local/bin/nvim ]; then
    NVIM_VERSION="$(
        /usr/local/bin/nvim --version 2>/dev/null |
        sed -n '1s/^NVIM v//p'
    )"

    if [ "$NVIM_VERSION" = "$EXPECTED_NEOVIM_VERSION" ]; then
        ok "Neovim ${NVIM_VERSION}"
    else
        fail "Neovim ${NVIM_VERSION:-unknown}; expected ${EXPECTED_NEOVIM_VERSION}"
    fi
else
    fail "/usr/local/bin/nvim missing"
fi

if command_exists starship; then
    STARSHIP_PATH="$(command -v starship)"

    STARSHIP_VERSION="$(
        "$STARSHIP_PATH" --version 2>/dev/null |
        sed -n '1s/^starship //p'
    )"

    if [ "$STARSHIP_VERSION" = "$EXPECTED_STARSHIP_VERSION" ]; then
        ok "Starship ${STARSHIP_VERSION}: ${STARSHIP_PATH}"
    else
        fail "Starship ${STARSHIP_VERSION:-unknown}; expected ${EXPECTED_STARSHIP_VERSION}"
    fi
else
    fail "Starship command missing"
fi

if command_exists tmux; then
    ok "$(tmux -V 2>/dev/null)"
fi

# ------------------------------------------------
# User symlinks
# ------------------------------------------------

section "Symlinks"

check_symlink \
    "${SCRIPT_DIR}/shell/zsh/.zshrc" \
    "${HOME}/.zshrc"

check_symlink \
    "${SCRIPT_DIR}/shell/bash/bashrc" \
    "${HOME}/.bashrc"

check_symlink \
    "${SCRIPT_DIR}/tmux/.tmux.conf" \
    "${HOME}/.tmux.conf"

check_symlink \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local" \
    "${HOME}/.tmux.conf.local"

check_symlink \
    "${SCRIPT_DIR}/nvim" \
    "${HOME}/.config/nvim-v1"

check_symlink \
    "${SCRIPT_DIR}/starship/starship.toml" \
    "${HOME}/.config/starship.toml"

check_symlink \
    "${SCRIPT_DIR}/tmux/bin/copy-to-clipboard" \
    "${HOME}/.local/bin/copy-to-clipboard"

# ------------------------------------------------
# PATH and shell
# ------------------------------------------------

section "Shell and PATH"

LOGIN_SHELL="$(
    getent passwd "$(id -un)" 2>/dev/null |
    awk -F: '{print $7}'
)"

case "$LOGIN_SHELL" in
    /usr/bin/zsh|/bin/zsh)
        ok "Login shell: ${LOGIN_SHELL}"
        ;;
    *)
        warn "Login shell: ${LOGIN_SHELL:-unknown}"
        ;;
esac

if path_contains "${HOME}/.local/bin"; then
    ok "PATH contains ${HOME}/.local/bin"
else
    fail "PATH missing ${HOME}/.local/bin"
fi

if [ -d "${HOME}/.dotnet/tools" ]; then
    if path_contains "${HOME}/.dotnet/tools"; then
        ok "PATH contains ${HOME}/.dotnet/tools"
    else
        warn "PATH missing ${HOME}/.dotnet/tools"
    fi
fi

if grep -Fq \
    '$HOME/.config/dotfiles/local.sh' \
    "${SCRIPT_DIR}/shell/common.sh" 2>/dev/null; then
    ok "common.sh has machine-local hook"
else
    fail "machine-local hook missing from common.sh"
fi

# ------------------------------------------------
# Machine-local / secrets
# ------------------------------------------------

section "Machine-local configuration"

if [ -d "${HOME}/.config/dotfiles" ]; then
    ok "${HOME}/.config/dotfiles exists"
else
    warn "${HOME}/.config/dotfiles missing"
fi

if [ -d "${HOME}/.config/secrets" ]; then
    ok "${HOME}/.config/secrets exists"
else
    warn "${HOME}/.config/secrets missing"
fi

if [ -f "${HOME}/.config/dotfiles/local.sh" ]; then
    if [ -r "${HOME}/.config/dotfiles/local.sh" ]; then
        ok "local.sh exists and is readable"
    else
        fail "local.sh exists but is not readable"
    fi
else
    ok "local.sh not configured (optional)"
fi

if [ "$DISTRO" = "kali" ]; then
    if [ "${MALWAREBAZAAR_AUTH_KEY+x}" = "x" ] &&
       [ -n "${MALWAREBAZAAR_AUTH_KEY:-}" ]; then
        ok "MalwareBazaar key: set"
    else
        warn "MalwareBazaar key: unset in current environment"
    fi
fi

# ------------------------------------------------
# tmux
# ------------------------------------------------

section "tmux"

if command_exists infocmp; then
    if infocmp tmux-256color >/dev/null 2>&1; then
        ok "tmux-256color terminfo exists"
    else
        fail "tmux-256color terminfo missing"
    fi
else
    warn "infocmp command unavailable"
fi

if grep -Eq \
    '^[[:space:]]*set[[:space:]]+-g[[:space:]]+prefix[[:space:]]+C-a([[:space:]]|$)' \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local"; then
    ok "tmux prefix: C-a"
else
    fail "tmux prefix C-a not found"
fi

if grep -Eq \
    '^[[:space:]]*set[[:space:]]+-g[[:space:]]+default-terminal[[:space:]]+"?tmux-256color"?([[:space:]]|$)' \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local"; then
    ok "tmux default-terminal: tmux-256color"
else
    fail "tmux default-terminal tmux-256color not found"
fi

if [ -f "${SCRIPT_DIR}/tmux/vendor/nord-tmux/nord.tmux" ]; then
    ok "Vendored Nord tmux theme exists"
else
    fail "Vendored Nord tmux theme missing"
fi

if grep -Fq \
    'vendor/nord-tmux/nord.tmux' \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local"; then
    ok "tmux loads vendored Nord theme"
else
    fail "Nord tmux loader missing"
fi

if grep -Fq \
    '@nord_tmux_show_status_content' \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local"; then
    ok "Nord tmux status configuration found"
else
    warn "Nord tmux status option not found"
fi

if [ -x "${SCRIPT_DIR}/tmux/bin/copy-to-clipboard" ]; then
    ok "Clipboard wrapper is executable"
else
    fail "Clipboard wrapper is not executable"
fi

if grep -Fq \
    'copy-to-clipboard' \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local"; then
    ok "tmux copy-mode uses clipboard wrapper"
else
    fail "tmux clipboard wrapper binding not found"
fi

# ------------------------------------------------
# Clipboard backend
# ------------------------------------------------

section "Clipboard"

if [ "$IS_WSL" = "yes" ]; then
    if [ -x /mnt/c/WINDOWS/System32/clip.exe ]; then
        ok "Clipboard backend: clip.exe"
    else
        fail "WSL detected but clip.exe missing"
    fi
elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    if command_exists wl-copy; then
        ok "Clipboard backend: wl-copy"
    else
        fail "Wayland detected but wl-copy missing"
    fi
else
    if command_exists xclip; then
        ok "Clipboard backend: xclip"
    elif command_exists xsel; then
        ok "Clipboard backend: xsel"
    else
        fail "No supported X11 clipboard backend"
    fi
fi

# ------------------------------------------------
# Neovim
# ------------------------------------------------

section "Neovim v1"

NVIM_CONFIG_FILES=(
    init.lua
    lazyvim.json
    lazy-lock.json
    stylua.toml
    lua/config/lazy.lua
    lua/config/options.lua
    lua/config/keymaps.lua
    lua/config/autocmds.lua
    lua/plugins/colorscheme.lua
)

for config_file in "${NVIM_CONFIG_FILES[@]}"; do
    if [ -f "${SCRIPT_DIR}/nvim/${config_file}" ]; then
        ok "Neovim config: ${config_file}"
    else
        fail "Neovim config missing: ${config_file}"
    fi
done

if grep -Eq \
    'require[[:space:]]*\([[:space:]]*"config\.lazy"[[:space:]]*\)' \
    "${SCRIPT_DIR}/nvim/init.lua"; then
    ok "init.lua loads config.lazy"
else
    fail "init.lua does not load config.lazy"
fi

if grep -Fq 'LazyVim/LazyVim' "${SCRIPT_DIR}/nvim/lua/config/lazy.lua" &&
   grep -Eq 'import[[:space:]]*=[[:space:]]*"lazyvim\.plugins"' \
       "${SCRIPT_DIR}/nvim/lua/config/lazy.lua" &&
   grep -Eq 'import[[:space:]]*=[[:space:]]*"plugins"' \
       "${SCRIPT_DIR}/nvim/lua/config/lazy.lua"; then
    ok "LazyVim starter plugin imports found"
else
    fail "LazyVim starter plugin imports incomplete"
fi

if grep -Fq \
    'lazyvim.plugins.extras.lang.clangd' \
    "${SCRIPT_DIR}/nvim/lazyvim.json"; then
    ok "LazyVim Extra: lang.clangd"
else
    fail "LazyVim lang.clangd Extra missing"
fi

if grep -Eq \
    'lazyvim\.plugins\.extras\.lang\.python|basedpyright|pyright|venv-selector|lazyvim_python_lsp' \
    "${SCRIPT_DIR}/nvim/lazyvim.json" \
    "${SCRIPT_DIR}/nvim/init.lua" \
    "${SCRIPT_DIR}/nvim/lua/config/"*.lua \
    "${SCRIPT_DIR}/nvim/lua/plugins/"*.lua; then
    fail "Python-specific LazyVim configuration found"
else
    ok "Python-specific LazyVim configuration absent"
fi

if grep -Fq 'nordtheme/vim' \
       "${SCRIPT_DIR}/nvim/lua/plugins/colorscheme.lua" &&
   grep -Eq 'colorscheme[[:space:]]*=[[:space:]]*"nord"' \
       "${SCRIPT_DIR}/nvim/lua/plugins/colorscheme.lua"; then
    ok "Neovim Nord plugin and colorscheme configured"
else
    fail "Neovim Nord configuration incomplete"
fi

if [ ! -e "${SCRIPT_DIR}/nvim/nvim-pack-lock.json" ] &&
   [ ! -e "${SCRIPT_DIR}/nvim/KICKSTART_UPSTREAM_COMMIT" ] &&
   [ ! -d "${SCRIPT_DIR}/nvim/lua/kickstart" ]; then
    ok "Old Kickstart metadata and configuration absent"
else
    fail "Old Kickstart metadata or configuration remains"
fi

if grep -RIEq \
    --include='*.lua' \
    --include='*.json' \
    'vim\.pack|packadd' \
    "${SCRIPT_DIR}/nvim"; then
    fail "Old vim.pack configuration found"
else
    ok "Old vim.pack configuration absent"
fi

if [ -d "${SCRIPT_DIR}/nvim/.git" ]; then
    fail "Nested .git found in Neovim configuration"
else
    ok "Nested .git absent from Neovim configuration"
fi

if env NVIM_APPNAME=nvim-v1 /usr/local/bin/nvim --headless \
    '+lua assert(vim.g.colors_name == "nord", "expected nord")' \
    '+lua assert(package.loaded["lazy"], "lazy.nvim not loaded")' \
    '+lua assert(package.loaded["lazyvim.config"], "LazyVim not loaded")' \
    '+qa' >/dev/null 2>&1; then
    ok "LazyVim runtime and Nord colorscheme"
else
    fail "LazyVim runtime or Nord colorscheme validation failed"
fi

MASON_CLANGD="${HOME}/.local/share/nvim-v1/mason/bin/clangd"

if [ -x "$MASON_CLANGD" ]; then
    ok "Mason clangd: ${MASON_CLANGD}"
else
    fail "Mason clangd missing or not executable: ${MASON_CLANGD}"
fi

if command_exists tree-sitter; then
    TREE_SITTER_VERSION="$(
        tree-sitter --version 2>/dev/null |
        head -n 1
    )"

    ok "Tree-sitter CLI: ${TREE_SITTER_VERSION:-installed}"
fi

# ------------------------------------------------
# Optional shell integrations
# ------------------------------------------------

section "Shell integrations"

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    ok "zsh-autosuggestions"
else
    warn "zsh-autosuggestions file not found"
fi

if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    ok "zsh-syntax-highlighting"
else
    warn "zsh-syntax-highlighting file not found"
fi

if grep -Fq \
    'starship init zsh' \
    "${SCRIPT_DIR}/shell/zsh/.zshrc"; then
    ok "Starship enabled in Zsh"
else
    fail "Starship Zsh initialization missing"
fi

if grep -Fq \
    'starship init bash' \
    "${SCRIPT_DIR}/shell/bash/bashrc"; then
    ok "Starship enabled in Bash"
else
    fail "Starship Bash initialization missing"
fi

if grep -Fq \
    'zoxide init zsh' \
    "${SCRIPT_DIR}/shell/zsh/.zshrc"; then
    ok "zoxide enabled in Zsh"
else
    fail "zoxide Zsh initialization missing"
fi

if grep -Fq \
    'zoxide init bash' \
    "${SCRIPT_DIR}/shell/bash/bashrc"; then
    ok "zoxide enabled in Bash"
else
    fail "zoxide Bash initialization missing"
fi

# ------------------------------------------------
# Safety invariants
# ------------------------------------------------

section "Safety invariants"

if [ ! -L "${HOME}/.profile" ]; then
    ok ".profile is not managed by v1 symlink"
else
    warn ".profile is a symlink; verify this was intentional"
fi

if [ ! -L "${HOME}/.zprofile" ]; then
    ok ".zprofile is not managed by v1 symlink"
else
    warn ".zprofile is a symlink; verify this was intentional"
fi

# ------------------------------------------------
# Summary
# ------------------------------------------------

section "Summary"

printf 'PASS : %d\n' "$PASS_COUNT"
printf 'WARN : %d\n' "$WARN_COUNT"
printf 'FAIL : %d\n' "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    printf '\n[RESULT] FAIL\n'
    exit 1
fi

if [ "$WARN_COUNT" -gt 0 ]; then
    printf '\n[RESULT] PASS with warnings\n'
    exit 0
fi

printf '\n[RESULT] PASS\n'
exit 0
