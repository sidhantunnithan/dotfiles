#!/bin/bash
set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_section() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_section "Setting up Zsh aliases"
echo "
alias ranger=\". ranger\"
alias rn=\"ranger\"
" >> ~/.zshrc
log_success "Zsh aliases added"

log_section "Setting up ss() SSH host picker"
if grep -q "^function ss()" ~/.zshrc; then
    log_success "ss() already exists, skipping"
else
cat >> ~/.zshrc << 'EOF'

function ss() {
    host=`cat /etc/hosts | awk '/# End Checkpoint/{exit} p && $0 != "" {print} /# Checkpoint/{p=1}' | sed "s/.*\ //" | fzf`
    ssh -v $host
}
EOF
log_success "ss() function added"
fi

log_section "Setting up EDITOR"
cat >> ~/.zshrc << 'EOF'

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

log_section "Setting up p() project switcher"
if grep -q "^function p()" ~/.zshrc; then
    log_success "p() already exists, skipping"
else
cat >> ~/.zshrc << 'EOF'

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
fi
