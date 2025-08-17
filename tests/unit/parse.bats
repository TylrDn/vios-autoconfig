#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

@test "yaml_get returns value" {
  run bash -lc '. ./lib/parse.sh; yaml_get tests/fixtures/map.yaml hmc.host'
  [ "$status" -eq 0 ]
  [ "$output" = "test-hmc.example.com" ]
}

@test "yaml_get returns missing key exit code when key missing" {
  missing_code=$(bash -lc '. ./lib/parse.sh; echo $YAML_GET_ERR_MISSING')
  run bash -lc '. ./lib/parse.sh; yaml_get tests/fixtures/map.yaml does.not.exist'
  [ "$status" -eq "$missing_code" ]
}

@test "yaml_get handles keys with dots" {
  run bash -lc '. ./lib/parse.sh; yaml_get tests/fixtures/map.yaml with\\.dot'
  [ "$status" -eq 0 ]
  [ "$output" = "dot-value" ]
}
