if ! command -v alacritty &> /dev/null; then
  echo "Installing alacritty..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install --cask alacritty
  else
    echo "Please install alacritty manually: https://alacritty.org"
  fi
fi

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
curl -fsSL "$DOTFILES_RAW/alacritty/.alacritty.toml" -o ~/.alacritty.toml

mkdir -p ~/.config/alacritty
curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
