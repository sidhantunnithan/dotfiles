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

log_section "Installing Lazydocker"
if ! command -v lazydocker &> /dev/null; then
  echo -e "${YELLOW}Lazydocker not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install lazydocker
    log_success "Lazydocker installed via Homebrew"
  else
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    log_success "Lazydocker installed via install script"
  fi
else
  log_success "Lazydocker already installed"
fi

log_section "Configuring Lazydocker"
CONFIG_DIR=~/.config/lazydocker

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p "$CONFIG_DIR"
curl -fsSL "$DOTFILES_RAW/lazydocker/config.yml" -o "$CONFIG_DIR/config.yml"
log_success "Lazydocker configuration file downloaded"

log_section "Setting up Zsh alias"
echo "alias lzd=lazydocker" >> ~/.zshrc
log_success "Zsh alias added"
