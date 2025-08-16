#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

usage() {
cat <<USAGE
Usage: $0 --target LPAR [options]

Options:
  --target NAME   Target client LPAR name
  --dry-run       Show commands without executing
  --force         Ignore idempotency marker
  --yes           Automatic yes to prompts
  --verbose       Increase logging
  --help          Show this help
USAGE
}

parse_common_flags "$@"
set -- "${POSITIONAL[@]}"

TARGET=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
  done

: "${TARGET:?--target required}"
require_env MS VIOS1
ensure_binary ssh

marker="vscsi-${TARGET}"
if ! enforce_marker "$marker"; then
  log INFO "vSCSI pair for $TARGET already exists"
  exit 0
fi

confirm "Create vSCSI adapter for $TARGET?" || exit 1

hmc_cli "mkvdev -m \"$MS\" -r vscsi -s -p \"$VIOS1\" -a adapter_type=server,remote_lpar_name=$TARGET,remote_slot_num=auto"
hmc_cli "lsmap -all -type vhost | grep -i \"$TARGET\""

log INFO "vSCSI setup complete for $TARGET"
