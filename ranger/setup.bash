#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="ranger"
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

log_section "Installing Ranger"
if ! command -v ranger &> /dev/null; then
  log_warn "Ranger not found, installing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ranger
  else
    apt_noninteractive install ranger
  fi
  log_success "Ranger installed"
else
  log_success "Ranger already installed"
fi

log_section "Configuring Ranger"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"
mkdir -p ~/.config/ranger
curl -fsSL "$DOTFILES_RAW/ranger/rc.conf" -o ~/.config/ranger/rc.conf
log_success "Ranger configuration file downloaded"

log_section "Setting up EDITOR environment variable"
EDITOR_MARKER="# dotfiles: EDITOR setup"
for rc in ~/.bashrc ~/.zshrc; do
  if [ -f "$rc" ] && ! grep -q "$EDITOR_MARKER" "$rc"; then
    cat >> "$rc" <<EOF

$EDITOR_MARKER
if command -v nvim &> /dev/null; then
    export EDITOR=nvim
elif command -v vim &> /dev/null; then
    export EDITOR=vim
elif command -v vi &> /dev/null; then
    export EDITOR=vi
elif command -v nano &> /dev/null; then
    export EDITOR=nano
fi
EOF
    log_success "Editor configuration added to $rc"
  fi
done
