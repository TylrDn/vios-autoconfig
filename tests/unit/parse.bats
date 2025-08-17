#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

@test "yaml_get returns value" {
  run bash -lc '. ./lib/parse.sh; yaml_get tests/fixtures/map.yaml hmc.host'
  [ "$status" -eq 0 ]
  [ "$output" = "test-hmc.example.com" ]
}

@test "yaml_get returns exit code 3 when key missing" {
  run bash -lc '. ./lib/parse.sh; yaml_get tests/fixtures/map.yaml does.not.exist'
  [ "$status" -eq 3 ]
}
