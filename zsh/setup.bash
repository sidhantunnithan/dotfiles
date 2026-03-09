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
