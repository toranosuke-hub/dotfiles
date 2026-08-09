#!/usr/bin/env bash

set -euo pipefail

# ================================================================
# dotfiles v1 bootstrap
#
# Supported:
#   - Ubuntu / WSL
#   - Kali Linux
#
# Goals:
#   - reproducible
#   - idempotent
#   - non-destructive
#
# This script intentionally does NOT:
#   - modify ~/.profile or ~/.zprofile
#   - run chsh
#   - touch secrets
#   - scan research directories
#   - execute malware/sample files
#   - run apt autoremove
#   - call the old top-level install.sh
# ================================================================

NEOVIM_VERSION="0.12.4"
STARSHIP_VERSION="1.22.1"

MODE=""

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BACKUP_SUFFIX=".before-v1-${TIMESTAMP}-$$"

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd -P
)"

REPO_DIR="$(
    cd -- "${SCRIPT_DIR}/.."
    pwd -P
)"

log() {
    printf '[INFO] %s\n' "$*"
}

ok() {
    printf '[OK]   %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

die() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'USAGE'
Usage:
  bootstrap.sh --dry-run
  bootstrap.sh --apply
  bootstrap.sh --help

Modes:
  --dry-run   Show what would be changed. Do not modify the system.
  --apply     Apply the bootstrap.
  --help      Show this help.

This script does not modify login shell automatically.
USAGE
}

print_command() {
    printf '         '
    printf '%q ' "$@"
    printf '\n'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            [ -z "$MODE" ] || die "Specify only one mode."
            MODE="dry-run"
            ;;
        --apply)
            [ -z "$MODE" ] || die "Specify only one mode."
            MODE="apply"
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac

    shift
done

if [ -z "$MODE" ]; then
    usage
    exit 2
fi

if [ "$(id -u)" -eq 0 ]; then
    die "Run bootstrap.sh as the normal user, not as root."
fi

# ------------------------------------------------
# Repository validation
# ------------------------------------------------

[ -f "${SCRIPT_DIR}/shell/common.sh" ] ||
    die "Cannot find ${SCRIPT_DIR}/shell/common.sh"

[ -f "${SCRIPT_DIR}/shell/zsh/.zshrc" ] ||
    die "Cannot find Zsh v1 configuration."

[ -f "${SCRIPT_DIR}/shell/bash/bashrc" ] ||
    die "Cannot find Bash v1 configuration."

[ -f "${SCRIPT_DIR}/tmux/.tmux.conf" ] ||
    die "Cannot find tmux v1 configuration."

[ -f "${SCRIPT_DIR}/tmux/.tmux.conf.local" ] ||
    die "Cannot find tmux local v1 configuration."

[ -f "${SCRIPT_DIR}/starship/starship.toml" ] ||
    die "Cannot find Starship v1 configuration."

[ -f "${SCRIPT_DIR}/nvim/init.lua" ] ||
    die "Cannot find Neovim v1 configuration."

[ -f "${SCRIPT_DIR}/tmux/bin/copy-to-clipboard" ] ||
    die "Cannot find clipboard wrapper."

log "Repository: ${REPO_DIR}"
log "v1 root:    ${SCRIPT_DIR}"
log "Mode:       ${MODE}"

# ------------------------------------------------
# OS detection
# ------------------------------------------------

[ -r /etc/os-release ] ||
    die "/etc/os-release is missing."

# shellcheck disable=SC1091
. /etc/os-release

case "${ID:-}" in
    ubuntu)
        DISTRO="ubuntu"
        ;;
    kali)
        DISTRO="kali"
        ;;
    *)
        die "Unsupported distribution: ${ID:-unknown}"
        ;;
esac

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    IS_WSL="yes"
else
    IS_WSL="no"
fi

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)
        NVIM_ARCH="x86_64"
        STARSHIP_ARCH="x86_64"
        ;;
    aarch64|arm64)
        NVIM_ARCH="arm64"
        STARSHIP_ARCH="aarch64"
        ;;
    *)
        die "Unsupported architecture: ${ARCH}"
        ;;
esac

NVIM_DIR="/opt/nvim-linux-${NVIM_ARCH}"
NVIM_BIN="${NVIM_DIR}/bin/nvim"

NVIM_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz"

