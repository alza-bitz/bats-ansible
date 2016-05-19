#!/usr/bin/env bats

load ../load

@test 'temp dir env var' {
  [[ -v BATS_ANSIBLE_TMPDIR ]]
  [[ -d $BATS_ANSIBLE_TMPDIR ]]
}

@test 'temp file' {
  run tmp_file 'content'
  [[ -f $output ]]
  [[ $(dirname $output) == $BATS_ANSIBLE_TMPDIR ]]
  [[ $(<$output) == 'content' ]]
}

@test 'temp file with content that has whitespace' {
  run tmp_file 'content that has whitespace'
  [[ -f $output ]]
  [[ $(<$output) == 'content that has whitespace' ]]
}

@test 'temp file with content as multiple args' {
  run tmp_file content that has whitespace
  [[ -f $output ]]
  [[ $(<$output) == 'content that has whitespace' ]]
}

@test 'temp file with empty content' {
  run tmp_file ''
  [[ $status > 0 ]]
}

@test 'temp file with no content' {
  run tmp_file
  [[ $status > 0 ]]
}

