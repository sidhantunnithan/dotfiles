#!/bin/bash
set -euo pipefail

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
YAZI_GITHUB_REPO="sxyazi/yazi"
YAZI_UBUNTU_FALLBACK_VERSION="v26.1.22"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_section() {
  echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_warn() {
  echo -e "${YELLOW}! $1${NC}"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

install_ya_pkg() {
  local pkg="$1"
  local out
  if out="$(ya pkg add "$pkg" 2>&1)"; then
    return 0
  fi

  if echo "$out" | grep -q "already exists in package.toml"; then
    return 0
  fi

  echo "$out" >&2
  return 1
}

version_le() {
  [[ "$1" == "$2" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" == "$1" ]]
}

detect_ubuntu_version() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == "ubuntu" ]]; then
      printf '%s\n' "${VERSION_ID:-}"
      return 0
    fi
  fi

  return 1
}

fetch_latest_yazi_tag() {
  curl -fsSL "https://api.github.com/repos/${YAZI_GITHUB_REPO}/releases/latest" |
    sed -n 's/.*"tag_name": "\(v[^"]*\)".*/\1/p' |
    head -n 1
}

resolve_yazi_linux_release() {
  local arch="$1"
  local tag asset_suffix ubuntu_version

  tag="$(fetch_latest_yazi_tag || true)"
  if [[ -z "$tag" ]]; then
    tag="$YAZI_UBUNTU_FALLBACK_VERSION"
  fi
  asset_suffix="unknown-linux-gnu"

  if ubuntu_version="$(detect_ubuntu_version)"; then
    if version_le "$ubuntu_version" "23.10"; then
      tag="$YAZI_UBUNTU_FALLBACK_VERSION"
      asset_suffix="unknown-linux-musl"
      log_warn "Ubuntu ${ubuntu_version} detected, using Yazi ${tag} musl fallback" >&2
    fi
  fi

  printf '%s %s\n' "$tag" "yazi-${arch}-${asset_suffix}.zip"
}

install_yazi_linux() {
  local arch install_dir tmp_dir tag asset archive source_dir

  case "$(uname -m)" in
    aarch64|arm64) arch="aarch64" ;;
    x86_64) arch="x86_64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac

  read -r tag asset <<< "$(resolve_yazi_linux_release "$arch")"
  archive="${asset}"
  install_dir="${HOME}/.local/bin"
  tmp_dir="$(mktemp -d)"

  log_section "Installing Yazi binaries"
  mkdir -p "$install_dir"
  rm -f "$install_dir/yazi" "$install_dir/ya"
  curl -fsSL "https://github.com/${YAZI_GITHUB_REPO}/releases/download/${tag}/${archive}" -o "$tmp_dir/$archive"
  unzip -q "$tmp_dir/$archive" -d "$tmp_dir"
  source_dir="$tmp_dir/${archive%.zip}"
  install -m 0755 "$source_dir/yazi" "$install_dir/yazi"
  install -m 0755 "$source_dir/ya" "$install_dir/ya"
  export PATH="$install_dir:$PATH"
  hash -r 2>/dev/null || true

  mkdir -p "$tmp_dir/xdg"
  XDG_CONFIG_HOME="$tmp_dir/xdg" "$install_dir/yazi" --version >/dev/null
  "$install_dir/ya" --version >/dev/null
  rm -rf "$tmp_dir"
  log_success "Installed Yazi ${tag} to ${install_dir}"
}

copy_managed_file() {
  local rel_path="$1"
  local destination="$2"

  if [[ -f "${SCRIPT_DIR}/${rel_path}" ]]; then
    cp "${SCRIPT_DIR}/${rel_path}" "$destination"
  else
    curl -fsSL "https://raw.githubusercontent.com/sidhantunnithan/dotfiles/main/yazi/${rel_path}" -o "$destination"
  fi
}

