#!/usr/bin/env bats

load ../load

setup() {
  local IFS='|'
  container=($(container_startup 'bats-ansible' 'alzadude/fedora-ansible-test:23'))
}

@test 'assert container started' {
  docker ps -q --no-trunc | grep ${container[3]}
}

@test 'unknown image' {
  run container_startup 'bats-ansible-2' 'docker-image-that-does-not-exist'
  [[ $status > 0 ]]
}

teardown() {
# TODO need an api to 'cleanup all containers started for this test'
  docker stop ${container[3]} > /dev/null
  docker rm ${container[3]} > /dev/null
}
