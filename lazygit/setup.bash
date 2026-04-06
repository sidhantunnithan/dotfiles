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
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
      LAZYGIT_ARCH="arm64"
    else
      LAZYGIT_ARCH="x86_64"
    fi
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
    sudo tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit
    rm /tmp/lazygit.tar.gz
    log_success "Lazygit installed from GitHub release"
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

log_section "Setting up shell alias"
for rc in ~/.zshrc ~/.bashrc; do
  if [ -f "$rc" ]; then
    if grep -q '^alias lzg=lazygit$' "$rc"; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/^alias lzg=lazygit$/alias lg=lazygit/' "$rc"
      else
        sed -i 's/^alias lzg=lazygit$/alias lg=lazygit/' "$rc"
      fi
      log_success "Alias updated in $rc"
    elif ! grep -q '^alias lg=lazygit$' "$rc"; then
      echo "alias lg=lazygit" >> "$rc"
      log_success "Alias added to $rc"
    fi
  fi
done
