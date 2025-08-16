#!/usr/bin/env bash
# scripts/verify.sh - display VIOS mappings
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 --vios <vios> [--dry-run]
Env: DRY_RUN=1 or APPLY=1; ./.env supplies HMC_* variables
EOF
}

VIOS=""
DRY_RUN="${DRY_RUN:-0}"; APPLY="${APPLY:-0}"

parse_flags "$@"

[[ -n "${VIOS}" ]] || { usage; exit 2; }
[[ "${VIOS}" =~ ^[A-Za-z0-9._:-]+$ ]] || die "Invalid VIOS: ${VIOS}"

common_init

run_hmc_vios "${VIOS}" "ioscli lsmap -all -type vhost"
run_hmc_vios "${VIOS}" "ioscli lsmap -all -npiv"
run_hmc_vios "${VIOS}" "ioscli entstat -d sea0"

