if ! command -v tmux &> /dev/null; then
  read -p "tmux is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install tmux
    else
      sudo apt install -y tmux
    fi
  fi
fi

rm -rf ~/.config/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

rm -rf ~/.config/tmux/plugins/catppuccin
mkdir ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.2 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux

rm -f ~/.tmux.conf
ln -s $PWD/tmux/.tmux.conf ~/.tmux.conf
