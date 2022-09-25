#!/bin/bash

# objectives :
#
# 1 - compress gallery
# 2 - nice GUI
# 3 - keep all metadata
# 4 - input/ouput parameters
# 5 - crop/maxsize parameters
# 6 - optionnal : codec choice

menu() {

  # initialize menu
  clear; tput civis; stty -echo
  trap 'clear; tput cnorm; stty echo' EXIT

  # draw menu layout
  if (( "$COLUMNS" > 35 )); then
    unset border
    blank="$(((COLUMNS-30)/2))"
    for ((i=0; i < "$COLUMNS"; i++)); do border+=':'; done
    echo -e "\e[36m\e[3;0f${border}\e[$((LINES-1));0f${border}\e[0m\e[1;${blank}f   ___\n\e[2;${blank}f  / _ \_______ ___ ___ ___  ____\n\e[3;$((blank+1))f/ ___/ __/ -_|_-<(_-</ _ \/ __/\n\e[4;${blank}f/_/  /_/  \__/___/___/\___/_/"
    echo -e "\e[$(((LINES/2-7)))B"
  else
    echo -e "\e[$(((LINES/2)-4))B"
  fi

  # display menu
  echo -e "\e[$(((COLUMNS-${#1}-4)/2))C\e[32m> ${1} <\e[0m\e[B"
  for i in "${@:2}"; do
    echo -e "\e[$(((COLUMNS-${#i}-4)/2))C  ${i}  \e[B"
  done

  while true; do

    # process keyboard input
    read -rsn1 -t 0.5 keyboardInput
    if [[ "$?" == 142 ]]; then
      [[ "$(tput cols)" != "$columns" || "$(tput lines)" != "$lines" ]] && return
    else
      case "$keyboardInput" in
        'A') [ "$hovering" != 1 ] && ((hovering--)) || hovering="${#@}";;
        'B') ((hovering++)) && [ "$hovering" = "$((${#@}+1))" ] && hovering=1;;
        *) continue;;
      esac
      currentOption="${@:hovering:1}"
      echo -e "\e[$(((COLUMNS-${#currentOption})/2))C${currentOption}"
    fi

  done

}

while true; do
  hovering=1;
  columns="$(tput columns)"; lines="$(tput lines)"
  menu 'INPUT FILES/FOLDER' 'OUTPUT DIRECTORY' 'PARAMETERS' 'COMPRESS'
done
