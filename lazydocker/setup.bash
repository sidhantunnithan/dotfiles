#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="lazydocker"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

log_section "Installing Lazydocker"
if ! command -v lazydocker &> /dev/null; then
  log_warn "Lazydocker not found, installing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install lazydocker
    log_success "Lazydocker installed via Homebrew"
  else
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    log_success "Lazydocker installed via install script"
  fi
else
  log_success "Lazydocker already installed"
fi

log_section "Configuring Lazydocker"
CONFIG_DIR=~/.config/lazydocker

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p "$CONFIG_DIR"
curl -fsSL "$DOTFILES_RAW/lazydocker/config.yml" -o "$CONFIG_DIR/config.yml"
log_success "Lazydocker configuration file downloaded"

log_section "Setting up shell alias"
for rc in ~/.zshrc ~/.bashrc; do
  if [ -f "$rc" ] && ! grep -q 'alias lzd=lazydocker' "$rc"; then
    echo "alias lzd=lazydocker" >> "$rc"
    log_success "Alias added to $rc"
  fi
done
