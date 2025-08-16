#!/usr/bin/env bash
set -euo pipefail

# load environment if .env exists next to repo root
REPO_ROOT="$(cd "${BASH_SOURCE%/*}/.." && pwd)"
if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  . "$REPO_ROOT/.env"
  set +a
fi

LOG_PREFIX="[vios-autoconfig]"

log() {
  local level="$1"; shift
  printf '%s [%s] %s\n' "$LOG_PREFIX" "$level" "$*" >&2
}

require_env() {
  local missing=0
  for var in "$@"; do
    if [ -z "${!var:-}" ]; then
      log err "Missing env var: $var"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || exit 1
}

confirm() {
  local q="$1"
  if [ "${AUTO_YES:-0}" -eq 1 ]; then
    return 0
  fi
  read -r -p "$q [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

run_cmd() {
  if [ "${DRY_RUN:-1}" -eq 1 ]; then
    echo "$@"
  else
    eval "$@"
  fi
}

H() {
  require_env HMC_HOST HMC_USER
  run_cmd ssh $SSH_OPTS "$HMC_USER@$HMC_HOST" "$@"
}

VRCMD() {
  local vios="$1"; shift
  H "viosvrcmd -m $MS -p $vios -c '$*'"
}

ensure_once() {
  local marker="$1"
  local dir=/var/tmp/vios-autoconfig
  mkdir -p "$dir"
  local file="$dir/$marker"
  if [ -e "$file" ]; then
    log info "Marker $marker exists, skipping"
    return 1
  fi
  touch "$file"
  return 0
}
