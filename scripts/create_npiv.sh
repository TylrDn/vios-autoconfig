#!/usr/bin/env bash
# scripts/create_npiv.sh - create NPIV mapping between VIOS and LPAR
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 --ms <managed-system> --vios <vios> --lpar <lpar> --slot <num> [--dry-run] [--apply]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

MS=""; VIOS=""; LPAR=""; SLOT=""
DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ms) MS="$2"; shift 2 ;;
    --vios) VIOS="$2"; shift 2 ;;
    --lpar) LPAR="$2"; shift 2 ;;
    --slot) SLOT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "${MS}" && -n "${VIOS}" && -n "${LPAR}" && -n "${SLOT}" ]] || { usage; exit 2; }

for x in "${MS}" "${VIOS}" "${LPAR}"; do
  [[ "${x}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid name: ${x}"
done
[[ "${SLOT}" =~ ^[0-9]+$ ]] || die "Slot must be integer"

common_init
confirm_apply

run_hmc() {
  require_cmd ssh
  local cmd="$*"
  [[ "${cmd}" != *$'\n'* && "${cmd}" != *";"* && "${cmd}" != *$'\r'* ]] || die "Refusing unsafe command"
  local ssh_cmd=(ssh -i "${HMC_SSH_KEY}" "${DEFAULT_SSH_OPTS[@]}" "${HMC_USER}@${HMC_HOST}" -- "${cmd}")
  if [[ "${DRY_RUN}" == "1" || "${APPLY}" != "1" ]]; then
    log INFO "[dry-run] ${ssh_cmd[*]}"
    return 0
  fi
  log INFO "HMC: ${cmd}"
  "${ssh_cmd[@]}" 2> >(tee -a "${LOG_DIR}/hmc.err" >&2) | tee -a "${LOG_DIR}/hmc.out"
}

with_lock "npiv-${LPAR}-${SLOT}" bash -c '
  run_hmc "chhwres -m '"${MS}"' -r virtualio --rsubtype fc -o a -p '"${VIOS}"' -s '"${SLOT}"' -a adapter_type=server,remote_lpar_name='"${LPAR}"'"
  run_hmc "chhwres -m '"${MS}"' -r virtualio --rsubtype fc -o a -p '"${LPAR}"' -s '"${SLOT}"' -a adapter_type=client,remote_lpar_name='"${VIOS}"'"
  run_hmc_vios '"${VIOS}"' "ioscli lsmap -all -npiv"
'
log INFO "NPIV mapping ensured: ${VIOS}<->${LPAR} slot ${SLOT}"

