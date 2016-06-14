#!/usr/bin/env bats

load ../src/stub

stub_err 'something went wrong\n' ssh-keygen

load ../load

@test 'container startup with ssh key not defined' {
  stub_err '' docker
  stub_err '' ansible
  run container_startup fedora
  [[ $status == 3 ]]
  [[ $output =~ 'something went wrong' ]]
}

teardown() {
  stub_cleanup
}
