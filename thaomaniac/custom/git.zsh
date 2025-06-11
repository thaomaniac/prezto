#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 thaomaniac <thaomaniac@gmail.com>
#-------------------------------------------------------------------------------

## Aliases
alias gst='git status'

## Functions

# Git commit with branch name as prefix
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
#   gcmat -t "YYYY-MM-DD HH:MM:SS" -m "Commit message"
# Notes:
#   - Time should be in the format "YYYY-MM-DD HH:MM:SS"
#   - The commit will use this time as both AuthorDate and CommitDate
gcmat() {
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
      echo "❌ Invalid option. Usage: gcmat -t \"YYYY-MM-DD HH:MM:SS\" -m \"commit message\""
      return 1
      ;;
    esac
  done

  if [ -z "$date" ] || [ -z "$message" ]; then
    echo "Usage: gcmat -t \"YYYY-MM-DD HH:MM:SS\" -m \"commit message\""
    return 1
  fi

  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git commit -m "$message"
}

# Create a merge request (MR) or pull request (PR) URL
gmrcr() {
  local remote_name="origin"
  local source_branch
  local target_branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) # $(git branch --show-current 2>/dev/null)
  local open_browser=false

  usage="❌ Missing or invalid arguments.
 Usage:
   gmrcr -t <target_branch>                     # use current branch as source
   gmrcr -s <source_branch>                     # use current branch as target
   gmrcr -s <source_branch> -t <target_branch>  # specify both branches
   gmrcr -s<source_branch> -t<target_branch>    # specify both branches
   gmrcr <branch> -s <source_branch>            # positional branch = target
   gmrcr <branch> -t <target_branch>            # positional branch = source"

  # Parse args
  positional=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -s)
      # Case: flag -s followed by source branch (e.g., -s staging)
      source_branch="$2"
      shift 2
      ;;
    -t)
      # Case: flag -t followed by target branch (e.g., -t develop)
      target_branch="$2"
      shift 2
      ;;
    -s*)
      # Case: flag -s<value> style (e.g., -sstaging)
      source_branch="${1:2}"
      shift
      ;;
    -t*)
      # Case: flag -t<value> style (e.g., -tdevelop)
      target_branch="${1:2}"
      shift
      ;;
    -o | --open)
      # Flag: open in browser
      open_browser=true
      shift
      ;;
    -*)
      # Case: unknown flag (starts with - but not recognized)
      echo "$usage"
      return 1
      ;;
    *)
      # Case: positional argument (e.g., TM-007)
      positional="$1"
      shift
      ;;
    esac
  done

  if [[ -z "$source_branch" && -z "$target_branch" ]]; then
    echo "$usage"
    return 1
  fi

  # Assign positional if available
  if [[ -n "$positional" ]]; then
    if [[ -n "$source_branch" && -z "$target_branch" ]]; then
      target_branch="$positional"
    elif [[ -n "$target_branch" && -z "$source_branch" ]]; then
      source_branch="$positional"
    else
      echo "$usage"
      return 1
    fi
  fi

  [[ -n "$source_branch" ]] || source_branch="$current_branch"
  [[ -n "$target_branch" ]] || target_branch="$current_branch"

  echo "✔ Using source: $source_branch → target: $target_branch"

  local remote_url=$(git config --get remote."$remote_name".url)
  if [[ -z "$remote_url" ]]; then
    echo "❌ Remote '$remote_name' not found."
    return 1
  fi

  # Convert SSH URL to HTTPS
  if [[ "$remote_url" =~ ^git@ ]]; then
    # Convert git@host:user/repo.git -> https://host/user/repo
    remote_url=$(echo "$remote_url" | sed -E 's#git@([^:]+):#https://\1/#')
  fi
  remote_url=${remote_url%.git}

  # Build the MR/PR URL based on provider
  local merge_url=""
  if [[ "$remote_url" == *"gitlab"* ]]; then
    merge_url="$remote_url/-/merge_requests/new?merge_request%5Bsource_branch%5D=$source_branch&merge_request%5Btarget_branch%5D=$target_branch"
  elif [[ "$remote_url" == *"github"* ]]; then
    merge_url="$remote_url/compare/$target_branch...$source_branch?expand=1"
  else
    echo "❌ Unsupported Git provider: $remote_url"
    return 2
  fi

  # Print the final URL
  echo "To create a merge request from '$source_branch' into '$target_branch', visit:"
  echo "  $merge_url"
  if [[ "$open_browser" == true ]]; then
    command -v xdg-open >/dev/null && xdg-open "$merge_url" >/dev/null 2>&1
  fi
}
