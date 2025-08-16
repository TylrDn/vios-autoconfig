#!/usr/bin/env bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
}

@test "lib/common.sh loads without env (missing vars) -> fails" {
  run bash -c 'set -euo pipefail; IFS=$'"'\n\t'"'; tmp=$(mktemp); chmod 600 "$tmp"; . ./lib/common.sh; load_env "$tmp"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"HMC_HOST is required"* ]]
}

@test "dry-run does not execute commands" {
  run bash -lc 'DRY_RUN=1 APPLY=0; . ./lib/common.sh; run echo hi'
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run]"* ]]
}

