#!/bin/bash

#=---------------=#
# CONFIG FUNCTION #
#=---------------=#

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

#=-------------------=#
# DEBUGGING FUNCTIONS #
#=-------------------=#

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

debugInfo() {

  echo
  echo -e "\e[34mInput options :\e[0m"
  echo
  echo -en "> Input : "; colorise "$input"
  echo -en "> Output : "; colorise "$output"
  echo
  echo -en "> Photos : "; colorise "$photos"
  echo -en "> Videos : "; colorise "$videos"
  echo -en "> Audios : "; colorise "$audios"
  echo
  echo -en "> Included extentions : "; colorise "${includedExtentions:1}"
  echo -en "> Excluded extentions : "; colorise "${excludedExtentions:1}"
  echo
  echo -en "> Recursive : "; colorise "$recursive"
  echo -en "> Overwrite : "; colorise "$overwrite"
  echo
  echo -e "\e[34mOther options :\e[0m"
  echo
  echo -en "> Threads : "; colorise "$threads"
  echo -en "> Verbose : "; colorise "$verbose"
  echo -en "> Logging : "; colorise "$logging"
  echo -en "> Loglevel : "; colorise "$loglevel"

}

colorise() {

  case "$1" in
    'true') echo -e "\e[32mtrue\e[0m";;
    'false') echo -e "\e[31mfalse\e[0m";;
    '') echo -e "\e[36mundefined\e[0m";;
    *) echo -e "\e[35m$1\e[0m";;
  esac

}

error() {

  echo -en '\e[31m\nERROR : '
  case "$1" in
    'badArg') echo "Unknown argument provided : $2";;
    'noArg') echo "No arguments provided";;
    'badParam') echo "Wrong parameter provided for argument $2 : $3";;
    'noParam') echo "No parameter provided for argument $2";;
    'badPath') echo "Non-existing path provided : $2";;
    'badCode') echo "Wrong code : $2";;
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

#=--------------=#
# ARGS FUNCTIONS #
#=--------------=#

processArgs() {

  getConfig
  args=($*); [ "$args" = '' ] && error 'noArg'
  [[ -n "$threads" ]] && threadsOption "$threads"
  for ((i=0; i < "${#args[@]}"; i++)); do
    previousArg="${args[i]}"
    case "${args[i]}" in
      '-i'|'--include') getNextArgs; includeOption "${nextArgs[@]}";;
      '-e'|'--exclude') getNextArgs; excludeOption;;
      '-l'|'--log'|'--logging') getNextArgs; logOption;;
      '-r'|'--recursive') recursive='true';;
      '-o'|'--overwrite') overwrite='true';;
      '-v'|'--verbose') verbose='true';;
      '-h'|'--help') help='true';;
      '-t'|'--threads') ((i++)); threadsOption "${args[i]}";;
      '-L'|'--loglevel') ((i++)); loglevelOption "${args[i]}";;
      *) error 'badArg' "${args[i]}";;
    esac
  done
  [ "$verbose" = 'true' ] && debugInfo
  [ "$logging" != 'false' ] && debugInfo | \
  sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" > "$logging"
  [ "$help" = 'true' ] && printHelp
  echo

}

getNextArgs() {

  unset nextArgs
  while [[ "${args[i+1]:0:1}" != '-' && -n "${args[i+1]}" ]]; do
    ((i++))
    nextArgs+=("${args[i]}")
  done

}

#getNextArgsFor() {
#
#  unset nextArgs
#  while [[ "${args[i+1]:0:1}" != '-' && -n "${args[i+1]}" ]]; do
#    ((i++))
#    nextArgs+=("${args[i]}")
#  done
#  "$1" "${nextArgs[@]}"
#
#}

