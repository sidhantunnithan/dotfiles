#!/bin/bash
set -euo pipefail

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

log_warn() {
  echo -e "${YELLOW}! $1${NC}"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

install_ya_pkg() {
  local pkg="$1"
  local out
  if out="$(ya pkg add "$pkg" 2>&1)"; then
    return 0
  fi

  if echo "$out" | grep -q "already exists in package.toml"; then
    return 0
  fi

  echo "$out" >&2
  return 1
}

log_section "Installing Yazi and dependencies"
if [[ "$(uname)" == "Darwin" ]]; then
  for pkg in yazi mediainfo git; do
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
  if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}git not found, installing...${NC}"
    sudo apt install -y git
    log_success "git installed via apt"
  else
    log_success "git already installed"
  fi
fi

log_section "Configuring Yazi"
YAZI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
mkdir -p "$YAZI_CONFIG_DIR/plugins" "$YAZI_CONFIG_DIR/flavors"
REPO_BASE="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/yazi"

for file in yazi.toml keymap.toml theme.toml package.toml init.lua; do
  curl -fsSL "$REPO_BASE/$file" -o "$YAZI_CONFIG_DIR/$file"
  log_success "Downloaded $file"
done

for plugin in smart-enter mediainfo; do
  mkdir -p "$YAZI_CONFIG_DIR/plugins/$plugin.yazi"
  curl -fsSL "$REPO_BASE/plugins/$plugin.yazi/main.lua" -o "$YAZI_CONFIG_DIR/plugins/$plugin.yazi/main.lua"
  log_success "Downloaded local plugin: $plugin"
done
log_success "Yazi config files installed"

log_section "Resetting managed Yazi assets"
rm -rf \
  "$YAZI_CONFIG_DIR/plugins/bookmarks.yazi" \
  "$YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi"
log_success "Cleared managed plugin/flavor directories"

log_section "Installing Yazi plugins"
require_cmd ya
install_ya_pkg dedukun/bookmarks
log_success "Installed plugin: dedukun/bookmarks"

log_section "Installing Yazi flavor"
install_ya_pkg yazi-rs/flavors:catppuccin-mocha
log_success "Installed flavor: catppuccin-mocha"

log_section "Syncing Yazi packages"
ya pkg install
log_success "Yazi packages synced"

if [ ! -f "$YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi/flavor.toml" ]; then
  log_warn "Flavor file still missing after install: $YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi/flavor.toml"
  exit 1
fi

if [ ! -f "$YAZI_CONFIG_DIR/plugins/bookmarks.yazi/main.lua" ]; then
  log_warn "Plugin file still missing after install: $YAZI_CONFIG_DIR/plugins/bookmarks.yazi/main.lua"
  exit 1
fi

log_section "Setting up f() yazi wrapper"
if [[ "$(uname)" == "Darwin" ]]; then
  RC_FILES=(~/.zshrc)
else
  RC_FILES=(~/.bashrc)
fi

for rc in "${RC_FILES[@]}"; do
  if [ -f "$rc" ]; then
    if grep -q "^function f()" "$rc"; then
      tmp_rc="$(mktemp)"
      awk '
        BEGIN { in_f = 0 }
        /^function f\(\) \{$/ { in_f = 1; next }
        in_f == 1 && /^\}$/ { in_f = 0; next }
        in_f == 0 { print }
      ' "$rc" > "$tmp_rc"
      mv "$tmp_rc" "$rc"
      log_success "Updated existing f() function in $rc"
    fi

    cat >> "$rc" << 'EOF'

function f() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    local yazi_term="$TERM"
    if [[ -n "$TMUX" || "$TERM" == tmux* || "$TERM" == screen* ]]; then
      yazi_term="xterm-256color"
    fi
    command env TERM="$yazi_term" yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
EOF
    log_success "f() function set in $rc"
  else
    log_success "$rc not found, skipping"
  fi
done
