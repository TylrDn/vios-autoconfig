#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=1
if [ "${APPLY:-0}" -eq 1 ]; then DRY_RUN=0; fi

usage(){ echo "Usage: $0 <LPAR> [--slot N] [--vios VIOSx] [--dry-run]" >&2; exit 1; }

LPAR=""; SLOT="auto"; VIOS="${VIOS1:-}";
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --slot) SLOT="$2"; shift 2;;
    --vios) VIOS="$2"; shift 2;;
    --help) usage;;
    *) LPAR="$1"; shift;;
  esac
done
[ -n "$LPAR" ] || usage

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

require_env MS
[ -n "$VIOS" ] || { log err "VIOS not set"; exit 1; }

H "chhwres -m $MS -r virtualio --rsubtype fc -o a -p $VIOS -s $SLOT -a adapter_type=server,remote_lpar_name=$LPAR"
H "chhwres -m $MS -r virtualio --rsubtype fc -o a -p $LPAR -s $SLOT -a adapter_type=client,remote_lpar_name=$VIOS"
H "lsmap -npiv"

echo "WWPNS=WWPN1,WWPN2"
