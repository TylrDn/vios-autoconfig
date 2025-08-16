#!/usr/bin/env bash
# scripts/create_sea.sh - create Shared Ethernet Adapter on a VIOS
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 --vios <vios> --backing <entX> --trunk <entY> --vswitch <switch> --vlan <id> [--dry-run] [--apply]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

VIOS=""; BACKING=""; TRUNK=""; VSWITCH=""; VLAN=""
DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vios) VIOS="$2"; shift 2 ;;
    --backing) BACKING="$2"; shift 2 ;;
    --trunk) TRUNK="$2"; shift 2 ;;
    --vswitch) VSWITCH="$2"; shift 2 ;;
    --vlan) VLAN="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "${VIOS}" && -n "${BACKING}" && -n "${TRUNK}" && -n "${VSWITCH}" && -n "${VLAN}" ]] || { usage; exit 2; }

for x in "${VIOS}" "${BACKING}" "${TRUNK}" "${VSWITCH}"; do
  [[ "${x}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid token: ${x}"
done
[[ "${VLAN}" =~ ^[0-9]+$ ]] || die "VLAN must be integer"

common_init
confirm_apply

with_lock "sea-${VIOS}" bash -c '
  run_hmc_vios "'"${VIOS}"'" "ioscli mkvdev -sea '"${BACKING}"' -vadapter '"${TRUNK}"' -default -defaultid '"${VLAN}"' -attr ha_mode=auto virt_adapters='"${TRUNK}"' vswitch='"${VSWITCH}"'"
  run_hmc_vios "'"${VIOS}"'" "ioscli entstat -d sea0"
'
log INFO "SEA created on ${VIOS} using ${BACKING}/${TRUNK} VLAN ${VLAN}"

