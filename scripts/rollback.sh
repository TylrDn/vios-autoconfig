#!/usr/bin/env bash
# scripts/rollback.sh - placeholder rollback handler
set -euo pipefail
IFS=$'\n\t'
LC_ALL=C
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() { echo "Usage: $0 <plan.jsonl>"; }

main() {
  [ "$#" -eq 1 ] || { usage; exit 1; }
  local plan="$1"
  [ -f "$plan" ] || die "plan not found: $plan"
  log INFO "rollback not implemented yet for $plan"
}

main "$@"
