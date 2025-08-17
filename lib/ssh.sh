#!/usr/bin/env bash
# lib/ssh.sh - thin wrapper around ssh enforcing default options
. "$(dirname "${BASH_SOURCE[0]}")/header.sh"

ssh_safe() {
  require_cmd ssh
  local host="$1"
  shift
  pin_hostkey "$host"
  local ssh_opts=("${DEFAULT_SSH_OPTS[@]}")
  ssh "${ssh_opts[@]}" "$host" "$@"
}
