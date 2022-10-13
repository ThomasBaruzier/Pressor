#!/bin/bash


# INITIALISATION

getConfig() {

  inputs=('.')
  output='.'

  images='true'
  videos='true'
  audios='true'

  includedExtentions=''
  excludedExtentions=''

  imageCodec='avif'
  videoCodec='av1'
  audioCodec='opus'

  recursive='true'
  overwrite='false'
  threads='all'

  verbose='false'
  log='false'
  loglevel='info'

}

processArgs() {

  # perform actions that need to be done before agument scanning
  args=("$@")
  for ((i=0; i < "${#args[@]}"; i++)); do
    [[ "${args[i]}" = '-h' || "${args[i]}" = '--help' ]] && printHelp
    [[ "${args[i]}" = '-i' || "${args[i]}" = '--include' ]] \
    && videos='false' && images='false' && audios='false' && unset includedExtentions
    [[ "${args[i]}" = '-e' || "${args[i]}" = '--exclude' ]] \
    && videos='true' && images='true' && audios='true' && unset excludedExtentions
  done

  # get paths
  i=0
  while [[ "${args[i]:0:1}" != '-' && "${args[i]}" != '' ]]; do
    paths+=("${args[i]}")
    ((i++))
  done

  # determine if elements in paths are input or output
  if [ "${#paths[@]}" = 0 ]; then
    warn 'noArg' "${inputs[@]} as input(s) and $output as output"
  elif [ "${#paths[@]}" = 1 ]; then
    inputs="$args"
  else
    inputs="${paths[@]::${#paths[@]}-1}"
    output="${paths[-1]}"
  fi
  [[ "$output" =~ '/' && ! -d "$output" ]] && warn 'createPath' "$output"

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

  # activate options
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
      source <(echo "${optionName:2}Option"'() { optionArgs=(${*}); '"$optionTasks"' for ((index=0; index < "${#optionArgs[@]}"; index++)); do case "${optionArgs[index]}" in '"$optionCases"' esac; done; }')
      unset optionName optionID optionCases optionTasks index
    fi
  done

}

# DEBUGGING

printHelp() {

  echo
  echo "USAGE : $0 <input(s)> <output> [arguments]"
  echo
  echo "Input options :"
  echo
  echo "  -i, --include {all|none|videos|images|audios|<extention(s)>}"
  echo "  -e, --exclude {all|none|videos|images|audios|<extention(s)>}"
  echo "      > Include or exclude file types or extentions"
  echo "      > Default : all (in both options)"
  echo
  echo "  -r, --recursive"
  echo "      > Include subfolders"
  echo "      > Default : false"
  echo "  -o, --overwrite"
  echo "      > Overwrites already compressed files"
  echo "      > Default : false"
  echo
  echo "Encoding options :"
  echo
  echo "  -c, --codec {jpg|jxl|avif|h264|h265|vp9|av1|vvc|mp3|opus} {quality}"
#  echo "      > Choose encoding codecs and quality parameters"
#  echo "      > Quality arguments (for common users) :"
#  echo "        {quality score/10} {compression efficiency/10} {audio quality/10}"
#  echo "      > Default : "
#  echo "      > Quality arguments (for expert users) :"
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
#  echo "  -c, --crop {all|images|videos} <width>x<height>"
#  echo "      > Crop and zoom to fit whithout distortions"
#  echo "      > Default : "
#  echo "  -m, --max-size {all|images|videos} <pixels>"
#  echo "      > Set a maximum lenght size in pixels"
#  echo "      > Default : "
#  echo
#  echo "Output options :"
#  echo
#  echo "  -R, --rename {all|none|videos|image|audios|<extention(s)>}"
#  echo "      > Rename the output files to their timestamps"
#  echo "      > Default : "
#  echo "  -T, --copy-tree"
#  echo "      > Replicate the input folder hierarachy for output"
#  echo "      > Default : true"
  echo
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

printVerbose() {

  echo
  echo -e "\e[34mInput options :\e[0m"
  echo
  echo -en "> Input(s) : "; colorise "${inputs[@]}"
  echo -en "> Output : "; colorise "$output"
  echo
  echo -en "> Images : "; colorise "$images"
  echo -en "> Videos : "; colorise "$videos"
  echo -en "> Audios : "; colorise "$audios"
  echo
  echo -en "> Included extentions : "; colorise "${includedExtentions:1}"
  echo -en "> Excluded extentions : "; colorise "${excludedExtentions:1}"
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
  echo -e "\e[34mOther options :\e[0m"
  echo
  echo -en "> Threads : "; colorise "$threads"
  echo -en "> Verbose : "; colorise "$verbose"
  echo -en "> Logging : "; colorise "$log"
  echo -en "> Loglevel : "; colorise "$loglevel"

}

colorise() {

  case "$1" in
    'true') echo -e "\e[32mtrue\e[0m";;
    'false') echo -e "\e[31mfalse\e[0m";;
    '') echo -e "\e[35mundefined\e[0m";;
    *) echo -e "\e[36m$@\e[0m";;
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
*) extention="${nextArgs[index]/\./}"; extention="${extention,,}"; includedExtentions+=" $extention"; excludedExtentions="${excludedExtentions// $extention}";;

