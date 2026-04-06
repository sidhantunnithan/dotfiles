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

version_lte() {
  [[ "$1" == "$2" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ]]
}

log_section "Installing Neovim"
if [[ "$(uname)" == "Darwin" ]]; then
  if ! command -v nvim &> /dev/null; then
    echo -e "${YELLOW}Neovim not found, installing...${NC}"
    brew install neovim
    log_success "Neovim installed"
  else
    log_success "Neovim already installed"
  fi
else
  # Linux: download latest release
  echo -e "${YELLOW}Setting up Neovim from latest release...${NC}"
  ARCH=$(uname -m)
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NVIM_TARBALL="nvim-linux-arm64.tar.gz"
  else
    NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
  fi
  NVIM_DIR="${NVIM_TARBALL%.tar.gz}"
  cd /tmp
  curl -LO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TARBALL"
  sudo rm -rf "/opt/$NVIM_DIR"
  sudo tar -C /opt -xzf "$NVIM_TARBALL"
  rm "$NVIM_TARBALL"
  cd -
  log_success "Neovim installed from latest release"

  # Add to PATH in bashrc if not already present
  if ! grep -q "export PATH=.*$NVIM_DIR/bin" ~/.bashrc; then
    echo "export PATH=\"\$PATH:/opt/$NVIM_DIR/bin\"" >> ~/.bashrc
    log_success "Neovim PATH added to ~/.bashrc"
  else
    log_success "Neovim PATH already in ~/.bashrc"
  fi
fi

log_section "Configuring Neovim"
DOTFILES_REPO="https://github.com/sidhantunnithan/dotfiles.git"
DOTFILES_RAW="https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main"

rm -rf ~/.config/nvim
TMPDIR=$(mktemp -d)
git clone --depth 1 "$DOTFILES_REPO" "$TMPDIR"
cp -r "$TMPDIR/nvim" ~/.config/nvim
rm -rf "$TMPDIR"
log_success "Neovim configuration cloned"

curl -fsSL "$DOTFILES_RAW/nvim/.prettierrc" -o ~/.prettierrc
log_success "Prettier config downloaded"

log_section "Installing Neovim dependencies"
if ! command -v rg &> /dev/null; then
  echo -e "${YELLOW}Ripgrep not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ripgrep
  else
    sudo apt install -y ripgrep
  fi
  log_success "Ripgrep installed"
else
  log_success "Ripgrep already installed"
fi

log_section "Checking build tools"
required_build_tools=(gcc make)
missing_build_tools=()

for tool in "${required_build_tools[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
    missing_build_tools+=("$tool")
  fi
done

if [[ ${#missing_build_tools[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Missing build tools: ${missing_build_tools[*]}${NC}"
  read -r -p "Install missing build tools now? [y/N]: " install_build_tools

  if [[ "$install_build_tools" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      xcode-select --install || true
      log_success "Requested Xcode Command Line Tools install"
    else
      sudo apt install -y "${missing_build_tools[@]}"
      log_success "Installed build tools: ${missing_build_tools[*]}"
    fi
  else
    echo -e "${YELLOW}Skipping build tool installation${NC}"
  fi
else
  log_success "Build tools already installed"
fi

log_section "Installing Tree-sitter CLI"
if ! command -v tree-sitter &> /dev/null; then
  echo -e "${YELLOW}Tree-sitter not found, installing...${NC}"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tree-sitter
    log_success "Tree-sitter installed via Homebrew"
  else
    TREE_SITTER_VERSION="v0.26.8"
    UBUNTU_BASELINE="22.04"

    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      if [[ "${ID:-}" == "ubuntu" ]] && [[ -n "${VERSION_ID:-}" ]]; then
        if version_lte "$VERSION_ID" "$UBUNTU_BASELINE"; then
          TREE_SITTER_VERSION="v0.25.10"
        fi
      fi
    fi

    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
      TREE_SITTER_ARCH="arm64"
    else
      TREE_SITTER_ARCH="x64"
    fi

    TREE_SITTER_ASSET="tree-sitter-linux-${TREE_SITTER_ARCH}.gz"
    TREE_SITTER_URL="https://github.com/tree-sitter/tree-sitter/releases/download/${TREE_SITTER_VERSION}/${TREE_SITTER_ASSET}"
    TREE_SITTER_BIN="$HOME/.local/bin/tree-sitter"

    mkdir -p "$HOME/.local/bin"
    curl -fL "$TREE_SITTER_URL" -o "/tmp/${TREE_SITTER_ASSET}"
    gzip -dc "/tmp/${TREE_SITTER_ASSET}" > "$TREE_SITTER_BIN"
    chmod 755 "$TREE_SITTER_BIN"
    rm -f "/tmp/${TREE_SITTER_ASSET}"
    log_success "Tree-sitter installed from ${TREE_SITTER_VERSION}"
  fi
else
  log_success "Tree-sitter already installed"
fi
