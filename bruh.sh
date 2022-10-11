#!/bin/bash


# INITIALISATION

getConfig() {

  input=''
  output=''

  videos='true'
  photos='true'
  audios='true'

  includedExtentions=''
  excludedExtentions=''

  recursive='false'
  overwrite='false'
  threads='all'

  verbose='false'
  logging='false'
  loglevel='info'

}

optionBuilder() {

  readarray -t options < "$0"
  i=0; while [[ "${options[i-2]}" != '# OPTIONS' ]]; do ((i++)); done
  for ((; i <= "${#options[@]}"; i++)); do
    if [[ "${options[i]}" =~ ^[a-zA-Z]+$ ]]; then
      optionName="${options[i],,}"
      optionID="${optionName:0:1}"
      [[ "${optionIDs[@]}" =~ "$optionID" ]] && optionID="${optionID^}"
      [[ ! "${optionIDs[@]}" =~ "$optionID" ]] && optionIDs+=("$optionID") || optionID=""
    elif [[ "${options[i]}" =~ ';;'$ ]]; then
      optionCases+="${options[i]} "
    elif [[ -n "${options[i]}" ]]; then
      optionTasks+="${options[i]};"
    elif [[ -n "$optionName" ]]; then
      source <(echo "${optionName}Option"'() { optionArgs=(${*}); [[ -z "${optionArgs[@]}" ]] && error "noParam" '"'-$optionID or --$optionName'"'; '"$optionTasks"' for ((index=0; index < "${#optionArgs[@]}"; index++)); do case "${optionArgs[index]}" in '"$optionCases"' esac; done; }')
      echo "${optionName}Option"'() { optionArgs=(${*}); [[ -z "${optionArgs[@]}" ]] && error "noParam" '"'-$optionID or --$optionName'"'; '"$optionTasks"' for ((index=0; index < "${#optionArgs[@]}"; index++)); do case "${optionArgs[index]}" in '"$optionCases"' esac; done; }'
      unset optionName optionID optionCases optionTasks
    fi
  done

}

# DEBUGGING

printHelp() {

  echo
  echo "USAGE : $0 <input> <output> [arguments]"
  echo
  echo "Input options :"
  echo
  echo "  -i, --include {all|none|videos|photos|audios|<extention>}"
  echo "  -e, --exclude {all|none|videos|photos|audios|<extention>}"
  echo "      > Include or exclude file types or extentions"
  echo "      > Default : include everything"
  echo
  echo "  -r, --recursive"
  echo "      > Include subfolders"
  echo "      > Default : false"
  echo "  -o, --overwrite"
  echo "      > Overwrites already compressed files"
  echo "      > Default : false"
  echo
#  echo "Encoding options :"
#  echo
#  echo "  -C, --codec {jpg|jxl|avif|h264|h265|vp9|av1|vvc|mp3|opus} {quality}"
#  echo "      > Choose encoding codecs and quality parameters"
#  echo "      > Quality arguments :"
#  echo "        {quality score/10} {compression efficiency/10} {audio quality/10}"
#  echo "      > Default : "
#  echo "      > Quality arguments (for expert users) :"
#  echo "      > Example : -C vp9 21 -5 avif 30 mp3"
#  echo "        • jpg <q:scale> (2-31) <preset> (placebo-veryfast)"
#  echo "          > Default : "
#  echo "        • jxl (planned for future versions)"
#  echo "          > Default : "
#  echo "        • avif <min> (0-63) <max> (0-63) <speed> (0-10)"
#  echo "          > Default : "
#  echo "        • h264|h265 <crf> (0-63) <preset> (placebo-veryfast) <opus-bitrate> (256-6)"
#  echo "          > Default : "
#  echo "        • vp9 <crf> (0-63) <cpu-used> (-8-8) <opus-bitrate> (256-6)"
#  echo "          > Default : "
#  echo "        • av1 <cq-level> (0-8) <cpu-used> (0-9) <opus-bitrate> (256-6)"
#  echo "          > Default : "
#  echo "        • vvc <preset> (slower-fast) <bitrate|qc> (n|0-63)"
#  echo "          > Default : "
#  echo "        • mp3|opus <bitrate> (256-6)"
#  echo "          > Default : "
#  echo "  -c, --crop {all|photos|videos} <width>x<height>"
#  echo "      > Crop and zoom to fit whithout distortions"
#  echo "      > Default : "
#  echo "  -m, --max-size {all|photos|videos} <pixels>"
#  echo "      > Set a maximum lenght size in pixels"
#  echo "      > Default : "
#  echo
#  echo "Output options :"
#  echo
#  echo "  -R, --rename {all|none|photos|videos|audios}"
#  echo "      > Rename the output files to their timestamps"
#  echo "      > Default : "
#  echo "  -T, --copy-tree"
#  echo "      > Replicate the input folder hierarachy for output"
#  echo "      > Default : true"
#  echo
  echo "Other options :"
  echo
  echo "  -t, --threads <all|number-of-threads>"
  echo "      > Number of threads to use"
  echo "      > Default : all"
  echo
  echo "  -v, --verbose : print more information"
  echo "  -l, --log {file} : --verbose redirected to a file"
  echo "  -L, --loglevel <0|1|2|info|warning|error>"
  echo "  -h, --help : print this menu"
  echo
  exit

}

error() {

  echo -en '\e[31m\nERROR : '
  case "$1" in
    'badArg') echo "Unknown argument provided : $2";;
    'noArg') echo "No arguments provided";;
    'badParam') echo "Wrong parameter provided for argument $2 : $3";;
    'noParam') echo "No parameter provided for argument $2";;
    'badPath') echo "Non-existing path provided : $2";;
  esac
  echo -en '\e[0m'
  printHelp

}

warn() {

  [ "$loglevel" = 'error' ] && return
  echo -en '\e[33m\nWARNING : '
  case "$1" in
    'maxThreads') echo "Using $2 threads instead of $3 (it's the maximum available)";;
  esac
  echo -en '\e[0m'

}

info() {

  [[ "$loglevel" = 'error' || "$loglevel" = 'warning' ]] && return
  echo -en '\nINFO : '
  case "$1" in
    'noFile') echo "No filename provided for $2 : Using $3";;
  esac

}

# MAIN PROGRAM

optionBuilder
processArgs "$@"
exit

# OPTIONS

THREADS
availableThreads="$(($(cat /proc/cpuinfo | grep -Po 'processor[^0-9]+\K[0-9]+$' | tail -n 1)+1))"
all|max|everything) threads="$availableThreads";;
[1-9]|[0-9][0-9]|[0-9][0-9][0-9]) (( "$1" > "$availableThreads" )) && warn "maxThreads" "$availableThreads" "$1" || threads="$(($1))";;
*) error 'badParam' '-t or --threads' "$1";;

INCLUDE
image*|photo*|picture*|pic*) photos='true';;
movie*|video*|vid*) videos='true';;
music*|audio*) audios='true';;
all|everything) photos='true'; videos='true'; audios='true';;
none|nothing) photos='false'; videos='false'; audios='false';;
*) extention="${1/\./}"; extention="${extention,,}"; includedExtentions+="$extention";;

EXCLUDE
image*|photo*|picture*|pic*) photos='false';;
movie*|video*|vid*) videos='false';;
music*|audio*) audios='false';;
all|everything) photos='false'; videos='false'; audios='false';;
none|nothing) photos='true'; videos='true'; audios='true';;
*) extention="${1/\./}"; extention="${extention,,}"; includedExtentions+="$extention";;
