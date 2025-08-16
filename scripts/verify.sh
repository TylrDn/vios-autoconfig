#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

usage(){ echo "Usage: $0 [--dry-run]" >&2; exit 0; }

parse_flags "$@"
set -- "${ARGS[@]}"
[ "$#" -eq 0 ] || usage

require_env MS VIOS1

H "lsmap -all -type vhost"
H "lsmap -all -npiv"
H "entstat -d sea0"
