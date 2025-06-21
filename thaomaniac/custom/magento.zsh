#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 thaomaniac <thaomaniac@gmail.com>
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

##----------Completion----------##

_loadMagentoFilePathCompletion() {
  rootDir="$ZTMDIR/local/magento/completion"
  fileDir="$rootDir$PWD"
  filePath="$fileDir/m2_cli"
  n98filePath="$fileDir/n98_cli"
}
m2-gen-cli-completion() {
  if ism2dir; then
    _loadMagentoFilePathCompletion
    rm -f "$filePath" &&  #nocorrect rm -i
      mkdir "$fileDir" && #nocorrect /bin/mkdir -p
      m2 --raw --no-ansi list | sed "s/[[:space:]].*//g" >"$filePath"
  else
    _print_msg_not_m2_dir
    return 1
  fi
}

# magento
_magento_list_command() {
  #  m2 --raw --no-ansi list | sed "s/[[:space:]].*//g"
  _loadMagentoFilePathCompletion
  if [[ -s $filePath ]]; then
    cat "$filePath"
  fi
}
_magento_autocomplete() {
  if ism2dir; then
    # shellcheck disable=SC2154
    for word in "${words[@]:1}"; do
      if [[ $word != -* ]]; then
        curW=$word
        break
      fi
    done
    case "$curW" in
      module:enable)
        # shellcheck disable=SC2046
        compadd $(m2 module:status --disabled)
        return
        ;;
      module:disable)
        # shellcheck disable=SC2046
        compadd $(m2 module:status --enabled)
        return
        ;;
      indexer:reindex)
        # shellcheck disable=SC2046
        compadd $(m2 indexer:info | sed "s/[[:space:]].*//g")
        return
        ;;
      deploy:mode:set)
        compadd developer production default
        return
        ;;
      admin:user:create)
        compadd - --admin-user --admin-password --admin-email --admin-firstname --admin-lastname --magento-init-params
        return
        ;;
    esac
    # shellcheck disable=SC2046
    compadd $(_magento_list_command)
  fi
}
compdef _magento_autocomplete m2 bin/magento

# netz98 magerun CLI tools for Magento 2 https://github.com/netz98/n98-magerun2
n98-m2() {
  "$(_phpVer)" /usr/local/bin/n98-magerun2.phar "$@"
}

n98-m2-gen-cli-completion() {
  _loadMagentoFilePathCompletion
  if ism2dir; then
    rm -f "$n98filePath" && #nocorrect rm -i
      mkdir "$fileDir" &&   #nocorrect /bin/mkdir -p
      n98-m2 --raw --no-ansi list | sed "s/[[:space:]].*//g;/^$/d" >"$n98filePath"
  else
    rm -f "$rootDir/n98_cli" && #nocorrect rm -i
      mkdir "$rootDir" &&       #nocorrect /bin/mkdir -p
      n98-m2 --raw --no-ansi list | sed "s/[[:space:]].*//g;/^$/d" >"$rootDir/n98_cli"
    _print_msg_not_m2_dir
  fi
}

#compdef n98-magerun2.phar
_n98_magerun2_list_command() {
  _loadMagentoFilePathCompletion
  if ism2dir; then
    if [[ -s "$n98filePath" ]]; then
      cat "$n98filePath"
    fi
  else
    if [[ -s "$rootDir/n98_cli" ]]; then
      cat "$rootDir/n98_cli"
    fi
  fi
}

_n98_magerun2_autocomplete() {
  # shellcheck disable=SC2046
  compadd $(_n98_magerun2_list_command)
}
compdef _n98_magerun2_autocomplete n98-m2 n98-magerun2.phar
##----------END Completion----------##
