#!/usr/bin/env bats

load ../load

readonly image="alzadude/bats-ansible-debian:buster"

@test 'container startup' {
  local _container
  _container=$(container_startup $image)
  docker ps -q --no-trunc | grep $_container
  docker exec $_container id test
}

@test 'container startup with image not found' {
  run container_startup xyz
  [[ $status > 0 ]]
}

@test 'container startup twice' {
  container_startup $image
  container_startup $image
}

@test 'container module exec ping' {
  local _container
  _container=$(container_startup $image)
  run container_exec_module $_container ping
  [[ $status == 0 ]]
  [[ $output =~ SUCCESS.*changed.*false.*ping.*pong ]]
}

@test 'container exec with command not found' {
  local _container
  _container=$(container_startup $image)
  run container_exec $_container some-command
  [[ $status > 0 ]]
  [[ $output =~ .*not.*found ]]
}

@test 'container exec sudo' {
  local _container
  _container=$(container_startup $image)
  run container_exec_sudo $_container id
  [[ $status == 0 ]]
  [[ $output =~ uid=0.*gid=0 ]]
}

teardown() {
  docker ps -q -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker stop > /dev/null
  docker ps -q -a -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker rm > /dev/null
}
