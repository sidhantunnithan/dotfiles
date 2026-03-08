if [[ "$(uname)" == "Darwin" ]]; then
  CONFIG_DIR=~/Library/Application\ Support/lazygit
else
  CONFIG_DIR=~/.config/lazygit
fi

mkdir -p "$CONFIG_DIR"
rm -f "$CONFIG_DIR/config.yml"
ln -s $PWD/lazygit/config.yml "$CONFIG_DIR/config.yml"

echo "alias lzg=lazygit" >> ~/.zshrc
