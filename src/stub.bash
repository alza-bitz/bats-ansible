
export PATH="$BATS_TEST_DIRNAME/stub:$PATH"

stub() {
  local _format=$1 _command=$2 _args
  shift 2
  _args=${@:-.*}
  mkdir -p $BATS_TEST_DIRNAME/stub
  [[ -f $BATS_TEST_DIRNAME/stub/$_command ]] || printf '#!/usr/bin/env bash\n' > $BATS_TEST_DIRNAME/stub/$_command
  printf '[[ $@ =~ %s ]] && printf '\''%s'\'' && exit\n' "$_args" "$_format" >> $BATS_TEST_DIRNAME/stub/$_command 
  chmod +x $BATS_TEST_DIRNAME/stub/$_command
}

stub_err() {
  local _format=$1 _command=$2 _exit=${3:-1}
  mkdir -p $BATS_TEST_DIRNAME/stub
  printf 'printf '\''%s'\'' && exit %s\n' "$_format" $_exit > $BATS_TEST_DIRNAME/stub/$_command
  chmod +x $BATS_TEST_DIRNAME/stub/$_command
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
