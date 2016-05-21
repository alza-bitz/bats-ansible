#!/usr/bin/env bats

load ../load

setup() {
  local IFS='|'
  container=$(container_startup fedora)
}

@test 'assert container started' {
  local IFS='|' _container
  _container=($container)
  docker ps -q --no-trunc | grep ${_container[3]}
}

@test 'container startup with invalid container type' {
  run container_startup centos
  [[ $status > 0 ]]
}

@test 'container exec with command that will not be found' {
  run container_exec $container some-command
  [[ $status > 0 ]]
}

teardown() {
# TODO need an api to 'cleanup all containers started for this test'
  local IFS='|' _container
  _container=($container)
  docker stop ${_container[3]} > /dev/null
  docker rm ${_container[3]} > /dev/null
}
