#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

usage(){ echo "Usage: $0 <LPAR> [--slot N] [--vios VIOSx] [--dry-run]" >&2; exit 1; }

parse_flags "$@"
set -- "${ARGS[@]}"

LPAR=""; SLOT="auto"; VIOS="${VIOS1:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --slot) SLOT="$2"; shift 2;;
    --vios) VIOS="$2"; shift 2;;
    *) [ -z "$LPAR" ] && LPAR="$1" || usage; shift;;
  esac
done
[ -n "$LPAR" ] || usage

require_env MS
[ -n "$VIOS" ] || { log err "VIOS not set"; exit 1; }

log info "Creating NPIV pair on $VIOS slot $SLOT for $LPAR"
H "chhwres -m \"$MS\" -r virtualio --rsubtype fc -o a -p \"$VIOS\" -s \"$SLOT\" -a adapter_type=server,remote_lpar_name=$LPAR"
H "chhwres -m \"$MS\" -r virtualio --rsubtype fc -o a -p \"$LPAR\" -s \"$SLOT\" -a adapter_type=client,remote_lpar_name=$VIOS"
H "lsmap -npiv"

echo "WWPNS=WWPN1,WWPN2"
