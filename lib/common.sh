#!/usr/bin/env bash

log() { printf '\033[1;34m[aide]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[aide]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[aide]\033[0m %s\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  elif has sudo; then
    sudo "$@"
  else
    die "root access is required (install sudo or run as root): $*"
  fi
}

ensure_home() {
  [[ -n ${HOME:-} && -d "$HOME" ]] || die "HOME is not a valid directory"
}
