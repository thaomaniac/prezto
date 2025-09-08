#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

## Aliases
alias gst='git status'
alias gb='git branch'
alias gcm='git commit --message'
alias gco='git checkout'
alias gf='git fetch'
alias gm='git merge'
alias gfm='git pull'
alias gp='git push'
alias gpc='git push --set-upstream origin "$(git-branch-current 2> /dev/null)"'
alias grs='git reset'
alias gs='git stash'

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
    echo "${_BOLD}${_RED}Unknown branch name${_RESET}"
    return 1
  fi
  if [[ $# != 1 ]]; then
    echo "${_BOLD}${_RED}Error:${_RESET} Expected 1 argument, but got $#."
    echo "Usage: commit \"Commit message\""
    return 1
  else
    local msg="${1[1]:u}${1[2,-1]}" # bash: "${1^}"
    git commit -m "$branch: $msg"
  fi
}


# Pretty git log graph
git-graph() {
  if [[ "$1" == "-h" ]]; then
    echo "Usage: git-graph [git-log options]"
    echo "  git-graph              pretty git log graph"
    echo "  git-graph -n 10        last 10 commits"
    echo "  git-graph --since=1w   last week"
    return 0
  fi

  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${_RED}Not a git repository${_RESET}" >&2
    return 1
  fi

  git log --graph --abbrev-commit --decorate \
    --format=format:'%C(bold yellow)%h%C(reset) %C(bold cyan)%ad%C(reset) %C(bold white)│%C(reset) %C(magenta)%G?%C(reset) %s %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' \
    --date=format:'%Y-%m-%d %H:%M' "$@"
}

# Git commit with custom date/time
# Usage:
#   gcm-at -t "YYYY-MM-DD HH:MM:SS" -m "Commit message"  # full datetime
#   gcm-at -t "2025-01-01" -m "msg"                       # date only, uses current time
#   gcm-at -t "09:00:00" -m "msg"                         # time only, uses today's date
# Notes:
#   - Auto-detects date vs time vs full datetime from -t value
#   - The commit will use this time as both AuthorDate and CommitDate
gcm-at() {

  usage() {
    echo "Usage: gcm-at -t <datetime> -m \"commit message\""
    echo "  -t: Date and/or time for commit. Auto-detected format:"
    echo "      \"YYYY-MM-DD HH:MM:SS\"  full datetime"
    echo "      \"YYYY-MM-DD HH:MM\"     full datetime (seconds default to 00)"
    echo "      \"YYYY-MM-DD\"           date only (time defaults to now)"
    echo "      \"MM-DD\"               date only (year defaults to current year)"
    echo "      \"MM-DD HH:MM:SS\"       datetime (year defaults to current year)"
    echo "      \"MM-DD HH:MM\"          datetime (year + seconds default)"
    echo "      \"HH:MM:SS\"             time only (date defaults to today)"
    echo "      \"HH:MM\"               time only (seconds default to 00)"
    echo "  -m: Commit message"
    echo "  -h: Show this help message"
  }

  local input message
  OPTIND=1

  while getopts "t:m:h" opt; do
    case $opt in
      t) input="$OPTARG" ;;
      m) message="$OPTARG" ;;
      h) usage; return 0 ;;
      *) usage; return 1 ;;
    esac
  done

  if [[ -z "$input" || -z "$message" ]]; then
    usage
    return 1
  fi

  local commit_date commit_time

  # Normalize MM-DD to YYYY-MM-DD (prepend current year)
  if [[ "$input" =~ ^([0-9]{2})-([0-9]{2})(\ .*|$) ]]; then
    input="$(date +%Y)-${match[1]}-${match[2]}${match[3]}"
  fi

  if [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    # Full datetime: YYYY-MM-DD HH:MM:SS
    commit_date="${input%% *}"
    commit_time="${input##* }"
  elif [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; then
    # Datetime without seconds: YYYY-MM-DD HH:MM
    commit_date="${input%% *}"
    commit_time="${input##* }:00"
  elif [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    # Date only
    commit_date="$input"
    commit_time=$(date +%H:%M:%S)
  elif [[ "$input" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    # Time with seconds: HH:MM:SS
    commit_date=$(date +%Y-%m-%d)
    commit_time="$input"
  elif [[ "$input" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
    # Time without seconds: HH:MM
    commit_date=$(date +%Y-%m-%d)
    commit_time="$input:00"
  else
    echo "Error: unrecognized format '$input'"
    usage
    return 1
  fi

  local datetime="$commit_date $commit_time"
  GIT_AUTHOR_DATE="$datetime" GIT_COMMITTER_DATE="$datetime" git commit -m "$message"
}

# Create a merge request (MR) or pull request (PR) URL
gmr-cr() {

  usage() {
    echo "Usage:
    gmr-cr -t <target_branch>                     # use current branch as source
    gmr-cr -s <source_branch>                     # use current branch as target
    gmr-cr -s <source_branch> -t <target_branch>  # specify both branches
    gmr-cr -s<source_branch> -t<target_branch>    # specify both branches
    gmr-cr -o --open                              # open URL in browser"
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
