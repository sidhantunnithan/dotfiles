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

log_section "Installing Lazygit"
if ! command -v lazygit &> /dev/null; then
  echo -e "${YELLOW}Lazygit not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install lazygit
    log_success "Lazygit installed via Homebrew"
  else
    sudo apt install lazygit
    log_success "Lazygit installed via apt"
  fi
else
  log_success "Lazygit already installed"
fi

log_section "Configuring Lazygit"
if [[ "$(uname)" == "Darwin" ]]; then
  CONFIG_DIR=~/Library/Application\ Support/lazygit
else
  CONFIG_DIR=~/.config/lazygit
fi

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p "$CONFIG_DIR"
curl -fsSL "$DOTFILES_RAW/lazygit/config.yml" -o "$CONFIG_DIR/config.yml"
log_success "Lazygit configuration file downloaded"

log_section "Setting up Zsh alias"
echo "alias lzg=lazygit" >> ~/.zshrc
log_success "Zsh alias added"
