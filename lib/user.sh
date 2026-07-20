#!/usr/bin/env bash

configure_user_bin() {
  local rc npmrc temp block
  block='# aide: user binaries
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# /aide: user binaries'

  install -d -m 0755 "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"

  for rc in "$HOME/.profile" "$HOME/.bashrc"; do
    touch "$rc"
    if ! grep -Fq '# aide: user binaries' "$rc"; then
      printf '\n%s\n' "$block" >>"$rc"
      log "Added user npm binaries to PATH in $rc"
    fi
  done

  if [[ -f "$HOME/.zshrc" || ${SHELL:-} == */zsh ]]; then
    rc="$HOME/.zshrc"
    touch "$rc"
    if ! grep -Fq '# aide: user binaries' "$rc"; then
      printf '\n%s\n' "$block" >>"$rc"
      log "Added user npm binaries to PATH in $rc"
    fi
  fi

  # Keep global npm packages in a stable, user-owned location across Node versions.
  npmrc="$HOME/.npmrc"
  touch "$npmrc"
  if grep -Eq '^[[:space:]]*prefix[[:space:]]*=' "$npmrc"; then
    temp="$(mktemp)"
    awk -v prefix="$HOME/.local" '
      /^[[:space:]]*prefix[[:space:]]*=/ {
        if (!written) print "prefix=" prefix
        written=1
        next
      }
      { print }
    ' "$npmrc" >"$temp"
    mv "$temp" "$npmrc"
  else
    printf '\nprefix=%s\n' "$HOME/.local" >>"$npmrc"
  fi
}

configure_git() {
  log "Configuring Git defaults for the current user"
  git config --global init.defaultBranch main
  git config --global user.name "KhanhIceTea"
  git config --global user.email "khanhicetea@gmail.com"
}

ensure_ssh_key() {
  local key="$HOME/.ssh/id_ed25519"
  install -d -m 0700 "$HOME/.ssh"

  if [[ ! -f "$key" ]]; then
    log "Generating an Ed25519 SSH key"
    ssh-keygen -q -t ed25519 -N '' -C "${USER:-user}@$(hostname)-aide" -f "$key"
  elif [[ ! -f "$key.pub" ]]; then
    log "Recreating the public half of the existing SSH key"
    ssh-keygen -y -f "$key" >"$key.pub"
    chmod 0644 "$key.pub"
  else
    log "SSH key already exists"
  fi
}

authorize_github_keys() {
  local github_user="${AIDE_GITHUB_USER:-khanhicetea}"
  local authorized="$HOME/.ssh/authorized_keys" temp key added=0
  temp="$(mktemp)"

  log "Fetching public keys from github.com/$github_user"
  if ! curl -fsSL "https://github.com/${github_user}.keys" -o "$temp"; then
    rm -f -- "$temp"
    die "could not fetch GitHub public keys for $github_user"
  fi
  if ! grep -Eq '^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp(256|384|521)) ' "$temp"; then
    rm -f -- "$temp"
    die "GitHub returned no valid SSH public keys for $github_user"
  fi

  touch "$authorized"
  chmod 0600 "$authorized"
  while IFS= read -r key; do
    [[ "$key" =~ ^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp(256|384|521))[[:space:]] ]] || continue
    if ! grep -Fqx -- "$key" "$authorized"; then
      printf '%s\n' "$key" >>"$authorized"
      added=$((added + 1))
    fi
  done <"$temp"

  log "Authorized $added new GitHub key(s) in $authorized"
  rm -f -- "$temp"
}

configure_user() {
  ensure_home
  install_prerequisites
  configure_user_bin
  configure_git
  ensure_ssh_key
  authorize_github_keys
}
