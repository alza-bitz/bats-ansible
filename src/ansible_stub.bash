
__stub_remote() {
  local _format=$1 _exit=$2 _container _command=$4 _args
  IFS='|' read -a _container -r <<< $3
  shift 4
  _args=${@:-.*}
  container_exec $_container mkdir -p /tmp/stub
  # 2x ansible lineinfile to /tmp/stub/$_command
  # 1x ansible lineinfile to ~/.bash_profile (PATH)
  container_exec $_container chmod +x /tmp/stub/$_command
}

