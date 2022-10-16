#!/bin/bash

# TODO

## better case regex
## exclude extentions in all concerned options
## exige a dot to confirm extention or be considered as error

# INITIALISATION

getConfig() {

  # input options

  inputs=('.')
  output='.'

  images='true'
  videos='true'
  audios='true'
  includeExtentions=''
  excludeExtentions=''

  recursive='true'
  overwrite='false'

  # encoding options

  imageCodec='avif'
  videoCodec='av1'
  audioCodec='opus'

  jpgQuality=''
  jpgEfficiency=''
  jxlQuality=''
  jxlEfficiency=''
  avifMinQuality=''
  avifMaxQuality=''
  avifEfficiency=''
  h264Quality=''
  h264Efficiency=''
  h264AudioQuality=''
  h265Quality=''
  h265Efficiency=''
  h265AudioQuality=''
  vp9Quality=''
  vp9Efficiency=''
  vp9AudioQuality=''
  av1Quality=''
  av1Efficiency=''
  av1AudioQuality=''
  vvcQuality=''
  vvcEfficiency=''
  vvcAudioQuality=''
  mp3Quality=''
  mp3Efficiency=''
  opusQuality=''
  opusEfficiency=''

  cropImages='false'
  cropVideos='false'
  cropImageValues=''
  cropVideoValues=''

  threads='all'

  # output options

  renameImages='false'
  renameVideos='false'
  renameAudios='false'
  renameExtentions=''

  tree='true'

  # other options

  verbose='false'
  log='false'
  loglevel='info'

}

processArgs() {

  # perform actions that need to be done before agument scanning
  args=("$@")
  for ((i=0; i < "${#args[@]}"; i++)); do
    args[i]="${args[i]/\~/$HOME}"
    [[ "${args[i]}" = '-h' || "${args[i]}" = '--help' ]] && printHelp
    [[ "${args[i]}" = '-i' || "${args[i]}" = '--include' ]] \
    && videos='false' && images='false' && audios='false' && unset includeExtentions
    [[ "${args[i]}" = '-e' || "${args[i]}" = '--exclude' ]] \
    && videos='true' && images='true' && audios='true' && unset excludeExtentions
    [[ "${args[i]}" = '-R' || "${args[i]}" = '--rename' ]] \
    && renameVideos='false' && renameImages='false' && renameAudios='false' && unset renameExtentions
    [[ "${args[i]}" = '-C' || "${args[i]}" = '--crop' ]] \
    && cropVideos='false' && cropImages='false' && cropAudios='false'
  done

  # get paths
  i=0
  while [[ "${args[i]:0:1}" != '-' && "${args[i]}" != '' ]]; do
    paths+=("${args[i]}")
    ((i++))
  done

  # determine if elements in paths are input or output
  if [ "${#paths[@]}" = 1 ]; then
    inputs="$args"
  elif [ "${#paths[@]}" != 0 ]; then
    inputs=("${paths[@]::${#paths[@]}-1}")
    if [[ -f "${paths[-1]}" ]]; then
      inputs+=("${paths[-1]}")
    else
      output="${paths[-1]}"
    fi
  fi

  # loop through the next arguments
  for ((; i < "${#args[@]}"; i++)); do
    for ((j=0; j < "${#optionNames[@]}"; j++)); do

      # if there is a match
      if [[ "${optionIDs[j]}" = "${args[i]}" || "${optionNames[j]}" = "${args[i]}" ]]; then
        match='true'
        optionName="${optionNames[j]:2}Option"

        # get the argument's options
        while [[ "${args[i+1]:0:1}" != '-' && -n "${args[i+1]}" ]]; do
          ((i++))
          nextArgs+=("${args[i]}")
        done

        # fire the argument's function with its arguments
        [ "${nextArgs[*]}" = '' ] && nextArgs='default'
        $optionName "${nextArgs[@]}"
        unset nextArgs optionName

      fi
    done
    [ "$match" != 'true' ] && error 'badArg' "${args[i]}"
    unset match
  done

  # activate options / warn
  [ "${#paths[@]}" = 0 ] && warn 'noArg' "'${inputs[@]}' as input(s) and '$output' as output"
  for i in "${inputs[@]}"; do
    if [[ "$i" =~ '/' ]]; then
      [[ -d "$i" || -f "$i" ]] || error 'badPath' "$i"
    fi
  done
  [[ -n "${cropImageValues[@]}" && -z "${cropVideoValues[@]}" ]] && cropVideoValues="${cropImageValues[@]}"
  [[ -z "${cropImageValues[@]}" && -n "${cropVideoValues[@]}" ]] && cropImageValues=("${cropVideoValues[@]}")
  [[ "$output" =~ '/' ]] && [[ -f "$output" ]] && error 'badPath' "$output" || [[ ! -d "$output" ]] && warn 'createPath' "$output"
  [ "$verbose" = 'true' ] && printVerbose
  [[ "$log" != 'false' && "$log" != '' ]] && printVerbose | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" >> "$log"
  [ "$help" = 'true' ] && printHelp

}

