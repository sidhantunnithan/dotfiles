if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
BREWFILE_TMP=$(mktemp)
curl -fsSL "$DOTFILES_RAW/brew/Brewfile" -o "$BREWFILE_TMP"
brew bundle --file="$BREWFILE_TMP"
rm -f "$BREWFILE_TMP"
