#!/usr/bin/env bats

load ../load

@test 'container startup with valid container type' {
  stub docker 'some-container-id\n'
  stub ansible 'localhost | SUCCESS => {}\n'
  run container_startup fedora
  [[ $status > 0 ]]
}

@test 'container startup with valid container type' {
  stub docker 'some-container-id\n'
  stub ansible 'localhost | SUCCESS => {}\n'
  run container_startup fedora
  [[ $output == 'container|localhost|5555|some-container-id' ]]
}

@test 'container startup with invalid container type' {
  stub docker 'some-container-id\n'
  stub ansible 'localhost | SUCCESS => {}\n'
  run container_startup centos
  printf '%s\n' $output
  [[ $status > 0 ]]
}

@test 'container startup with valid container type and container name' {
  stub docker 'some-container-id\n'
  stub ansible 'localhost | SUCCESS => {}\n'
  run container_startup fedora some-container
  [[ $output == 'some-container|localhost|5555|some-container-id' ]]
}

@test 'container cleanup with valid container' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  stub docker 'some-container-id\n'
  run container_cleanup $_container
  [[ $status == 0 ]]
}

@test 'container cleanup with no container' {
#  stub docker 'No such container' 1
  run container_cleanup
  [[ $status > 0 ]]
}

@test 'container inventory with valid container' {
  run container_inventory 'container|some-ssh-host|some-ssh-port|some-container-id'
  [[ $output == 'container ansible_host=some-ssh-host ansible_port=some-ssh-port' ]]
}

@test 'container inventory with invalid container' {
  run container_inventory 'container|some-ssh-host|some-ssh-port'
  [[ $status > 0 ]]
}

@test 'container inventory with no container' {
  run container_inventory
  [[ $status > 0 ]]
}

@test 'container exec module with no module name' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  run container_exec $_container
  [[ $status > 0 ]]
}

@test 'container exec module with module name' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_args_record ansible 'container | SUCCESS => {}\nstdout from some-module\n')
  run container_exec_module $_container some-module
  [[ $output =~ 'stdout from some-module' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -m some-module ' ]]
  [[ ! $_args =~ ' -a ' ]]
}

@test 'print args' {
  run print_args arg-one arg-two 'arg three' "arg four" -opt-a arg
  [[ $output == "arg-one arg-two 'arg three' 'arg four' -opt-a arg" ]]
}

@test 'container exec with no command' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  run container_exec $_container
  [[ $status > 0 ]]
}

@test 'container exec with command' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_args_record ansible 'container | SUCCESS => {}\nstdout from some-command\n')
  run container_exec $_container some-command
  [[ $output == 'stdout from some-command' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -m shell ' ]]
  [[ $_args =~ ' -a some-command ' ]] 
}

@test 'container exec with command that has no output' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_args_record ansible 'container | SUCCESS => {}\n')
  run container_exec $_container some-command
  [[ $output == '' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -m shell ' ]]
  [[ $_args =~ ' -a some-command ' ]]
}

@test 'container exec with command that has args' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_args_record ansible)
  container_exec $_container some-command arg-one arg-two 'arg three' "arg four" -opt-a arg
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -m shell ' ]]
  [[ $_args =~ " -a \"some-command arg-one arg-two 'arg three' 'arg four' -opt-a arg\" " ]] 
}

@test 'container dnf conf' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_args_record ansible)
  container_dnf_conf $_container some-key some-value
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -s ' ]]
  [[ $_args =~ ' -m lineinfile ' ]]
  [[ $_args =~ " -a \"dest=/etc/dnf/dnf.conf regexp='^some-key=\S+$' line='some-key=some-value'\" " ]]
}

@test 'container dnf conf with no conf value' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  run container_dnf_conf $_container some-key
  [[ $status > 0 ]]
}

@test 'container dnf conf with no conf key or value' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  run container_dnf_conf $_container
  [[ $status > 0 ]]
}

teardown() {
  stub_cleanup
}