#optionBuilder() {
#
#  readarray -t options < options
#  for ((j; j < "${#options[@]}"; j++)); do
#    line=(${options[j]})
#    case "${#line[@]}" in
#      1) getArgs; getActions; convertCode;;
#      0) :;;
#      *) error 'badCode' "${options[j]}";;
#    esac
#  done
#
#}
#
#getArgs() {
#
#  optionName="${options[j]% *}"
#  optionNames+=("$optionName")
#  optionID="${options[j]:0:1}"
#  [[ "${optionIDs[@]}" =~ "$optionID" ]] \
#  && optionID="${optionID^}"
#  [[ ! "${optionIDs[@]}" =~ "$optionID" ]] \
#  && optionIDs+=("$optionID") || optionID=""
#
#}
#
#getActions() {
#
#  while (( "${#options[j+1]}" > 0 )); do
#    ((j++)); line=(${options[j]})
#    for ((k=0; k < "${#line[@]}"; k++)); do
#      if [[ "${line[k]}" = ':' ]]; then
#        line='true'
#      fi
#    done
#    if [ "$line" = 'true' ]; then
#      unset line
#      optionCases+=("${options[j]}")
#    else
#      optionDo+=("${options[j]}")
#      [ "${optionDo[-1]: -1}" != ';' ] && \
#      optionDo["${#optionDo[@]}"]+=';'
#    fi
#  done
#
#}
#
#convertCode() {
#
#  for ((k=0; k < "${#optionCases[@]}"; k++)); do
#    line=(${optionCases[k]/\*/<star>})
#    l=0
#    while [[ "${line[l]}" != ':' ]]; do
#      convertedCase+="${line[l]}|"
#      ((l++))
#    done
#    convertedCase="${convertedCase::-1}) "
#    convertedCase="${convertedCase/<star>/*}"
#    ((l++))
#    while [[ "${line[l]}" != '' ]]; do
#      convertedCase+="${line[l]} "
#      ((l++))
#    done
#    convertedCase="${convertedCase::-1}"
#    convertedCase+=';;'
#    convertedCases+=("$convertedCase")
#    unset convertedCase
#  done
#
#  source <(echo "${optionName}Option"'() { optionArgs=(${*}); [[ -z "${optionArgs[@]}" ]] && error "noParam" '"'-$optionID or --$optionName'"'; '"${optionDo[@]}"' for ((j=0; j < "${#optionArgs[@]}"; j++)); do case "${optionArgs[j]}" in '"${convertedCases[@]}"' esac; done; }')
#  echo "${optionName}Option"'() { optionArgs=(${*}); [[ -z "${optionArgs[@]}" ]] && error "noParam" '"'-$optionID or --$optionName'"'; '"${optionDo[@]}"' for ((j=0; j < "${#optionArgs[@]}"; j++)); do case "${optionArgs[j]}" in '"${convertedCases[@]}"' esac; done; }'
#  unset optionDo
#
#}

includeOption() {

  [ "$nextArgs" = '' ] && error 'noParam' '-e or --exclude'
  for ((j=0; j < "${#nextArgs[@]}"; j++)); do
    case "${nextArgs[j]}" in
      'image'*|'photo'*|'picture'*|'pic'*) photos='true';;
      'movie'*|'video'*|'vid'*) videos='true';;
      'music'*|'audio'*) audios='true';;
      'all'|'everything') photos='true' && videos='true' && audios='true';;
      'none'|'nothing') photos='false' && videos='false' && audios='false';;
      *) extention="${nextArgs[j]/\./}" && extention="${extention,,}"
         includedExtentions+=" $extention"
    esac
  done

}

excludeOption() {

  [ "$nextArgs" = '' ] && error 'noParam' '-i or --exclude'
  for ((j=0; j < "${#nextArgs[@]}"; j++)); do
    case "${nextArgs[j]}" in
      'image'*|'photo'*|'picture'*|'pic'*) photos='false';;
      'movie'*|'video'*|'vid'*) videos='false';;
      'music'*|'audio'*) audios='false';;
      'all'|'everything') photos='false' && videos='false' && audios='false';;
      'none'|'nothing') photos='true' && videos='true' && audios='true';;
      *) extention="${nextArgs[j]/\./}" && extention="${extention,,}"
         excludedExtentions+=" $extention"
    esac
  done

}

logOption() {

  [ "$nextArgs" = '' ] && info 'noFile' '-l or --log' "log.txt" && logging='log.txt' && return
  [[ "$nextArgs" =~ '/' ]] && [[ ! -d "${nextArgs%/*}" ]] && error 'badPath' "${nextArgs%/*}"
  logging="$nextArgs"

}

loglevelOption() {

  [ "$1" = '' ] && error 'noParam' '-L or --loglevel'
  case "$1" in
    '2'|'info') loglevel='info';;
    '1'|'warn'|'warning') loglevel='warning';;
    '0'|'error') loglevel='error';;
    *) error 'badParam' '-L or --loglevel' "$1";;
  esac

}

#=------------=#
# MAIN PROGRAM #
#=------------=#

optionBuilder
processArgs "$@"
