#!/usr/bin/env zsh
################################################################################
# Copyright (c) 2025 thaomaniac <thaomaniac@gmail.com>
################################################################################

### Aliases
alias update='sudo apt-get update'
alias autoremove='sudo apt-get autoremove'
alias autoclean='sudo apt-get autoclean'

#alias colorls command
if type "colorls" >/dev/null; then
  alias ls='colorls --indicator-style=none --color=never'
fi

## Upgrade package
#upgrade() {
#  if [ -z "$1" ]; then
#    echo "\e[1;31mMust specify 1 package\e[0m"
#    return 1
#  fi
#  sudo apt-get --only-upgrade install "$1"
#}
#
## Switch php version
#switch-php() {
#  if [ -z "$1" ]; then
#    sudo update-alternatives --config php
#  else
#    if [[ $1 =~ ^[0-9]\.[0-9]$ ]]; then #x.y # $1 == ?.?
#      sudo update-alternatives --set php /usr/bin/php"$1"
#    elif [[ $1 =~ ^[0-9]\[0-9]$ ]]; then #xy
#      # shellcheck disable=SC2001
#      sudo update-alternatives --set php /usr/bin/php"$(sed 's/./&./' <<<"$1")"
#    elif [[ $1 =~ ^php\[0-9]\.[0-9]$ ]]; then #phpx.y
#      sudo update-alternatives --set php /usr/bin/"$1"
#    else
#      sudo update-alternatives --set php /usr/bin/php"$1"
#    fi
#  fi
#}
#_list_all_php_ver() {
#  # shellcheck disable=SC2046
#  compadd $(update-alternatives --list php | sed "s/.*php//g") #sed 's/^.*php/php/
#}
#compdef _list_all_php_ver switch-php
#
## Restart service
#restart-service() {
#  sudo service "$1" restart
#}
#compdef _service restart-service
## compdef restart-service=service

## Reset trial phpstorm for old version <= 2021.*
#phpstorm_reset() {
#  rm -f ~/.config/JetBrains/PhpStorm*/options/other.xml
#  rm -rf ~/.config/JetBrains/PhpStorm*/eval
#  rm -rf ~/.java/.userPrefs
#}
