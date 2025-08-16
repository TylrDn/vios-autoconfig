#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=1
if [ "${APPLY:-0}" -eq 1 ]; then DRY_RUN=0; fi

usage(){ echo "Usage: $0 [--dry-run]" >&2; exit 1; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --help) usage;;
    *) usage;;
  esac
done

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

require_env MS VIOS1 BACKING_ETH TRUNK_ADAPTER VSWITCH SEA_VLAN

H "mkvdev -sea $BACKING_ETH -vadapter $TRUNK_ADAPTER -default -defaultid $SEA_VLAN -attr ha_mode=auto virt_adapters=$TRUNK_ADAPTER vswitch=$VSWITCH"
H "entstat -d sea0"

echo "SEA=sea0"
