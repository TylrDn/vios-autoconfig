#!/usr/bin/env bash
# scripts/bootstrap_known_hosts.sh - populate known_hosts from map files
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
  for file in "$@"; do
    [ -f "$file" ] || continue
    if host="$(yaml_get "$file" hmc.host 2>/dev/null)"; then
      log INFO "pinning hostkey for $host"
      pin_hostkey "$host"
    else
      log WARN "missing hmc.host in $file"
    fi
  done
}

main "$@"
