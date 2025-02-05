#!/usr/bin/env zsh
################################################################################
# Copyright (c) 2024 thaomaniac  <thaomaniac@gmail.com>
################################################################################

ZTMDIR=${ZDOTDIR:-$HOME}/.zprezto/thaomaniac
# Source Prezto.
if [[ -s "$ZTMDIR/init.zsh" ]]; then
  source "$ZTMDIR/init.zsh"
fi

# Customize to your needs...
function tmcustomload {
  local file

  # load custom command files
  local -a TM_CUSTOM_FILE=(
    agnoster # Override Agnoster theme
    alias    # Alias & custom function
    git      # Git
    magento  # Magento CLI
    docker   # Docker CLI
    terminal # Custom terminal function
  )

  for file in "${TM_CUSTOM_FILE[@]}"; do
    file=$ZTMDIR/custom/$file.zsh
    if [[ -f $file ]]; then
      source "$file"
    fi
  done

  # load completions
  fpath=($ZTMDIR/completions $fpath)

  # load local file (not in git)
  for file in $ZTMDIR/local/*; do
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
tmcustomload

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
