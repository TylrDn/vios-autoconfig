#!/usr/bin/env bash
# scripts/rollback.sh - placeholder rollback handler
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR%/scripts}/lib/header.sh"

usage() { echo "Usage: $0 <plan.jsonl>"; }

main() {
  [ "$#" -eq 1 ] || { usage; exit 1; }
  local plan="$1"
  [ -f "$plan" ] || die "plan not found: $plan"
  log INFO "rollback not implemented yet for $plan"
}

main "$@"
