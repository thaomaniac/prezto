#!/usr/bin/env zsh

ssh() {
  command ssh "$@"
  _set-window-title-tm
}

# Extract connection details from a companion `ssh-*` function.
#
# Supported shapes:
# - `ssh -i /path/to/key -p2222 user@example.com`
# - `ssh -i /path/to/key user@example.com -t 'cd /path && exec $SHELL'`
# - `ssh host-alias`
# - `sshpass -p 'secret' ssh user@example.com`
# - `sshpass -p "$ssh_pass" ssh -i /path/to/key user@example.com`
#
# Notes:
# - The target function should contain a single-line `ssh` or `sshpass ... ssh`
#   command so this parser can extract key, port, password, and remote host.
# - When `sshpass` uses a variable, define it inside the same function in a
#   simple assignment such as `local ssh_pass='secret'`.
function _extract_ssh_config() {
  local target_func="$1"
  if ! whence -f "$target_func" >/dev/null && whence -f "ssh-$target_func" >/dev/null; then
    target_func="ssh-$target_func"
  fi

  local func_def=$(whence -f "$target_func")
  if [[ -z "$func_def" ]]; then
    echo "ERROR=1"
    return 1
  fi

  local ssh_line=$(echo "$func_def" | grep -E '\bsshpass\b' | tail -n 1)
  if [[ -z "$ssh_line" ]]; then
    ssh_line=$(echo "$func_def" | grep -E '\bssh\b' | tail -n 1)
  fi

  local pass_val=""
  local warning=""
  if echo "$ssh_line" | grep -q "sshpass"; then
    if type "sshpass" >/dev/null 2>&1; then
      local pass_arg=$(echo "$ssh_line" | grep -oE '\-p\s+[^ ]+' | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")
      pass_val="$pass_arg"
      if [[ "$pass_arg" == \$* ]]; then
        local var_name=${pass_arg#\$}
        pass_val=$(echo "$func_def" | grep -E "\b${var_name}=" | head -1 | cut -d'=' -f2- | sed -E "s/^[[:space:]]*['\"]?//; s/['\"]?[[:space:]]*;?[[:space:]]*$//")
      fi
    else
      warning="'sshpass' is required by $target_func but not installed."
    fi
  fi

  local key=$(echo "$ssh_line" | grep -oE '\-i\s+[^ ]+' | head -1)
  local port=$(echo "$ssh_line" | grep -oE '\-p\s*[0-9]+' | head -1)

  local remote_host=$(echo "$ssh_line" | sed -E 's/-i\s+[^ ]+//g; s/-p\s*[0-9]+//g; s/-t//g; s/\bssh\b//g; s/\bsshpass\b//g; s/-p\s+[^ ]+//g; s/--[a-z-]+//g')
  remote_host=$(echo "$remote_host" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
  remote_host=$(echo "$remote_host" | grep -oE '[^ ]+@[^ ]+|[a-zA-Z0-9.-]+\.[a-z]{2,}' | head -1)

  if [[ -z "$remote_host" ]]; then
    remote_host=$(echo "$ssh_line" | tr ' ' '\n' | grep -v '^-' | grep -v 'ssh' | tail -n 1)
  fi

  if [[ -z "$remote_host" ]]; then
    echo "ERROR=1"
    return 1
  fi

  echo "FUNC_NAME=${(q)target_func}"
  echo "PASS_VAL=${(q)pass_val}"
  [[ -n "$warning" ]] && echo "WARN_MSG=${(q)warning}"
  echo "KEY=${(q)key}"
  echo "PORT=${(q)port}"
  echo "REMOTE_HOST=${(q)remote_host}"
}

# Auto SCP from SSH function
# Usage: sscp [options] <ssh_function_name_or_suffix> <src> <dest>
function sscp() {
  local scp_opts=()
  local args=()

  _sscp_show_help() {
    echo "${_YELLOW}Usage:${_RESET} sscp [scp_options] <ssh_func> <src> <dest>"
    echo ""
    echo "${_YELLOW}Arguments:${_RESET}"
    echo "  scp_options  Any standard scp options (e.g., -r, -C, -v, -P port)"
    echo "  ssh_func     Name or suffix of the SSH function (e.g., evp-staging)"
    echo "  src          Source file path (local or remote with ':')"
    echo "  dest         Destination file path (local or remote with ':')"
    echo ""
    echo "${_YELLOW}Examples:${_RESET}"
    echo "  Recursive: sscp -r evp-staging :/remote/dir ~/Downloads"
    echo "  Download:  sscp evp-staging :/remote/file.sql ~/Downloads"
    echo "  Upload:    sscp evp-staging ~/local/file.sql :/remote/path/"
  }

  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      _sscp_show_help
      return 0
    elif [[ "$arg" == -* ]]; then
      scp_opts+=("$arg")
    else
      args+=("$arg")
    fi
  done

  if [[ ${#args} -lt 3 ]]; then
    _sscp_show_help
    return 1
  fi

  local ssh_func_name="${args[1]}"
  local source_path="${args[2]}"
  local dest_path="${args[3]}"

  local ERROR WARN_MSG FUNC_NAME PASS_VAL KEY PORT REMOTE_HOST
  eval "$(_extract_ssh_config "$ssh_func_name")"

  if [[ -n "$ERROR" ]]; then
    echo "Error: Could not determine configuration for '$ssh_func_name'"
    return 1
  fi
  [[ -n "$WARN_MSG" ]] && echo "Warning: $WARN_MSG"

  local pass_cmd=""
  local remote_host="$REMOTE_HOST"
  local port="${PORT/-p/-P}"

  [[ -n "$PASS_VAL" ]] && pass_cmd="sshpass -p '$PASS_VAL'"

  local cmd_parts=()
  [[ -n "$pass_cmd" ]] && cmd_parts+=($pass_cmd)
  cmd_parts+=(scp)
  [[ -n "$KEY" ]] && cmd_parts+=($KEY)
  [[ -n "$port" ]] && cmd_parts+=($port)
  [[ ${#scp_opts} -gt 0 ]] && cmd_parts+=("${scp_opts[@]}")

  local final_cmd=""
  if [[ "$source_path" == :* ]]; then
    final_cmd="${cmd_parts[*]} $remote_host${source_path} $dest_path"
  elif [[ "$dest_path" == :* ]]; then
    final_cmd="${cmd_parts[*]} $source_path $remote_host${dest_path}"
  else
    echo "Error: One of the paths must start with ':' to indicate a remote location."
    return 1
  fi

  echo "Executing command:"
  echo "  ${_YELLOW}${final_cmd}${_RESET}"
  eval "$final_cmd"
}

_sscp() {
  local -a ssh_funcs suffixes
  ssh_funcs=(${(k)functions[(I)ssh-*]})
  suffixes=(${ssh_funcs#ssh-})
  _arguments \
    '(-h --help)'{-h,--help}'[show help message]' \
    '1:ssh function:compadd -a suffixes' \
    '2:source:_files' \
    '3:destination:_files'
}
compdef _sscp sscp

# Auto Rsync from SSH function
# Usage: ssrsync [options] <ssh_function_name_or_suffix> <src> <dest>
function ssrsync() {
  local rsync_opts=()
  local args=()

  _ssrsync_show_help() {
    echo "${_YELLOW}Usage:${_RESET} ssrsync [rsync_options] <ssh_func> <src> <dest>"
    echo ""
    echo "${_YELLOW}Arguments:${_RESET}"
    echo "  rsync_options Any standard rsync options (e.g., --delete, -n, --exclude)"
    echo "                Note: -avz and --progress are included by default."
    echo "  ssh_func      Name or suffix of the SSH function (e.g., evp-staging)"
    echo "  src           Source file path (local or remote with ':')"
    echo "  dest          Destination file path (local or remote with ':')"
    echo ""
    echo "${_YELLOW}Examples:${_RESET}"
    echo "  Download:  ssrsync evp-staging :/remote/dir ~/Downloads"
    echo "  Upload:    ssrsync evp-staging ~/local/dir :/remote/dir"
  }

  # rsync options that take a separate value argument (not --opt=val form)
  local -A _rsync_valued_opts
  _rsync_valued_opts=(
    --exclude 1 --include 1 --exclude-from 1 --include-from 1
    --filter 1 -f 1 --files-from 1 --bwlimit 1 --timeout 1
    --max-size 1 --min-size 1 --max-delete 1 --partial-dir 1
    --temp-dir 1 -T 1 --link-dest 1 --copy-dest 1 --compare-dest 1
    --suffix 1 --log-file 1 --log-file-format 1 --password-file 1
    --chmod 1 --chown 1 --block-size 1 -B 1
    --out-format 1 --log-format 1 --address 1 --port 1
    --usermap 1 --groupmap 1 --compress-level 1 --read-batch 1
    --write-batch 1 --only-write-batch 1
  )

  local i=1
  while [[ $i -le $# ]]; do
    local arg="${@[$i]}"
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      _ssrsync_show_help
      return 0
    elif [[ "$arg" == -* ]]; then
      # if option takes a value and is not in --opt=val form, consume next arg too
      local opt_key="${arg%%=*}"
      if [[ -n "${_rsync_valued_opts[$opt_key]}" && "$arg" != *=* ]]; then
        rsync_opts+=("$arg" "${@[$((i+1))]}")
        (( i += 2 ))
      else
        rsync_opts+=("$arg")
        (( i++ ))
      fi
    else
      args+=("$arg")
      (( i++ ))
    fi
  done

  if [[ ${#args} -lt 3 ]]; then
    _ssrsync_show_help
    return 1
  fi

  local ssh_func_name="${args[1]}"
  local source_path="${args[2]}"
  local dest_path="${args[3]}"

  local ERROR WARN_MSG FUNC_NAME PASS_VAL KEY PORT REMOTE_HOST
  eval "$(_extract_ssh_config "$ssh_func_name")"

  if [[ -n "$ERROR" ]]; then
    echo "Error: Could not determine configuration for '$ssh_func_name'"
    return 1
  fi
  [[ -n "$WARN_MSG" ]] && echo "Warning: $WARN_MSG"

  local remote_host="$REMOTE_HOST"
  local ssh_cmd="ssh"

  [[ -n "$PASS_VAL" ]] && ssh_cmd="sshpass -p '$PASS_VAL' ssh"
  [[ -n "$KEY" ]] && ssh_cmd="$ssh_cmd $KEY"
  [[ -n "$PORT" ]] && ssh_cmd="$ssh_cmd $PORT"

  local rsync_base=(rsync --progress -avz -e "$ssh_cmd")
  [[ ${#rsync_opts} -gt 0 ]] && rsync_base+=("${rsync_opts[@]}")

  local -a final_cmd=("${rsync_base[@]}")
  if [[ "$source_path" == :* ]]; then
    final_cmd+=("$remote_host${source_path}" "$dest_path")
  elif [[ "$dest_path" == :* ]]; then
    final_cmd+=("$source_path" "$remote_host${dest_path}")
  else
    echo "Error: One of the paths must start with ':' to indicate a remote location."
    return 1
  fi

  echo "Executing command:"
  echo "  ${_YELLOW}${(q)final_cmd[@]}${_RESET}"
  "${final_cmd[@]}"
}

_ssrsync() {
  local -a ssh_funcs suffixes
  ssh_funcs=(${(k)functions[(I)ssh-*]})
  suffixes=(${ssh_funcs#ssh-})
  _arguments \
    '(-h --help)'{-h,--help}'[show help message]' \
    '1:ssh function:compadd -a suffixes' \
    '2:source:_files' \
    '3:destination:_files'
}
compdef _ssrsync ssrsync
