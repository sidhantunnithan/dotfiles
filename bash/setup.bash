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

upsert_function() {
  local rc_file="$1"
  local fn_name="$2"
  local tmp_rc

  if grep -q "^function ${fn_name}()" "$rc_file"; then
    tmp_rc="$(mktemp)"
    awk -v fn="$fn_name" '
      BEGIN { in_fn = 0 }
      $0 ~ "^function " fn "\\(\\) \\{$" { in_fn = 1; next }
      in_fn == 1 && /^}$/ { in_fn = 0; next }
      in_fn == 0 { print }
    ' "$rc_file" > "$tmp_rc"
    mv "$tmp_rc" "$rc_file"
  fi
}

RC=~/.bashrc

if [ ! -f "$RC" ]; then
  echo -e "${YELLOW}~/.bashrc not found — creating it${NC}"
  touch "$RC"
fi

log_section "Installing LS_COLORS config"
mkdir -p ~/.config/custom
curl --output ~/.config/custom/lscolors.sh https://raw.githubusercontent.com/sidhantunnithan/LS_COLORS/refs/heads/master/lscolors.sh
log_success "LS_COLORS script downloaded"

log_section "Sourcing LS_COLORS in Bash"
LSCOLORS_MARKER="# dotfiles: LS_COLORS setup"
if ! grep -q "$LSCOLORS_MARKER" "$RC"; then
  cat >> "$RC" <<'EOF'

# dotfiles: LS_COLORS setup
source ~/.config/custom/lscolors.sh
EOF
  log_success "LS_COLORS sourcing added"
else
  log_success "LS_COLORS sourcing already present"
fi

log_section "Ensuring ls color output in Bash"
LS_COLOR_ALIAS_MARKER="# dotfiles: ls color alias"
if ! grep -q "$LS_COLOR_ALIAS_MARKER" "$RC"; then
  cat >> "$RC" <<'EOF'

# dotfiles: ls color alias
if command -v gls &> /dev/null; then
    alias ls='gls --color=auto'
elif ls -G . &> /dev/null; then
    alias ls='ls -G'
fi
EOF
  log_success "ls color alias added"
else
  log_success "ls color alias already present"
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

log_section "Setting up Bash aliases"
ALIAS_MARKER="# dotfiles: bash aliases"
if ! grep -q "$ALIAS_MARKER" "$RC"; then
  cat >> "$RC" <<'EOF'

# dotfiles: bash aliases
alias ranger=". ranger"
alias rn="ranger"
EOF
  log_success "Bash aliases added"
else
  log_success "Bash aliases already present"
fi

log_section "Setting up ss() SSH host picker"
upsert_function "$RC" "ss"
cat >> "$RC" << 'EOF'

function ss() {
    host=$(cat /etc/hosts | awk '/# End Checkpoint/{exit} p && $0 != "" {print} /# Checkpoint/{p=1}' | sed "s/.*\ //" | fzf)
    ssh -v "$host"
}
EOF
log_success "ss() function set"

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

log_section "Setting up p() project switcher"
upsert_function "$RC" "p"
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
log_success "p() function set"
