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
BOOKMARKS_PKG="sidhantunnithan/bookmarks"
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

# Probed against a throwaway empty config. This runs after the managed flavor
# has been cleared but before it is reinstalled, and Yazi refuses to start on a
# dangling flavor reference: it writes "Failed to read flavor ..." straight to
# the tty (bypassing the pipe) and then blocks on "Press <Enter> to continue".
# </dev/null guarantees the probe can never wait for a keypress.
yazi_version() {
  local bin="${1:-yazi}"
  local probe_dir version
  probe_dir="$(mktemp -d)"
  version="$(XDG_CONFIG_HOME="$probe_dir" "$bin" --version </dev/null 2>/dev/null |
    sed -n 's/^Yazi \([0-9][0-9.]*\).*/\1/p')" || true
  rm -rf "$probe_dir"
  printf '%s\n' "$version"
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

# Upstream compress.yazi opens its "Create archive:" box empty: it computes a
# default name only *after* the dialog returns, and only uses it when an empty
# string was submitted. This rewrites main.lua so the name is computed up front
# and passed as `value`, pre-filling the box -- file name without its last
# extension, directory name as-is, or the cwd name for a multi-file selection.
#
# Applied as a post-install patch rather than a vendored copy so the plugin keeps
# tracking upstream. The eight anchors below are byte-identical in the pinned and
# the legacy revisions, so one patch covers both. If upstream ever rewrites those
# blocks the anchor count stops matching and the file is left untouched: the
# plugin still works, it just loses the autofill.
patch_compress_autofill() {
  local file tmp
  file="$YAZI_CONFIG_DIR/plugins/compress.yazi/main.lua"

  if [ ! -f "$file" ]; then
    log_warn "compress.yazi/main.lua not found, skipping autofill patch"
    return 0
  fi

  if grep -q "value = default_name," "$file"; then
    log_success "Archive-name autofill already applied"
    return 0
  fi

  tmp="$(mktemp)"

  if awk '
    BEGIN { hits = 0 }

    # 1. declare the flag before the hovered branch
    $0 == "\tif #paths == 0 and tab.current.hovered then" {
      hits++
      print "\tlocal is_single_dir = false"
      print; next
    }

    # 2. a hovered target knows its own type
    $0 == "\t\tnames[1] = tostring(tab.current.hovered.name)" {
      hits++
      print
      print "\t\tis_single_dir = tab.current.hovered.cha.is_dir or false"
      next
    }

    # 3. a single *selected* target never hits the branch above, so look its
    #    type up in the directory listing; then hand the flag back to entry()
    $0 == "\treturn path_fnames, names, tostring(tab.current.cwd)" {
      hits++
      print "\tif #names == 1 and not is_single_dir then"
      print "\t\tfor _, f in ipairs(tab.current.files) do"
      print "\t\t\tif tostring(f.name) == names[1] then"
      print "\t\t\t\tis_single_dir = f.cha.is_dir or false"
      print "\t\t\t\tbreak"
      print "\t\t\tend"
      print "\t\tend"
      print "\tend"
      print ""
      print "\treturn path_fnames, names, tostring(tab.current.cwd), is_single_dir"
      next
    }

    # 4. receive it
    $0 == "\t\tlocal path_fnames, fnames, output_dir = selected_or_hovered()" {
      hits++
      print "\t\tlocal path_fnames, fnames, output_dir, is_single_dir = selected_or_hovered()"
      next
    }

    # 5. compute the default name *before* the dialog opens
    $0 == "\t\t-- Get archive filename" {
      hits++
      print "\t\t-- Determine the default name for the archive up front, so it can"
      print "\t\t-- pre-fill the input box instead of only applying on empty submit."
      print "\t\tlocal default_name"
      print "\t\tif #fnames == 1 then"
      print "\t\t\t-- drop a file'"'"'s last extension; leave directories and dotfiles"
      print "\t\t\t-- such as .env whole, as they have no name before the dot."
      print "\t\t\tdefault_name = is_single_dir and fnames[1] or (fnames[1]:match(\"^(.+)%.[^.]+$\") or fnames[1])"
      print "\t\telse"
      print "\t\t\tdefault_name = Url(output_dir).name"
      print "\t\tend"
      print ""
      print; next
    }

    # 6. pre-fill it
    $0 == "\t\t\ttitle = \"Create archive:\"," {
      hits++
      print
      print "\t\t\tvalue = default_name,"
      next
    }

    # 7/8. drop the old post-dialog computation, now redundant
    $0 == "\t\t-- Determine the default name for the archive" { hits++; next }
    $0 == "\t\tlocal default_name = #fnames == 1 and fnames[1] or Url(output_dir).name" { hits++; next }

    { print }

    END { if (hits != 8) { printf "anchors matched: %d of 8\n", hits > "/dev/stderr"; exit 1 } }
  ' "$file" > "$tmp"; then
    mv "$tmp" "$file"
    log_success "Patched compress.yazi: archive name autofills in the dialog"
  else
    rm -f "$tmp"
    log_warn "compress.yazi/main.lua does not match the expected layout, leaving it unpatched (no archive-name autofill)"
  fi
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
      asset_suffix="unknown-linux-musl"
      log_warn "Ubuntu ${ubuntu_version} detected, using Yazi ${tag} musl build" >&2
    fi
  fi

  printf '%s %s\n' "$tag" "yazi-${arch}-${asset_suffix}.zip"
}

