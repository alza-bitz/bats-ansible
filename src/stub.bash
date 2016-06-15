
export PATH="$BATS_TEST_DIRNAME/stub:$PATH"

__stub() {
  local _format=$1 _exit=$2 _command=$3 _args
  shift 3
  _args=${@:-.*}
  mkdir -p $BATS_TEST_DIRNAME/stub
  [[ -f $BATS_TEST_DIRNAME/stub/$_command ]] || printf '#!/usr/bin/env bash\n' > $BATS_TEST_DIRNAME/stub/$_command
  printf '[[ $@ =~ %s ]] && printf '\''%s'\'' && exit %s\n' "$_args" "$_format" $_exit >> $BATS_TEST_DIRNAME/stub/$_command
  chmod +x $BATS_TEST_DIRNAME/stub/$_command
}

stub() {
  local _format=$1 _command=$2 _args
  shift 2
  _args=$@
  __stub "$_format" 0 $_command $_args 
}

stub_err() {
  __stub "$@"
}

stub_and_record() {
  local _format=$1 _command=$2 _record_to
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
