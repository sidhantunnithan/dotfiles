#!/bin/bash
set -e

# ── Logging ──────────────────────────────────────────────────────────────────
TAG="zsh"
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

# Install a package via the platform's package manager.
# Runs `apt-get update` once on Linux so packages can be located on fresh hosts.
APT_UPDATED=0
install_pkg() {
  local pkg="$1"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install "$pkg"
  elif command -v apt-get &> /dev/null; then
    if [ "$APT_UPDATED" -eq 0 ]; then
      apt_noninteractive update
      APT_UPDATED=1
    fi
    apt_noninteractive install "$pkg"
  else
    log_warn "No supported package manager found; please install '${pkg}' manually"
    return 1
  fi
}

# Portable in-place sed (BSD sed on macOS needs an explicit empty suffix).
sed_i() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

upsert_function() {
  local rc_file="$1"
  local fn_name="$2"
  local tmp_rc

  if grep -q "^function ${fn_name}()" "$rc_file"; then
    tmp_rc="$(mktemp)"
    # Remove the existing function block *and* any blank lines immediately
    # preceding it, so repeated runs don't accumulate whitespace.
    awk -v fn="$fn_name" '
      $0 ~ "^function " fn "\\(\\) \\{$" { in_fn = 1; nbuf = 0; next }
      in_fn == 1 && /^}$/ { in_fn = 0; next }
      in_fn == 1 { next }
      /^[[:space:]]*$/ { buf[nbuf++] = $0; next }
      { for (i = 0; i < nbuf; i++) print buf[i]; nbuf = 0; print }
      END { for (i = 0; i < nbuf; i++) print buf[i] }
    ' "$rc_file" > "$tmp_rc"
    mv "$tmp_rc" "$rc_file"
  fi
}

log_section "Installing Zsh"
if ! command -v zsh &> /dev/null; then
  log_warn "Zsh not found, installing..."
  install_pkg zsh
  log_success "Zsh installed"
else
  log_success "Zsh already installed"
fi

RC=~/.zshrc

if [ ! -f "$RC" ]; then
  log_warn "~/.zshrc not found — creating it"
  touch "$RC"
fi

log_section "Installing fzf"
if ! command -v fzf &> /dev/null; then
  log_warn "fzf not found, installing..."
  install_pkg fzf
  log_success "fzf installed"
else
  log_success "fzf already installed"
fi

log_section "Setting up fzf key bindings"
FZF_MARKER="# dotfiles: fzf key bindings"
if ! grep -q "$FZF_MARKER" "$RC"; then
  cat >> "$RC" <<'EOF'

# dotfiles: fzf key bindings
if command -v fzf &> /dev/null; then
  # Cache fzf's zsh integration to a file so we spawn fzf at most once a week
  # instead of twice on every shell startup (Ctrl-R, Ctrl-T, Alt-C).
  _fzf_cache="$HOME/.cache/fzf-init.zsh"
  [ -d "${_fzf_cache:h}" ] || mkdir -p "${_fzf_cache:h}"
  if [ ! -s "$_fzf_cache" ] || [ -n "$(find "$_fzf_cache" -mtime +7 2>/dev/null)" ]; then
    if fzf --zsh > "$_fzf_cache.tmp" 2>/dev/null && [ -s "$_fzf_cache.tmp" ]; then
      # fzf >= 0.48
      mv "$_fzf_cache.tmp" "$_fzf_cache"
    else
      rm -f "$_fzf_cache.tmp"
      # Older fzf without `--zsh`: cache the key-bindings script from disk.
      for _fzf_kb in \
        "$(brew --prefix 2>/dev/null)/opt/fzf/shell/key-bindings.zsh" \
        /usr/share/fzf/key-bindings.zsh \
        /usr/share/doc/fzf/examples/key-bindings.zsh; do
        [ -f "$_fzf_kb" ] && cp "$_fzf_kb" "$_fzf_cache" && break
      done
      unset _fzf_kb
    fi
  fi
  [ -s "$_fzf_cache" ] && source "$_fzf_cache"
  unset _fzf_cache
fi
EOF
  log_success "fzf key bindings added"
else
  log_success "fzf key bindings already present"
fi

log_section "Optimizing zsh startup"

# 1. Lazy-load nvm — sourcing nvm.sh eagerly costs ~80ms on every shell. Defer
#    it until `nvm` is first run. node/npm/npx keep resolving to whatever is on
#    PATH (e.g. Homebrew) at full speed.
NVM_LAZY_MARKER="# dotfiles: lazy nvm"
if ! grep -q "$NVM_LAZY_MARKER" "$RC"; then
  # Strip the classic eager nvm lines the nvm installer appends, if present.
  if grep -qE '^\[ -s "\$NVM_DIR/nvm\.sh" \]|^export NVM_DIR=' "$RC"; then
    tmp_rc="$(mktemp)"
    grep -vE '^export NVM_DIR=|^\[ -s "\$NVM_DIR/nvm\.sh" \]|^\[ -s "\$NVM_DIR/bash_completion" \]' "$RC" > "$tmp_rc"
    mv "$tmp_rc" "$RC"
  fi
  cat >> "$RC" <<'EOF'

# dotfiles: lazy nvm
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}
EOF
  log_success "Lazy nvm loader installed"
else
  log_success "Lazy nvm loader already present"
fi

# 2. Oh My Zsh startup tweaks — only when OMZ is actually sourced in the rc.
if grep -q 'source \$ZSH/oh-my-zsh.sh' "$RC"; then
  # a) Stop the periodic update-check git fetch that can stall startup.
  if grep -qE "^zstyle ':omz:update' mode " "$RC"; then
    if grep -q "^zstyle ':omz:update' mode disabled" "$RC"; then
      log_success "Oh My Zsh update check already disabled"
    else
      sed_i "s|^zstyle ':omz:update' mode .*|zstyle ':omz:update' mode disabled  # dotfiles: no update fetch on startup|" "$RC"
      log_success "Disabled Oh My Zsh update check"
    fi
  fi
  # b) Skip the compaudit security scan on every compinit (safe single-user).
  if grep -q '^ZSH_DISABLE_COMPFIX=' "$RC"; then
    log_success "ZSH_DISABLE_COMPFIX already set"
  else
    tmp_rc="$(mktemp)"
    awk '
      /^source \$ZSH\/oh-my-zsh.sh/ && !done {
        print "ZSH_DISABLE_COMPFIX=\"true\"  # dotfiles: skip compaudit on startup"
        print ""
        done = 1
      }
      { print }
    ' "$RC" > "$tmp_rc"
    mv "$tmp_rc" "$RC"
    log_success "Set ZSH_DISABLE_COMPFIX"
  fi
fi

log_section "Setting up Zsh aliases"
ALIAS_MARKER="# dotfiles: zsh aliases"
if ! grep -q "$ALIAS_MARKER" "$RC"; then
  cat >> "$RC" <<'EOF'

# dotfiles: zsh aliases
alias rn=". ranger"
EOF
  log_success "Zsh aliases added"
else
  log_success "Zsh aliases already present"
fi

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

# NOTE: upsert-based sections (ss, p) re-append on every run, so they must come
# after all append-once marker sections above to keep the file order stable.
log_section "Setting up ss() SSH host picker"
upsert_function "$RC" "ss"
cat >> "$RC" << 'EOF'

function ss() {
    host=$(cat /etc/hosts | awk '/# End Checkpoint/{exit} p && $0 != "" {print} /# Checkpoint/{p=1}' | sed "s/.*\ //" | fzf)
    ssh -v "$host"
}
EOF
log_success "ss() function set"

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
