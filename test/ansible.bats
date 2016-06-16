#!/usr/bin/env bats

load ../src/stub

stub '' ssh-keygen

load ../load

@test 'container ssh key exported' {
  env | grep -q ^ANSIBLE_PRIVATE_KEY_FILE=${BATS_ANSIBLE_TMPDIR}/${BATS_ANSIBLE_TEST_RUN}_rsa
}

@test 'container startup with valid container type' {
  stub 'some-container-id\n' docker run
  stub 'localhost | SUCCESS => {}\n' ansible
  stub '1.2.3.4' docker inspect
  touch ${ANSIBLE_PRIVATE_KEY_FILE}.pub
  run container_startup fedora
  [[ $output == 'container|1.2.3.4|22|some-container-id' ]]
}

@test 'container startup with no container type' {
  stub_err '' 123 docker
  stub_err '' 123 ansible
  run container_startup
  [[ $status == 1 ]]
}

@test 'container startup with ssh pub key not readable' {
  stub_err '' 123 docker
  stub_err '' 123 ansible
  run container_startup fedora
  [[ $status == 4 ]]
}

@test 'container startup with invalid container type' {
  stub_err '' 123 docker
  stub_err '' 123 ansible
  touch ${ANSIBLE_PRIVATE_KEY_FILE}.pub
  run container_startup centos
  [[ $status == 5 ]]
}

@test 'container startup with docker run error' {
  stub_err 'something went wrong\n' 123 docker run
  stub_err '' 123 ansible
  touch ${ANSIBLE_PRIVATE_KEY_FILE}.pub
  run container_startup fedora
  [[ $status == 6 ]]
}

@test 'container startup with docker inspect error' {
  stub 'some-container-id\n' docker run
  stub_err 'something went wrong\n' 123 docker inspect
  stub_err '' 123 ansible
  touch ${ANSIBLE_PRIVATE_KEY_FILE}.pub
  run container_startup fedora
  [[ $status == 7 ]]
}

@test 'container startup with ssh timeout' {
  stub 'some-container-id\n' docker
  stub_err '' 123 ansible
  touch ${ANSIBLE_PRIVATE_KEY_FILE}.pub
  run container_startup fedora
  [[ $status == 8 ]]
}

@test 'container startup with valid container type and container name' {
  stub 'some-container-id\n' docker run
  stub 'localhost | SUCCESS => {}\n' ansible
  stub '1.2.3.4' docker inspect
  touch ${ANSIBLE_PRIVATE_KEY_FILE}.pub
  run container_startup fedora some-container
  [[ $output == 'some-container|1.2.3.4|22|some-container-id' ]]
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
  [[ ! $_args =~ ' -s ' ]]
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

@test 'container exec module with module name and sudo' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_and_record 'container | SUCCESS => {}\nstdout from some-module\n' ansible)
  run container_exec_module_sudo $_container some-module
  printf '%s\n' $output
  [[ $output =~ 'stdout from some-module' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -s ' ]]
  [[ $_args =~ ' -m some-module ' ]]
  [[ ! $_args =~ ' -a ' ]]
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
  _tmp=$(stub_and_record 'container | SUCCESS | rc=0 >>\nstdout from some-command\n' ansible)
  run container_exec $_container some-command
  [[ $output == 'stdout from some-command' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ ! $_args =~ ' -s ' ]]
  [[ $_args =~ ' -m shell ' ]]
  [[ $_args =~ ' -a some-command ' ]] 
}

@test 'container exec with command that fails' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  stub_err 'container | FAILED | rc=1 >>\n' 123 ansible
  run container_exec $_container some-command-that-fails
  [[ $status == 123 ]]
  [[ $output == '' ]]
}

@test 'container exec with command and ansible fails' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  stub_err 'container | UNREACHABLE! => {\n}' 123 ansible
  run container_exec $_container some-command
  [[ $status == 123 ]] 
  [[ $output == 'container | UNREACHABLE! => {'$'\n''}' ]]
}

@test 'container exec with command that has no output' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_and_record 'container | SUCCESS | rc=0 >>\n' ansible)
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
  _tmp=$(stub_and_record 'container | rc=0 >>\n' ansible)
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

@test 'container exec with command and sudo' {
  local _container='container|some-ssh-host|some-ssh-port|some-container-id'
  local _tmp _args_record _args
  _tmp=$(stub_and_record 'container | SUCCESS | rc=0 >>\nstdout from some-command\n' ansible)
  run container_exec_sudo $_container some-command
  [[ $output == 'stdout from some-command' ]]
  IFS=$'\n' _args_record=($(< $_tmp))
  [[ ${#_args_record[@]} == 1 ]]
  _args=${_args_record[0]}
  [[ $_args =~ ^container ]]
#  [[ $_args =~ "-i \S+" ]]
  [[ $_args =~ ' -u test ' ]]
  [[ $_args =~ ' -s ' ]]
  [[ $_args =~ ' -m shell ' ]]
  [[ $_args =~ ' -a some-command ' ]]
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
