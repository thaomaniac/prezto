#!/usr/bin/env zsh
################################################################################
# Copyright (c) 2024 thaomaniac  <thaomaniac@gmail.com>
################################################################################

#check the current directory is docker or is in the directory containing docker
# 0 true; 1 false
# shellcheck disable=SC2120
isDockerDir() {
  if [[ -z $IS_DOCKER_DIR || $1 == "-f" ]]; then
    IS_DOCKER_DIR=1
    local current_directory
    current_directory=$(pwd)
    while [[ "$current_directory" != "/" ]]; do
      if [ -f "$current_directory/docker-compose.yml" ]; then
        DOCKER_ROOT=$current_directory
        IS_DOCKER_DIR=0
      fi
      current_directory=$(dirname "$current_directory")
    done
  fi

  return "$IS_DOCKER_DIR"
}

_check_docker_dir() {
  unset IS_DOCKER_DIR
  isDockerDir
}
add-zsh-hook chpwd _check_docker_dir

dkc-script() {
  if isDockerDir; then
    scriptCommand=$1
    shift
    "$DOCKER_ROOT/scripts/$scriptCommand" "$@"
  else
    echo 'Current directory is not a docker environment, abort action!'
    return 1
  fi
}

# Define completion function for dkc-script
_dkc-script_completion() {
  if ! isDockerDir; then
    return
  fi
  local commands_xdebug
  commands_xdebug=(
    'enable:Enable Xdebug'
    'on:Enable Xdebug'
    'disable:Disable Xdebug'
    'off:Disable Xdebug'
    'status:Status Xdebug'
  )

  local commands_database
  commands_database=(
    'exec:Exec database'
    'create:Create database'
    'drop:Drop database'
    'import:Import database'
    'export:Export database'
    'list:List databases'
  )

  local commands=(
    'xdebug:Xdebug command description'
    'database:Database command description'
  )
  case ${words[2]} in
  xdebug)
    [[ ${#words[@]} -eq 3 || ${words[3]} == php* ]] && _describe 'xdebug command' commands_xdebug || _default
    ;;
  database)
    [[ ${#words[@]} -eq 3 ]] && _describe 'database command' commands_database || _default
    ;;
  *)
    _describe 'command' commands || _default
    ;;
  esac

}
compdef _dkc-script_completion dkc-script

##---Magento command with docker
_m2DockerPhpVerFile() {
  local file="$DOCKER_ROOT/.php-map"
  local phpVer='php'

  if [ -f "$file" ]; then
    while IFS=":" read -r folder php_version; do
      if [[ "$PWD" == *"/$folder" ]]; then
        phpVer=$php_version
        break
      fi
    done <"$file"
  fi
  echo "$phpVer"
}

_isMultiDocker() {
  isDockerDir
  if [ -f "$DOCKER_ROOT/.php-map" ]; then
    return 0 #true
  fi
  return 1 # false
}

_m2-docker() {
  local phpService='php'
  if _isMultiDocker; then
    ! ism2dir && _print_msg_not_m2_dir && return 1
    phpService=$(_m2DockerPhpVerFile)
    local lastDir=${PWD##*/}
    local m2_working_dir="$lastDir"
  fi
  local workingDir=$(docker inspect --format='{{.Config.WorkingDir}}' "$(docker compose ps -q "$phpService")")
  docker compose exec -T "$phpService" bash -c "cd $workingDir/$m2_working_dir && bin/magento $* --ansi"
}

_m2-normal() {
  eval "$(_phpVer)" bin/magento "$@"
}

m2() {
  if isDockerDir; then
    _m2-docker "$@"
  else
    _m2-normal "$@"
  fi
}

composer-dkc() {
  local phpService='php'
  if _isMultiDocker; then
    ! ism2dir && _print_msg_not_m2_dir && return 1
    phpService=$(_m2DockerPhpVerFile)
    local lastDir=${PWD##*/}
    local m2_working_dir="$lastDir"
  fi
  local workingDir=$(docker inspect --format='{{.Config.WorkingDir}}' "$(docker compose ps -q "$phpService")")
  docker compose exec "$phpService" bash -c "cd $workingDir/$m2_working_dir && composer $*"
}
compdef composer-dkc=composer
alias dkc-composer=composer-dkc
compdef dkc-composer=composer
