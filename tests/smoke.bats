#!/usr/bin/env bats

@test "repo has scripts" {
  run bash -lc 'test -d scripts && ls -1 scripts | wc -l'
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