optionBuilder() {

  # read options
  readarray -t options < "$0"
  i=0; while [[ "${options[i-2]}" != '# OPTIONS' ]]; do ((i++)); done
  for ((; i <= "${#options[@]}"; i++)); do

    # give it a name and an ID
    if [[ "${options[i]}" =~ ^[a-zA-Z]+$ ]]; then
      optionName="--${options[i],,}"
      optionNames+=("$optionName")
      optionID="${optionName:1:2}"

      # get a unique ID if it is a duplicate
      alphabet=(a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P k K r R s S t T u U v V w W x X y Y z Z)
      for ((index=0; index < "${#alphabet[@]}"; index++)); do
        [[ "-${alphabet[index]}" = "$optionID" ]] && break
      done
      while [[ "${optionIDs[@]}" =~ "$optionID" ]]; do
        ((index++))
        [ "$index" = 52 ] && index=0
        optionID="-${alphabet[index]}"
      done
      optionIDs+=("$optionID")

    # differenciate options' tasks from cases
    elif [[ "${options[i]}" =~ ';;'$ ]]; then
      optionCases+="${options[i]} "
    elif [[ -n "${options[i]}" ]]; then
      optionTasks+="${options[i]};"

    # build and fire the function
    elif [[ -n "$optionName" ]]; then
      source <(echo "${optionName:2}Option"'() { optionArgs=(${*}); name='"$optionName"'; id='"$optionID"'; '"$optionTasks"' for ((index=0; index < "${#optionArgs[@]}"; index++)); do arg="${optionArgs[index]}"; case "${optionArgs[index]}" in '"$optionCases"' esac; done; }')
      unset optionName optionID optionCases optionTasks index
    fi
  done

}

# DEBUGGING

printHelp() {

  i=0
  echo
  echo "USAGE : $0 <input(s)> <output> [arguments]"
  echo
  echo "Input options :"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} {all|none|videos|images|audios|<extention(s)>}"; ((i++))
  echo "  ${optionIDs[i]}, ${optionNames[i]} {all|none|videos|images|audios|<extention(s)>}"; ((i++))
  echo "      > Include or exclude file types or extentions"
  echo "      > Default : all (in both options)"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]}"; ((i++))
  echo "      > Include subfolders"
  echo "      > Default : true"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]}"; ((i++))
  echo "      > Overwrites already compressed files"
  echo "      > Default : false"
  echo
  echo "Encoding options :"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} {jpg|jxl|avif|h264|h265|vp9|av1|vvc|mp3|opus} {quality}"; ((i++))
  echo "      > Choose encoding codecs and quality parameters"
#  echo "      > Quality arguments (for common users) :"
#  echo "        {quality score/10} {compression efficiency/10} {audio quality/10}"
  echo "      > Quality arguments (for expert users) :"
  echo "        • jpg <q:scale> (2-31) <preset> (placebo-veryfast)"
  echo "        • jxl (planned for future versions)"
  echo "        • avif <min> (0-63) <max> (0-63) <speed> (0-10)"
  echo "        • h264|h265 <crf> (0-63) <preset> (placebo-veryfast) <aac-bitrate> (256-6)"
  echo "        • vp9 <crf> (0-63) <cpu-used> (0-16) <opus-bitrate> (256-6)"
  echo "        • av1 <cq-level> (0-8) <cpu-used> (0-9) <opus-bitrate> (256-6)"
  echo "        • vvc <preset> (slower-fast) <bitrate|qc> (n|0-63) <opus-bitrate> (256-6)"
  echo "        • mp3|opus <bitrate> (256-6)"
  echo "      > Defaults : set in config"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} {all|images|videos} <width>x<height>|<max-length>"; ((i++))
  echo "      > Crop and zoom to fit or set a maximum length without distortions"
  echo "      > Default : none"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} <all|number-of-threads>"; ((i++))
  echo "      > Number of threads to use"
  echo "      > Default : all"
  echo
  echo "Output options :"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} {all|none|videos|images|audios|<extention(s)>}"; ((i++))
  echo "      > Rename the output files to their timestamps"
  echo "      > Default : none"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]}"; ((i++))
  echo "      > Copy the input folder hierarachy to output"
  echo "      > Default : true"
  echo
  echo "Other options :"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} : print more information"; ((i++))
  echo "  ${optionIDs[i]}, ${optionNames[i]} {file} : --verbose redirected to a file"; ((i++))
  echo "  ${optionIDs[i]}, ${optionNames[i]} <0|1|2|info|warning|error>"; ((i++))
  echo "  ${optionIDs[i]}, ${optionNames[i]} : print this menu"
  echo
  exit

}

