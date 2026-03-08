if ! command -v nvim &> /dev/null; then
  read -p "neovim is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install neovim
    else
      sudo apt install -y neovim
    fi
  fi
fi

rm -rf ~/.config/nvim
ln -s $PWD/nvim ~/.config/nvim

if ! command -v rg &> /dev/null; then
  read -p "ripgrep (rg) is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install ripgrep
    else
      sudo apt install -y ripgrep
    fi
  fi
fi

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
