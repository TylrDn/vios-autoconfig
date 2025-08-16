#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

usage(){ echo "Usage: $0 [--dry-run]" >&2; exit 1; }

parse_flags "$@"
set -- "${ARGS[@]}"
[ "$#" -eq 0 ] || usage

require_env MS VIOS1 BACKING_ETH TRUNK_ADAPTER VSWITCH SEA_VLAN

log info "Creating SEA on $VIOS1"
H "mkvdev -sea \"$BACKING_ETH\" -vadapter \"$TRUNK_ADAPTER\" -default -defaultid \"$SEA_VLAN\" -attr ha_mode=auto virt_adapters=\"$TRUNK_ADAPTER\" vswitch=\"$VSWITCH\""
H "entstat -d sea0"

echo "SEA=sea0"