printVerbose() {

  [[ -n "${avifMinQuality}" || -n "${avifMaxQuality}" ]] && avifQuality="${avifMinQuality}-${avifMaxQuality}"
  echo
  echo -e "\e[34mInput options :\e[0m"
  echo
  echo -en "> Input(s) : "; colorise "${inputs[@]}"
  echo -en "> Output : "; colorise "$output"
  echo
  echo -en "> Images : "; colorise "$images"
  echo -en "> Videos : "; colorise "$videos"
  echo -en "> Audios : "; colorise "$audios"
  echo -en "> Include extentions : "; colorise "${includeExtentions:1}"
  echo -en "> Exclude extentions : "; colorise "${excludeExtentions:1}"
  echo
  echo -en "> Recursive : "; colorise "$recursive"
  echo -en "> Overwrite : "; colorise "$overwrite"
  echo
  echo -e "\e[34mEncoding options :\e[0m"
  echo
  echo -en "> Image codec : "; colorise "$imageCodec"
  echo -en "> Video codec : "; colorise "$videoCodec"
  echo -en "> Audio codec : "; colorise "$audioCodec"
  echo
  echo     "Codec | Quality    | Efficiency | Audio Quality"
  echo     "——————|————————————|————————————|——————————————"
  echo -en "JPG   | "; colorise 'tab' "$jpgQuality"; colorise 'tab' "$jpgEfficiency"; echo
  echo -en "JXL   | "; colorise 'tab' "$jxlQuality"; colorise 'tab' "$jxlEfficiency"; echo
  echo -en "AVIF  | "; colorise 'tab' "$avifQuality"; colorise 'tab' "$avifEfficiency"; echo
  echo -en "H264  | "; colorise 'tab' "$h264Quality"; colorise 'tab' "$h264Efficiency"; colorise "$h264AudioQuality"
  echo -en "H265  | "; colorise 'tab' "$h265Quality"; colorise 'tab' "$h265Efficiency"; colorise "$h265AudioQuality"
  echo -en "VP9   | "; colorise 'tab' "$vp9Quality"; colorise 'tab' "$vp9Efficiency"; colorise "$vp9AudioQuality"
  echo -en "AV1   | "; colorise 'tab' "$av1Quality"; colorise 'tab' "$av1Efficiency"; colorise "$av1AudioQuality"
  echo -en "VVC   | "; colorise 'tab' "$vvcQuality"; colorise 'tab' "$vvcEfficiency"; colorise "$vvcAudioQuality"
  echo -en "MP3   | "; colorise 'tab' "$mp3Quality"; colorise 'tab' "$mp3Efficiency"; echo
  echo -en "OPUS  | "; colorise 'tab' "$opusQuality"; colorise 'tab' "$opusEfficiency"; echo
  echo
  echo -en "> Crop images : "; colorise "$cropImages"
  echo -en "> Crop videos : "; colorise "$cropVideos"
  echo -en "> Crop image value(s) : "; colorise "${cropImageValues[@]}"
  echo -en "> Crop video value(s) : "; colorise "${cropVideoValues[@]}"
  echo
  echo -en "> Threads : "; colorise "$threads"
  echo
  echo -e "\e[34mOutput options :\e[0m"
  echo
  echo -en "> Rename images : "; colorise "$renameImages"
  echo -en "> Rename videos : "; colorise "$renameVideos"
  echo -en "> Rename audios : "; colorise "$renameAudios"
  echo -en "> Rename extentions : "; colorise "$renameExtentions"
  echo
  echo -en "> Tree : "; colorise "$tree"
  echo
  echo -e "\e[34mOther options :\e[0m"
  echo
  echo -en "> Verbose : "; colorise "$verbose"
  echo -en "> Log : "; colorise "$log"
  echo -en "> Loglevel : "; colorise "$loglevel"

}

colorise() {

  case "$1" in
    'true') echo -e "\e[32mtrue\e[0m";;
    'false') echo -e "\e[31mfalse\e[0m";;
    '') echo -e "\e[35mundefined\e[0m";;
    'tab')
      [[ -z "$2" ]] && echo -en "\e[35mundefined\e[0m  | "
      [[ -n "$2" ]] && printf '\e[36m%-11s\e[0m| ' "$2";;
    *) echo -e "\e[36m$@\e[0m";;
  esac

}

