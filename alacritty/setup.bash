#!/bin/bash
set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_section() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_section "Installing Alacritty"
if ! command -v alacritty &> /dev/null; then
  echo -e "${YELLOW}Alacritty not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install --cask alacritty
    log_success "Alacritty installed via Homebrew"
  else
    echo "Please install alacritty manually: https://alacritty.org"
  fi
else
  log_success "Alacritty already installed"
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
