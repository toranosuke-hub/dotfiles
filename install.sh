#!/usr/bin/env bash

set -Eeuo pipefail

DOT_DIRECTORY="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)"

DOTFILES=(
  ".bashrc"
  ".zshrc"
  ".vimrc"
  ".tmux.conf"
  ".config/nvim/init.vim"
)

echo "[INFO] dotfiles directory: $DOT_DIRECTORY"

for file in "${DOTFILES[@]}"; do
  source_path="$DOT_DIRECTORY/$file"
  target_path="$HOME/$file"

  if [[ ! -e "$source_path" ]]; then
    echo "[SKIP] Source not found: $source_path"
    continue
  fi

  mkdir -p "$(dirname -- "$target_path")"
  ln -sfn "$source_path" "$target_path"
  echo "[LINK] $target_path -> $source_path"
done

# TPM
if command -v git >/dev/null 2>&1; then
  if [[ ! -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
    echo "[INSTALL] TPM"
    mkdir -p "$HOME/.tmux/plugins"
    git clone \
      https://github.com/tmux-plugins/tpm \
      "$HOME/.tmux/plugins/tpm"
  else
    echo "[OK] TPM already installed"
  fi
else
  echo "[WARN] git is not installed; TPM was not installed"
fi

# tmux plugins
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]] &&
   command -v tmux >/dev/null 2>&1; then
  echo "[INSTALL] tmux plugins"
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
fi

# vim-plug
if command -v curl >/dev/null 2>&1; then
  if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    echo "[INSTALL] vim-plug"
    curl -fLo "$HOME/.vim/autoload/plug.vim" \
      --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    echo "[OK] vim-plug already installed"
  fi
else
  echo "[WARN] curl is not installed; vim-plug was not installed"
fi

echo
echo "[DONE] Dotfiles setup completed"
echo
echo "Restart or reload:"
echo "  zsh:  exec zsh"
echo "  tmux: tmux source-file ~/.tmux.conf"
echo "  vim:  vim +PlugInstall +qall"
