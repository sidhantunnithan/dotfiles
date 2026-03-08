if ! command -v brew &> /dev/null; then
  read -p "Homebrew is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

brew bundle --file=$PWD/brew/Brewfile
