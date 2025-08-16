#!/usr/bin/env bats

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  export PATH="$PWD/tests/mocks/bin:$PATH"
  export HMC_HOST=host HMC_USER=user MS=ms VIOS1=vios1
  export TMPDIR="$BATS_TEST_TMPDIR"
}

@test "--dry-run logs commands" {
  run scripts/create-vscsi.sh --dry-run --target foo
  [ "$status" -eq 0 ]
  [[ "$output" =~ mkvdev ]]
}

@test "idempotency marker prevents duplicate run" {
  run scripts/create-vscsi.sh --dry-run --target bar
  [ "$status" -eq 0 ]
  run scripts/create-vscsi.sh --dry-run --target bar
  [ "$status" -eq 0 ]
  [[ "$output" =~ already\ exists ]]
}

@test "vios_cmd uses viosvrcmd" {
  run bash -c '. lib/common.sh; vios_cmd vios1 "lsmap -all"'
  [ "$status" -eq 0 ]
  [[ "$output" =~ viosvrcmd ]]
}
