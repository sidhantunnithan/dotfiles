rm -f ~/.alacritty.toml
ln -s $PWD/alacritty/.alacritty.toml ~/.alacritty.toml

mkdir -p ~/.config/alacritty
curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
