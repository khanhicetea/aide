#!/usr/bin/env bash

install_prerequisites() {
  local missing=0 command
  for command in curl git ssh-keygen; do
    has "$command" || missing=1
  done
  ((missing == 0)) && return

  log "Installing prerequisites"
  if has apt-get; then
    as_root apt-get update
    as_root apt-get install -y ca-certificates curl git openssh-client
  elif has dnf; then
    as_root dnf install -y ca-certificates curl git openssh-clients
  elif has yum; then
    as_root yum install -y ca-certificates curl git openssh-clients
  elif has pacman; then
    as_root pacman -Sy --needed --noconfirm ca-certificates curl git openssh
  elif has apk; then
    as_root apk add ca-certificates curl git openssh-client
  else
    die "unsupported package manager; install curl, git, and ssh-keygen first"
  fi
}

install_mise() {
  if [[ -x /usr/local/bin/mise ]]; then
    log "mise is already installed at /usr/local/bin/mise"
    return
  fi

  log "Installing mise system-wide"
  local temp_dir
  temp_dir="$(mktemp -d)"
  if ! curl -fsSL https://mise.run | MISE_INSTALL_PATH="$temp_dir/mise" sh; then
    rm -rf -- "$temp_dir"
    die "mise installation failed"
  fi
  if [[ ! -x "$temp_dir/mise" ]]; then
    rm -rf -- "$temp_dir"
    die "mise installer did not produce an executable"
  fi
  if ! as_root install -m 0755 "$temp_dir/mise" /usr/local/bin/mise; then
    rm -rf -- "$temp_dir"
    die "could not install mise in /usr/local/bin"
  fi
  rm -rf -- "$temp_dir"
}

configure_shell() {
  local rc block
  block='# aide: mise activation
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi
# /aide: mise activation'

  rc="$HOME/.bashrc"
  touch "$rc"
  if ! grep -Fq '# aide: mise activation' "$rc"; then
    printf '\n%s\n' "$block" >>"$rc"
    log "Enabled mise in $rc"
  fi

  if [[ -f "$HOME/.zshrc" || ${SHELL:-} == */zsh ]]; then
    rc="$HOME/.zshrc"
    touch "$rc"
    if ! grep -Fq '# aide: mise activation' "$rc"; then
      block="${block/mise activate bash/mise activate zsh}"
      printf '\n%s\n' "$block" >>"$rc"
      log "Enabled mise in $rc"
    fi
  fi
}

setup_tools() {
  ensure_home
  install_prerequisites
  install_mise
  configure_shell

  local node_version="${AIDE_NODE_VERSION:-lts}"
  log "Installing Node.js $node_version for the current user"
  /usr/local/bin/mise use --global "node@$node_version"
  log "Node.js $(/usr/local/bin/mise exec -- node --version) is ready"
}
