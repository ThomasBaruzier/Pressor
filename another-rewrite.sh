#!/bin/bash

# help menu

usage() {

  echo "USAGE : $0 <input> <output> [arguments] "
  echo
  echo "Arguments :"
  echo
  echo "  --codec or -c <vp9|av1, jpg|avif, mp3|opus>"
  echo "  --recursive or -r : Include subfolders"
  echo
  echo "  --debug or -d : print debug information"
  echo "  --help or -h : print this menu"
  echo
  echo "Not yet implemented :"
  echo
  echo "  --crop <width>x<height> : Crop to fit photos and videos"
  echo "    --crop-photos <width>x<height> : For photos only"
  echo "    --crop-videos <width>x<height> : For videos only"
  echo
  echo "  --max-size <number> : Set a maximum size for photos and videos"
  echo "    --max-size-photos <number> : For photos only"
  echo "    --max-size-videos <number> : For videos only"
  echo
  echo "  --rename : rename output to photos and videos timestamps"
  echo "    --rename-photos : For photos only"
  echo "    --rename-videos : For videos only"
  echo
  echo "  --verbose or -v : print more information"
  echo "  --log or -l <file> : --verbose redirected to a file"
  echo "  --overwrite or -o : overwrites already compressed files"
  echo "  --threads or -t : control the usage of computing ressources"
  echo "  --crf : set video quality"
  echo "  --audio-bitrate : set audio bitrate"
  echo "  --av1-quality : set av1 quality"
  echo "  --vp9-quality: set vp9 quality"
  echo "  --avif-quality : set avif quality"
  echo
  exit

}

# argument processing
echo
args=($*); [[ -z "${args[0]}" ]] && usage
for ((i=0; i < "${#args[@]}"; i++)); do

  case "${args[i]}" in
    '--codec'|'-c') ((i++))
      echo "deal : ${args[i]}"

      while [[ "${args[i]:0:1}" != '-' && "${args[i]}" != '' ]]; do
        case "${args[i]}" in
          'vp9'|'av1') [[ -z "$videoCodec" ]] && videoCodec="${args[i]}" || \
            echo -e "\e[31mERROR : Please input only one video codec\e[0m";;
          'jpg'|'avif') [[ -z "$imageCodec" ]] && imageCodec="${args[i]}" || \
            echo -e "\e[31mERROR : Please input only one image codec\e[0m";;
          'mp3'|'opus') [[ -z "$audioCodec" ]] && audioCodec="${args[i]}" || \
            echo -e "\e[31mERROR : Please input only one audio codec\e[0m";;
          *) echo -e "\e[31mERROR : Bad codec\e[0m"; echo; usage;;
        esac
        ((i++))
      done
      ((i--));;

    '--recursive'|'-r') recursivity='true';;
    '--debug'|'-d') debug='true';;
    '--help'|'-h') usage;;

    -*)echo -e "\e[31mERROR : Invalid argument : '${args[i]}'\e[0m"
       [[ "${args[i]:0:1}" != '-' ]] && ((i++)); echo; usage;;

    *) if [[ -z "$input" ]]; then
         input="$(readlink -f ${args[i]})"
         if [[ ! -d "$input" && ! -f "$input" ]]; then
           echo -e "\e[31mERROR : Input path isn't a file or directory : '$input'\e[0m" && echo && exit
         fi
       elif [[ -z "$output" ]]; then
         output="$(readlink -f ${args[i]})"
         if [[ ! -d "$output" ]]; then
           echo -e "\e[31mERROR : Output path isn't a directory : '${output}'\e[0m\n"
           read -ren1 -p "Do you want to create it ? (default=n) : " makeOutputDirectory
           echo
           [[ "$makeOutputDirectory" = 'y' ]] && mkdir -p "$output" || unset output
         fi
       fi;;

  esac

done

[[ -z "$input" ]] && echo -e "\e[31mERROR : Input and output paths aren't set\e[0m\n" && exit
[[ -z "$output" ]] && echo -e "\e[31mERROR : Output path isn't set\e[0m\n" && exit

# debugging
if [[ "$debug" == 'true' ]]; then
  [[ -z "$input" ]] && input='not set'
  [[ -z "$output" ]] && output='not set'
  [[ -z "$recursivity" ]] && recursivity='false'
  [[ -z "$videoCodec" ]] && videoCodec='av1'
  [[ -z "$imageCodec" ]] && imageCodec='avif'
  [[ -z "$audioCodec" ]] && audioCodec='opus'
  echo -en '\e[36m'
  echo 'DEBBUGGING :'
  echo
  echo "Input : $input"
  echo "Output : $output"
  echo "Recursivity : $recursivity"
  echo "Video codec : $videoCodec"
  echo "Image codec : $imageCodec"
  echo "Audio codec : $audioCodec"
  echo -e '\e[0m'
fi

echo 'Starting...'
echo
