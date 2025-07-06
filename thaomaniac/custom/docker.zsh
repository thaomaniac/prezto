#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

# Aliases
alias dk='docker'
alias dkc='docker compose'

#check the current directory is docker or is in the directory containing docker
# 0 true; 1 false
# shellcheck disable=SC2120
isDockerDir() {
  if [[ -z $IS_DOCKER_DIR ]]; then
    IS_DOCKER_DIR=1
    local current_directory
    current_directory=$(pwd)
    while [[ "$current_directory" != "/" ]]; do
      if [ -f "$current_directory/docker-compose.yml" ]; then
        DOCKER_ROOT=$current_directory
        IS_DOCKER_DIR=0
        break
      fi
      current_directory=$(dirname "$current_directory")
    done
  fi

  return "$IS_DOCKER_DIR"
}

_print_msg_not_docker_dir() {
  echo "${_BOLD}${_YELLOW}Notice:${_RESET} Current directory is not a docker environment."
}

# Load docker scripts and set up aliases
_docker_scripts_load() {
  [[ "$_DKCS_INITIALIZED" == true ]] && return

  # Define the function and aliases
  dkc-script() { _dkc-script "$@"; }
  alias dkc-composer=_composer-dkc composer-dkc=_composer-dkc
  # Set up completion for function and aliases
  compdef _dkc-script_completion dkc-script
  compdef composer-dkc=composer dkc-composer=composer

  # Dynamically create aliases for each script in the scripts directory
  # shellcheck disable=SC2139
  if [[ -d "$DOCKER_ROOT/scripts" ]]; then
    _DYNAMIC_DKCS_ALIASES=()
    # Iterate over each file in the scripts directory
    for f in "$DOCKER_ROOT/scripts/"*(^-/); do
      # Skip *.sh files
      [[ "$f" == *.sh ]] && continue
      local name="${f##*/}"
      alias "dkcs-$name"="dkc-script $name"
      _DYNAMIC_DKCS_ALIASES+=("dkcs-$name")
    done
    _DKCS_INITIALIZED=true
  fi
}

# Unload docker scripts and remove aliases
_docker_scripts_unload() {
  [[ "$_DKCS_INITIALIZED" != true ]] && return
  {
    # Remove function and its completion
    unfunction dkc-script
    unalias dkc-composer composer-dkc
    compdef -d dkc-script dkc-composer composer-dkc
    # Remove dynamically created script aliases
    ((${#_DYNAMIC_DKCS_ALIASES})) && unalias "${_DYNAMIC_DKCS_ALIASES[@]}"
  } 2> /dev/null

  _DYNAMIC_DKCS_ALIASES=()
  _DKCS_INITIALIZED=false
}

# Initialize docker scripts based on current directory
_init_docker_scripts() {
  if isDockerDir; then
    _docker_scripts_load
  else
    _docker_scripts_unload
  fi
}

# Run a docker script from the scripts directory
_dkc-script() {
  if isDockerDir; then
    scriptCommand=$1
    shift
    "$DOCKER_ROOT/scripts/$scriptCommand" "$@"
  else
    _print_msg_not_docker_dir
    return 1
  fi
}

# Zsh completion for dkc-script
_dkc-script_completion() {
  # Verify we're in a docker project directory
  isDockerDir || return 1

  # Level 1 Completion: Script names
  if ((CURRENT == 2)) && [[ -d "$DOCKER_ROOT/scripts" ]]; then
    local -a scripts_with_desc

    # Process each script in the scripts directory
    for script in "$DOCKER_ROOT"/scripts/*(N); do
      # Extract description from script file (if exists)
      local desc=$(grep -m1 "^# *DESCRIPTION:" "$script" 2> /dev/null | sed 's/^# *DESCRIPTION: *//')

      # Only include scripts that have descriptions
      [[ -n "$desc" ]] && scripts_with_desc+=("${script:t}:$desc")
    done

    # Display available scripts with descriptions
    _describe 'Available scripts' scripts_with_desc

    # Level 2 Completion: Script actions
  elif ((CURRENT == 3)); then
    local script_name=${words[2]} # Get the script name from command line
    local script_path="$DOCKER_ROOT/scripts/$script_name"

    if [[ -f "$script_path" ]]; then
      local -a actions

      # Parse ACTION declarations from script file
      while IFS= read -r line; do
        if [[ "$line" =~ "^# *ACTION: ([^ ]+) +(.+)" ]]; then
          # Format: action:description
          actions+=("${match[1]}:${match[2]}")
        fi
      done < "$script_path"

      if ((${#actions[@]} > 0)); then
        # Show available actions with descriptions
        _describe 'Available actions' actions
      else
        # Fallback to file completion if no actions defined
        _files
      fi
    fi

    # Level 3+ Completion: Action arguments (placeholder for future extension)
  elif ((CURRENT >= 4)); then
    # Currently just suggests files, can be enhanced later
    _arguments \
      '*:files:_files' && return 0
  fi
}

# Get mapped php version
_dockerPhpVerFile() {
  local file="$DOCKER_ROOT/.php-map"
  local phpVer='php'

  if [ -f "$file" ]; then
    while IFS=":" read -r folder php_version || [[ -n "$folder" ]]; do
      if [[ "$PWD" == *"/$folder" ]]; then
        phpVer=$php_version
        break
      fi
    done < "$file"
  fi
  echo "$phpVer"
}

# Are there multiple projects or just one project?
_isMultiDocker() {
  isDockerDir
  if [ -f "$DOCKER_ROOT/.php-map" ]; then
    return 0 #true
  fi
  return 1 # false
}

# Run cmd in docker container
_docker_exec_cmd() {
  local cmd="$*"
  local phpService='php'
  local prj_dir prj_path workingDir

  if _isMultiDocker; then
    phpService="$(_dockerPhpVerFile)"
    prj_dir="${PWD##*/}"
  fi
  workingDir=$(docker inspect --format='{{.Config.WorkingDir}}' "$(docker compose ps -q "$phpService")")
  prj_path=$workingDir/$prj_dir

  docker compose exec -T "$phpService" bash -c "cd $prj_path && $cmd"
}

##---PHP Composer command with docker
_composer-dkc() {
  if isDockerDir; then
    _docker_exec_cmd "composer $*"
  else
    _print_msg_not_docker_dir && return 1
  fi
}

##---Magento command with docker
_m2-docker() {
  _docker_exec_cmd "bin/magento $* --ansi"
}

m2() {
  if isDockerDir; then
    _m2-docker "$@"
  else
    $(_phpVer) bin/magento "$@"
  fi
}

##---N98 Magerun2 command with docker
_n98-m2-docker() {
  _docker_exec_cmd "n98-magerun2.phar $* --ansi"
}

n98-m2() {
  if isDockerDir; then
    _n98-m2-docker "$@"
  else
    $(_phpVer) n98-magerun2.phar "$@"
  fi
}

## -- Hook to monitor directory changes
_chpwd_hook_handler() {
  unset IS_DOCKER_DIR && isDockerDir
  _init_docker_scripts
}
add-zsh-hook chpwd _chpwd_hook_handler && _chpwd_hook_handler
