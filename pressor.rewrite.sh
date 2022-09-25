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

  # arguments handling
  args=(${*})
  unset subOptions mainOptions
  for ((i = 0; i < "${#args[@]}"; i++)); do
    case "${args[i]}" in
      -*) subOptions+=("${args[i]:1}");;
      *) mainOptions+=("${args[i]}");;
    esac
  done

  # display options
  while true; do
    optionIndex=0
    for i in "${mainOptions[@]}"; do
      [ "$optionIndex" = "$hovering" ] && [ "${isSelected[optionIndex]}" = true ] && \
          echo -e "\e[$(((COLUMNS-${#i}-4)/2))C\e[32mv ${i} v\e[0m" && \
          echo -e "\e[$(((COLUMNS-${#subOptions[@]})/2))C\e[31m${subOptions[@]}\e[0m"
      [ "$optionIndex" = "$hovering" ] && [ "${isSelected[optionIndex]}" = '' ] && \
          echo -e "\e[$(((COLUMNS-${#i}-4)/2))C\e[32m> ${i} <\e[0m\e[B"
      [ "$optionIndex" != "$hovering" ] && [ "${isSelected[optionIndex]}" = true ] && \
          echo -e "\e[$(((COLUMNS-${#i}-4)/2))Cv ${i} v" && \
          echo -e "\e[$(((COLUMNS-${#subOptions[@]})/2))C\e[31m${subOptions[@]}\e[0m"
      [ "$optionIndex" != "$hovering" ] && [ "${isSelected[optionIndex]}" = '' ] && \
          echo -e "\e[$(((COLUMNS-${#i})/2))C${i}\e[B"
      ((optionIndex++))
    done

#    for i in "${@}"; do
#      [ "$optionIndex" = "$hovering" ] && [ "${isSelected[optionIndex]}" = true ] && \
#          echo -e "\e[$(((COLUMNS-${#i}-4)/2))C\e[32mv ${i} v\e[0m\e[B"
#      [ "$optionIndex" = "$hovering" ] && [ "${isSelected[optionIndex]}" = '' ] && \
#          echo -e "\e[$(((COLUMNS-${#i}-4)/2))C\e[32m> ${i} <\e[0m\e[B"
#      [ "$optionIndex" != "$hovering" ] && [ "${isSelected[optionIndex]}" = true ] && \
#          echo -e "\e[$(((COLUMNS-${#i}-4)/2))Cv ${i} v\e[B"
#      [ "$optionIndex" != "$hovering" ] && [ "${isSelected[optionIndex]}" = '' ] && \
#          echo -e "\e[$(((COLUMNS-${#i}-4)/2))C  ${i}  \e[B"
#      ((optionIndex++))
#    done

    echo -e "\e[$((${#@}*2+1))A"

    # process keyboard input
    read -rsn1 -t 2 keyboardInput
    if [[ "$?" == 142 ]]; then
      [[ "$(tput cols)" != "$columns" || "$(tput lines)" != "$lines" ]] && return
    else
      case "$keyboardInput" in
        A) [ "$hovering" != 0 ] && ((hovering--));;
        B) (( "$hovering" < "$((${#@}-1))" )) && ((hovering++));;
        C) isSelected[hovering]=true;;
        D) unset isSelected[hovering];;
        '')[ "${isSelected[hovering]}" = true ] && \
           unset isSelected[hovering] || \
           isSelected[hovering]=true;;
      esac
    fi
  done

}

hovering=0
while true; do
  columns="$(tput cols)"
  lines="$(tput lines)"
  menu 'INPUT_FOLDER/FILES' '-Input' 'OUTPUT_DIRECTORY' 'PARAMETERS' 'COMPRESS'
done
