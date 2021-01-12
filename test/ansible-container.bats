#!/usr/bin/env bats

load ../load

@test 'container startup' {
  local _container _mounts
  _container=$(container_startup python)
  docker ps -q --no-trunc | grep $_container
}

@test 'container startup with image not found' {
  run container_startup xyz
  [[ $status > 0 ]]
}

@test 'container startup twice' {
  container_startup python
  container_startup python
}

@test 'container module exec ping' {
  local _container
  _container=$(container_startup python)
  run container_exec_module $_container ping
  [[ $status == 0 ]]
  [[ $output =~ SUCCESS.*changed.*false.*ping.*pong ]]
}

@test 'container exec with command not found' {
  local _container
  _container=$(container_startup python)
  run container_exec $_container some-command
  [[ $status > 0 ]]
  [[ $output =~ '/bin/sh: 1: some-command: not found' ]]
}

teardown() {
  docker ps -q -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker stop > /dev/null
  docker ps -q -a -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker rm > /dev/null
}
