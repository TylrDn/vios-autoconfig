#!/usr/bin/env bash
# scripts/create_sea.sh - create Shared Ethernet Adapter on a VIOS
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR%/scripts}/lib/header.sh"

usage() {
  cat <<EOF
Usage: $0 --vios <vios> --backing <entX> --trunk <entY> --vswitch <switch> --vlan <id> [--dry-run] [--apply]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

parse_flags "$@"

VIOS="${FLAG_VIOS:-}"
BACKING="${FLAG_BACKING:-}"
TRUNK="${FLAG_TRUNK:-}"
VSWITCH="${FLAG_VSWITCH:-}"
VLAN="${FLAG_VLAN:-}"

[[ -n "${VIOS}" && -n "${BACKING}" && -n "${TRUNK}" && -n "${VSWITCH}" && -n "${VLAN}" ]] || { usage; exit 2; }

for x in "${VIOS}" "${BACKING}" "${TRUNK}" "${VSWITCH}"; do
  [[ "${x}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid token: ${x}"
done
[[ "${VLAN}" =~ ^[0-9]+$ ]] || die "VLAN must be integer"

common_init
confirm_apply

with_lock "sea-${VIOS}-${VSWITCH}-${VLAN}" bash -c '
  run_hmc_vios "'"${VIOS}"'" "ioscli mkvdev -sea '"${BACKING}"' -vadapter '"${TRUNK}"' -default -defaultid '"${VLAN}"' -attr ha_mode=auto virt_adapters='"${TRUNK}"' vswitch='"${VSWITCH}"'"
  run_hmc_vios "'"${VIOS}"'" "ioscli entstat -d sea0"
'
log INFO "SEA created on ${VIOS} using ${BACKING}/${TRUNK} VLAN ${VLAN}"

