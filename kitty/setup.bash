#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="kitty"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

log_section "Installing Kitty"
if ! command -v kitty &> /dev/null; then
  log_warn "Kitty not found, installing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install --cask kitty
    log_success "Kitty installed via Homebrew"
  else
    sudo apt install -y kitty || {
      log_warn "apt install failed — try: sudo add-apt-repository ppa:sw1tchbl4d3/kitty && sudo apt update && sudo apt install kitty"
      exit 1
    }
    log_success "Kitty installed via apt"
  fi
else
  log_success "Kitty already installed"
fi

log_section "Installing JetBrainsMono Nerd Font"
if [[ "$(uname)" == "Darwin" ]]; then
  FONT_DIR=~/Library/Fonts
else
  FONT_DIR=~/.local/share/fonts
fi
if ! find "$FONT_DIR" -name "JetBrainsMonoNerdFont*" 2>/dev/null | grep -q .; then
  log_warn "Font not found, installing..."
  if [[ "$(uname)" != "Darwin" ]] && ! command -v unzip &> /dev/null; then
    sudo apt install -y unzip
  fi
  mkdir -p "$FONT_DIR"
  TMPDIR=$(mktemp -d)
  curl -fsSL -o "$TMPDIR/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
  unzip -qo "$TMPDIR/JetBrainsMono.zip" -d "$TMPDIR/fonts"
  cp "$TMPDIR"/fonts/*.ttf "$FONT_DIR/"
  rm -rf "$TMPDIR"
  if [[ "$(uname)" != "Darwin" ]]; then
    fc-cache -f "$FONT_DIR"
  fi
  log_success "JetBrainsMono Nerd Font installed"
else
  log_success "JetBrainsMono Nerd Font already installed"
fi

log_section "Configuring Kitty"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
KITTY_CONFIG_DIR=~/.config/kitty

mkdir -p "$KITTY_CONFIG_DIR"

curl -fsSL "$DOTFILES_RAW/kitty/kitty.conf" -o "$KITTY_CONFIG_DIR/kitty.conf"
log_success "Configuration file downloaded"

curl -fsSL "$DOTFILES_RAW/kitty/catppuccin-mocha.conf" -o "$KITTY_CONFIG_DIR/catppuccin-mocha.conf"
log_success "Catppuccin color theme downloaded"

log_section "Kitty setup complete"
log_warn "Restart Kitty or reload config to apply changes"