error() {

  echo -en '\e[31m\nERROR : '
  case "$1" in
    'badArg') echo "Wrong or unknown argument provided : $2";;
    'noArg') echo "No arguments provided";;
    'badParam') echo "Wrong parameter provided for argument $2 : $3";;
    'noParam') echo "No parameter provided for argument $2";;
    'badPath') echo "Non-existing path provided : $2";;
    'badCons') echo "Bad option construction for argument $2"; echo "Usage : $3";;
    'badOption') echo "Wrong option $2 for parameter $3 inside of argument $4";;
  esac
  echo -e "\e[0mFor help, use $0 --help\n"
  exit

}

warn() {

  [ "$loglevel" = 'error' ] && return
  echo -en '\e[33m\nWARNING : '
  case "$1" in
    'noArg') echo "No arguments provided : Using $2";;
    'noParam') echo "No parameter provided for argument $2 : Using $3";;
    'badParam') echo "Wrong or unknown parameter provided for argument $2";;
    'createPath') echo "Not a valid path : $2. Creating it.";;
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

# ADVANCED OPTIONS

cropAdvanced() {

  if [[ "$arg" =~ ^[0-9]*$ && "${nextArgs[index+1]}" =~ ^[0-9]+$ ]]; then
    dimentions="${arg} ${nextArgs[index+1]}"
    ((index++))
    [[ "$index" = 1 && "${nextArgs[index+1]}" =~ [a-zA-Z] ]] && error "badCons" "$id or $name" "$name <type> <dimention(s)> or --crop <dimention(s)>"
  elif [[ "$arg" =~ ^[0-9]*'x'?':'?[0-9]*$ ]]; then
    dimentions="${arg/x/ }"
    dimentions="${dimentions/:/ }"
    [[ "$index" = 0 && "${nextArgs[index+1]}" =~ [a-zA-Z] ]] && error "badCons" "$id or $name" "$name <type> <dimention(s)> or --crop <dimention(s)>"
  else
    error 'badArg' "$arg"
  fi
  [[ "$arg" = 0 || "${nextArgs[index+1]}" = 0 ]] && error 'badArg' "0 (you can't crop by 0)"
  case "${nextArgs[index-1]}" in
    image*|photo*|picture*|pic*) cropImageValues="$dimentions";;
    movie*|video*|vid*) cropVideoValues="$dimentions";;
    none|nothing) error 'badOption' "$arg" "${nextArgs[index-1]}" "$id or $name (you need to specify a valid type of file to apply crop values)";;
    "$arg"|default|all|everything) cropImageValues="$dimentions"; cropImages='true'; cropVideos='true'; cropImageValues="$dimentions"; cropVideoValues="$dimentions";;
  esac

}

codecAdvanced() {

  case "${nextArgs[0]}" in
    jpg|jxl|avif|h264|h265|vp9|av1|vvc|mp3|opus)
      toProcess+=("${nextArgs[index-1]}")
      while [[ -n "${nextArgs[index]}" ]]; do
        case "${nextArgs[index]}" in
          jpg|jxl|avif|h264|h265|vp9|av1|vvc|mp3|opus) break;;
          *) toProcess+=("${nextArgs[index]}"); ((index++));;
        esac
      done
      (( "${#toProcess[@]}" > 4 )) && error "badCons" "$id or $name" "$name <type> or $name <type> <quality> or $name <type> <quality> <efficiency>"
      case "${toProcess[0]}" in
        jpg) jpgQuality="${toProcess[1]}"; jpgEfficiency="${toProcess[2]}";;
        jxl) jxlQuality="${toProcess[1]}"; jxlEfficiency="${toProcess[2]}";;
        avif) avifMinQuality="${toProcess[1]}"; avifMaxQuality="${toProcess[2]}"; avifEfficiency="${toProcess[3]}";;
        h264) h264Quality="${toProcess[1]}"; h264Efficiency="${toProcess[2]}"; h264AudioQuality="${toProcess[3]}";;
        h265) h265Quality="${toProcess[1]}"; h265Efficiency="${toProcess[2]}"; h265AudioQuality="${toProcess[3]}";;
        vp9) vp9Quality="${toProcess[1]}"; vp9Efficiency="${toProcess[2]}"; vp9AudioQuality="${toProcess[3]}";;
        av1) av1Quality="${toProcess[1]}"; av1Efficiency="${toProcess[2]}"; av1AudioQuality="${toProcess[3]}";;
        vvc) vvcQuality="${toProcess[1]}"; vvcEfficiency="${toProcess[2]}"; vvcAudioQuality="${toProcess[3]}";;
        mp3) mp3Quality="${toProcess[1]}"; mp3Efficiency="${toProcess[2]}";;
        opus) opusQuality="${toProcess[1]}"; opusEfficiency="${toProcess[2]}";;
      esac
      unset toProcess
      ;;
    *) error "badCons" "$id or $name" "$name <type> or $name <type> <quality> or $name <type> <quality> <efficiency>";;
  esac

}


