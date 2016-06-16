#!/usr/bin/env bats

load ../src/stub

stub_err 'something went wrong\n' 123 ssh-keygen

load ../load

@test 'container startup with ssh key not defined' {
  stub_err '' 123 docker
  stub_err '' 123 ansible
  run container_startup fedora
  [[ $status == 3 ]]
  [[ $output =~ 'something went wrong' ]]
}

teardown() {
  stub_cleanup
}
