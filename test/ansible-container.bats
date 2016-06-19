#!/usr/bin/env bats

load ../load

@test 'assert container started' {
  local IFS='|' _container
  _container=($(container_startup fedora))
  docker ps -q --no-trunc | grep ${_container[3]}
}

@test 'assert container volumes' {
  local IFS='|' _container _mounts
  _container=($(container_startup fedora))
  _mounts=($(docker inspect -f '{{ range .Mounts }}{{ .Destination }}|{{ end }}' ${_container[3]}))
  [[ ${#_mounts[@]} == 2 ]]
  [[ "|${_mounts[*]}|" =~ |/var/cache/dnf| ]]
  [[ "|${_mounts[*]}|" =~ |/var/tmp| ]]
}

@test 'container startup with invalid container type' {
  run container_startup centos
  [[ $status > 0 ]]
}

@test 'container startup twice with different host names' {
  container_startup fedora container-one
  container_startup fedora container-two
}

@test 'container startup twice with duplicate host names' {
  run container_startup fedora
  run container_startup fedora
  [[ $status > 0 ]]
}

@test 'container module exec ping' {
  local _container
  _container=$(container_startup fedora)
  run container_exec_module $_container ping
  [[ $status == 0 ]]
  [[ $output =~ SUCCESS.*changed.*false.*ping.*pong ]]
}

@test 'container exec with command not found' {
  local _container
  _container=$(container_startup fedora)
  run container_exec $_container some-command
  [[ $status > 0 ]]
  [[ $output =~ 'command not found' ]]
}

teardown() {
  docker ps -q -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker stop > /dev/null
  docker ps -q -a -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker rm > /dev/null
}
