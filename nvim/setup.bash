#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="nvim"
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

version_lte() {
  [[ "$1" == "$2" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ]]
}

log_section "Installing Neovim"
if [[ "$(uname)" == "Darwin" ]]; then
  if ! command -v nvim &> /dev/null; then
    log_warn "Neovim not found, installing..."
    brew install neovim
    log_success "Neovim installed"
  else
    log_success "Neovim already installed"
  fi
else
  # Linux: download latest release
  log_warn "Setting up Neovim from latest release..."
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
  log_warn "Ripgrep not found, installing..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install ripgrep
  else
    apt_noninteractive install ripgrep
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
  log_warn "Missing build tools: ${missing_build_tools[*]}"
  read -r -p "Install missing build tools now? [y/N]: " install_build_tools

  if [[ "$install_build_tools" =~ ^[Yy]$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      xcode-select --install || true
      log_success "Requested Xcode Command Line Tools install"
    else
      apt_noninteractive install "${missing_build_tools[@]}"
      log_success "Installed build tools: ${missing_build_tools[*]}"
    fi
  else
    log_warn "Skipping build tool installation"
  fi
else
  log_success "Build tools already installed"
fi

log_section "Installing Tree-sitter CLI"
if ! command -v tree-sitter &> /dev/null; then
  log_warn "Tree-sitter not found, installing..."
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
