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

log_section "Installing Homebrew"
if ! command -v brew &> /dev/null; then
  echo -e "${YELLOW}Homebrew not found, installing...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log_success "Homebrew installed"
else
  log_success "Homebrew already installed"
fi

log_section "Installing packages from Brewfile"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
BREWFILE_TMP=$(mktemp)
curl -fsSL "$DOTFILES_RAW/brew/Brewfile" -o "$BREWFILE_TMP"
brew bundle --file="$BREWFILE_TMP"
log_success "Brewfile packages installed"
rm -f "$BREWFILE_TMP"
