
export ANSIBLE_HOST_KEY_CHECKING=false

readonly BATS_ANSIBLE_TEST_RUN=$(set -o pipefail; (< /dev/urandom tr -dc 0-9 2>/dev/null || true) | head -c 5)

if [[ $BATS_ANSIBLE_TMPDIR && $BATS_ANSIBLE_TEST_RUN ]]
then
  readonly _SSH_KEY_RESULT=$(< /dev/zero ssh-keygen -q -N "" -f ${BATS_ANSIBLE_TMPDIR}/${BATS_ANSIBLE_TEST_RUN}_rsa 2>&1 || true)
  if [[ ! $_SSH_KEY_RESULT ]]
  then
    readonly BATS_ANSIBLE_SSH_KEY=${BATS_ANSIBLE_TMPDIR}/${BATS_ANSIBLE_TEST_RUN}_rsa
  fi
fi

__container_image() {
  local _container_type=$1
  local -A _images=([fedora]='alzadude/fedora-ansible-test:23')
  [[ -n ${_images[$_container_type]} ]] || return 1
  printf '%s' ${_images[$_container_type]}
}

__name_prefix() {
  local _checksum IFS=' '
  _checksum=($(cksum - <<< "$BATS_TEST_DIRNAME")) || return 1
  printf 'bats_ansible_%s' ${_checksum[0]}
}

__container_name() {
  local _name_prefix=$1 _host=$2
  printf '%s_%s_%s' $_name_prefix $BATS_ANSIBLE_TEST_RUN $_host
}

__container_volume() {
  local _name_prefix=$1 _path=$2 _path_enc=$2
  _path_enc=${_path_enc#/}
  _path_enc=${_path_enc//\//_}
  _path_enc=${_path_enc//./_}
  _path_enc=${_path_enc// /_}
  _path_enc=${_path_enc//-/_}
  _path_enc=${_path_enc,,}
  printf '%s_%s:%s' $_name_prefix $_path_enc $_path
}

container_startup() {
  [[ $# > 0 ]] || { printf 'container_startup: container type required\n' >&2; return 1; }
  [[ $BATS_ANSIBLE_TEST_RUN ]] || { printf 'container_startup: could not define BATS_ANSIBLE_TEST_RUN\n' >&2; return 2; }
  [[ $BATS_ANSIBLE_SSH_KEY ]] || { printf 'container_startup: could not define BATS_ANSIBLE_SSH_KEY: %s\n' "$_SSH_KEY_RESULT" >&2; return 3; }
  local _container_type=$1 _host=${2:-container}
  local _ssh_key_pub
  _ssh_key_pub=$(< ${BATS_ANSIBLE_SSH_KEY}.pub) || return 4
  local _container_image _name_prefix _container_name _container_ip
  _container_image=$(__container_image $_container_type) || \
    { printf "container_startup: unknown container type '%s'\n" $_container_type >&2; return 5; }
  _name_prefix=$(__name_prefix) || return $?
  local _container_id
  _container_id=$(docker run -d \
    --name $(__container_name $_name_prefix $_host) -l bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN \
    -e USERNAME=test -e AUTHORIZED_KEYS="$_ssh_key_pub" \
    -v $(__container_volume $_name_prefix /var/cache/dnf) -v $(__container_volume $_name_prefix /var/tmp) \
    $_container_image) || return 6
  _container_ip=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $_container_id) || \
    { printf 'container_startup: could not get container ip\n' >&2; return 7; }
  ansible localhost -m wait_for -a "port=22 host=$_container_ip search_regex=OpenSSH delay=1 timeout=10" > /dev/null || \
    { printf 'container_startup: timed out waiting for ssh\n' >&2; return 8; }
  printf '%s|%s|%s|%s' $_host $_container_ip 22 $_container_id
}

container_cleanup() {
  docker ps -q -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker stop > /dev/null
  docker ps -q -a -f label=bats_ansible_test_run=$BATS_ANSIBLE_TEST_RUN | xargs -r docker rm > /dev/null
}

container_inventory() {
  local IFS='|' _container
  _container=($1)
  [[ ${#_container[@]} == 4 ]] || { printf 'container_inventory: valid container required\n' >&2; return 1; }
  printf '%s ansible_host=%s ansible_port=%s\n' ${_container[0]} ${_container[1]} ${_container[2]}
}

__container_exec_module() {
  local IFS='|' _sudo=$1 _container _name=$3 _args=$4 _hosts
  _container=($2)
  [[ ${#_container[@]} == 4 ]] || { printf 'container_exec_module: valid container required\n' >&2; return 1; }
  _hosts=$(tmp_file $(container_inventory "${_container[*]}"))
  ANSIBLE_LIBRARY=../ \
    ansible ${_container[0]} --private-key $BATS_ANSIBLE_SSH_KEY -i $_hosts -u test ${_sudo:+-s} -m $_name ${_args:+-a} $_args
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
    if [[ ${_args[$_idx]} =~ [[:space:]] ]]
    then
      printf "'%s'" "${_args[$_idx]}"
    else
      printf '%s' ${_args[$_idx]}
    fi
    (( _idx == ${#_args[@]} - 1 )) || printf ' '
  done
}

__container_exec() {
  local IFS='|' _sudo=$1 _container _cmd _hosts
  _container=($2)
  [[ ${#_container[@]} == 4 ]] || { printf 'container_exec: valid container required\n' >&2; return 1; }
  _hosts=$(tmp_file $(container_inventory "${_container[*]}"))
  shift 2
  _cmd=$(__print_args $@)
  (set -o pipefail;
    ansible ${_container[0]} --private-key $BATS_ANSIBLE_SSH_KEY -i $_hosts -u test ${_sudo:+-s} -m shell -a "$_cmd" |
    sed -r -e '1!b' -e '/rc=[0-9]+/d')
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
  local IFS='|' _container _hosts _name=$2 _value=$3
  _container=($1)
  [[ ${#_container[@]} == 4 ]] || { printf 'container_dnf_conf: valid container required\n' >&2; return 1; }
  _hosts=$(tmp_file $(container_inventory "${_container[*]}"))
  ansible ${_container[0]} --private-key $BATS_ANSIBLE_SSH_KEY -i $_hosts -u test -s -m lineinfile -a \
    "dest=/etc/dnf/dnf.conf regexp='^$_name=\S+$' line='$_name=$_value'" > /dev/null
}