log_section "Installing Yazi and dependencies"
if [[ "$(uname)" == "Darwin" ]]; then
  for pkg in yazi mediainfo git; do
    if ! command -v "$pkg" &> /dev/null; then
      echo -e "${YELLOW}$pkg not found, installing...${NC}"
      brew install "$pkg"
      log_success "$pkg installed via Homebrew"
    else
      log_success "$pkg already installed"
    fi
  done
else
  for pkg in mediainfo git curl unzip; do
    if ! command -v "$pkg" &> /dev/null; then
      echo -e "${YELLOW}$pkg not found, installing...${NC}"
      sudo apt install -y "$pkg"
      log_success "$pkg installed via apt"
    else
      log_success "$pkg already installed"
    fi
  done
  install_yazi_linux
fi

log_section "Configuring Yazi"
YAZI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
mkdir -p "$YAZI_CONFIG_DIR/plugins" "$YAZI_CONFIG_DIR/flavors"

for file in yazi.toml keymap.toml theme.toml package.toml init.lua; do
  copy_managed_file "$file" "$YAZI_CONFIG_DIR/$file"
  log_success "Installed $file"
done

for plugin in smart-enter mediainfo; do
  mkdir -p "$YAZI_CONFIG_DIR/plugins/$plugin.yazi"
  copy_managed_file "plugins/$plugin.yazi/main.lua" "$YAZI_CONFIG_DIR/plugins/$plugin.yazi/main.lua"
  log_success "Installed local plugin: $plugin"
done
log_success "Yazi config files installed"

log_section "Resetting managed Yazi assets"
rm -rf \
  "$YAZI_CONFIG_DIR/plugins/bookmarks.yazi" \
  "$YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi"
log_success "Cleared managed plugin/flavor directories"

log_section "Installing Yazi plugins"
require_cmd ya
install_ya_pkg dedukun/bookmarks
log_success "Installed plugin: dedukun/bookmarks"

log_section "Installing Yazi flavor"
install_ya_pkg yazi-rs/flavors:catppuccin-mocha
log_success "Installed flavor: catppuccin-mocha"

log_section "Syncing Yazi packages"
ya pkg install
log_success "Yazi packages synced"

if [ ! -f "$YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi/flavor.toml" ]; then
  log_warn "Flavor file still missing after install: $YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi/flavor.toml"
  exit 1
fi

if [ ! -f "$YAZI_CONFIG_DIR/plugins/bookmarks.yazi/main.lua" ]; then
  log_warn "Plugin file still missing after install: $YAZI_CONFIG_DIR/plugins/bookmarks.yazi/main.lua"
  exit 1
fi

log_section "Setting up f() yazi wrapper"
if [[ "$(uname)" == "Darwin" ]]; then
  RC_FILES=(~/.zshrc)
else
  RC_FILES=(~/.bashrc)
fi

for rc in "${RC_FILES[@]}"; do
  if [ -f "$rc" ]; then
    if grep -q "^function f()" "$rc"; then
      tmp_rc="$(mktemp)"
      awk '
        BEGIN { in_f = 0 }
        /^function f\(\) \{$/ { in_f = 1; next }
        in_f == 1 && /^\}$/ { in_f = 0; next }
        in_f == 0 { print }
      ' "$rc" > "$tmp_rc"
      mv "$tmp_rc" "$rc"
      log_success "Updated existing f() function in $rc"
    fi

    cat >> "$rc" << 'EOF'

function f() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    local yazi_term="$TERM"
    if [[ -n "$TMUX" || "$TERM" == tmux* || "$TERM" == screen* ]]; then
      yazi_term="xterm-256color"
    fi
    command env TERM="$yazi_term" yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
EOF
    log_success "f() function set in $rc"
  else
    log_success "$rc not found, skipping"
  fi
done

if [[ "$(uname)" == "Darwin" ]]; then
  echo -e "${YELLOW}Run the following or open a new terminal to use the f() command:${NC}"
  echo "  source ~/.zshrc"
else
  echo -e "${YELLOW}Run the following or open a new terminal to use the f() command:${NC}"
  echo "  source ~/.bashrc"
fi
