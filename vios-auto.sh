#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
. "$SCRIPT_DIR/lib/common.sh"

usage() {
cat <<USAGE
Usage: $0 [options] <subcommand> [args]

Subcommands:
  create-vscsi    Create a vSCSI adapter
  create-npiv     Create an NPIV mapping (placeholder)
  create-sea      Create a Shared Ethernet Adapter (placeholder)
  run-extension   Run script from extensions/ directory

Options:
  --dry-run       Show commands without executing (default)
  --force         Ignore idempotency markers
  --yes           Automatic yes to prompts
  --verbose       Increase logging
  --help          Show this help
USAGE
}

parse_common_flags "$@"
set -- "${POSITIONAL[@]}"
[ "$#" -gt 0 ] || { usage; exit 1; }
cmd="$1"; shift

# allow "subcommand --help" without loading environment
if [ "${1:-}" = "--help" ]; then
  case "$cmd" in
    create-vscsi)
      "$SCRIPT_DIR/scripts/create-vscsi.sh" --help ;;
    create-npiv)
      "$SCRIPT_DIR/scripts/create-npiv.sh" --help ;;
    create-sea)
      "$SCRIPT_DIR/scripts/create-sea.sh" --help ;;
    run-extension)
      echo "Usage: $0 run-extension <name> [args]" ;;
    *) usage ;;
  esac
  exit 0
fi

case "$cmd" in
  create-vscsi)
    load_env MS VIOS1
    "$SCRIPT_DIR/scripts/create-vscsi.sh" "$@" ;;
  create-npiv)
    load_env
    "$SCRIPT_DIR/scripts/create-npiv.sh" "$@" ;;
  create-sea)
    load_env
    "$SCRIPT_DIR/scripts/create-sea.sh" "$@" ;;
  run-extension)
    load_env
    [ "$#" -gt 0 ] || { log ERROR "Missing extension name"; exit 1; }
    "$SCRIPT_DIR/extensions/$1.sh" "${@:2}" ;;
  *)
    usage
    exit 1 ;;
 esac
