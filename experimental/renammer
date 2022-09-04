#!/bin/bash

readarray -t files <<< $(find . -type f)
readarray -t dates <<< $(find . -type f -printf '%CY%Cm%Cd-%CH%CM%CS\n' -type f | sed -E 's:.{11}$::g')

for ((i=0; i < "${#files[@]}"; i++)); do
  if [[ "${files[i]}" =~ '20'[1-2][0-9][-|\.|_]*[0-9][0-9][-|\.|_]*[0-9][0-9][-|\.|_]*[0-9]*[-|\.|_]*[0-9]* ]]; then
    newName="$(echo ${files[i]##*/} | egrep -o '20[1-2][0-9][-|\.|_]{0,1}[0-9]{2}[-|\.|_]{0,1}[0-9]{2}[-|\.|_]{0,1}[0-9]{0,2}[-|\.|_]{0,1}[0-9]{0,2}[-|\.|_]{0,1}[0-9]{0,2}' | sed 's:[-|\.|_]::g' | sed 's:.:&-:8' | sed 's:-$::g')"
    if [[ "${#newName}" == 15 ]] ; then

      # check if dupe
      if [[ "${names[@]}" =~ "$newName" ]]; then
#        newName="$(($newName+1))"
        newName="$newName-dupe"
      else
        names+=("$newName")
      fi

      echo -e "\e[32m${files[i]%/*}/$newName\e[0m"

    else

      newName="${newName:0:8}-000000"

      # check if dupe
      if [[ "${names[@]}" =~ "$newName" ]]; then
#        newName="$(($newName+1))"
        newName="$newName-dupe"
      else
        names+=("$newName")
      fi

      echo "${files[i]%/*}/$newName"

    fi

  else

    newName="${dates[i]}"

    # check if dupe
    if [[ "${names[@]}" =~ "$newName" ]]; then
#      newName="$(($newName+1))"
      newName="$newName-dupe"
    else
      names+=("$newName")
    fi

    echo -e "\e[31m${files[i]%/*}/$newName\e[0m      <<     ${files[i]##*/}"

  fi

done

printf '%s\n' "${names[@]}" > log
