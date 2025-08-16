#!/usr/bin/env bash
# scripts/create_vscsi.sh - create vSCSI mapping for an LPAR via HMC/VIOS
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 --ms <managed-system> --vios <vios> --lpar <lpar> --server-slot <num> --client-slot <num> [--dry-run] [--apply]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

MS=""; VIOS=""; LPAR=""; S_SLOT=""; C_SLOT=""
DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ms) MS="$2"; shift 2 ;;
    --vios) VIOS="$2"; shift 2 ;;
    --lpar) LPAR="$2"; shift 2 ;;
    --server-slot) S_SLOT="$2"; shift 2 ;;
    --client-slot) C_SLOT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "${MS}" && -n "${VIOS}" && -n "${LPAR}" && -n "${S_SLOT}" && -n "${C_SLOT}" ]] || { usage; exit 2; }

# Validate tokens
for x in "${MS}" "${VIOS}" "${LPAR}"; do
  [[ "${x}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid name: ${x}"
done
[[ "${S_SLOT}" =~ ^[0-9]+$ && "${C_SLOT}" =~ ^[0-9]+$ ]] || die "Slots must be integers"

# Init + optional confirmation
common_init
confirm_apply

# Prevent duplicate by lock on LPAR mapping
with_lock "vscsi-${LPAR}-${S_SLOT}-${C_SLOT}" bash -c '
  # 1) Ensure server vhost exists on VIOS
  run_hmc_vios "'"${VIOS}"'" "ioscli mkvdev -r server -s vscsi -fbo -dev vhost'"${S_SLOT}"'"" || true
  # 2) Map to client
  run_hmc_vios "'"${VIOS}"'" "ioscli mkvscsi -vadapter vhost'"${S_SLOT}"' -client '"${LPAR}"' -clslot '"${C_SLOT}"'"
  # 3) Verify
  run_hmc_vios "'"${VIOS}"'" "ioscli lsmap -all -fmt :"
'
log INFO "vSCSI mapping ensured: ${VIOS}:vhost${S_SLOT} -> ${LPAR}:${C_SLOT}"

