if ! command -v lazygit &> /dev/null; then
  read -p "lazygit is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install lazygit
    else
      echo "Please install lazygit manually: https://github.com/jesseduffield/lazygit#installation"
    fi
  fi
fi

if [[ "$(uname)" == "Darwin" ]]; then
  CONFIG_DIR=~/Library/Application\ Support/lazygit
else
  CONFIG_DIR=~/.config/lazygit
fi

mkdir -p "$CONFIG_DIR"
rm -f "$CONFIG_DIR/config.yml"
ln -s $PWD/lazygit/config.yml "$CONFIG_DIR/config.yml"

echo "alias lzg=lazygit" >> ~/.zshrc
