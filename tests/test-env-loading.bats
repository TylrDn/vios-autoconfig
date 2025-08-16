#!/usr/bin/env bats

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

@test "load_env reads .env" {
  cp .env.example .env
  chmod 600 .env
  run bash -c '. lib/common.sh; load_env; echo "$HMC_HOST"'
  rm .env
  [ "$status" -eq 0 ]
  [ "$output" = "hmchost.example" ]
}

@test "require_env fails when variable missing" {
  run bash -c '. lib/common.sh; HMC_HOST=; require_env HMC_HOST'
  [ "$status" -eq 1 ]
}
