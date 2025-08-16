#!/usr/bin/env bash
# scripts/map_scsi.sh - map an hdisk to an LPAR via vhost
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 --vios <vios> --lpar <lpar> --vhost <vhost> --disk <hdiskN> [--dry-run] [--apply]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

VIOS=""; LPAR=""; VHOST=""; DISK=""
DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vios) VIOS="$2"; shift 2 ;;
    --lpar) LPAR="$2"; shift 2 ;;
    --vhost) VHOST="$2"; shift 2 ;;
    --disk) DISK="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "${VIOS}" && -n "${LPAR}" && -n "${VHOST}" && -n "${DISK}" ]] || { usage; exit 2; }

for x in "${VIOS}" "${LPAR}" "${VHOST}" "${DISK}"; do
  [[ "${x}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid token: ${x}"
done

common_init
confirm_apply

with_lock "map-${LPAR}-${DISK}" bash -c '
  run_hmc_vios "'"${VIOS}"'" "ioscli mkvdev -vdev '"${DISK}"' -vadapter '"${VHOST}"'"
  run_hmc_vios "'"${VIOS}"'" "ioscli lsmap -vadapter '"${VHOST}"'"
'
log INFO "Mapped ${DISK} to ${LPAR} via ${VHOST} on ${VIOS}"

