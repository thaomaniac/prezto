#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

###----------Agnoster theme - Rewrite Prompt components----------###

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    if [[ $PWD != "$HOME" ]]; then
      print -n "%{%k%F{green}%}\n❯%B_%b"
    else
      print -n "%{%k%F{green}%}❯%B_%b"
    fi
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

# Dir: current working directory
prompt_dir() {
  if [[ $PWD != "$HOME" ]]; then
    prompt_segment default default '%~'
  fi
  #prompt_segment default default ' %4c'
}

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    if [[ $PWD != "$HOME" ]]; then
      START_ICON=''
      _load_dir_icon
      prompt_segment default green "%(!.%{%F{white}%}.)$START_ICON "
    fi
  fi
}

# Icon for begin the prompt with Nerd Font
_load_dir_icon() {
  if [[ -s "$PWD/bin/magento" ]]; then
    START_ICON="\ue740" #
    return 1
  elif [[ -s "$PWD/docker-compose.yml" ]]; then
    START_ICON="\uf308" #
    return 1
  elif [[ $PWD/ == /home/* ]]; then
    START_ICON="\Uf02dc" #󰋜
    return 1
  elif [[ ! -w $PWD ]]; then
    local -i w=$?
    START_ICON=""
  else
    START_ICON="\uf31b" #
    #START_ICON="\uf07c" #
  fi
}
#➜

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} $PLUSMINUS"
    else
      color=green
      ref="%B${ref}%b \U2714"
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment default $color
    print -n " $ref"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  if [[ $RETVAL -eq 130 ]]; then
    symbols+="%{%F{default}%}$CROSS"
  elif [[ $RETVAL -ne 0 ]]; then
    symbols+="%{%F{red}%}$CROSS $CROSS $CROSS"
  fi
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment default default "$symbols\n"
}
