#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=1
if [ "${APPLY:-0}" -eq 1 ]; then DRY_RUN=0; fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --help) echo "Usage: $0 [--dry-run]" >&2; exit 0;;
    *) shift;;
  esac
done

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

require_env MS VIOS1

H "lsmap -all -type vhost"
H "lsmap -all -npiv"
H "entstat -d sea0"
