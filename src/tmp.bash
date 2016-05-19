
[[ -v BATS_ANSIBLE_TMPDIR ]] || export BATS_ANSIBLE_TMPDIR=$(mktemp -d)

trap 'tmp_cleanup' EXIT

tmp_file() {
  local _contents="$@"
  [[ -n $_contents ]] || { printf 'tmp_file: valid content required\n' >&2; return 1; }
  local _tmp
  _tmp=$(mktemp -p $BATS_ANSIBLE_TMPDIR) && printf '%s' "$_contents" > $_tmp && printf $_tmp
}

tmp_file_empty() {
  mktemp -p $BATS_ANSIBLE_TMPDIR
}

tmp_cleanup() {
  rm -rf $BATS_ANSIBLE_TMPDIR
}
