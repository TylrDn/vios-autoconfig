#!/usr/bin/env bash
# scripts/create_npiv.sh - create NPIV mapping between VIOS and LPAR
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR%/scripts}/lib/header.sh"

usage() {
  cat <<EOF
Usage: $0 --ms <managed-system> --vios <vios> --lpar <lpar> --slot <num> [--dry-run] [--apply]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

parse_flags "$@"

MS="${FLAG_MS:-}"
VIOS="${FLAG_VIOS:-}"
LPAR="${FLAG_LPAR:-}"
SLOT="${FLAG_SLOT:-}"

[[ -n "${MS}" && -n "${VIOS}" && -n "${LPAR}" && -n "${SLOT}" ]] || { usage; exit 2; }

for x in "${MS}" "${VIOS}" "${LPAR}"; do
  [[ "${x}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid name: ${x}"
done
[[ "${SLOT}" =~ ^[0-9]+$ ]] || die "Slot must be integer"

common_init
confirm_apply

with_lock "npiv-${MS}-${LPAR}-${SLOT}" bash -c '
  run_hmc chhwres -m '"${MS}"' -r virtualio --rsubtype fc -o a -p '"${VIOS}"' -s '"${SLOT}"' -a adapter_type=server,remote_lpar_name='"${LPAR}"''
  run_hmc chhwres -m '"${MS}"' -r virtualio --rsubtype fc -o a -p '"${LPAR}"' -s '"${SLOT}"' -a adapter_type=client,remote_lpar_name='"${VIOS}"''
  run_hmc_vios '"${VIOS}"' "ioscli lsmap -all -npiv"
'
log INFO "NPIV mapping ensured: ${VIOS}<->${LPAR} slot ${SLOT}"

