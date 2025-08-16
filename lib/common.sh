#!/usr/bin/env bash
# lib/common.sh - shared safety, logging, and HMC helpers
# Follows Google Shell Style Guide & OWASP shell safety guidance.

set -euo pipefail
IFS=$'\n\t'
umask 077

# ---- Globals (readonly)
readonly APP_NAME="vios-autoconfig"
readonly STATE_DIR="/var/tmp/${APP_NAME}"
readonly LOCK_DIR="${STATE_DIR}/locks"
readonly LOG_DIR="${STATE_DIR}/logs"
readonly KNOWN_HOSTS="${STATE_DIR}/known_hosts"
readonly DEFAULT_SSH_OPTS=(
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
  -o UserKnownHostsFile="${KNOWN_HOSTS}"
  -o ConnectTimeout=10
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=3
)

mkdir -p "${LOCK_DIR}" "${LOG_DIR}"
: > "${LOG_DIR}/run.log"

# ---- Logging (redact sensitive values)
_redact() {
  sed -E 's/\b((passw(or)?d|token|secret|key)=)[^[:space:]]+/\1REDACTED/gi'
}
_ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
log() { printf '%s [%s] %s\n' "$(_ts)" "${1:-INFO}" "${*:2}" | _redact | tee -a "${LOG_DIR}/run.log" >&2; }
die() { log ERROR "$*"; exit 1; }

# ---- Require commands
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

# ---- Load .env (if present) and enforce required vars
load_env() {
  local env_file="${1:-.env}"
  if [[ -f "${env_file}" ]]; then
    # shellcheck disable=SC1090
    set -a; . "${env_file}"; set +a
  fi
  : "${HMC_HOST:?HMC_HOST is required}"
  : "${HMC_USER:?HMC_USER is required}"
  : "${HMC_SSH_KEY:?HMC_SSH_KEY is required}"
  [[ -f "${HMC_SSH_KEY}" ]] || die "HMC_SSH_KEY not found: ${HMC_SSH_KEY}"
  chmod 600 "${HMC_SSH_KEY}" 2>/dev/null || true
  export HMC_HOST HMC_USER HMC_SSH_KEY
}

# ---- Host key pinning (idempotent, hashed entries)
pin_hostkey() {
  require_cmd ssh-keyscan
  require_cmd ssh-keygen
  local host="$1"
  [[ "${host}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid HMC host: ${host}"
  touch "${KNOWN_HOSTS}"
  chmod 600 "${KNOWN_HOSTS}"
  if ! ssh-keygen -F "${host}" -f "${KNOWN_HOSTS}" >/dev/null 2>&1; then
    log INFO "Pinning SSH host key for ${host}"
    ssh-keyscan -T 5 -H "${host}" >>"${KNOWN_HOSTS}" 2>>"${LOG_DIR}/ssh-keyscan.log" || die "Failed to pin host key for ${host}"
  fi
}

# ---- Concurrency lock using flock
with_lock() {
  local name="$1"; shift
  local lock="${LOCK_DIR}/${name}.lock"
  exec 9>"${lock}"
  if ! flock -n 9; then
    die "Another process holds lock: ${name}"
  fi
  "$@"
}

# ---- Safe command runner (dry-run aware)
DRY_RUN="${DRY_RUN:-0}"
APPLY="${APPLY:-0}"
run() {
  if [[ "${DRY_RUN}" == "1" || "${APPLY}" != "1" ]]; then
    log INFO "[dry-run] $*"
    return 0
  fi
  log INFO "RUN: $*"
  "$@"
}

# ---- Build HMC command safely — SSH → viosvrcmd (no eval)
# Example: run_hmc_vios "vios1" "ioscli chdev -dev ent0 -attr jumbo_frames=yes"
run_hmc_vios() {
  require_cmd ssh
  local vios="$1"; shift
  local ios_cmd="$*"

  [[ "${vios}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid VIOS name: ${vios}"
  # Conservative injection guard (reject control chars, newlines, semicolons)
  [[ "${ios_cmd}" != *$'\n'* && "${ios_cmd}" != *";"* && "${ios_cmd}" != *$'\r'* ]] || die "Refusing unsafe command"

  local ssh_cmd=(ssh -i "${HMC_SSH_KEY}" "${DEFAULT_SSH_OPTS[@]}" "${HMC_USER}@${HMC_HOST}")
  local full=( "${ssh_cmd[@]}" -- viosvrcmd -m "${vios}" -c "${ios_cmd}" )

  if [[ "${DRY_RUN}" == "1" || "${APPLY}" != "1" ]]; then
    log INFO "[dry-run] ${full[*]}"
    return 0
  fi

  log INFO "HMC: ${vios} :: ${ios_cmd}"
  "${full[@]}" 2> >(tee -a "${LOG_DIR}/hmc.err" >&2) | tee -a "${LOG_DIR}/hmc.out"
}

# ---- Confirm destructive apply unless CI environment is set
confirm_apply() {
  if [[ "${APPLY}" == "1" && -z "${CI:-}" ]]; then
    read -r -p "About to APPLY changes — type 'apply' to continue: " ans
    [[ "${ans}" == "apply" ]] || die "User aborted"
  fi
}

# ---- Initialization helper
common_init() {
  load_env "${1:-.env}"
  pin_hostkey "${HMC_HOST}"
  require_cmd ssh
}

