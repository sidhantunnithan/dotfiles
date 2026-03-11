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
if [[ "$(uname)" == "Darwin" ]]; then
  if ! command -v nvim &> /dev/null; then
    echo -e "${YELLOW}Neovim not found, installing...${NC}"
    brew install neovim
    log_success "Neovim installed"
  else
    log_success "Neovim already installed"
  fi
else
  # Linux: download latest release
  echo -e "${YELLOW}Setting up Neovim from latest release...${NC}"
  ARCH=$(uname -m)
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NVIM_TARBALL="nvim-linux-arm64.tar.gz"
  else
    NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
  fi
  NVIM_DIR="${NVIM_TARBALL%.tar.gz}"
  cd /tmp
  curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TARBALL"
  sudo rm -rf "/opt/$NVIM_DIR"
  sudo tar -C /opt -xzf "$NVIM_TARBALL"
  rm "$NVIM_TARBALL"
  cd -
  log_success "Neovim installed from latest release"

  # Add to PATH in bashrc if not already present
  if ! grep -q "export PATH=.*$NVIM_DIR/bin" ~/.bashrc; then
    echo "export PATH=\"\$PATH:/opt/$NVIM_DIR/bin\"" >> ~/.bashrc
    log_success "Neovim PATH added to ~/.bashrc"
  else
    log_success "Neovim PATH already in ~/.bashrc"
  fi
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
