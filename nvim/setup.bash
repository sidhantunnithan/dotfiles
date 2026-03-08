rm -rf ~/.config/nvim
ln -s $PWD/nvim ~/.config/nvim

if ! command -v tree-sitter &> /dev/null; then
  read -p "tree-sitter CLI is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install tree-sitter-cli
    else
      sudo apt install -y tree-sitter-cli
    fi
  fi
fi
