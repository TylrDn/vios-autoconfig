#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

usage(){ echo "Usage: $0 <LPAR> <hdiskN> [--dry-run]" >&2; exit 1; }

parse_flags "$@"
set -- "${ARGS[@]}"

[ "$#" -ge 2 ] || usage
LPAR="$1"; DISK="$2"; shift 2

require_env MS VIOS1

VHOST_CMD="lshwres -m \"$MS\" -r virtualio --rsubtype scsi -F phys_loc,client_lpar_name | grep ',"$LPAR"$' | cut -d, -f1"
if [ "$DRY_RUN" -eq 1 ]; then
  H "$VHOST_CMD"
  VHOST="vhost?"
else
  VHOST=$(H "$VHOST_CMD")
fi

log info "Mapping $DISK to $LPAR via $VHOST"
H "mkvdev -m \"$MS\" -vdev \"$DISK\" -vadapter \"$VHOST\""
H "lsmap -vadapter \"$VHOST\""

echo "MAPPED=$LPAR:$DISK"
