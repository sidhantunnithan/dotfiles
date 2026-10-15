#!/bin/bash
set -e

# Installs or upgrades JetBrainsMono Nerd Font to the latest release. Shared by
# kitty/setup.bash and alacritty/setup.bash so the two stop drifting apart.

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="nerd-font"
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

FONT_GLOB="JetBrainsMono*NerdFont*"
CASK="font-jetbrains-mono-nerd-font"

log_section "Installing JetBrainsMono Nerd Font"

if [[ "$(uname)" == "Darwin" ]]; then
  # Brew tracks the latest release and upgrades it with everything else.
  if brew list --cask "$CASK" &> /dev/null; then
    brew upgrade --cask "$CASK" || true
    log_success "JetBrainsMono Nerd Font up to date (Homebrew)"
  else
    # Copies left by the old zip install make the cask refuse to install.
    if find ~/Library/Fonts -maxdepth 1 -name "$FONT_GLOB" 2>/dev/null | grep -q .; then
      log_warn "Removing manually installed copies from ~/Library/Fonts"
      find ~/Library/Fonts -maxdepth 1 -name "$FONT_GLOB" -delete
    fi
    brew install --cask "$CASK"
    log_success "JetBrainsMono Nerd Font installed via Homebrew"
  fi
  exit 0
fi

FONT_DIR=~/.local/share/fonts

# The release is embedded in the font's name table, e.g. "Nerd Fonts 3.5.1".
installed_version() {
  local f
  f="$(find "$FONT_DIR" -maxdepth 1 -name 'JetBrainsMonoNerdFont-Regular.ttf' 2>/dev/null | head -n 1)"
  [[ -n "$f" ]] || return 0
  grep -aoE 'Nerd Fonts [0-9.]+' "$f" | head -n 1 | awk '{print $3}'
}

latest_version() {
  curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest 2>/dev/null \
    | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/'
}

INSTALLED="$(installed_version)"
LATEST="$(latest_version || true)"

if [[ -n "$INSTALLED" && ( -z "$LATEST" || "$INSTALLED" == "$LATEST" ) ]]; then
  [[ -z "$LATEST" ]] && log_warn "Could not look up the latest release, keeping ${INSTALLED}"
  log_success "JetBrainsMono Nerd Font ${INSTALLED} already installed"
  exit 0
fi

if [[ -n "$INSTALLED" ]]; then
  log_warn "JetBrainsMono Nerd Font ${INSTALLED} installed, latest is ${LATEST}, upgrading..."
else
  log_warn "Font not found, installing..."
fi

if ! command -v unzip &> /dev/null; then
  apt_noninteractive install unzip
fi

TMPDIR=$(mktemp -d)
curl -fsSL -o "$TMPDIR/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip -qo "$TMPDIR/JetBrainsMono.zip" -d "$TMPDIR/fonts"

# Drop old copies first, including ones in the legacy ~/.fonts, so fontconfig
# only ever sees one version of the family.
for dir in "$FONT_DIR" ~/.fonts; do
  [[ -d "$dir" ]] && find "$dir" -maxdepth 1 -name "$FONT_GLOB" -delete
done
mkdir -p "$FONT_DIR"
cp "$TMPDIR"/fonts/*.ttf "$FONT_DIR/"
rm -rf "$TMPDIR"
fc-cache -f "$FONT_DIR"

log_success "JetBrainsMono Nerd Font $(installed_version) installed"
