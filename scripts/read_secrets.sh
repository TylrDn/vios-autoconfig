#!/usr/bin/env bash
# scripts/read_secrets.sh - load secrets from .env securely
set -euo pipefail
IFS=$'\n\t'
LC_ALL=C
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "${SCRIPT_DIR%/scripts}/lib/common.sh"

usage() { echo "Usage: $0 [env-file]"; }

main() {
  local env_file="${1:-.env}"
  load_env "$env_file"
  echo "HMC_HOST=$HMC_HOST"
  echo "HMC_USER=$HMC_USER"
  echo "HMC_SSH_KEY=$HMC_SSH_KEY"
}

main "$@"
