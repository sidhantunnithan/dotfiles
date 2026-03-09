if ! command -v nvim &> /dev/null; then
  echo "Installing neovim..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install neovim
  else
    sudo apt install -y neovim
  fi
fi

DOTFILES_REPO="https://github.com/sidhantunnithan/dotfiles.git"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"

rm -rf ~/.config/nvim
TMPDIR=$(mktemp -d)
git clone --depth 1 "$DOTFILES_REPO" "$TMPDIR"
cp -r "$TMPDIR/nvim" ~/.config/nvim
rm -rf "$TMPDIR"

curl -fsSL "$DOTFILES_RAW/nvim/.prettierrc" -o ~/.prettierrc

if ! command -v rg &> /dev/null; then
  echo "Installing ripgrep..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ripgrep
  else
    sudo apt install -y ripgrep
  fi
fi

if ! command -v tree-sitter &> /dev/null; then
  echo "Installing tree-sitter-cli..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tree-sitter-cli
  else
    sudo apt install -y tree-sitter-cli
  fi
fi
