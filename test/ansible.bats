#!/usr/bin/env bats

load ../load

@test 'container startup with valid container type' {
  stub 'some-container-id\n' docker
  stub 'localhost | SUCCESS => {}\n' ansible
  BATS_ANSIBLE_SSH_KEY=$(tmp_file_empty) run container_startup fedora
  [[ $output == 'container|localhost|5555|some-container-id' ]]
}

@test 'container startup with invalid container type' {
  stub_err docker
  stub_err ansible
  BATS_ANSIBLE_SSH_KEY=$(tmp_file_empty) run container_startup centos
  [[ $status == 3 ]]
}

@test 'container startup with ssh key not found' {
  stub_err docker
  stub_err ansible
  BATS_ANSIBLE_SSH_KEY=/does/not/exist run container_startup fedora
  [[ $status == 2 ]]
}

@test 'container startup with ssh timeout' {
  stub 'some-container-id\n' docker
  stub_err ansible
  BATS_ANSIBLE_SSH_KEY=$(tmp_file_empty) run container_startup fedora
  [[ $status == 5 ]]
}

@test 'container startup with valid container type and container name' {
  stub 'some-container-id\n' docker
  stub 'localhost | SUCCESS => {}\n' ansible
  BATS_ANSIBLE_SSH_KEY=$(tmp_file_empty) run container_startup fedora some-container
  [[ $output == 'some-container|localhost|5555|some-container-id' ]]
}

@test 'container cleanup with one container' {
  stub 'some-container-id\n' docker
  run container_cleanup
  [[ $status == 0 ]]
}

@test 'container cleanup with no containers' {
  stub '\n' docker
  run container_cleanup
  [[ $status == 0 ]]
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
  _tmp=$(stub_and_record 'container | SUCCESS => {}\nstdout from some-module\n' ansible)
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

@test 'container exec module with module name and args' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_and_record 'container | SUCCESS => {}\nstdout from some-module\n' ansible)
  run container_exec_module $_container some-module "arg-one=val-one arg-two='val two'"
  [[ $output =~ 'stdout from some-module' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -m some-module ' ]]
  [[ $_args =~ " -a \"arg-one=val-one arg-two='val two'\"" ]]
}

@test 'print args' {
  run __print_args arg-one arg-two 'arg three' "arg four" -opt-a arg
  [[ $output == "arg-one arg-two 'arg three' 'arg four' -opt-a arg" ]]
}

@test 'print args with no args' {
  run __print_args
  [[ $output == "" ]]
}

@test 'container exec with no command' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  run container_exec $_container
  [[ $status > 0 ]]
}

@test 'container exec with command' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_and_record 'container | SUCCESS => {}\nstdout from some-command\n' ansible)
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
  _tmp=$(stub_and_record 'container | SUCCESS => {}\n' ansible)
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
  _tmp=$(stub_and_record 'container | SUCCESS => {}\n' ansible)
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
  _tmp=$(stub_and_record 'container | SUCCESS => {}\n' ansible)
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
