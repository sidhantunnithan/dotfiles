if ! command -v lazygit &> /dev/null; then
  echo "Installing lazygit..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install lazygit
  else
    echo "Please install lazygit manually: https://github.com/jesseduffield/lazygit#installation"
  fi
fi

if [[ "$(uname)" == "Darwin" ]]; then
  CONFIG_DIR=~/Library/Application\ Support/lazygit
else
  CONFIG_DIR=~/.config/lazygit
fi

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p "$CONFIG_DIR"
curl -fsSL "$DOTFILES_RAW/lazygit/config.yml" -o "$CONFIG_DIR/config.yml"

echo "alias lzg=lazygit" >> ~/.zshrc
