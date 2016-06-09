#!/usr/bin/env bash

travis_startup() {
  local _project_path _container_path _container_id
  _project_path=${1:-$PWD}
  _container_path=/home/travis/${_project_path##*/}
  _container_id=$(docker run -d -v $_project_path:$_container_path quay.io/travisci/travis-ruby) || return $?
  printf '%s %s' $_container_id $_container_path
}

travis_exec_sh() {
  local _container=($1 $2) _cmd
  shift 2
  _cmd=$@
  docker exec -u travis ${_container[0]} bash -l -c "cd ${_container[1]}; $_cmd" || return $?
}

travis_cleanup() {
  local _container=($1 $2)
  docker stop ${_container[0]}
  docker rm ${_container[0]} 
}
