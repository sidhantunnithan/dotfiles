#!/bin/bash
set -e

# Installs STIX Two Math on Linux as a fallback for symbols JetBrains Mono lacks,
# e.g. Claude Code's mode indicator ⏵ (U+23F5). macOS ships this exact file in
# /System/Library/Fonts/Supplemental and falls back to it, so installing it here
# makes both platforms draw those symbols the same way. Ubuntu's fonts-stix is
# still STIX 1.1, hence the download. Upstream hasn't released since 2.13
# (2021), so the version is pinned and checked by hash.

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="stix-math"
log()         { printf '\033[01;34m[%s]\033[00m %s\n'                       "$TAG" "$*"; }
log_section() { printf '\n\033[01;34m[%s]\033[00m \033[01m%s\033[00m\n'     "$TAG" "$*"; }
log_success() { printf '\033[01;34m[%s]\033[00m \033[00;32m%s\033[00m\n'    "$TAG" "$*"; }
log_warn()    { printf '\033[01;34m[%s]\033[00m \033[00;33m%s\033[00m\n'    "$TAG" "$*"; }
log_error()   { printf '\033[01;34m[%s]\033[00m \033[00;31m%s\033[00m\n'    "$TAG" "$*"; }

log_section "Installing STIX Two Math"

if [[ "$(uname)" == "Darwin" ]]; then
  log_success "Ships with macOS, nothing to do"
  exit 0
fi

STIX_TAG="v2.13b171"
STIX_SHA256="3a5f3f26f40d5698b3c62dd085d48d6663696a3f80825aab8b553d5097518e8c"
FONT_DIR=~/.local/share/fonts
FONT_FILE="$FONT_DIR/STIXTwoMath-Regular.otf"

if [[ -f "$FONT_FILE" ]] && echo "$STIX_SHA256  $FONT_FILE" | sha256sum -c --status; then
  log_success "STIX Two Math ${STIX_TAG} already installed"
  exit 0
fi

TMP_FILE=$(mktemp)
curl -fsSL -o "$TMP_FILE" "https://raw.githubusercontent.com/stipub/stixfonts/${STIX_TAG}/fonts/static_otf/STIXTwoMath-Regular.otf"
if ! echo "$STIX_SHA256  $TMP_FILE" | sha256sum -c --status; then
  log_error "Downloaded STIX Two Math does not match the expected SHA-256"
  rm -f "$TMP_FILE"
  exit 1
fi

mkdir -p "$FONT_DIR"
mv "$TMP_FILE" "$FONT_FILE"
chmod 644 "$FONT_FILE"
fc-cache -f "$FONT_DIR"
log_success "STIX Two Math ${STIX_TAG} installed to ${FONT_DIR}"
