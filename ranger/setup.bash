if ! command -v ranger &> /dev/null; then
  echo "Installing ranger..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ranger
  else
    sudo apt install -y ranger
  fi
fi

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p ~/.config/ranger
curl -fsSL "$DOTFILES_RAW/ranger/rc.conf" -o ~/.config/ranger/rc.conf

EDITOR_BLOCK='
if command -v nvim &> /dev/null; then
    export EDITOR=nvim
elif command -v vim &> /dev/null; then
    export EDITOR=vim
elif command -v vi &> /dev/null; then
    export EDITOR=vi
elif command -v nano &> /dev/null; then
    export EDITOR=nano
fi'

for rc in ~/.bashrc ~/.zshrc; do
    if [ -f "$rc" ] && ! grep -q '^if command -v nvim' "$rc"; then
        echo "$EDITOR_BLOCK" >> "$rc"
    fi
done