STARSHIP_ARCHIVE="starship-${STARSHIP_ARCH}-unknown-linux-gnu.tar.gz"
STARSHIP_URL="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/${STARSHIP_ARCHIVE}"
STARSHIP_SHA_URL="${STARSHIP_URL}.sha256"

ok "Distribution: ${DISTRO}"
ok "WSL: ${IS_WSL}"
ok "Architecture: ${ARCH}"

# ------------------------------------------------
# sudo
# ------------------------------------------------

SUDO_VALIDATED="no"

ensure_sudo() {
    if [ "$SUDO_VALIDATED" = "yes" ]; then
        return
    fi

    command -v sudo >/dev/null 2>&1 ||
        die "sudo is required for this operation."

    log "Validating sudo access..."
    sudo -v

    SUDO_VALIDATED="yes"
}

run_as_root() {
    ensure_sudo
    sudo "$@"
}

# ------------------------------------------------
# apt packages
# ------------------------------------------------

APT_PACKAGES=(
    bash
    bash-completion
    zsh
    tmux
    git
    curl
    ca-certificates
    tar
    gzip
    unzip
    build-essential
    fzf
    zoxide
    bat
    ripgrep
    fd-find
    lazygit
    tree-sitter-cli
    zsh-autosuggestions
    zsh-syntax-highlighting
)

if [ "$IS_WSL" = "yes" ]; then
    :
elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    APT_PACKAGES+=(wl-clipboard)
else
    APT_PACKAGES+=(xclip xsel)
fi

MISSING_PACKAGES=()

for pkg in "${APT_PACKAGES[@]}"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null |
        grep -q '^install ok installed$'; then
        :
    else
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ "${#MISSING_PACKAGES[@]}" -eq 0 ]; then
    ok "Required apt packages are installed."
else
    log "Missing apt packages:"
    printf '         %s\n' "${MISSING_PACKAGES[@]}"

    if [ "$MODE" = "dry-run" ]; then
        log "Would run:"
        print_command sudo apt-get update
        print_command sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    else
        run_as_root apt-get update
        run_as_root apt-get install -y "${MISSING_PACKAGES[@]}"
    fi
fi

# ------------------------------------------------
# User directories
# ------------------------------------------------

USER_DIRS=(
    "${HOME}/.config"
    "${HOME}/.config/dotfiles"
    "${HOME}/.config/secrets"
    "${HOME}/.local"
    "${HOME}/.local/bin"
    "${HOME}/.cache"
)

for target_dir in "${USER_DIRS[@]}"; do
    if [ -d "$target_dir" ]; then
        ok "Directory exists: ${target_dir}"
    elif [ "$MODE" = "dry-run" ]; then
        log "Would create directory: ${target_dir}"
    else
        mkdir -p -- "$target_dir"
        ok "Created directory: ${target_dir}"
    fi
done

# ------------------------------------------------
# User symlinks
# ------------------------------------------------

ensure_user_symlink() {
    local source_path="$1"
    local target_path="$2"
    local current_target=""

    if [ -L "$target_path" ]; then
        current_target="$(readlink "$target_path")"

        if [ "$current_target" = "$source_path" ]; then
            ok "Symlink: ${target_path}"
            return
        fi
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        local backup_path="${target_path}${BACKUP_SUFFIX}"

        if [ "$MODE" = "dry-run" ]; then
            log "Would backup:"
            printf '         %s\n' "$target_path"
            printf '      -> %s\n' "$backup_path"
        else
            mv -- "$target_path" "$backup_path"
            ok "Backup: ${backup_path}"
        fi
    fi

    if [ "$MODE" = "dry-run" ]; then
        log "Would create symlink:"
        printf '         %s -> %s\n' "$target_path" "$source_path"
    else
        ln -s -- "$source_path" "$target_path"
        ok "Symlink: ${target_path} -> ${source_path}"
    fi
}

ensure_user_symlink \
    "${SCRIPT_DIR}/shell/zsh/.zshrc" \
    "${HOME}/.zshrc"

ensure_user_symlink \
    "${SCRIPT_DIR}/shell/bash/bashrc" \
    "${HOME}/.bashrc"

ensure_user_symlink \
    "${SCRIPT_DIR}/tmux/.tmux.conf" \
    "${HOME}/.tmux.conf"

