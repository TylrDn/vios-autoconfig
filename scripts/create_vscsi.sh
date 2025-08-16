#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

usage() { echo "Usage: $0 <LPAR> [--dry-run]" >&2; exit 1; }

parse_flags "$@"
set -- "${ARGS[@]}"

[ "$#" -eq 1 ] || usage
LPAR="$1"

require_env MS VIOS1

if ! ensure_once "vscsi_$LPAR"; then
  log info "vSCSI pair for $LPAR already exists"
  echo "VHOST=existing"
  exit 0
fi

H "mkvdev -m \"$MS\" -r vscsi -s -p \"$VIOS1\" -a adapter_type=server,remote_lpar_name=$LPAR,remote_slot_num=auto"
H "lsmap -all -type vhost | grep -i \"$LPAR\""

echo "VHOST=vhost?"
