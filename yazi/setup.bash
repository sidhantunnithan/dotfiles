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

log_section "Installing Yazi and dependencies"
if [[ "$(uname)" == "Darwin" ]]; then
  for pkg in yazi mediainfo; do
    if ! command -v "$pkg" &> /dev/null; then
      echo -e "${YELLOW}$pkg not found, installing...${NC}"
      brew install "$pkg"
      log_success "$pkg installed via Homebrew"
    else
      log_success "$pkg already installed"
    fi
  done
else
  if ! command -v yazi &> /dev/null; then
    echo -e "${YELLOW}Yazi not found, installing...${NC}"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
      YAZI_ARCH="aarch64"
    else
      YAZI_ARCH="x86_64"
    fi
    YAZI_DEB="/tmp/yazi-${YAZI_ARCH}-unknown-linux-gnu.deb"
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/v26.1.22/yazi-${YAZI_ARCH}-unknown-linux-gnu.deb" -o "$YAZI_DEB"
    sudo apt install -y "$YAZI_DEB"
    rm -f "$YAZI_DEB"
    log_success "Yazi installed via .deb package"
  else
    log_success "Yazi already installed"
  fi
  if ! command -v mediainfo &> /dev/null; then
    echo -e "${YELLOW}mediainfo not found, installing...${NC}"
    sudo apt install -y mediainfo
    log_success "mediainfo installed via apt"
  else
    log_success "mediainfo already installed"
  fi
fi

log_section "Configuring Yazi"
YAZI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
mkdir -p "$YAZI_CONFIG_DIR/plugins"
REPO_BASE="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/yazi"

for file in yazi.toml keymap.toml theme.toml package.toml init.lua; do
  curl -fsSL "$REPO_BASE/$file" -o "$YAZI_CONFIG_DIR/$file"
  log_success "Downloaded $file"
done
log_success "Yazi config files installed"

log_section "Installing Yazi plugins"
if ! command -v ya &> /dev/null; then
  echo -e "${YELLOW}ya CLI not found, skipping plugin install${NC}"
else
  ya pkg add dedukun/bookmarks
  log_success "Yazi plugins installed"
fi

log_section "Setting up f() yazi wrapper"
for rc in ~/.zshrc ~/.bashrc; do
  if [ -f "$rc" ] && ! grep -q "^function f()" "$rc"; then
    cat >> "$rc" << 'EOF'

function f() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
EOF
    log_success "f() function added to $rc"
  else
    log_success "f() already exists in $rc, skipping"
  fi
done
