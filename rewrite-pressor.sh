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
    echo -e "\e[$((LINES/2-8))B"
  else
    echo -e "\e[$((LINES/2-4))B"
  fi

  # display menu
  for ((i=1; i < "$((${#@}+1))"; i++)); do
    [ "$hovering" = "$i" ] && echo -e "[\e[32m*\e[0m] ${@:i:1}\n" || echo -e "[ ] ${@:i:1}\n"
  done

  # process keyboard input
  while true; do
    read -rsn1 -t 0.5 keyboardInput
    if [[ "$?" == 142 ]]; then
      [[ "$(tput cols)" != "$columns" || "$(tput lines)" != "$lines" ]] && return
    else
      preHovering="$hovering"
      case "$keyboardInput" in
        'A') [ "$hovering" != 1 ] && ((hovering--)) || hovering="${#@}";;
        'B') ((hovering++)) && [ "$hovering" = "$((${#@}+1))" ] && hovering=1;;
        *) continue;;
      esac
      echo -en "\e[$((LINES/2+preHovering*2-4));2f \e[$((LINES/2+hovering*2-4));2f\e[32m*\e[0m"
      case "$hovering" in
        1) echo -en '\n\e[34m\e[2K'
           stty echo; tput cnorm
           read -e -i "$input" input
           stty -echo; tput civis;;
        2) echo -en '\n\e[34m\e[2K'
           stty echo; tput cnorm
           read -e -i "$output" output
           stty -echo; tput civis;;
        3):;;
        4):;;
      esac
    fi
  done

}

# variable initialisation
hovering=1; input="~/"; output="~/"

# main loop
while true; do
  columns="$(tput cols)"; lines="$(tput lines)"
  menu 'INPUT FILES/FOLDER' 'OUTPUT DIRECTORY' 'PARAMETERS' 'COMPRESS'
done
