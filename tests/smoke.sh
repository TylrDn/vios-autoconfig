#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
set -a
. ./.env.example
set +a

cmds=(
  "scripts/create_vscsi.sh app-lpar --dry-run"
  "scripts/map_scsi.sh app-lpar hdisk0 --dry-run"
  "scripts/create_npiv.sh db-lpar --slot 10 --dry-run"
  "scripts/create_sea.sh --dry-run"
  "scripts/verify.sh --dry-run"
)

fail=0
for c in "${cmds[@]}"; do
  echo "Running: $c"
  if ! out=$(eval "$c" 2>&1); then
    echo "Command failed: $c" >&2
    echo "$out" >&2
    fail=1
    continue
  fi
  if [ -z "$out" ]; then
    echo "No output for $c" >&2
    fail=1
  fi
  if echo "$out" | grep -q "Missing env"; then
    echo "Missing env detected for $c" >&2
    fail=1
  fi
  echo "$out"
done

exit $fail
