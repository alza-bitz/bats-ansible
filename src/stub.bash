
export PATH="$BATS_TEST_DIRNAME/stub:$PATH"

stub() {
  local _command=$1 _format=$2 _args
  shift 2
  _args=$@
  mkdir -p $BATS_TEST_DIRNAME/stub
  printf 'printf '\''%s'\'' "'$_args'"\n' "$_format" > $BATS_TEST_DIRNAME/stub/$_command 
  chmod +x $BATS_TEST_DIRNAME/stub/$_command
}

stub_err() {
  local _command=$1 _exit=${2:-1}
  mkdir -p $BATS_TEST_DIRNAME/stub
  printf 'exit %s\n' $_exit > $BATS_TEST_DIRNAME/stub/$_command
  chmod +x $BATS_TEST_DIRNAME/stub/$_command
}

stub_args() {
  local _command=$1
  mkdir -p $BATS_TEST_DIRNAME/stub
  cp "$(dirname "${BASH_SOURCE[0]}")"/stub/stub_args $BATS_TEST_DIRNAME/stub
  printf 'stub_args "$@"\n' > $BATS_TEST_DIRNAME/stub/$_command
  chmod +x $BATS_TEST_DIRNAME/stub/$_command
}

stub_args_record() {
  local _command=$1 _format=$2 _record_to
  _record_to=$(tmp_file_empty)
  mkdir -p $BATS_TEST_DIRNAME/stub
  cp "$(dirname "${BASH_SOURCE[0]}")"/stub/stub_args $BATS_TEST_DIRNAME/stub
  printf 'stub_args "$@" > %s\n' $_record_to > $BATS_TEST_DIRNAME/stub/$_command
  printf 'printf '\''%s'\''\n' "$_format" >> $BATS_TEST_DIRNAME/stub/$_command
  chmod +x $BATS_TEST_DIRNAME/stub/{$_command,stub_args}
  printf '%s' $_record_to
}

stub_cleanup() {
  rm -rf $BATS_TEST_DIRNAME/stub
}
