#!/bin/bash
set -euo pipefail

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="kitty-terminfo"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

TERM_NAME="xterm-kitty"
TERMINFO_SRC_URL="https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo"
USER_TERMINFO_DIR="$HOME/.terminfo"

has_terminfo() {
  command -v infocmp &> /dev/null && infocmp -x "$TERM_NAME" &> /dev/null
}

# Non-interactive sudo only: this script is meant to be run through `curl | bash`,
# where stdin is the script itself and a password prompt would hang.
sudo_prefix() {
  if [[ "$(id -u)" -eq 0 ]]; then
    printf '%s' ""
    return 0
  fi
  if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
    printf '%s' "sudo"
    return 0
  fi
  return 1
}

# Works on any host with ncurses' tic and no sudo: compiles kitty's terminfo
# description into ~/.terminfo, which ncurses searches before the system database.
install_from_source() {
  local tmp_dir tic_out

  if ! command -v tic &> /dev/null; then
    log_error "tic not found — install ncurses (apt: ncurses-bin) and re-run"
    return 1
  fi

  tmp_dir="$(mktemp -d)"

  log "Downloading terminfo description from kitty upstream"
  if ! curl -fsSL "$TERMINFO_SRC_URL" -o "$tmp_dir/kitty.terminfo"; then
    log_error "Failed to download $TERMINFO_SRC_URL"
    rm -rf "$tmp_dir"
    return 1
  fi

  mkdir -p "$USER_TERMINFO_DIR"
  # tic warns about the description field on older ncurses; only surface its
  # output when the compile actually fails.
  if ! tic_out="$(tic -x -o "$USER_TERMINFO_DIR" "$tmp_dir/kitty.terminfo" 2>&1)"; then
    log_error "tic failed to compile the terminfo description"
    printf '%s\n' "$tic_out" >&2
    rm -rf "$tmp_dir"
    return 1
  fi

  rm -rf "$tmp_dir"
  log_success "Compiled $TERM_NAME into $USER_TERMINFO_DIR"
}

# The kitty.app bundle ships a pre-compiled terminfo tree, so a local install can
# be fixed without network access and stays in sync with the installed kitty.
install_from_kitty_app() {
  local candidate resolved bundle_terminfo=""

  for candidate in \
    /Applications/kitty.app/Contents/Resources/kitty/terminfo \
    "$HOME/Applications/kitty.app/Contents/Resources/kitty/terminfo"; do
    if [[ -d "$candidate" ]]; then
      bundle_terminfo="$candidate"
      break
    fi
  done

  if [[ -z "$bundle_terminfo" ]] && command -v kitty &> /dev/null; then
    # /Applications/kitty.app/Contents/MacOS/kitty → .../Contents/Resources/kitty/terminfo
    resolved="$(cd "$(dirname "$(command -v kitty)")" && pwd)"
    candidate="$(dirname "$resolved")/Resources/kitty/terminfo"
    [[ -d "$candidate" ]] && bundle_terminfo="$candidate"
  fi

  [[ -n "$bundle_terminfo" ]] || return 1

  mkdir -p "$USER_TERMINFO_DIR"
  # Only the compiled hash directories (x/, 78/) belong in ~/.terminfo; the
  # bundle also carries the .terminfo/.termcap sources next to them.
  # The trailing slash is stripped because BSD cp copies a directory's contents,
  # not the directory itself, when the source path ends in one.
  for candidate in "$bundle_terminfo"/*/; do
    [[ -d "$candidate" ]] && cp -R "${candidate%/}" "$USER_TERMINFO_DIR/"
  done
  log_success "Copied terminfo from $bundle_terminfo to $USER_TERMINFO_DIR"
}

install_macos() {
  if install_from_kitty_app; then
    return 0
  fi
  log_warn "kitty.app terminfo not found, falling back to upstream description"
  install_from_source
}

install_linux() {
  local sudo_cmd

  if ! command -v apt-get &> /dev/null; then
    log_warn "apt-get not found, falling back to a user-local install"
    install_from_source
    return
  fi

  if ! sudo_cmd="$(sudo_prefix)"; then
    log_warn "No passwordless sudo, falling back to a user-local install"
    install_from_source
    return
  fi

  log "Installing kitty-terminfo via apt"
  # NEEDRESTART_* suppress needrestart's full-screen "which services should be
  # restarted?" dialog, which -y does not answer.
  if $sudo_cmd env DEBIAN_FRONTEND=noninteractive \
                   NEEDRESTART_MODE=a \
                   NEEDRESTART_SUSPEND=1 \
       apt-get install -y kitty-terminfo; then
    log_success "kitty-terminfo installed system-wide"
    return
  fi

  log_warn "apt install failed, falling back to a user-local install"
  install_from_source
}

log_section "Installing $TERM_NAME terminfo"

if has_terminfo; then
  log_success "$TERM_NAME terminfo already present, nothing to do"
  exit 0
fi

if [[ "$(uname)" == "Darwin" ]]; then
  install_macos
else
  install_linux
fi

log_section "Verifying"
if ! has_terminfo; then
  log_error "$TERM_NAME still does not resolve"
  log_warn "As a last resort, run this from the kitty client machine:"
  log "  infocmp -a $TERM_NAME | ssh <host> 'tic -x -o ~/.terminfo /dev/stdin'"
  exit 1
fi
log_success "infocmp $TERM_NAME resolves"

colors="$(TERM=$TERM_NAME tput colors 2>/dev/null || true)"
if [[ "$colors" == "256" ]]; then
  log_success "TERM=$TERM_NAME tput colors → 256"
else
  log_warn "TERM=$TERM_NAME tput colors → ${colors:-<no output>} (expected 256)"
fi

log_section "Terminfo setup complete"
log "Takes effect immediately — no re-login needed"
