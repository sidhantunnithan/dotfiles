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

log_section "Installing Yazi"
if ! command -v yazi &> /dev/null; then
  echo -e "${YELLOW}Yazi not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install yazi
    log_success "Yazi installed via Homebrew"
  else
    YAZI_DEB="/tmp/yazi-aarch64-unknown-linux-gnu.deb"
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/v26.1.22/yazi-aarch64-unknown-linux-gnu.deb" -o "$YAZI_DEB"
    sudo apt install -y "$YAZI_DEB"
    rm -f "$YAZI_DEB"
    log_success "Yazi installed via .deb package"
  fi
else
  log_success "Yazi already installed"
fi

log_section "Configuring Yazi"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -L ~/.config/yazi ] || [ -d ~/.config/yazi ]; then
  rm -rf ~/.config/yazi
fi
ln -s "$DOTFILES_DIR" ~/.config/yazi
log_success "Yazi config directory symlinked"

log_section "Setting up y() yazi wrapper"
for rc in ~/.zshrc ~/.bashrc; do
  if [ -f "$rc" ] && ! grep -q "^function y()" "$rc"; then
    cat >> "$rc" << 'EOF'

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
EOF
    log_success "y() function added to $rc"
  else
    log_success "y() already exists in $rc, skipping"
  fi
done
