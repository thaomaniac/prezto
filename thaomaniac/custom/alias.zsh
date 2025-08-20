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
