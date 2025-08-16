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

parse_flags() {
  DRY_RUN=1
  if [ "${APPLY:-0}" -eq 1 ]; then DRY_RUN=0; fi
  ARGS=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --apply) DRY_RUN=0 ;;
      --help) usage; exit 0 ;;
      *) ARGS+=("$1") ;;
    esac
    shift
  done
  if [ "$DRY_RUN" -eq 0 ]; then APPLY=1; else APPLY=0; fi
}

run_cmd() {
  if [ "${DRY_RUN:-1}" -eq 1 ]; then
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

H() {
  require_env HMC_HOST HMC_USER
  local ssh=(ssh)
  if [ -n "${SSH_OPTS:-}" ]; then
    # shellcheck disable=SC2206
    ssh+=($SSH_OPTS)
  fi
  ssh+=("$HMC_USER@$HMC_HOST")
  run_cmd "${ssh[@]}" "$*"
}

VRCMD() {
  local vios="$1"; shift
  local cmd
  printf -v cmd '%s ' "$@"
  cmd=${cmd% }
  H "viosvrcmd -m \"$MS\" -p \"$vios\" -c '$cmd'"
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
