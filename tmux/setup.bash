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
if command -v tmux &> /dev/null; then
  echo -e "${YELLOW}Tmux already installed, removing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew uninstall tmux
  else
    sudo apt remove -y tmux
  fi
fi
echo -e "${YELLOW}Installing Tmux...${NC}"
if [[ "$(uname)" == "Darwin" ]]; then
  brew install tmux
else
  sudo apt install -y libevent-dev libncurses-dev build-essential bison pkg-config
  TMUX_VERSION="3.6"
  TMUX_TAR="tmux-${TMUX_VERSION}.tar.gz"
  curl -fsSL "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/${TMUX_TAR}" -o "/tmp/${TMUX_TAR}"
  tar -xzf "/tmp/${TMUX_TAR}" -C /tmp
  (cd "/tmp/tmux-${TMUX_VERSION}" && ./configure && make && sudo make install)
  rm -rf "/tmp/${TMUX_TAR}" "/tmp/tmux-${TMUX_VERSION}"
fi
log_success "Tmux installed"

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
mkdir -p ~/.config/tmux
curl -fsSL "$DOTFILES_RAW/tmux/.tmux.conf" -o ~/.config/tmux/tmux.conf
log_success "Tmux configuration file downloaded"

if tmux list-sessions &> /dev/null; then
  tmux source-file ~/.config/tmux/tmux.conf
  log_success "Tmux configuration reloaded"
else
  log_success "Tmux not running — config will apply on next session"
fi
