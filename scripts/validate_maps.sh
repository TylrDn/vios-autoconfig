#!/usr/bin/env bash
# scripts/validate_maps.sh - ensure map files meet minimal schema
set -euo pipefail
IFS=$'\n\t'
LC_ALL=C
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"
# shellcheck source=../lib/parse.sh
. "${SCRIPT_DIR%/scripts}/lib/parse.sh"

usage() { echo "Usage: $0 [maps/*.yaml]"; }

main() {
  [ "$#" -gt 0 ] || set -- maps/*.yaml
  local ok=1
  for file in "$@"; do
    [ -f "$file" ] || continue
    if yaml_get "$file" hmc.host >/dev/null 2>&1; then
      log INFO "validated $file"
    else
      log ERROR "$file missing hmc.host"
      ok=0
    fi
  done
  return $ok
}

main "$@"
