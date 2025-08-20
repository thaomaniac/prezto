#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

_motd_banner() {
  local custom_text="$MOTD_BANNER_TEXT"
  local font="smslant"
  local final_output=""

  _get_default() {
    DEFAULT_LOGO_B64="IF9fX19fX19fIF9fX19fICBfX19fICBfXyAgX19fX19fICAgXyAgX19fX19fX19fICBfX19fXwov"
    DEFAULT_LOGO_B64+="XyAgX18vIC8vIC8gXyB8LyBfXyBcLyAgfC8gIC8gXyB8IC8gfC8gLyAgXy8gXyB8LyBfX18vCiAv"
    DEFAULT_LOGO_B64+="IC8gLyBfICAvIF9fIC8gL18vIC8gL3xfLyAvIF9fIHwvICAgIC8vIC8vIF9fIC8gL19fICAKL18v"
    DEFAULT_LOGO_B64+="IC9fLy9fL18vIHxfXF9fX18vXy8gIC9fL18vIHxfL18vfF8vX19fL18vIHxfXF9fXy8gIAo="
    # http://patorjk.com/software/taag/#p=display&h=2&f=Small%20Slant&t=THAOMANIAC

    echo "$DEFAULT_LOGO_B64" | base64 -d 2> /dev/null
  }

  if [ -z "$custom_text" ]; then
    final_output=$(_get_default)
  else
    if command -v figlet > /dev/null; then
      final_output=$(figlet -f "$font" "$custom_text" 2> /dev/null)
    elif command -v toilet > /dev/null; then
      final_output=$(toilet -f "$font" "$custom_text" 2> /dev/null)
    fi
    # Trim leading/trailing whitespace
    final_output="${final_output%"${final_output##*[![:space:]]}"}"
    if [ -z "$final_output" ]; then
      final_output=$(_get_default)
    fi
  fi

  echo "$final_output"
}

function _motd_greeting() {
  local use_lolcat="$MOTD_LOLCAT"
  if [ "$use_lolcat" = "1" ] && command -v lolcat > /dev/null; then
    _motd_banner | lolcat
  else
    _motd_banner
  fi
  # shellcheck disable=SC2028
  echo "\n${_BOLD}${_BLINK}${MOTD_DISPLAY_NAME:-$USER}${_RESET} - $(date '+%Y-%m-%d %H:%M:%S') ${_BLINK}-${_RESET} $(lsb_release -sd)\n"
}
_motd_greeting

_get-window-title-tm() {
  local title
  local trimPwdPatterns=(
    "[^/]*/www/[^/]*/www/"
    "$HOME/www/"
  ) 2> /dev/null
  title="${PWD/#$HOME/~}"
  for regex in "${trimPwdPatterns[@]}"; do
    if [[ $PWD =~ $regex ]]; then
      local trimPwd=${PWD#*"${MATCH}"} #remove $dir at the beginning
      #title=${trimPwd%%/*} #remove all except the first folder
      [[ -n $trimPwd ]] && title=$trimPwd
      break
    fi
  done
  echo "$title"
}

_set-window-title-tm() {
  printf '\e]2;%s\a' "$(_get-window-title-tm)"
}

_set-window-title-tm
add-zsh-hook chpwd _set-window-title-tm

# Elapsed and execution time display for commands
# https://gist.github.com/knadh/123bca5cfdae8645db750bfb49cb44b0
function elapsed_preexec() {
  if [[ "$SHOW_ELAPSED" == 1 ]]; then
    epLastCmd="$1"
    [[ -n $epLastCmd && $epLastCmd != "clear" && $epLastCmd != "reset" ]] &&
      elapsedTimer=$(date +%s%3N)
  fi
}
elapsed_precmd() {
  if [[ "$SHOW_ELAPSED" && "$elapsedTimer" ]]; then
    local -r now=$(date +%s%3N)
    local -rF d_ms=$((now - elapsedTimer))
    local -rF d_s=$((d_ms / 1000))
    local -rF ms=$((d_ms % 1000))
    local -rF s=$((d_s % 60))
    local -ri m=$(((d_s / 60) % 60))
    local -ri h=$((d_s / 3600))
    if ((h > 0)); then
      printf -v elapsed '%ih%im%is' ${h} ${m} ${s}
    elif ((m > 0)); then
      printf -v elapsed '%im%is' ${m} ${s}
    elif ((s >= 1)); then
      printf -v elapsed '%.2fs' ${s}
    else
      printf -v elapsed '%ims' ${ms}
    fi
    RPROMPT="${elapsed}"
    if [ "$SHOW_TIMESTAMP" ]; then
      RPROMPT+="|%D{%H:%M:%S}"
    fi
    unset elapsedTimer
    unset elapsed
  elif [ "$SHOW_TIMESTAMP" ]; then
    RPROMPT="%D{%H:%M:%S}"
  else
    unset RPROMPT
  fi
}
showTimePrompt() {
  if [[ "$1" == "-h" ]]; then
    echo "Usage: showTimePrompt [elapsed] [timestamp]"
    echo "  No args:        enable both elapsed time and timestamp"
    echo "  showTimePrompt 1    enable elapsed time only"
    echo "  showTimePrompt 1 1  enable both"
    echo "  showTimePrompt 0 1  enable timestamp only"
    echo "  showTimePrompt 0    disable all"
    return 0
  fi

  unset SHOW_TIMESTAMP
  unset SHOW_ELAPSED
  unset RPROMPT
  unset elapsedTimer

  if [[ -z $1 ]]; then
    SHOW_TIMESTAMP=1
    SHOW_ELAPSED=1
  else
    [[ $1 == 1 ]] && SHOW_ELAPSED=1
    [[ $2 == 1 ]] && SHOW_TIMESTAMP=1
  fi
}
add-zsh-hook preexec elapsed_preexec
add-zsh-hook precmd elapsed_precmd
# END Elapsed and execution time

# override bgnotify_formatted
function bgnotify_formatted() { ## args: (exit_status, command, elapsed_seconds)
  elapsed="$(($3 % 60))s"
  (($3 >= 60)) && elapsed="$((($3 % 3600) / 60))m $elapsed"
  (($3 >= 3600)) && elapsed="$(($3 / 3600))h $elapsed"
  [ $1 -eq 0 ] && notify-send -i org.gnome.Terminal "Success ($elapsed)✔" "$2" || notify-send -i org.gnome.Terminal "FAIL ($elapsed)✘" "$2"
}

# Print a newline before the prompt
_print_new_line_preexec() {
  [[ -n $1 && $1 != "clear" && $1 != "reset" ]] && pnl_newline=true
}
_print_new_line_precmd() {
  if [[ "$pnl_newline" == true ]]; then
    echo # Print a blank line
    if [[ "$_DETECTED_TERMINAL" == "ubuntu" ]]; then
      draw_horizontal_line "─"
    fi
    unset pnl_newline
  fi
}
add-zsh-hook preexec _print_new_line_preexec
add-zsh-hook precmd _print_new_line_precmd

# Function: draw_horizontal_line
draw_horizontal_line() {
  local char="${1:-_}"
  local color_code='\e[38;5;236m'
  local reset_code='\e[0m'
  local cols
  cols=$(tput cols)

  # printf "${color_code}%*s${reset_code}\n" "$cols" '' | tr ' ' "$char"
  printf "${color_code}%s${reset_code}\n" "$(printf '%*s' "$cols" '' | sed "s/ /$char/g")"
}

detect_terminal() {
  if [[ "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
    echo "jetbrains"
  elif [[ "$TERM_PROGRAM" == "vscode" ]]; then
    echo "vscode"
  elif [[ "$COLORTERM" == "truecolor" ]] || [[ "$TERM" == "xterm-256color" ]]; then
    echo "ubuntu"
  else
    echo "unknown"
  fi
}
# Cache once at load time — terminal emulator doesn't change during a session
_DETECTED_TERMINAL=$(detect_terminal)

# Ctrl+W behavior:
# Remove "-" from WORDCHARS so it deletes only the last part of a hyphenated word
WORDCHARS=${WORDCHARS//-/}
