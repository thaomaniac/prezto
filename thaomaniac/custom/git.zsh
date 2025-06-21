#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 thaomaniac <thaomaniac@gmail.com>
#-------------------------------------------------------------------------------

## Aliases
unalias g 2>/dev/null
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
#   gcm-at -t "YYYY-MM-DD HH:MM:SS" -m "Commit message"
# Notes:
#   - Time should be in the format "YYYY-MM-DD HH:MM:SS"
#   - The commit will use this time as both AuthorDate and CommitDate
gcm-at() {

  usage() {
    echo "Usage: gcm-at -t \"YYYY-MM-DD HH:MM:SS\" -m \"commit message\""
    echo "  -t: Time for commit (format: YYYY-MM-DD HH:MM:SS)"
    echo "  -m: Commit message"
    echo "  -h: Show this help message"
  }

  local date message

  # Parse flags for time (-t) and message (-m)
  while getopts "t:m:h" opt; do
    case $opt in
    t)
      date="$OPTARG"
      ;;
    m)
      message="$OPTARG"
      ;;
    h)
      usage
      return 0
      ;;
    *)
      usage
      return 1
      ;;
    esac
  done

  # Check if both date and message are provided
  if [[ -z "$date" || -z "$message" ]]; then
    usage
    return 1
  fi

  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git commit -m "$message"
}

# Create a merge request (MR) or pull request (PR) URL
gmr-cr() {

  usage() {
    echo "Usage:
    gmrcr -t <target_branch>                     # use current branch as source
    gmrcr -s <source_branch>                     # use current branch as target
    gmrcr -s <source_branch> -t <target_branch>  # specify both branches
    gmrcr -s<source_branch> -t<target_branch>    # specify both branches
    gmrcr -o --open                              # open URL in browser"
  }

  local remote_name="origin"
  local source_branch
  local target_branch
  local current_branch
  local open_browser=false

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -s)
      source_branch="$2"
      shift 2
      ;;
    -t)
      target_branch="$2"
      shift 2
      ;;
    -s*)
      source_branch="${1:2}"
      shift
      ;;
    -t*)
      target_branch="${1:2}"
      shift
      ;;
    -o | --open)
      # Flag: open in browser
      open_browser=true
      shift
      ;;
    -h)
      usage
      return 0
      ;;
    -*)
      usage
      return 1
      ;;
    *)
      # ignore args
      shift
      ;;
    esac
  done

  if [[ -z "$source_branch" && -z "$target_branch" ]]; then
    usage
    return 1
  fi
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) # $(git branch --show-current 2>/dev/null)
  [[ -n "$source_branch" ]] || source_branch="$current_branch"
  [[ -n "$target_branch" ]] || target_branch="$current_branch"

  local remote_url
  remote_url=$(git config --get remote."$remote_name".url)
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
  case "$remote_url" in
  *gitlab*)
    merge_url="$remote_url/-/merge_requests/new?merge_request%5Bsource_branch%5D=$source_branch&merge_request%5Btarget_branch%5D=$target_branch"
    ;;
  *github*)
    merge_url="$remote_url/compare/$target_branch...$source_branch?expand=1"
    ;;
  *)
    echo "❌ Unsupported Git provider: $remote_url"
    return 2
    ;;
  esac

  # Print the final URL
  echo "✔ Using source: $source_branch → target: $target_branch"
  echo "To create a merge request from '$source_branch' into '$target_branch', visit:"
  echo "  $merge_url"
  [[ "$open_browser" == "true" ]] && command -v xdg-open >/dev/null && xdg-open "$merge_url" >/dev/null 2>&1
  return 0
}
