#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="kitty"
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

DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"

log_section "Installing Kitty"
if [[ "$(uname)" == "Darwin" ]]; then
  if brew list --cask kitty &> /dev/null; then
    brew upgrade --cask kitty || true
    log_success "Kitty up to date (Homebrew)"
  elif command -v kitty &> /dev/null; then
    log_warn "Kitty $(kitty --version | awk '{print $2}') installed outside Homebrew, not upgrading"
  else
    brew install --cask kitty
    log_success "Kitty installed via Homebrew"
  fi
else
  # apt's kitty lags years behind (0.21 on Ubuntu 22.04), so use the official
  # installer, which always fetches the latest release into ~/.local/kitty.app.
  KITTY_APP=~/.local/kitty.app
  INSTALLED="$("$KITTY_APP/bin/kitty" --version 2> /dev/null | awk '{print $2}' || true)"
  LATEST="$(curl -fsSL https://api.github.com/repos/kovidgoyal/kitty/releases/latest 2> /dev/null \
    | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/' || true)"

  if [[ -n "$INSTALLED" && ( -z "$LATEST" || "$INSTALLED" == "$LATEST" ) ]]; then
    [[ -z "$LATEST" ]] && log_warn "Could not look up the latest release, keeping ${INSTALLED}"
    log_success "Kitty ${INSTALLED} already installed"
  else
    if [[ -n "$INSTALLED" ]]; then
      log_warn "Kitty ${INSTALLED} installed, latest is ${LATEST}, upgrading..."
    else
      log_warn "Kitty not found in ${KITTY_APP}, installing..."
    fi
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    log_success "Kitty $("$KITTY_APP/bin/kitty" --version | awk '{print $2}') installed to ${KITTY_APP}"
  fi

  mkdir -p ~/.local/bin ~/.local/share/applications
  ln -sf "$KITTY_APP/bin/kitty" "$KITTY_APP/bin/kitten" ~/.local/bin/
  # Desktop entries in ~/.local/share/applications override the system ones,
  # so the launcher starts this kitty even if an apt kitty is still around.
  cp "$KITTY_APP"/share/applications/kitty*.desktop ~/.local/share/applications/
  sed -i "s|Icon=kitty|Icon=$KITTY_APP/share/icons/hicolor/256x256/apps/kitty.png|g; \
          s|Exec=kitty|Exec=$KITTY_APP/bin/kitty|g" \
      ~/.local/share/applications/kitty*.desktop
  log_success "Linked kitty into ~/.local/bin and installed desktop launcher"

  # An apt kitty in /usr/bin wins whenever ~/.local/bin is missing from PATH.
  # kitty-terminfo is marked manual so a later autoremove keeps it: hosts and
  # tmux still need the xterm-kitty entry it provides.
  if dpkg -s kitty &> /dev/null; then
    log_warn "Removing apt kitty $(dpkg-query -W -f='${Version}' kitty)"
    dpkg -s kitty-terminfo &> /dev/null && sudo apt-mark manual kitty-terminfo > /dev/null
    apt_noninteractive remove kitty kitty-doc
    log_success "apt kitty removed (kitty-terminfo kept)"
  fi

  log_section "Putting ~/.local/bin first in PATH"
  PATH_MARKER="# dotfiles: ~/.local/bin first in PATH"
  for rc in ~/.bashrc ~/.zshrc; do
    [[ -f "$rc" ]] || continue
    if ! grep -q "$PATH_MARKER" "$rc"; then
      cat >> "$rc" <<'EOF'

# dotfiles: ~/.local/bin first in PATH
case ":$PATH:" in
  ":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
      log_success "PATH entry added to ${rc}"
    else
      log_success "PATH entry already present in ${rc}"
    fi
  done
fi

curl -fsSL "$DOTFILES_RAW/fonts/nerd-font.bash" | bash
curl -fsSL "$DOTFILES_RAW/fonts/stix-math.bash" | bash

log_section "Configuring Kitty"
KITTY_CONFIG_DIR=~/.config/kitty

mkdir -p "$KITTY_CONFIG_DIR"

# The download replaces kitty.conf wholesale; keep a backup when it differs, so
# a change made only on this machine isn't lost without notice.
KITTY_CONF_TMP=$(mktemp)
curl -fsSL "$DOTFILES_RAW/kitty/kitty.conf" -o "$KITTY_CONF_TMP"
if [[ -f "$KITTY_CONFIG_DIR/kitty.conf" ]] && ! cmp -s "$KITTY_CONF_TMP" "$KITTY_CONFIG_DIR/kitty.conf"; then
  BACKUP="$KITTY_CONFIG_DIR/kitty.conf.bak.$(date +%Y%m%d%H%M%S)"
  cp "$KITTY_CONFIG_DIR/kitty.conf" "$BACKUP"
  log_warn "Local kitty.conf differs from the repo, backed up to ${BACKUP}:"
  diff -u "$BACKUP" "$KITTY_CONF_TMP" || true
fi
mv "$KITTY_CONF_TMP" "$KITTY_CONFIG_DIR/kitty.conf"
log_success "Configuration file downloaded"

curl -fsSL "$DOTFILES_RAW/kitty/catppuccin-mocha.conf" -o "$KITTY_CONFIG_DIR/catppuccin-mocha.conf"
log_success "Catppuccin color theme downloaded"

log_section "Kitty setup complete"
log_warn "Restart Kitty or reload config to apply changes"
