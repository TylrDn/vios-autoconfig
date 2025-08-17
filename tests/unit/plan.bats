#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

@test "plan_init creates file" {
  run bash -lc '. ./lib/plan.sh; plan_init; [ -f "$PLAN_PATH" ] && echo ok'
  [ "$status" -eq 0 ]
  [ "$output" = ok ]
}

@test "plan_add appends line" {
  run bash -lc '. ./lib/plan.sh; plan_init; plan_add "{\"action\":\"pin-hostkey\",\"host\":\"h\"}"; wc -l < "$PLAN_PATH"'
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "plan_add appends multiple lines" {
  run bash -lc '
    . ./lib/plan.sh;
    plan_init;
    plan_add "{\"action\":\"pin-hostkey\",\"host\":\"h1\"}";
    plan_add "{\"action\":\"pin-hostkey\",\"host\":\"h2\"}";
    plan_add "{\"action\":\"pin-hostkey\",\"host\":\"h3\"}";
    wc -l < "$PLAN_PATH"
  '
  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "plan_apply skips malformed JSON but processes valid entries" {
  run bash -lc '
    . ./lib/plan.sh;
    plan_init;
    plan_add "{\"action\":\"pin-hostkey\",\"host\":\"good.example\"}";
    echo "{this is: not json" >> "$PLAN_PATH";
    plan_add "{\"action\":\"pin-hostkey\",\"host\":\"good2.example\"}";
    pin_hostkey(){ echo "PIN:$1"; }
    export -f pin_hostkey
    plan_apply 2>&1 | grep "^PIN"
  '
  [ "$status" -eq 0 ]
  [ "$output" = $'PIN:good.example\nPIN:good2.example' ]
}

@test "plan_apply reports error on unknown action" {
  run bash -lc '
    . ./lib/plan.sh;
    plan_init;
    echo "{\"action\":\"totally-unknown\"}" >> "$PLAN_PATH";
    plan_apply
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown action: totally-unknown"* ]]
}
