
__stub_remote() {
  local _format=$1 _exit=$2 _container  _command=$4 _args
  IFS='|' read -a _container -r <<< $3
  shift 4
  _args=${@:-.*}
}

