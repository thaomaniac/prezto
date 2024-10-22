#!/usr/bin/env zsh
################################################################################
# Copyright (c) 2024 thaomaniac  <thaomaniac@gmail.com>
################################################################################

## Aliases
alias gst='git status'

## Functions
# git commit with branch name as prefix
# commit message must be enclosed in quotation marks
commit() {
  # shellcheck disable=SC2155
  local branch=$(git-branch-current 2>/dev/null)
  if [ -z "$branch" ]; then
    echo "\e[1;31mUnknown branch name\e[0m"
    return 1
  fi
  if [[ $# != 1 ]]; then
    echo "\e[1;31mTypeScript Error:\e[0m Expected 1 arguments, but got $#!"
    return 1
  else
    # shellcheck disable=SC2155
    local msg=$(echo "$1" | cut -c1 | command tr a-z A-Z)$(echo "$1" | cut -c2-)
    git commit -m "$branch: $msg"
  fi
}
