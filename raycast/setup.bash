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

log_section "Installing Raycast"
if ! command -v raycast &> /dev/null && [[ "$(uname)" == "Darwin" ]]; then
  echo -e "${YELLOW}Raycast not found, installing...${NC}"
  brew install --cask raycast
  log_success "Raycast installed"
elif [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${YELLOW}Raycast is macOS only${NC}"
else
  log_success "Raycast already installed"
fi

log_section "Manual Raycast configuration"
echo -e "${YELLOW}To complete setup:${NC}"
echo "1. Open Raycast > Settings > Advanced > Import"
echo "2. Download config from: https://github.com/sidhantunnithan/dotfiles/tree/main/raycast"