ensure_user_symlink \
    "${SCRIPT_DIR}/tmux/.tmux.conf.local" \
    "${HOME}/.tmux.conf.local"

ensure_user_symlink \
    "${SCRIPT_DIR}/nvim" \
    "${HOME}/.config/nvim-v1"

ensure_user_symlink \
    "${SCRIPT_DIR}/starship/starship.toml" \
    "${HOME}/.config/starship.toml"

ensure_user_symlink \
    "${SCRIPT_DIR}/tmux/bin/copy-to-clipboard" \
    "${HOME}/.local/bin/copy-to-clipboard"

# ------------------------------------------------
# Root-owned path backup helper
# ------------------------------------------------

backup_root_target() {
    local target_path="$1"
    local backup_path="${target_path}${BACKUP_SUFFIX}"

    if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
        return
    fi

    if [ "$MODE" = "dry-run" ]; then
        log "Would backup root-owned target:"
        printf '         %s\n' "$target_path"
        printf '      -> %s\n' "$backup_path"
    else
        run_as_root mv -- "$target_path" "$backup_path"
        ok "Backup: ${backup_path}"
    fi
}

# ------------------------------------------------
# Neovim
# ------------------------------------------------

install_neovim() {
    local installed_version=""

    if [ -x "$NVIM_BIN" ]; then
        installed_version="$(
            "$NVIM_BIN" --version 2>/dev/null |
                sed -n '1s/^NVIM v//p'
        )"
    fi

    if [ "$installed_version" = "$NEOVIM_VERSION" ]; then
        ok "Neovim ${NEOVIM_VERSION}: ${NVIM_BIN}"
    elif [ "$MODE" = "dry-run" ]; then
        log "Would install Neovim ${NEOVIM_VERSION}"
        printf '         %s\n' "$NVIM_URL"
        printf '         target: %s\n' "$NVIM_DIR"
    else
        local temp_dir=""
        local archive=""
        local extracted=""

        temp_dir="$(mktemp -d)"
        archive="${temp_dir}/nvim.tar.gz"
        extracted="${temp_dir}/nvim-linux-${NVIM_ARCH}"

        log "Downloading Neovim ${NEOVIM_VERSION}..."

        curl \
            --fail \
            --location \
            --retry 3 \
            --output "$archive" \
            "$NVIM_URL"

        tar -xzf "$archive" -C "$temp_dir"

        [ -x "${extracted}/bin/nvim" ] ||
            die "Downloaded Neovim archive is invalid."

        local downloaded_version=""

        downloaded_version="$(
            "${extracted}/bin/nvim" --version |
                sed -n '1s/^NVIM v//p'
        )"

        [ "$downloaded_version" = "$NEOVIM_VERSION" ] ||
            die "Unexpected Neovim version: ${downloaded_version}"

        backup_root_target "$NVIM_DIR"

        run_as_root mv -- "$extracted" "$NVIM_DIR"
        run_as_root chown -R root:root "$NVIM_DIR"

        rm -rf -- "$temp_dir"

        ok "Installed Neovim ${NEOVIM_VERSION}"
    fi

    if [ -L /usr/local/bin/nvim ] &&
       [ "$(readlink /usr/local/bin/nvim)" = "$NVIM_BIN" ]; then
        ok "Neovim symlink: /usr/local/bin/nvim"
    else
        backup_root_target /usr/local/bin/nvim

        if [ "$MODE" = "dry-run" ]; then
            log "Would create:"
            printf '         /usr/local/bin/nvim -> %s\n' "$NVIM_BIN"
        else
            run_as_root ln -s -- "$NVIM_BIN" /usr/local/bin/nvim
            ok "Neovim symlink: /usr/local/bin/nvim -> ${NVIM_BIN}"
        fi
    fi
}

install_neovim

# ------------------------------------------------
# Starship
# ------------------------------------------------

