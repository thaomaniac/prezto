#!/usr/bin/env zsh
################################################################################
# Copyright (c) 2025 thaomaniac <thaomaniac@gmail.com>
################################################################################

## Aliases
alias gst='git status'

## Functions

# Git commit with branch name as prefix
#
# Usage:
#   commit "Commit message"

# Notes:
#   - Commit message must be enclosed in quotation marks
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

# Git commit with custom date
# Usage:
#   git_commit_at -t "YYYY-MM-DD HH:MM:SS" -m "Commit message"
#
# Notes:
#   - Time should be in the format "YYYY-MM-DD HH:MM:SS"
#   - The commit will use this time as both AuthorDate and CommitDate
gcommit_at() {
  local date="$1"
  local message="$2"

  # Parse flags for time (-t) and message (-m)
  while getopts "t:m:" opt; do
    case $opt in
      t)
        date="$OPTARG"
        ;;
      m)
        message="$OPTARG"
        ;;
      *)
        echo "❌ Invalid option. Usage: git_commit_at -t \"YYYY-MM-DD HH:MM:SS\" -m \"commit message\""
        return 1
        ;;
    esac
  done

  if [ -z "$date" ] || [ -z "$message" ]; then
    echo "Usage: git_commit_at -t \"YYYY-MM-DD HH:MM:SS\" -m \"commit message\""
    return 1
  fi

  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git commit -m "$message"
}
