if ! command -v tmux &> /dev/null; then
  echo "Installing tmux..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tmux
  else
    sudo apt install -y tmux
  fi
fi

rm -rf ~/.config/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

rm -rf ~/.config/tmux/plugins/catppuccin
mkdir ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.2 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
curl -fsSL "$DOTFILES_RAW/tmux/.tmux.conf" -o ~/.tmux.conf

tmux source-file ~/.tmux.conf
