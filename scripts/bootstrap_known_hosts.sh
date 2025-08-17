#!/usr/bin/env bash
# scripts/bootstrap_known_hosts.sh - populate known_hosts from map files
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR%/scripts}/lib/header.sh"
. "${SCRIPT_DIR%/scripts}/lib/parse.sh"

usage() { echo "Usage: $0 [maps/*.yaml]"; }

main() {
  [ "$#" -gt 0 ] || set -- maps/*.yaml
  local -a hosts=()
  local file host
  for file in "$@"; do
    [ -f "$file" ] || continue
    if host="$(yaml_get "$file" hmc.host 2>/dev/null)"; then
      hosts+=("$host")
    else
      log WARN "missing hmc.host in $file"
    fi
  done

  if [ "${#hosts[@]}" -gt 0 ]; then
    declare -A seen=()
    local -a unique_hosts=()
    for host in "${hosts[@]}"; do
      if [[ -z "${seen[$host]:-}" ]]; then
        unique_hosts+=("$host")
        seen[$host]=1
      fi
    done
    for host in "${unique_hosts[@]}"; do
      log INFO "pinning hostkey for $host"
      pin_hostkey "$host"
    done
  fi
}

main "$@"
