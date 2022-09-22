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

  while true; do

    if [[ "$rows" != "$LINES" || "$columns" != "$COLUMNS" ]]; then
      selected=0
      drawMenu 'INPUT FOLDER/FILES' 'OUTPUT DIRECTORY' 'PARAMETERS' 'COMPRESS'
    fi

    columns="$COLUMNS"
    rows="$LINES"
    sleep 0.02

  done

}

drawMenu() {

  clear
  tput civis
  trap 'tput cnorm; exit' 2 3
  if (( "$COLUMNS" > 35 )); then

    unset border
    for ((i=0; i < "$COLUMNS"; i++)); do border+=':'; done

    blank="$(((COLUMNS-30)/2))"
    echo -e "\e[4;0f\e[36m${border}\e[$((LINES-2));0f${border}\\e[0m\e[0;0f"
    echo -e "\e[2;${blank}f   ___"
    echo -e "\e[3;${blank}f  / _ \_______ ___ ___ ___  ____"
    echo -e "\e[4;$((blank+1))f/ ___/ __/ -_|_-<(_-</ _ \/ __/"
    echo -e "\e[5;${blank}f/_/  /_/  \__/___/___/\___/_/"
    echo -e "\e[$(((LINES/2-9)))B"

  else

    echo -e "\e[$(((LINES/2)-4))B"

  fi

  while true; do

    optionIndex=0
    for i in "${@}"; do
      if [[ "$optionIndex" == "$selected" ]]; then
        echo -e "\e[$(((COLUMNS-${#i}-4)/2))C\e[32m> ${i} <\e[0m\e[B"
      else
        echo -e "\e[$(((COLUMNS-${#i}-4)/2))C  ${i}  \e[B"
      fi
    ((optionIndex++))
    done
    echo -e "\e[$((${#@}*2+1))A"

    read -rsn1 keyboardInput
    if [[ "$keyboardInput" == 'A' && (( "$selected" > '0' )) ]]; then
      ((selected--))
    elif [[ "$keyboardInput" == 'B' && (( "$selected" < "$((${#@}-1))" )) ]]; then
      ((selected++))
    fi

  done

}

menu
