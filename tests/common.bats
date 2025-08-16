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

@test "parse_flags isolates variables" {
  run bash -lc 'set -euo pipefail; IFS=$'"'\n\t'"'; . ./lib/common.sh; parse_flags --path /tmp --foo bar; [[ "$PATH" != "/tmp" && "$FLAG_FOO" == "bar" && "$FLAG_PATH" == "/tmp" ]] && echo ok'
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "run_hmc rejects unsafe metacharacters" {
  run bash -lc 'set -euo pipefail; IFS=$'"'\n\t'"'; tmp=$(mktemp); chmod 600 "$tmp"; HMC_HOST=h HMC_USER=u HMC_SSH_KEY="$tmp" DRY_RUN=1 APPLY=1; . ./lib/common.sh; run_hmc ls "|" wc'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Refusing unsafe command"* ]]
}

