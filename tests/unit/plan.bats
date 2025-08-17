#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

@test "plan_init creates file" {
  run bash -lc '. ./lib/common.sh; . ./lib/plan.sh; plan_init; [ -f "$PLAN_PATH" ] && echo ok'
  [ "$status" -eq 0 ]
  [ "$output" = ok ]
}

@test "plan_add appends line" {
  run bash -lc '. ./lib/common.sh; . ./lib/plan.sh; plan_init; plan_add "{\"action\":\"pin-hostkey\",\"host\":\"h\"}"; wc -l < "$PLAN_PATH"'
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}
