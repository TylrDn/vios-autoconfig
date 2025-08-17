#!/usr/bin/env bash
# scripts/apply.sh - apply a previously generated plan
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR%/scripts}/lib/header.sh"
. "${SCRIPT_DIR%/scripts}/lib/plan.sh"

usage() { echo "Usage: $0 <plan.jsonl>"; }

main() {
  [ "$#" -eq 1 ] || { usage; exit 1; }
  PLAN_PATH="$1"
  [ -f "$PLAN_PATH" ] || die "plan not found: $PLAN_PATH"
  confirm_apply
  plan_apply
}

main "$@"
