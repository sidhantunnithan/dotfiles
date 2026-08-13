#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="alacritty"
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

log_section "Installing Alacritty"
if ! command -v alacritty &> /dev/null; then
  log_warn "Alacritty not found, installing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install --cask alacritty
    log_success "Alacritty installed via Homebrew"
  else
    apt_noninteractive install alacritty || {
      log_warn "apt install failed — try: sudo add-apt-repository ppa:aslatter/ppa && sudo apt update && sudo apt install alacritty"
      exit 1
    }
    log_success "Alacritty installed via apt"
  fi
else
  log_success "Alacritty already installed"
fi

log_section "Installing JetBrainsMono Nerd Font"
if [[ "$(uname)" == "Darwin" ]]; then
  FONT_DIR=~/Library/Fonts
else
  FONT_DIR=~/.local/share/fonts
fi
if ! find "$FONT_DIR" -name "JetBrainsMonoNerdFont*" 2>/dev/null | grep -q .; then
  log_warn "Font not found, installing..."
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

log_section "Configuring Alacritty"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"

mkdir -p ~/.config/alacritty

curl -fsSL "$DOTFILES_RAW/alacritty/.alacritty.toml" -o ~/.config/alacritty/alacritty.toml
log_success "Configuration file downloaded"

curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
log_success "Catppuccin color theme downloaded"

if [[ "$(uname)" == "Darwin" ]]; then
  cat > ~/.config/alacritty/platform.toml <<'EOF'
[window]
option_as_alt = "Both"

[terminal.shell]
args = ["--login"]
program = "/bin/zsh"

[[keyboard.bindings]]
action = "Paste"
key = "V"
mods = "Command"

[[keyboard.bindings]]
action = "Copy"
key = "C"
mods = "Command"

[[keyboard.bindings]]
action = "Quit"
key = "Q"
mods = "Command"

[[keyboard.bindings]]
action = "ToggleFullscreen"
key = "Return"
mods = "Command"
EOF
  log_success "Platform config written (macOS)"
else
  cat > ~/.config/alacritty/platform.toml <<'EOF'
[terminal.shell]
args = ["--login"]
program = "/bin/bash"

[[keyboard.bindings]]
action = "Paste"
key = "V"
mods = "Control|Shift"

[[keyboard.bindings]]
action = "Copy"
key = "C"
mods = "Control|Shift"

[[keyboard.bindings]]
action = "ToggleFullscreen"
key = "F11"
EOF
  log_success "Platform config written (Linux)"
fi
