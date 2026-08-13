#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="tmux"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

# apt on its own still stops for debconf and for needrestart's full-screen
# "which services should be restarted?" dialog, neither of which -y answers.
# NEEDRESTART_MODE=a restarts affected services silently; NEEDRESTART_SUSPEND
# covers older needrestart releases that ignore it.
apt_noninteractive() {
  sudo env DEBIAN_FRONTEND=noninteractive \
           NEEDRESTART_MODE=a \
           NEEDRESTART_SUSPEND=1 \
    apt-get -y -o Dpkg::Options::=--force-confold "$@"
}

log_section "Installing Tmux"
if command -v tmux &> /dev/null; then
  log_warn "Tmux already installed, removing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew uninstall tmux
  else
    apt_noninteractive remove tmux
  fi
fi
log_warn "Installing Tmux..."
if [[ "$(uname)" == "Darwin" ]]; then
  brew install tmux
else
  apt_noninteractive install libevent-dev libncurses-dev build-essential bison pkg-config
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
