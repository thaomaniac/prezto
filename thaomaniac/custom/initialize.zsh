#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# Copyright (c) 2025 ThaoManiac
# Author: thaomaniac <thaomaniac@gmail.com>
# Licensed under the MIT License
#-------------------------------------------------------------------------------

ZTMDIR=${ZDOTDIR:-$HOME}/.zprezto/thaomaniac
# Source Prezto.
if [[ -s "$ZTMDIR/init.zsh" ]]; then
  source "$ZTMDIR/init.zsh"
fi

# Customize to your needs...
function _tmcustomload {
  local file
  # load custom command files
  local -a TM_CUSTOM_FILE=(
    terminal # Custom terminal function
    agnoster # Override Agnoster theme
    alias    # Alias & custom function
    git      # Git
    magento  # Magento CLI
    shopify  # Shopify CLI
    docker   # Docker CLI
  )

  for file in "${TM_CUSTOM_FILE[@]}"; do
    file=$ZTMDIR/custom/$file.zsh
    if [[ -f $file ]]; then
      source "$file"
    fi
  done

  # load local file (not in git)
  for file in "$ZTMDIR"/local/*(N); do
    if [[ -f $file ]]; then
      source "$file"
    fi
  done
  
  # load local completion
  for file in "$ZTMDIR"/local/completions/*(N); do
    if [[ -f $file ]]; then
      source "$file"
    fi
  done

  # load external plugins
  local plugin
  local plugin_dir
  local TM_CUSTOM_PLUGINS

  zstyle ':tm:custom:plugins' plugins \
    bgnotify \
    you-should-use

  zstyle -g TM_CUSTOM_PLUGINS ':tm:custom:plugins' plugins
  for plugin in "${TM_CUSTOM_PLUGINS[@]}"; do
    plugin_dir=${ZTMDIR}/plugins/${plugin}
    if [[ ! -d "$plugin_dir" ]]; then
      echo "$0: Missing custom plugin dir: $plugin_dir"
    fi
    if [[ -s "${plugin_dir}/init.zsh" ]]; then
      source "${plugin_dir}/init.zsh"
    elif [[ -s "${plugin_dir}/${plugin}.plugin.zsh" ]]; then
      source "${plugin_dir}/${plugin}.plugin.zsh"
    fi
  done
}

# shellcheck disable=SC2034
# _setup_color
# Initializes ANSI color and style variables.
# ESC can be written as '\033' (POSIX standard) or '\e' (Bash/Zsh shorthand).
_setup_color() {
  # The [ -t 1 ] check only works when the function is not called from
  # a subshell (like in `$(...)` or `(...)`, so this hack redefines the
  # function at the top level to always return false when stdout is not
  # a tty.
  if [ -t 1 ]; then
    is_tty() {
      true
    }
  else
    is_tty() {
      false
    }
  fi

  # Adapted from code and information by Anton Kochkov (@XVilka)
  # Source: https://gist.github.com/XVilka/8346728
  supports_truecolor() {
    case "$COLORTERM" in
      truecolor | 24bit) return 0 ;;
    esac

    case "$TERM" in
      iterm | \
        tmux-truecolor | \
        linux-truecolor | \
        xterm-truecolor | \
        screen-truecolor) return 0 ;;
    esac

    return 1
  }

  # Only use colors if connected to a terminal
  if ! is_tty; then
    return
  fi

  if supports_truecolor; then
    _RAINBOW=(
      "$(printf '\033[38;2;255;0;0m')"
      "$(printf '\033[38;2;255;97;0m')"
      "$(printf '\033[38;2;247;255;0m')"
      "$(printf '\033[38;2;0;255;30m')"
      "$(printf '\033[38;2;77;0;255m')"
      "$(printf '\033[38;2;168;0;255m')"
      "$(printf '\033[38;2;245;0;172m')"
    )
  else
    _RAINBOW=(
      "$(printf '\033[38;5;196m')"
      "$(printf '\033[38;5;202m')"
      "$(printf '\033[38;5;226m')"
      "$(printf '\033[38;5;082m')"
      "$(printf '\033[38;5;021m')"
      "$(printf '\033[38;5;093m')"
      "$(printf '\033[38;5;163m')"
    )
  fi

  # Foreground colors
  _BLACK=$(printf '\033[30m')
  _RED=$(printf '\033[31m')
  _GREEN=$(printf '\033[32m')
  _YELLOW=$(printf '\033[33m')
  _BLUE=$(printf '\033[34m')
  _MAGENTA=$(printf '\033[35m')
  _CYAN=$(printf '\033[36m')
  _WHITE=$(printf '\033[37m')

  # Background colors
  _BG_RED=$(printf '\033[41m')
  _BG_GREEN=$(printf '\033[42m')
  _BG_YELLOW=$(printf '\033[43m')
  _BG_BLUE=$(printf '\033[44m')
  _BG_MAGENTA=$(printf '\033[45m')
  _BG_CYAN=$(printf '\033[46m')
  _BG_WHITE=$(printf '\033[47m')
  _BG_BLACK=$(printf '\033[40m')

  # Text Styles / Effects
  _BOLD=$(printf '\033[1m')               # Bold / Increased intensity
  _DIM=$(printf '\033[2m')                # Dim / Decreased intensity
  _ITALIC=$(printf '\033[3m')             # Italic text (may not be supported everywhere)
  _UNDERLINE=$(printf '\033[4m')          # Single underline
  _BLINK=$(printf '\033[5m')              # Slow blink (rarely enabled by default)
  _FAST_BLINK=$(printf '\033[6m')         # Fast blink (very rarely supported)
  _INVERSE=$(printf '\033[7m')            # Invert foreground/background
  _HIDDEN=$(printf '\033[8m')             # Hidden / Concealed (useful for passwords)
  _STRIKE=$(printf '\033[9m')             # Strikethrough
  _DOTTED_UNDERLINE=$(printf '\033[4:4m') # Dotted underline
  _DASHED_UNDERLINE=$(printf '\033[4:5m') # Dashed underline
  _UNDERCURL=$(printf '\033[4:3m')        # Curly underline (undercurl)

  # Additional / Extended
  _DOUBLE_UNDERLINE=$(printf '\033[21m') # Double underline (not widely supported)
  _OVERLINE=$(printf '\033[53m')         # Overline (newer terminals only)
  _HYPERLINKS="\e]8;;%s\e\\%s\e]8;;\e\\" # Usage: printf "$_HYPERLINKS" "URL" "TEXT"

  # Disable / Reset
  _RESET=$(printf '\033[0m')                  # Reset all format style, color, effects
  _NO_FG=$(printf '\033[39m')                 # Reset foreground color (30–37, 90–97, 38;x)
  _NO_BG=$(printf '\033[49m')                 # Reset background color (40–47, 100–107, 48;x)
  _NO_BOLD=$(printf '\033[22m')               # Reset bold + dim
  _NO_DIM=$(printf '\033[22m')                # Same as bold (bold + dim share code)
  _NO_ITALIC=$(printf '\033[23m')             # Disable italic
  _NO_UNDERLINE=$(printf '\033[24m')          # Disable single underline (4)
  _NO_BLINK=$(printf '\033[25m')              # Disable blink (5 + 6)
  _NO_INVERSE=$(printf '\033[27m')            # Disable inverse
  _NO_HIDDEN=$(printf '\033[28m')             # Disable hidden
  _NO_STRIKE=$(printf '\033[29m')             # Disable strikethrough
  _UNDERLINE_RESET=$(printf '\033[4:0m')      # Reset underline types: 4:1..4:5
  _UNDERLINE_COLOR_RESET=$(printf '\033[59m') # Reset underline color
  _NO_OVERLINE=$(printf '\033[55m')           # Disable overline
}
_setup_color
_tmcustomload

# remove background color 'ls'
export LS_COLORS="$LS_COLORS:ow=1;34:tw=1;34:"

#remove autocompletion color
zstyle ':completion:*:default' list-colors

# Disable correct command
unsetopt correct

# Disable confirm a rm *
# setopt rmstarsilent

# Fix cursor style to I-Beam
#_fix_cursor() {
#   echo -ne '\e[5 q'
#}
#precmd_functions+=(_fix_cursor)

# use a 256 colour terminal
export TERM=xterm-256color
