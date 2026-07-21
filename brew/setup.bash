#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="brew"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

log_section "Installing Homebrew"
if ! command -v brew &> /dev/null; then
  log_warn "Homebrew not found, installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log_success "Homebrew installed"
else
  log_success "Homebrew already installed"
fi

log_section "Installing packages from Brewfile"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
BREWFILE_TMP=$(mktemp)
curl -fsSL "$DOTFILES_RAW/brew/Brewfile" -o "$BREWFILE_TMP"

# Strip cask and vscode lines on Linux (unsupported)
if [[ "$(uname)" != "Darwin" ]]; then
  sed -i '/^cask /d;/^vscode /d' "$BREWFILE_TMP"
  log_success "Filtered macOS-only entries for Linux"
fi

brew bundle --file="$BREWFILE_TMP"
log_success "Brewfile packages installed"
rm -f "$BREWFILE_TMP"
