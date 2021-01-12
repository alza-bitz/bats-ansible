
export ANSIBLE_CONFIG=${BATS_TEST_DIRNAME}/ansible.cfg

readonly BATS_ANSIBLE_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd .. && pwd)"
readonly BATS_ANSIBLE_TEST_RUN=$(set -o pipefail; (< /dev/urandom tr -dc 0-9 2>/dev/null || true) | head -c 5)


container_testuser() {
  useradd -m test
}

container_wait() {
  [[ $# == 1 ]] || { printf 'container_wait: container required\n' >&2; return 1; }
  local _container=$1 _attempt=0
  while [[ $_attempt < 3 ]]
  do
    _attempt=$(( $_attempt + 1 ))
    _result=$(docker inspect -f {{.State.Running}} $_container)
    [[ $_result == "true" ]] && return 0
    sleep 0.5
  done
  return 2
}

container_startup() {
  [[ $# == 1 ]] || { printf 'container_startup: container image required\n' >&2; return 1; }
  [[ $BATS_ANSIBLE_TEST_RUN ]] || { printf 'container_startup: could not define BATS_ANSIBLE_TEST_RUN\n' >&2; return 2; }
  local _container_image=$1 _container_id
  _container_id=$(docker run --init -d \
    -v $BATS_ANSIBLE_DIR:/bats-ansible:ro,Z \
    -l bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN \
    $_container_image bash -c 'set -e; source /bats-ansible/load.bash; container_testuser; while true; do sleep 10000; done') || return 3
  container_wait $_container_id || { printf 'container_startup: timed out waiting for container to start\n' >&2; return 4; }
  printf '%s' $_container_id
}

container_cleanup() {
  docker ps -q -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker stop > /dev/null
  docker ps -q -a -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker rm > /dev/null
}

container_inventory() {
  [[ $# == 1 ]] || { printf 'container_inventory: container required\n' >&2; return 1; }
  local _host=$1
  printf 'container ansible_host=%s ansible_connection=docker\n' $_host
}

__container_exec_module() {
  local IFS='|' _sudo=$1 _container=$2 _name=$3 _args=$4 _hosts
  _hosts=$(tmp_file_empty)
  container_inventory $_container > $_hosts
  ANSIBLE_LIBRARY=${BATS_TEST_DIRNAME}/.. ansible container -i $_hosts -u test ${_sudo:+-s} -m $_name ${_args:+-a} $_args
}

container_exec_module() {
  [[ $# > 1 ]] || { printf 'container_exec_module: container, module name required\n' >&2; return 1; }
  __container_exec_module '' "$@"
}

container_exec_module_sudo() {
  [[ $# > 1 ]] || { printf 'container_exec_module_sudo: container, module name required\n' >&2; return 1; }
  __container_exec_module sudo "$@"
}

__print_args() {
  local _args=("$@")
  for _idx in ${!_args[@]}
  do
    if [[ ${_args[$_idx]} =~ [[:space:]\&] ]]
    then
      printf "'%s'" "${_args[$_idx]}"
    else
      printf '%s' ${_args[$_idx]}
    fi
    (( _idx == ${#_args[@]} - 1 )) || printf ' '
  done
}

__container_exec() {
  local _sudo=$1 _container=$2 _cmd=$3 _hosts
  _hosts=$(tmp_file_empty)
  container_inventory $_container > $_hosts
  shift 2
  _cmd=$(__print_args "$@")
  (set -o pipefail;
    ansible container -i $_hosts -u test ${_sudo:+-s} -m shell -a "$_cmd" | sed -r -e '1!b' -e '/rc=[0-9]+/d')
}

container_exec() {
  [[ $# > 1 ]] || { printf 'container_exec: container, command required\n' >&2; return 1; }
  __container_exec '' "$@"
}

container_exec_sudo() {
  [[ $# > 1 ]] || { printf 'container_exec_sudo: container, command required\n' >&2; return 1; }
  __container_exec sudo "$@"
}

container_dnf_conf() {
  [[ $# == 3 ]] || { printf 'container_dnf_conf: container, conf name, conf value required\n' >&2; return 1; }
  local _container=$1 _name=$2 _value=$3 _hosts
  _hosts=$(tmp_file_empty)
  container_inventory $_container > $_hosts
  ansible container -i $_hosts -u test -s -m lineinfile -a \
    "dest=/etc/dnf/dnf.conf regexp='^$_name=\S+$' line='$_name=$_value'" > /dev/null
}
