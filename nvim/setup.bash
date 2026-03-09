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

log_section "Installing Neovim"
if ! command -v nvim &> /dev/null; then
  echo -e "${YELLOW}Neovim not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install neovim
  else
    sudo apt install -y neovim
  fi
  log_success "Neovim installed"
else
  log_success "Neovim already installed"
fi

log_section "Configuring Neovim"
DOTFILES_REPO="https://github.com/sidhantunnithan/dotfiles.git"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"

rm -rf ~/.config/nvim
TMPDIR=$(mktemp -d)
git clone --depth 1 "$DOTFILES_REPO" "$TMPDIR"
cp -r "$TMPDIR/nvim" ~/.config/nvim
rm -rf "$TMPDIR"
log_success "Neovim configuration cloned"

curl -fsSL "$DOTFILES_RAW/nvim/.prettierrc" -o ~/.prettierrc
log_success "Prettier config downloaded"

log_section "Installing Neovim dependencies"
if ! command -v rg &> /dev/null; then
  echo -e "${YELLOW}Ripgrep not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ripgrep
  else
    sudo apt install -y ripgrep
  fi
  log_success "Ripgrep installed"
else
  log_success "Ripgrep already installed"
fi

if ! command -v tree-sitter &> /dev/null; then
  echo -e "${YELLOW}Tree-sitter not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tree-sitter-cli
  else
    sudo apt install -y tree-sitter-cli
  fi
  log_success "Tree-sitter installed"
else
  log_success "Tree-sitter already installed"
fi
