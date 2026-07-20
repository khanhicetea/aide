#!/usr/bin/env bash

install_pi() {
  local -a npm_command pi_command
  local pi_bin="$HOME/.local/bin/pi"

  install -d -m 0755 "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
  export npm_config_prefix="$HOME/.local"

  if has npm; then
    npm_command=(npm)
    pi_command=("$pi_bin")
  elif [[ -x /usr/local/bin/mise ]]; then
    npm_command=(/usr/local/bin/mise exec -- npm)
    pi_command=(/usr/local/bin/mise exec -- "$pi_bin")
  else
    die "npm is required; run './aide tools' first"
  fi

  log "Installing pi for the current user"
  "${npm_command[@]}" install -g --ignore-scripts @earendil-works/pi-coding-agent
  [[ -x "$pi_bin" ]] || die "pi was installed but $pi_bin was not created"

  log "Installing pi packages"
  "${pi_command[@]}" install npm:@juicesharp/rpiv-ask-user-question
  "${pi_command[@]}" install npm:pi-powerline-footer
  "${pi_command[@]}" install npm:pi-xai-oauth
  "${pi_command[@]}" install git:github.com/khanhicetea/web-access-kit@main
}

install_agy() {
  log "Installing agy"
  curl -fsSL https://antigravity.google/cli/install.sh | bash

  local token_file="$HOME/.gemini/antigravity-cli/antigravity-oauth-token"
  if [[ ! -f "$token_file" ]]; then
    install -d -m 0755 "$HOME/.gemini/antigravity-cli"
    touch "$token_file"
  fi
}

sync_agents() {
  ensure_home
  local source="$AIDE_ROOT/.agents"
  [[ -d "$source" ]] || die "agent source directory does not exist: $source"

  install_pi
  install -d -m 0755 "$HOME/.agents"
  cp -a "$source/." "$HOME/.agents/"

  install_agy

  log "Copied repository agents to $HOME/.agents"
}
