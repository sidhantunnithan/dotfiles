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

log_section "Installing Zsh"
if ! command -v zsh &> /dev/null; then
  echo -e "${YELLOW}Zsh not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install zsh
  else
    sudo apt install -y zsh
  fi
  log_success "Zsh installed"
else
  log_success "Zsh already installed"
fi

RC=~/.zshrc

if [ ! -f "$RC" ]; then
  echo -e "${YELLOW}~/.zshrc not found — creating it${NC}"
  touch "$RC"
fi

log_section "Installing fzf"
if ! command -v fzf &> /dev/null; then
  echo -e "${YELLOW}fzf not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install fzf
  else
    sudo apt install -y fzf
  fi
  log_success "fzf installed"
else
  log_success "fzf already installed"
fi

log_section "Setting up Zsh aliases"
ALIAS_MARKER="# dotfiles: zsh aliases"
if ! grep -q "$ALIAS_MARKER" "$RC"; then
  cat >> "$RC" <<'EOF'

# dotfiles: zsh aliases
alias rn=". ranger"
EOF
  log_success "Zsh aliases added"
else
  log_success "Zsh aliases already present"
fi

log_section "Setting up ss() SSH host picker"
if ! grep -q "^function ss()" "$RC"; then
  cat >> "$RC" << 'EOF'

function ss() {
    host=$(cat /etc/hosts | awk '/# End Checkpoint/{exit} p && $0 != "" {print} /# Checkpoint/{p=1}' | sed "s/.*\ //" | fzf)
    ssh -v "$host"
}
EOF
  log_success "ss() function added"
else
  log_success "ss() already exists, skipping"
fi

log_section "Setting up EDITOR"
EDITOR_MARKER="# dotfiles: EDITOR setup"
if ! grep -q "$EDITOR_MARKER" "$RC"; then
  cat >> "$RC" <<EOF

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
  log_success "EDITOR configured"
else
  log_success "EDITOR already configured"
fi

log_section "Setting up y() yazi wrapper"
if ! grep -q "^function y()" "$RC"; then
  cat >> "$RC" << 'EOF'

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
EOF
  log_success "y() function added"
else
  log_success "y() already exists, skipping"
fi

log_section "Setting up p() project switcher"
if ! grep -q "^function p()" "$RC"; then
  cat >> "$RC" << 'EOF'

function p() {
    local project_dirs=(
        # Add your project directories here, e.g.:
        # ~/Projects
        # ~/Work
    )
    local selected
    selected=$(
        for d in "${project_dirs[@]}"; do
            ls -1 "$d" | sed "s|^|${d##*/}/|"
        done | fzf
    )
    if [ -n "$selected" ]; then
        local base="${selected%%/*}"
        for d in "${project_dirs[@]}"; do
            [[ "${d##*/}" == "$base" ]] && cd "$d/${selected#*/}" && return
        done
    fi
}
EOF
  log_success "p() function added"
else
  log_success "p() already exists, skipping"
fi
