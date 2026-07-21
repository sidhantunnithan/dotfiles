#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="raycast"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

log_section "Installing Raycast"
if ! command -v raycast &> /dev/null && [[ "$(uname)" == "Darwin" ]]; then
  log_warn "Raycast not found, installing..."
  brew install --cask raycast
  log_success "Raycast installed"
elif [[ "$(uname)" != "Darwin" ]]; then
  log_warn "Raycast is macOS only"
else
  log_success "Raycast already installed"
fi

log_section "Manual Raycast configuration"
log_warn "To complete setup:"
log "1. Open Raycast > Settings > Advanced > Import"
log "2. Download config from: https://github.com/sidhantunnithan/dotfiles/tree/main/raycast"
