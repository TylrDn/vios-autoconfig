#!/usr/bin/env bash
# Centralized header for all scripts: sets safe shell options and sources common helpers.
set -Eeuo pipefail
IFS=$' \t\n'
LC_ALL=C
umask 077

# Resolve library directory and source common.sh
_hdr_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "${_hdr_dir}/common.sh"
