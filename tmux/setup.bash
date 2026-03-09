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

log_section "Installing Tmux"
if ! command -v tmux &> /dev/null; then
  echo -e "${YELLOW}Tmux not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tmux
  else
    sudo apt install -y tmux
  fi
  log_success "Tmux installed"
else
  log_success "Tmux already installed"
fi

log_section "Installing Tmux Plugin Manager (TPM)"
rm -rf ~/.config/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
log_success "TPM cloned"

log_section "Installing Catppuccin Tmux theme"
rm -rf ~/.config/tmux/plugins/catppuccin
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.2 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
log_success "Catppuccin theme installed"

log_section "Configuring Tmux"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
curl -fsSL "$DOTFILES_RAW/tmux/.tmux.conf" -o ~/.tmux.conf
log_success "Tmux configuration file downloaded"

tmux source-file ~/.tmux.conf
log_success "Tmux configuration reloaded"
