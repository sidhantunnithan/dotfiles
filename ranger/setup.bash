if ! command -v ranger &> /dev/null; then
  read -p "ranger is not installed. Install it? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      brew install ranger
    else
      sudo apt install -y ranger
    fi
  fi
fi

mkdir -p ~/.config/ranger
rm -f ~/.config/ranger/rc.conf
ln -s $PWD/ranger/rc.conf ~/.config/ranger/rc.conf

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
