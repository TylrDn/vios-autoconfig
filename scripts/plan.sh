#!/usr/bin/env bash
# scripts/plan.sh - generate plan from map files
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR%/scripts}/lib/header.sh"
. "${SCRIPT_DIR%/scripts}/lib/parse.sh"
. "${SCRIPT_DIR%/scripts}/lib/plan.sh"

usage() { echo "Usage: $0 <map.yaml>"; }

main() {
  [ "$#" -eq 1 ] || { usage; exit 1; }
  local file="$1"
  plan_init
  if host="$(yaml_get "$file" hmc.host 2>/dev/null)"; then
    plan_add "{\"action\":\"pin-hostkey\",\"host\":\"$host\"}"
    log INFO "plan stored at $PLAN_PATH"
    echo "$PLAN_PATH"
  else
    die "missing hmc.host in $file"
  fi
}

main "$@"
