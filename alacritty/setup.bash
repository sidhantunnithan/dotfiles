if ! command -v alacritty &> /dev/null; then
  read -p "alacritty is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install --cask alacritty
    else
      echo "Please install alacritty manually: https://alacritty.org"
    fi
  fi
fi

rm -f ~/.alacritty.toml
ln -s $PWD/alacritty/.alacritty.toml ~/.alacritty.toml

mkdir -p ~/.config/alacritty
curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
