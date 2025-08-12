#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

##----------Magento command----------##

# check is current directory is magento
ism2dir() {
  if [ -f "$PWD/bin/magento" ]; then
    return 0 #true
  fi
  return 1 # false
}
_print_msg_not_m2_dir() {
  echo "${_BOLD}${_YELLOW}Notice:${_RESET} Current directory is not the magento folder"
}

#---Alias with Nginx multiple php
m2() {
  $(_phpVer) bin/magento "$@"
}
alias cc='m2 cache:clean'
alias cf='m2 cache:flush'
alias sdc='m2 setup:di:compile'
alias ssd='m2 setup:static-content:deploy'
alias seup='m2 setup:upgrade'
alias sup='m2 setup:upgrade'

_phpVer() {
  _m2phpVer
}
# Helper: validate PHP version format (phpx.y)
_is_php_version_format() {
  local ver="$1"
  [[ "$ver" =~ ^php[0-9]+\.[0-9]+$ ]]
}

_m2phpVer() {
  # If not inside a Magento 2 directory, return default "php"
  ! ism2dir && echo 'php' && return

  local fileDir="$ZTMDIR/local/magento/"
  local file="$fileDir/php_version"
  local projectDir="$PWD"
  local newVer="$1"

  # Ensure directory and file exist
  [ ! -d "$fileDir" ] && mkdir -p "$fileDir"
  [ ! -f "$file" ] && touch "$file"

  # === WRITE MODE ===
  if [ -n "$newVer" ]; then
    # Remove existing line (if any)
    local escDir=${projectDir//\//\\/}
    sed -i "/^$escDir:/d" "$file"
    # Prepend new entry to top
    sed -i "1i $projectDir:$newVer" "$file"
    printf "Project PHP version set to ${_BOLD}%s" "$newVer"
    return 0
  fi

  # === READ MODE ===
  local currentVer
  currentVer=$(grep "^$projectDir:" "$file" | cut -d':' -f2)
  if [ -n "$currentVer" ]; then
    echo "$currentVer"
    return 0
  fi
  printf "${_BOLD}${_RED}Error:${_RESET} No PHP version has been set for directory: %s\n" "$projectDir" >&2
  return 1
}

# Usage: m2-gen-php-version php8.1
m2-set-php-version() {
  if ism2dir; then
    # Check missing or invalid format in one block
    if [ -z "$1" ] || ! _is_php_version_format "$1"; then
      echo "${_RED}${_BOLD}Invalid or missing argument.${_RESET}"
      printf "%b\n" "Usage: m2-set-php-version phpx.y"
      printf "%b\n" "Example: m2-set-php-version php8.1"
      return 1
    fi
    _m2phpVer "$1"
  else
    _print_msg_not_m2_dir
    return 1
  fi
}

# netz98 magerun CLI tools for Magento 2 https://github.com/netz98/n98-magerun2
n98-m2() {
  "$(_phpVer)" /usr/local/bin/n98-magerun2.phar "$@"
}

##----------Completion----------##
[[ -f "$ZTMDIR/custom/completions/_magento" ]] && source "$ZTMDIR/custom/completions/_magento"