install_starship() {
    local installed_path=""
    local installed_version=""

    if command -v starship >/dev/null 2>&1; then
        installed_path="$(command -v starship)"

        installed_version="$(
            "$installed_path" --version 2>/dev/null |
                sed -n '1s/^starship //p'
        )"
    fi

    if [ "$installed_version" = "$STARSHIP_VERSION" ]; then
        ok "Starship ${STARSHIP_VERSION}: ${installed_path}"
        return
    fi

    if [ "$MODE" = "dry-run" ]; then
        log "Would install Starship ${STARSHIP_VERSION}"
        printf '         %s\n' "$STARSHIP_URL"
        return
    fi

    local temp_dir=""
    local archive=""
    local sha_file=""
    local expected_sha=""
    local actual_sha=""

    temp_dir="$(mktemp -d)"
    archive="${temp_dir}/${STARSHIP_ARCHIVE}"
    sha_file="${archive}.sha256"

    log "Downloading Starship ${STARSHIP_VERSION}..."

    curl \
        --fail \
        --location \
        --retry 3 \
        --output "$archive" \
        "$STARSHIP_URL"

    curl \
        --fail \
        --location \
        --retry 3 \
        --output "$sha_file" \
        "$STARSHIP_SHA_URL"

    expected_sha="$(
        tr -d '[:space:]' < "$sha_file"
    )"

    actual_sha="$(
        sha256sum "$archive" |
            awk '{print $1}'
    )"

    [ -n "$expected_sha" ] ||
        die "Starship checksum file is empty."

    [ "$actual_sha" = "$expected_sha" ] ||
        die "Starship SHA-256 verification failed."

    tar -xzf "$archive" -C "$temp_dir"

    [ -x "${temp_dir}/starship" ] ||
        die "Downloaded Starship archive is invalid."

    local downloaded_version=""

    downloaded_version="$(
        "${temp_dir}/starship" --version |
            sed -n '1s/^starship //p'
    )"

    [ "$downloaded_version" = "$STARSHIP_VERSION" ] ||
        die "Unexpected Starship version: ${downloaded_version}"

    backup_root_target /usr/local/bin/starship

    run_as_root install \
        -m 0755 \
        "${temp_dir}/starship" \
        /usr/local/bin/starship

    rm -rf -- "$temp_dir"

    ok "Installed Starship ${STARSHIP_VERSION}"
}

install_starship

# ------------------------------------------------
# Clipboard backend
# ------------------------------------------------

if [ "$IS_WSL" = "yes" ]; then
    if [ -x /mnt/c/WINDOWS/System32/clip.exe ]; then
        ok "Clipboard backend: WSL clip.exe"
    else
        warn "WSL detected but clip.exe was not found."
    fi
elif [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    if command -v wl-copy >/dev/null 2>&1; then
        ok "Clipboard backend: wl-copy"
    else
        warn "Wayland detected but wl-copy is unavailable."
    fi
else
    if command -v xclip >/dev/null 2>&1; then
        ok "Clipboard backend: xclip"
    elif command -v xsel >/dev/null 2>&1; then
        ok "Clipboard backend: xsel"
    else
        warn "No supported Linux clipboard backend found."
    fi
fi

# ------------------------------------------------
# Login shell
# ------------------------------------------------

CURRENT_LOGIN_SHELL="$(
    getent passwd "$(id -un)" |
        awk -F: '{print $7}'
)"

if [ "$CURRENT_LOGIN_SHELL" = "/usr/bin/zsh" ] ||
   [ "$CURRENT_LOGIN_SHELL" = "/bin/zsh" ]; then
    ok "Login shell: ${CURRENT_LOGIN_SHELL}"
else
    warn "Login shell is ${CURRENT_LOGIN_SHELL:-unknown}"
    warn "bootstrap.sh does not run chsh automatically."
fi

# ------------------------------------------------
# Neovim plugin bootstrap
# ------------------------------------------------

if [ "$MODE" = "dry-run" ]; then
    log "Would initialize Neovim v1:"
    printf '         NVIM_APPNAME=nvim-v1 /usr/local/bin/nvim --headless +qa\n'
else
    log "Initializing Neovim v1..."

    env \
        NVIM_APPNAME=nvim-v1 \
        /usr/local/bin/nvim \
        --headless \
        '+qa'

    ok "Neovim v1 headless initialization completed."
fi

# ------------------------------------------------
# Final notes
# ------------------------------------------------

printf '\n'

ok "bootstrap.sh completed in ${MODE} mode."

log "No changes were made to:"
printf '         %s\n' \
    "${HOME}/.profile" \
    "${HOME}/.zprofile"

log "Secrets were not read, copied, or modified."

if [ "$MODE" = "apply" ]; then
    log "Run v1/check.sh after bootstrap validation is implemented."
fi
