#!/bin/bash
set -euo pipefail

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="yazi"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

YAZI_GITHUB_REPO="sxyazi/yazi"
YAZI_UBUNTU_FALLBACK_VERSION="v26.1.22"
COMPRESS_MIN_YAZI_VERSION="26.5.6"
COMPRESS_LEGACY_REV="46a6b9f02ff2f8aced466a1f01a3fe241f1cd45f"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &> /dev/null; then
    log_error "Missing required command: $cmd" >&2
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

yazi_version() {
  yazi --version | sed -n 's/^Yazi \([0-9][0-9.]*\).*/\1/p'
}

# ya pkg has no --rev flag, so an older pin has to be cloned by hand. Removing
# the dep from package.toml stops `ya pkg install` replacing it with the newer
# revision pinned there.
drop_package_dep() {
  local file="$1" dep="$2" tmp
  tmp="$(mktemp)"

  awk -v dep="$dep" '
    /^\[\[plugin\.deps\]\]/ {
      if (inblk && !drop) printf "%s", blk
      blk = $0 "\n"; inblk = 1; drop = 0; next
    }
    inblk && /^\[/ {
      if (!drop) printf "%s", blk
      blk = ""; inblk = 0; print; next
    }
    inblk {
      blk = blk $0 "\n"
      if ($0 == "use = \"" dep "\"") drop = 1
      next
    }
    { print }
    END { if (inblk && !drop) printf "%s", blk }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

# Yazi has no built-in compression, so the T/C keys in keymap.toml are backed by
# KKV9/compress. The revision pinned in package.toml needs a Yazi newer than the
# one installed on older Ubuntu, so those hosts get the last revision that still
# supports them rather than a plugin Yazi refuses to load.
install_compress_plugin() {
  local version target
  version="$(yazi_version 2>/dev/null || true)"

  if [[ -z "$version" ]] || version_le "$COMPRESS_MIN_YAZI_VERSION" "$version"; then
    install_ya_pkg KKV9/compress
    log_success "Installed plugin: KKV9/compress"
    return 0
  fi

  target="$YAZI_CONFIG_DIR/plugins/compress.yazi"
  log_warn "Yazi $version predates $COMPRESS_MIN_YAZI_VERSION, pinning compress.yazi to ${COMPRESS_LEGACY_REV:0:7}"
  drop_package_dep "$YAZI_CONFIG_DIR/package.toml" "KKV9/compress"
  rm -rf "$target"
  git clone -q https://github.com/KKV9/compress.yazi "$target"
  git -C "$target" checkout -q "$COMPRESS_LEGACY_REV"
  rm -rf "$target/.git"
  log_success "Installed plugin: KKV9/compress (legacy pin)"
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
      log_error "Unsupported architecture: $(uname -m)" >&2
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

# Dependencies are listed as "package[:binary]" because a package name does not
# always match the command it provides (e.g. Homebrew's sevenzip ships `7zz`).
# 7-Zip is required by Yazi's built-in extractor, which shells out to `7zz`/`7z`
# for every archive format, .tar.gz included.
install_dep() {
  local spec="$1" installer="$2"
  local pkg="${spec%%:*}"
  local bins="${spec##*:}"
  local bin

  # Several binaries may satisfy one package (Debian's p7zip-full ships `7z`,
  # the newer 7zip package ships `7zz`); any one of them counts as installed.
  IFS='|' read -ra bins <<< "$bins"
  for bin in "${bins[@]}"; do
    if command -v "$bin" &> /dev/null; then
      log_success "$pkg already installed"
      return 0
    fi
  done

  log_warn "$pkg not found, installing..."
  "$installer" "$pkg"
  log_success "$pkg installed"
}

brew_install() { brew install "$1"; }

# Ubuntu 24.04+ renamed p7zip-full to 7zip; try the modern name first.
apt_install() {
  local pkg="$1"
  if [[ "$pkg" == "7zip" ]]; then
    sudo apt install -y 7zip || sudo apt install -y p7zip-full
  else
    sudo apt install -y "$pkg"
  fi
}

log_section "Installing Yazi and dependencies"
if [[ "$(uname)" == "Darwin" ]]; then
  for spec in yazi mediainfo git 'imagemagick:magick|convert' sevenzip:7zz; do
    install_dep "$spec" brew_install
  done
else
  for spec in mediainfo git curl unzip 'imagemagick:magick|convert' '7zip:7zz|7z'; do
    install_dep "$spec" apt_install
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

# Only genuinely local plugins belong here. Anything listed in package.toml is
# deployed by `ya pkg install`, which aborts if it finds a directory it did not
# write itself.
for plugin in smart-enter mediainfo; do
  mkdir -p "$YAZI_CONFIG_DIR/plugins/$plugin.yazi"
  copy_managed_file "plugins/$plugin.yazi/main.lua" "$YAZI_CONFIG_DIR/plugins/$plugin.yazi/main.lua"
  log_success "Installed local plugin: $plugin"
done
log_success "Yazi config files installed"

log_section "Resetting managed Yazi assets"
# Every ya pkg-managed asset is cleared so `ya pkg install` always redeploys it
# from scratch; this also repairs installs left inconsistent by earlier runs.
rm -rf \
  "$YAZI_CONFIG_DIR/plugins/bookmarks.yazi" \
  "$YAZI_CONFIG_DIR/plugins/compress.yazi" \
  "$YAZI_CONFIG_DIR/plugins/full-border.yazi" \
  "$YAZI_CONFIG_DIR/plugins/zoom.yazi" \
  "$YAZI_CONFIG_DIR/flavors/catppuccin-mocha.yazi"
log_success "Cleared managed plugin/flavor directories"

log_section "Installing Yazi plugins"
require_cmd ya
install_ya_pkg dedukun/bookmarks
log_success "Installed plugin: dedukun/bookmarks"
install_compress_plugin

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

for plugin in bookmarks compress; do
  if [ ! -f "$YAZI_CONFIG_DIR/plugins/$plugin.yazi/main.lua" ]; then
    log_warn "Plugin file still missing after install: $YAZI_CONFIG_DIR/plugins/$plugin.yazi/main.lua"
    exit 1
  fi
done

log_section "Setting up f() yazi wrapper"
if [[ "$(uname)" == "Darwin" ]]; then
  RC_FILES=(~/.zshrc)
else
  RC_FILES=(~/.bashrc)
fi

if [[ "$(uname)" != "Darwin" ]]; then
  rc=~/.bashrc
  if [ -f "$rc" ]; then
    if grep -q "^export TERM=" "$rc"; then
      sed -i 's/^export TERM=.*/export TERM=xterm-kitty/' "$rc"
      log_success "Updated TERM=xterm-kitty in $rc"
    else
      echo $'\nexport TERM=xterm-kitty' >> "$rc"
      log_success "Set TERM=xterm-kitty in $rc"
    fi
  fi
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
    command env EDITOR="nvim" VISUAL="nvim" yazi "$@" --cwd-file="$tmp"
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
  log_warn "Run the following or open a new terminal to use the f() command:"
  log "  source ~/.zshrc"
else
  log_warn "Run the following or open a new terminal to use the f() command:"
  log "  source ~/.bashrc"
fi
