#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "${BASH_SOURCE%/*}/.." && pwd)"

# ---- environment handling ---------------------------------------------------
load_env() {
  if [ -f "$REPO_ROOT/.env" ]; then
    local perm
    perm=$(stat -c '%a' "$REPO_ROOT/.env")
    if [ "$perm" != "600" ]; then
      echo "ERROR: .env must have 600 permissions" >&2
      exit 1
    fi
    set -a
    . "$REPO_ROOT/.env"
    set +a
  else
    read -r -p "HMC_HOST: " HMC_HOST
    read -r -p "HMC_USER: " HMC_USER
    export HMC_HOST HMC_USER
  fi
}

mask() {
  local s="$*"
  local v val
  for v in $(compgen -v | grep -E 'PASS|TOKEN|SECRET'); do
    val=${!v}
    [ -n "$val" ] && s=${s//${val}/****}
  done
  printf '%s' "$s"
}

# ---- logging ----------------------------------------------------------------
LOG_LEVEL=${LOG_LEVEL:-2} # 0=ERROR,1=WARN,2=INFO,3=DEBUG

log() {
  local level=$1; shift
  local level_num
  case $level in
    ERROR) level_num=0 ;;
    WARN)  level_num=1 ;;
    INFO)  level_num=2 ;;
    DEBUG) level_num=3 ;;
    *)     level_num=2 ;;
  esac
  if [ "$LOG_LEVEL" -ge "$level_num" ]; then
    printf '[%s] %s\n' "$level" "$*" >&2
  fi
}

# ---- flag parsing -----------------------------------------------------------
DRY_RUN=1
FORCE=0
AUTO_YES=0

parse_common_flags() {
  POSITIONAL=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --force) FORCE=1; shift ;;
      --yes) AUTO_YES=1; shift ;;
      --verbose) LOG_LEVEL=3; shift ;;
      --help) usage; exit 0 ;;
      --) shift; POSITIONAL+=("$@"); break ;;
      -*) POSITIONAL+=("$@"); break ;;
      *) POSITIONAL+=("$@"); break ;;
    esac
  done
}

# ---- helpers ----------------------------------------------------------------
require_env() {
  local missing=0
  for var in "$@"; do
    if [ -z "${!var:-}" ]; then
      log ERROR "Missing env var: $var"
      missing=1
    fi
  done
  [ "$missing" -eq 0 ] || exit 1
}

ensure_binary() {
  for b in "$@"; do
    if ! command -v "$b" >/dev/null 2>&1; then
      log ERROR "Missing required binary: $b"
      exit 1
    fi
  done
}

confirm() {
  local q="$1"
  if [ "$AUTO_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi
  read -r -p "$q [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

retry() {
  local retries=${RETRIES:-3}
  local delay=${RETRY_DELAY:-1}
  local attempt=0
  until "$@"; do
    rc=$?
    if [ "$attempt" -ge "$retries" ]; then
      return "$rc"
    fi
    attempt=$(( attempt + 1 ))
    log WARN "Retrying ($attempt/$retries)..."
    sleep "$delay"
  done
}

run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    log INFO "$(mask "$*")"
    return 0
  fi
  local out rc
  out=$(retry "$@" 2>&1) && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 255 ]; then
      log ERROR "$out"
      exit 2
    fi
    log ERROR "$out"
    exit 3
  fi
  [ "$LOG_LEVEL" -ge 3 ] && log DEBUG "$out"
}

hmc_cli() {
  require_env HMC_HOST HMC_USER
  ensure_binary ssh
  local ssh=(ssh)
  if [ -n "${SSH_OPTS:-}" ]; then
    # shellcheck disable=SC2206
    ssh+=($SSH_OPTS)
  fi
  ssh+=("$HMC_USER@$HMC_HOST" "$*")
  run_cmd "${ssh[@]}"
}

vios_cmd() {
  local vios="$1"; shift
  require_env MS
  hmc_cli "viosvrcmd -m \"$MS\" -p \"$vios\" -c '$*'"
}

enforce_marker() {
  local name="$1"
  local marker="/var/tmp/vios-autoconfig-${name}.marker"
  if [ -e "$marker" ] && [ "$FORCE" -eq 0 ]; then
    log INFO "Marker exists for $name"
    return 1
  fi
  mkdir -p "$(dirname "$marker")"
  : > "$marker"
  return 0
}
