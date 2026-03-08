if ! command -v raycast &> /dev/null && [[ "$(uname)" == "Darwin" ]]; then
  read -p "Raycast is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    brew install --cask raycast
  fi
fi

echo "Import Raycast settings manually: open Raycast > Settings > Advanced > Import"
echo "Config file: $PWD/raycast/$(ls raycast/*.rayconfig)"