install_yazi_linux() {
  local arch install_dir tmp_dir tag asset archive source_dir installed

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

  log_section "Installing Yazi binaries"

  # Both binaries come out of the same archive, so a missing `ya` means the
  # install is incomplete no matter what `yazi --version` reports. The probe
  # targets $install_dir directly: a distro-packaged yazi elsewhere on PATH
  # says nothing about the copy this script manages.
  export PATH="$install_dir:$PATH"
  hash -r 2>/dev/null || true
  if [[ -x "$install_dir/yazi" && -x "$install_dir/ya" ]]; then
    installed="$(yazi_version "$install_dir/yazi")"
    if [[ -n "$installed" && "v${installed}" == "$tag" ]]; then
      log_success "Yazi ${tag} already installed in ${install_dir}"
      return 0
    fi
    log_warn "Yazi ${installed:-unknown} installed, expected ${tag}, reinstalling"
  fi

  tmp_dir="$(mktemp -d)"
  mkdir -p "$install_dir"
  rm -f "$install_dir/yazi" "$install_dir/ya"
  curl -fsSL "https://github.com/${YAZI_GITHUB_REPO}/releases/download/${tag}/${archive}" -o "$tmp_dir/$archive"
  unzip -q "$tmp_dir/$archive" -d "$tmp_dir"
  source_dir="$tmp_dir/${archive%.zip}"
  install -m 0755 "$source_dir/yazi" "$install_dir/yazi"
  install -m 0755 "$source_dir/ya" "$install_dir/ya"
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

# Ubuntu 24.04+ renamed p7zip-full to 7zip; try the modern name first.
apt_install() {
  local pkg="$1"
  if [[ "$pkg" == "7zip" ]]; then
    apt_noninteractive install 7zip || apt_noninteractive install p7zip-full
  else
    apt_noninteractive install "$pkg"
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
install_ya_pkg "$BOOKMARKS_PKG"
log_success "Installed plugin: $BOOKMARKS_PKG"
install_compress_plugin

log_section "Installing Yazi flavor"
install_ya_pkg yazi-rs/flavors:catppuccin-mocha
log_success "Installed flavor: catppuccin-mocha"

log_section "Syncing Yazi packages"
ya pkg install
log_success "Yazi packages synced"

# bookmarks.yazi is our own fork, so it tracks main rather than the revision
# pinned in package.toml. `ya pkg upgrade` re-resolves to the latest commit and
# rewrites the pin; that is how ya pkg expresses branch tracking, as it has no
# ref/branch syntax of its own. Non-fatal: `ya pkg install` above already
# deployed the pinned revision, which is a fine fallback when GitHub is
# unreachable.
if ya pkg upgrade "$BOOKMARKS_PKG"; then
  log_success "Tracking latest main: $BOOKMARKS_PKG"
else
  log_warn "Could not upgrade $BOOKMARKS_PKG, keeping the revision pinned in package.toml"
fi

log_section "Patching compress.yazi"
patch_compress_autofill

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
