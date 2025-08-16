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

DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

parse_flags "$@"

VIOS="${FLAG_VIOS:-}"
LPAR="${FLAG_LPAR:-}"
VHOST="${FLAG_VHOST:-}"
DISK="${FLAG_DISK:-}"

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

