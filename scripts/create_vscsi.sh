#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=1
if [ "${APPLY:-0}" -eq 1 ]; then
  DRY_RUN=0
fi

usage() { echo "Usage: $0 <LPAR> [--dry-run]" >&2; exit 1; }

LPAR=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ; shift ;;
    --help) usage ;;
    *) LPAR="$1" ; shift ; break ;;
  esac
done

[ -n "$LPAR" ] || usage

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

require_env MS VIOS1

if ! ensure_once "vscsi_$LPAR"; then
  echo "VHOST=existing"
  exit 0
fi

H "mkvdev -m $MS -r vscsi -s -p $VIOS1 -a adapter_type=server,remote_lpar_name=$LPAR,remote_slot_num=auto"
H "lsmap -all -type vhost | grep -i $LPAR"

echo "VHOST=vhost?"