EXCLUDE
image*|photo*|picture*|pic*) images='false';;
movie*|video*|vid*) videos='false';;
music*|audio*) audios='false';;
default|all|everything) images='false'; videos='false'; audios='false';;
none|nothing) images='true'; videos='true'; audios='true';;
*) extention="${nextArgs[index]/\./}"; extention="${extention,,}"; excludedExtentions+=" $extention"; includedExtentions="${includedExtentions// $extention}";;

RECURSIVE
default|y|yes|'true') recursive='true';;
n|no|'false') recursive='false';;
*) error 'badParam' '-r or --recursive' "${nextArgs[index]}";;

OVERWRITE
default|y|yes|'enable'|'true') overwrite='true';;
n|no|disable|'false') overwrite='false';;
*) error 'badParam' '-o or --overwrite' "${nextArgs[index]}";;

CODEC
jpg|jxl|avif) imageCodec="${nextArgs[index]}";;
h264|h265|vp9|av1|vvc) videoCodec="${nextArgs[index]}";;
mp3|opus) audioCodec="${nextArgs[index]}";;
*) error 'badParam' '-c or --codec' "${nextArgs[index]}";;

THREADS
availableThreads="$(($(cat /proc/cpuinfo | grep -Po 'processor[^0-9]+\K[0-9]+$' | tail -n 1)+1))"
all|max|everything) threads="$availableThreads";;
[1-9]|[0-9][0-9]|[0-9][0-9][0-9]) (( "${nextArgs[index]}" > "$availableThreads" )) && warn "maxThreads" "$availableThreads" "${nextArgs[index]}" || threads="$((${nextArgs[index]}))";;
default) warn 'noParam' '-t or --threads' "$availableThreads threads" && threads="$availableThreads";;
*) error 'badParam' '-t or --threads' "${nextArgs[index]}";;

VERBOSE
default|y|yes|'enable'|'true') verbose='true';;
n|no|disable|'false') verbose='false';;
*) error 'badParam' '-v or --verbose' "${nextArgs[index]}";;

LOG
default) info 'noFile' '-l or --log' "log.txt" && log='log.txt';;
*/*) [[ ! -d "${nextArgs%/*}" ]] && error 'badPath' "${nextArgs%/*}"; log="$nextArgs";;
*) log="$nextArgs";;

LOGLEVEL
2|i|info*|information*) loglevel='info';;
1|w|warn*|warning*) loglevel='warning';;
0|e|err|error*) loglevel='error';;
default) error 'noParam' '-L or --loglevel';;
*) error 'badParam' '-L or --loglevel' "${nextArgs[index]}";;

HELP
*) printHelp;;