# MAIN PROGRAM

optionBuilder
getConfig
processArgs "$@"
echo; exit

# OPTIONS

INCLUDE
image*|photo*|picture*|pic*) images='true';;
movie*|video*|vid*) videos='true';;
music*|audio*) audios='true';;
default|all|everything) images='true'; videos='true'; audios='true';;
none|nothing) images='false'; videos='false'; audios='false';;
*) extention="${arg/\./}"; extention="${extention,,}"; includeExtentions+=" $extention"; excludeExtentions="${excludeExtentions// $extention}";;

EXCLUDE
image*|photo*|picture*|pic*) images='false';;
movie*|video*|vid*) videos='false';;
music*|audio*) audios='false';;
default|all|everything) images='false'; videos='false'; audios='false';;
none|nothing) images='true'; videos='true'; audios='true';;
*) extention="${arg/\./}"; extention="${extention,,}"; excludeExtentions+=" $extention"; includeExtentions="${includeExtentions// $extention}";;

RECURSIVE
default|y|yes|'true') recursive='true';;
n|no|'false') recursive='false';;
*) error 'badParam' "$id or $name" "$arg";;

OVERWRITE
default|y|yes|'true') overwrite='true';;
n|no|'false') overwrite='false';;
*) error 'badParam' "$id or $name" "$arg";;

CODEC
jpg|jxl|avif) imageCodec="$arg";;
h264|h265|vp9|av1|vvc) videoCodec="$arg";;
mp3|opus) audioCodec="$arg";;
default) error 'noParam' "$id or $name" "$arg";;
*) codecAdvanced;;

CROP
image*|photo*|picture*|pic*) cropImages='true';;
movie*|video*|vid*) cropVideos='true';;
music*|audio*) error 'badArg' "$arg (you can't crop audio files)";;
default|all|everything) cropImages='true'; cropVideos='true';;
none|nothing) cropImages='false'; cropVideos='false';;
*) cropAdvanced;;

THREADS
availableThreads="$(($(cat /proc/cpuinfo | grep -Po 'processor[^0-9]+\K[0-9]+$' | tail -n 1)+1))"
all|max|everything) threads="$availableThreads";;
[1-9]|[0-9][0-9]|[0-9][0-9][0-9]) (( "$arg" > "$availableThreads" )) && warn "maxThreads" "$availableThreads" "$arg" || threads="$(($arg))";;
default) warn 'noParam' "$id or $name" "$arg" "$availableThreads threads" && threads="$availableThreads";;
*) error 'badParam' "$id or $name" "$arg";;

RENAME
image*|photo*|picture*|pic*) renameImages='true';;
movie*|video*|vid*) renameVideos='true';;
music*|audio*) renameAudios='true';;
default|all|everything) renameImages='true'; renameVideos='true'; renameAudios='true';;
none|nothing) renameImages='false'; renameVideos='false'; renameAudios='false';;
*) extention="${arg/\./}"; extention="${extention,,}"; renameExtentions="${renameExtentions// $extention}"; renameExtentions+=" $extention";;

TREE
default|y|yes|'true') tree='true';;
n|no|'false') tree='false';;
*) error 'badParam' "$id or $name" "$arg";;

VERBOSE
default|y|yes|'true') verbose='true';;
n|no|'false') verbose='false';;
*) error 'badParam' "$id or $name" "$arg";;

LOG
default) info 'noFile' "$id or $name" "$arg" "log.txt" && log='log.txt';;
*/*) [[ ! -d "${nextArgs%/*}" ]] && error 'badPath' "${nextArgs%/*}"; log="$nextArgs";;
*) log="$nextArgs";;

LOGLEVEL
2|i|info*|information*) loglevel='info';;
1|w|warn*|warning*) loglevel='warning';;
0|e|err|error*) loglevel='error';;
default) error 'noParam' "$id or $name";;
*) error 'badParam' "$id or $name" "$arg";;

HELP
*) printHelp;;
