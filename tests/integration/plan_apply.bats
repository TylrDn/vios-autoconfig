#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

@test "plan and apply pin-hostkey" {
  run bash -lc 'PATH=tests/stubs:$PATH; plan=$(./scripts/plan.sh tests/fixtures/map.yaml); ./scripts/apply.sh "$plan"'
  [ "$status" -eq 0 ]
}
