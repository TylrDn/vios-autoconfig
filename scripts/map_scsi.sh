#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=1
if [ "${APPLY:-0}" -eq 1 ]; then DRY_RUN=0; fi

usage(){ echo "Usage: $0 <LPAR> <hdiskN> [--dry-run]" >&2; exit 1; }

LPAR=""; DISK=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --help) usage;;
    *) if [ -z "$LPAR" ]; then LPAR="$1"; elif [ -z "$DISK" ]; then DISK="$1"; else break; fi; shift;;
  esac
done
[ -n "$LPAR" ] && [ -n "$DISK" ] || usage

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

require_env MS VIOS1

VHOST="vhost?"
H "lshwres -m $MS -r virtualio --rsubtype scsi -F phys_loc,client_lpar_name | grep $LPAR"
H "mkvdev -m $MS -vdev $DISK -vadapter $VHOST"
H "lsmap -vadapter $VHOST"

echo "MAPPED=$LPAR:$DISK"
