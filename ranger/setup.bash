#!/bin/bash
set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_section() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_section "Installing Ranger"
if ! command -v ranger &> /dev/null; then
  echo -e "${YELLOW}Ranger not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ranger
  else
    sudo apt install -y ranger
  fi
  log_success "Ranger installed"
else
  log_success "Ranger already installed"
fi

log_section "Configuring Ranger"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p ~/.config/ranger
curl -fsSL "$DOTFILES_RAW/ranger/rc.conf" -o ~/.config/ranger/rc.conf
log_success "Ranger configuration file downloaded"

log_section "Setting up Editor environment variable"
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
        log_success "Editor configuration added to $rc"
    fi
done
