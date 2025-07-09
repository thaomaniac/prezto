#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

### Aliases
alias update='sudo apt-get update'
alias autoremove='sudo apt-get autoremove'
alias autoclean='sudo apt-get autoclean'

#alias colorls command
if type "colorls" > /dev/null; then
  alias ls='colorls --indicator-style=none --color=never'
fi

## Upgrade package
#upgrade() {
#  if [ -z "$1" ]; then
#    echo "\e[1;31mMust specify 1 package\e[0m"
#    return 1
#  fi
#  sudo apt-get --only-upgrade install "$1"
#}
#
## Switch php version
#switch-php() {
#  if [ -z "$1" ]; then
#    sudo update-alternatives --config php
#  else
#    if [[ $1 =~ ^[0-9]\.[0-9]$ ]]; then #x.y # $1 == ?.?
#      sudo update-alternatives --set php /usr/bin/php"$1"
#    elif [[ $1 =~ ^[0-9]\[0-9]$ ]]; then #xy
#      # shellcheck disable=SC2001
#      sudo update-alternatives --set php /usr/bin/php"$(sed 's/./&./' <<<"$1")"
#    elif [[ $1 =~ ^php\[0-9]\.[0-9]$ ]]; then #phpx.y
#      sudo update-alternatives --set php /usr/bin/"$1"
#    else
#      sudo update-alternatives --set php /usr/bin/php"$1"
#    fi
#  fi
#}
#_list_all_php_ver() {
#  # shellcheck disable=SC2046
#  compadd $(update-alternatives --list php | sed "s/.*php//g") #sed 's/^.*php/php/
#}
#compdef _list_all_php_ver switch-php
#
## Restart service
#restart-service() {
#  sudo service "$1" restart
#}
#compdef _service restart-service
## compdef restart-service=service

## Reset trial phpstorm for old version <= 2021.*
#phpstorm_reset() {
#  rm -f ~/.config/JetBrains/PhpStorm*/options/other.xml
#  rm -rf ~/.config/JetBrains/PhpStorm*/eval
#  rm -rf ~/.java/.userPrefs
#}

## Kill process by name pattern
kill-process-name() {

  usage() {
    echo -e "${_BOLD}${_YELLOW}Usage:${_RESET} kill-process-name [-f] [-y] [-h] ${_BOLD}\"pattern\"${_RESET}" >&2
    echo -e "  ${_BOLD}-f${_RESET}  Force kill (SIGKILL instead of SIGTERM)"
    echo -e "  ${_BOLD}-y${_RESET}  Skip confirmation prompt"
    echo -e "  ${_BOLD}-h${_RESET}  Show this help message"
  }

  local force=0
  local skip_confirm=0
  local pattern=""

  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
    -f) force=1 ;;
    -y) skip_confirm=1 ;;
    -h) usage; return 0 ;;
    -*)
      echo -e "${_RED}Unknown option: $arg${_RESET}" >&2
      return 1
      ;;
    *)
      if [[ -z "$pattern" ]]; then
        pattern="$arg"
      else
        echo -e "${_RED}Multiple patterns not supported${_RESET}" >&2
        return 1
      fi
      ;;
    esac
  done

  if [[ -z "$pattern" ]]; then
    usage
    return 1
  fi

  # Find matching processes
  local pids
  pids=$(pgrep -f "$pattern")

  if [[ -z "$pids" ]]; then
    echo -e "${_YELLOW}No matching processes found for pattern: ${_BLUE}\"$pattern\"${_RESET}"
    return 0
  fi

  # Display matching processes
  echo -e "${_GREEN}Matching processes for pattern: ${_BLUE}\"$pattern\"${_RESET}\n"
  ps -o user,pid,cmd -p "$(echo "$pids" | paste -sd, -)" || {
    echo -e "${_RED}Failed to display process information${_RESET}" >&2
    return 1
  }
  echo

  # Confirm action
  if [[ "$skip_confirm" -ne 1 ]]; then
    printf "${_YELLOW}Kill ALL these process(es)? [y/N]: ${_RESET}"
    read -r answer
    case "$answer" in
    y | Y | yes | YES) ;;
    *)
      echo -e "${_RED}${_BOLD}Canceled by user.${_RESET}"
      return 0
      ;;
    esac
  fi

  # Determine signal
  local signal=""
  local signal_name="SIGTERM"
  if [[ "$force" -eq 1 ]]; then
    signal="-9"
    signal_name="SIGKILL"
  fi

  # Kill processes
  echo -e "${_YELLOW}Killing processes with signal $signal_name...${_RESET}"
  if echo "$pids" | xargs kill $signal 2> /dev/null; then
    echo -e "${_BOLD}${_GREEN}Completed.${_RESET}"
  else
    echo -e "${_RED}Some processes could not be killed (may require sudo)${_RESET}" >&2
    return 1
  fi
}
