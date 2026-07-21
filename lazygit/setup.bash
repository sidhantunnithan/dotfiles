#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="lazygit"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

log_section "Installing Lazygit"
if ! command -v lazygit &> /dev/null; then
  log_warn "Lazygit not found, installing..."
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
