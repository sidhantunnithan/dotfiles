if ! command -v raycast &> /dev/null && [[ "$(uname)" == "Darwin" ]]; then
  echo "Installing Raycast..."
  brew install --cask raycast
fi

echo "Import Raycast settings manually: open Raycast > Settings > Advanced > Import"
echo "Download config from: https://github.com/sidhantunnithan/dotfiles/tree/main/raycast"
