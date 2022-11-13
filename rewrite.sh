#!/bin/bash

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
  deepSearch='false'
  overwrite='false'

  # encoding options

  imageCodec='avif'
  videoCodec='av1'
  audioCodec='opus'

  jpgQuality=''
  jpgEfficiency=''
  jpgDepth=''
  avifMinQuality='0'
  avifMaxQuality='40'
  avifEfficiency='0'
  avifDepth='10'
  jxlQuality='80'
  jxlEfficiency='9'
  jxlDepth=''
  x264Quality=''
  x264Efficiency=''
  x264Depth=''
  x264AudioQuality=''
  x265Quality=''
  x265Efficiency=''
  x265Depth=''
  x265AudioQuality=''
  vp9Quality=''
  vp9Efficiency=''
  vp9Depth=''
  vp9AudioQuality=''
  av1Quality=''
  av1Efficiency=''
  av1Depth=''
  av1AudioQuality=''
  vvcQuality=''
  vvcEfficiency=''
  vvcDepth=''
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
  ffmpegArgs=''

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

  # define extentions
  imageExtentions='jpg jpeg png tiff tif raw bmp heif heic avif jxl'
  videoExtentions='mp4 mkv 3pg m4v f4v f4a m4b m4r f4b mov wmv wma webm flv avi vvc 266'
  audioExtentions='mp3 aac flac aiff alac m4a cda wav opus ogg'

}

processArgs() {

  # perform actions that need to be done before agument scanning
  args=("$@")
  [[ -z "$args" ]] && error 'noArg'
  for ((i=0; i < "${#args[@]}"; i++)); do

    args[i]="${args[i]//\~/$HOME}"
    [[ "${args[i]}" = '-h' || "${args[i]}" = '--help' ]] && printHelp

    if [[ "${args[i]}" = '-i' || "${args[i]}" = '--include' ]]; then
      ((i++))
      while [[ "${args[i]:0:1}" != '-' && -n "${args[i]:0:1}" ]]; do
        includeArgs+="${args[i]:1} "
        ((i++))
      done
      [[ "$includeArgs" =~ $imageExtentions ]] && images='false'
      [[ "$includeArgs" =~ $videoExtentions ]] && videos='false'
      [[ "$includeArgs" =~ $audioExtentions ]] && audios='false'
      [[ ! "$includeArgs" =~ $imageExtentions|$videoExtentions|$audioExtentions ]] \
      && videos='false' && images='false' && audios='false' && unset includeExtentions
    fi

    if [[ "${args[i]}" = '-e' || "${args[i]}" = '--exclude' ]]; then
      ((i++))
      while [[ "${args[i]:0:1}" != '-' && -n "${args[i]:0:1}" ]]; do
        excludeArgs+="${args[i]:1} "
        ((i++))
      done
      [[ ! "$excludeArgs" =~ $imageExtentions|$videoExtentions|$audioExtentions ]] \
      && videos='true' && images='true' && audios='true' && unset excludeExtentions
    fi

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

  # check input/ouput
  [ "${#paths[@]}" = 0 ] && warn 'noIO' "'${inputs[@]}' as input(s) and '$output' as output"
  for ((j=0; j < "${#inputs[@]}"; j++)); do
    if [[ "${inputs[j]}" =~ '/' ]]; then
      [[ -d "${inputs[j]}" || -f "${inputs[j]}" ]] || error 'badPath' "${inputs[j]}"
    fi
    inputs[j]=$(readlink -f "${inputs[j]}")
  done
  [[ "$output" =~ '/' ]] && [[ -f "$output" ]] && error 'badPath' "$output" \
  || [[ ! -d "$output" ]] && warn 'createPath' "$output"
  output=$(readlink -f "$output")

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

  # check for wrong values
  checkCodecRange "$jpgQuality" jpg 2 31
  checkCodecValue "$jpgEfficiency" jpg ffmpegPresets
  checkCodecValue "$jpgDepth" jpg depth
  checkCodecRange "$avifMinQuality" avif 0 63
  checkCodecRange "$avifMaxQuality" avif 0 63
  checkCodecRange "$avifEfficiency" avif 0 10
  checkCodecValue "$avifDepth" avif depth
  checkCodecRange "$jxlQuality" jxl 0 100
  checkCodecRange "$jxlEfficiency" jxl 1 9
  checkCodecValue "$jxlDepth" jxl depth
  checkCodecRange "$x264Quality" x264 0 63
  checkCodecValue "$x264Efficiency" x264 ffmpegPresets
  checkCodecValue "$x264Depth" x264 depth
  checkCodecRange "$x264AudioQuality" x264 0 9
  checkCodecRange "$x265Quality" x265 0 63
  checkCodecValue "$x265Efficiency" x265 ffmpegPresets
  checkCodecValue "$x265Depth" x265 depth
  checkCodecRange "$x265AudioQuality" x265 0 9
  checkCodecRange "$vp9Quality" vp9 0 63
  checkCodecRange "$vp9Efficiency" vp9 0 16
  checkCodecValue "$vp9Depth" vp9 depth
  checkCodecRange "$vp9AudioQuality" vp9 1 512
  checkCodecRange "$av1Quality" av1 0 63
  checkCodecRange "$av1Efficiency" av1 0 9
  checkCodecValue "$av1Depth" av1 depth
  checkCodecRange "$av1AudioQuality" av1 1 512
  checkCodecRange "$vvcQuality" vvc 0 63
  checkCodecValue "$vvcEfficiency" vvc vvcPresets
  checkCodecValue "$vvcDepth" vvc depth
  checkCodecRange "$vvcAudioQuality" vvc 1 512
  checkCodecRange "$mp3Quality" mp3 0 9
  checkCodecValue "$mp3Efficiency" mp3 ffmpegPresets
  checkCodecRange "$opusQuality" opus 1 512
  checkCodecRange "$opusEfficiency" opus 0 10

  # check options
  includeExtentions="${includeExtentions:1}"
  excludeExtentions="${excludeExtentions:1}"
  renameExtentions="${renameExtentions:1}"
  [ "$threads" = 'all' ] && threadsOption 'all'
  [[ -n "${cropImageValues[@]}" && -z "${cropVideoValues[@]}" ]] && cropVideoValues="${cropImageValues[@]}"
  [[ -z "${cropImageValues[@]}" && -n "${cropVideoValues[@]}" ]] && cropImageValues=("${cropVideoValues[@]}")

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

    # give it a name and ang ID
    if [[ "${options[i]// /-}" =~ ^[A-Z-]+$ ]]; then
      optionName="--${options[i],,}"
      optionName="${optionName// /-}"
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

    # differenciate option tasks from cases
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
  echo "  ${optionIDs[i]}, ${optionNames[i]} {all|none|videos|images|audios|.<extention(s)>}"; ((i++))
  echo "  ${optionIDs[i]}, ${optionNames[i]} {all|none|videos|images|audios|.<extention(s)>}"; ((i++))
  echo "      > Include or exclude file types or extentions (case insensitive)"
  echo "      > Default : all (in both options)"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]}"; ((i++))
  echo "      > Include subfolders"
  echo "      > Default : true"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]}"; ((i++))
  echo "      > Search files by their content, not their extentions"
  echo "      > Default : false"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]}"; ((i++))
  echo "      > Overwrites already compressed files"
  echo "      > Default : false"
  echo
  echo "Encoding options :"
  echo
  echo "  ${optionIDs[i]}, ${optionNames[i]} {jpg|jxl|avif|x264|x265|vp9|av1|vvc|mp3|opus} {quality}"; ((i++))
  echo "      > Choose encoding codecs and quality parameters"
#  echo "      > Quality arguments (for common users) :"
#  echo "        {quality score/10} {compression efficiency/10} {audio quality/10}"
  echo "      > Quality arguments (for expert users) :"
  echo "        • jpg <q:scale> (2-31) <preset> (placebo-veryfast)"
  echo "        • avif <min> (0-63) <max> (0-63) <speed> (0-10)"
  echo "        • jxl <quality> (100-0) <effort> (9-1)"
  echo "        • x264|x265 <crf> (0-63) <preset> (placebo-veryfast) <mp3-quality> (0-9)"
  echo "        • vp9 <crf> (0-63) <cpu-used> (0-16) <opus-bitrate> (512-1)"
  echo "        • av1 <cq> (0-63) <cpu-used> (0-9) <opus-bitrate> (512-1)"
  echo "        • vvc <qc> (0-63) <preset> (slower-fast) <opus-bitrate> (512-1)"
  echo "        • mp3 <quality> (0-9) <preset> (placebo-veryfast)"
  echo "        • opus <bitrate> (512-1) <speed> (10-0)"
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
  echo "  ${optionIDs[i]}, ${optionNames[i]} <parameters/options>"; ((i++))
  echo "      > Use custom ffmpeg arguments when applicable"
  echo "      > Note : you will need to escape all the single/double quotes"
  echo "      > Default : set in config"
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
  echo -en "> Include extentions : "; colorise "$includeExtentions"
  echo -en "> Exclude extentions : "; colorise "$excludeExtentions"
  echo
  echo -en "> Recursive : "; colorise "$recursive"
  echo -en "> Deep search : "; colorise "$deepSearch"
  echo -en "> Overwrite : "; colorise "$overwrite"
  echo
  echo -e "\e[34mEncoding options :\e[0m"
  echo
  echo -en "> Image codec : "; colorise "$imageCodec"
  echo -en "> Video codec : "; colorise "$videoCodec"
  echo -en "> Audio codec : "; colorise "$audioCodec"
  echo
  echo     "Codec │ Quality    │ Efficiency │ Bit Depth  │ Audio Quality"
  echo     "──────┼────────────┼────────────┼────────────┼──────────────"
  echo -en "JPG   │ "; colorise 'tab' "$jpgQuality"; colorise 'tab' "$jpgEfficiency"; colorise 'tab' "$jpgDepth"; echo
  echo -en "JXL   │ "; colorise 'tab' "$jxlQuality"; colorise 'tab' "$jxlEfficiency"; colorise 'tab' "$jxlDepth"; echo
  echo -en "AVIF  │ "; colorise 'tab' "$avifQuality"; colorise 'tab' "$avifEfficiency"; colorise 'tab' "$avifDepth"; echo
  echo -en "X264  │ "; colorise 'tab' "$x264Quality"; colorise 'tab' "$x264Efficiency"; colorise 'tab' "$x264Depth"; colorise "$x264AudioQuality"
  echo -en "X265  │ "; colorise 'tab' "$x265Quality"; colorise 'tab' "$x265Efficiency"; colorise 'tab' "$x265Depth"; colorise "$x265AudioQuality"
  echo -en "VP9   │ "; colorise 'tab' "$vp9Quality"; colorise 'tab' "$vp9Efficiency"; colorise 'tab' "$vp9Depth"; colorise "$vp9AudioQuality"
  echo -en "AV1   │ "; colorise 'tab' "$av1Quality"; colorise 'tab' "$av1Efficiency"; colorise 'tab' "$av1Depth"; colorise "$av1AudioQuality"
  echo -en "VVC   │ "; colorise 'tab' "$vvcQuality"; colorise 'tab' "$vvcEfficiency"; colorise 'tab' "$vvcDepth"; colorise "$vvcAudioQuality"
  echo -en "MP3   │ "; colorise 'tab' "$mp3Quality"; colorise 'tab' "$mp3Efficiency"; echo "           │"
  echo -en "OPUS  │ "; colorise 'tab' "$opusQuality"; colorise 'tab' "$opusEfficiency"; echo "           │"
  echo
  echo -en "> Crop images : "; colorise "$cropImages"
  echo -en "> Crop videos : "; colorise "$cropVideos"
  echo -en "> Crop image value(s) : "; colorise "${cropImageValues[@]}"
  echo -en "> Crop video value(s) : "; colorise "${cropVideoValues[@]}"
  echo
  echo -en "> Threads : "; colorise "$threads"
  echo -en "> Custom ffmpeg arguments : "; colorise "$ffmpegArgs"
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
      [[ -z "$2" ]] && echo -en "\e[35mundefined\e[0m  │ "
      [[ -n "$2" ]] && printf '\e[36m%-11s\e[0m│ ' "$2";;
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
    'badOption') echo "Wrong option $2 for the parameter $3 inside of argument $4";;
    'badValue') echo "Wrong option $2 ($3 parameter, argument $4) :"; echo "$5";;
    '') echo "Wrong option $2 for the parameter $3 inside of argument $4 :"; echo "$5";;
  esac
  echo -e "\e[0mFor help, use $0 --help\n"
  exit

}

warn() {

  [ "$loglevel" = 'error' ] && return
  echo -en '\e[33m\nWARNING : '
  case "$1" in
    'noArg') echo "No arguments provided : Using $2";;
    'noIO') echo "No input(s)/output provided : Using $2";;
    'noParam') echo "No parameter provided for argument $2 : Using $3";;
    'badParam') echo "Wrong or unknown parameter provided for argument $2";;
    'createPath') echo "Not a valid path : $2. Creating it.";;
    'maxThreads') echo "Using $2 threads instead of $3 (it's the maximum available)";;
    'noMedia') echo "No $2 found";;
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
    jpg|jxl|avif|x264|x265|vp9|av1|vvc|mp3|opus)
      toProcess+=("${nextArgs[index-1]}")

      # scan next options
      while [[ -n "${nextArgs[index]}" ]]; do
        case "${nextArgs[index]}" in
          jpg|jxl|avif|x264|x265|vp9|av1|vvc|mp3|opus) break;;
          *) toProcess+=("${nextArgs[index]}"); ((index++));;
        esac
      done

      # check syntax
      case "${toProcess[0]}" in
        avif|x264|x265|vp9|av1|vvc) (( "${#toProcess[@]}" > 5 )) && error "badCons" "$id or $name" "$name <type> <quality> <efficiency> <depth> <audio-bitrate>";;
        jpg|jxl) (( "${#toProcess[@]}" > 4 )) && error "badCons" "$id or $name" "$name <type> <quality> <efficiency> <depth>";;
        mp3|opus) (( "${#toProcess[@]}" > 3 )) && error "badCons" "$id or $name" "$name <type> <quality> <efficiency>";;
      esac

      # associate option values to variables
      case "${#toProcess[@]}" in

        2|3|4|5)
          case "${toProcess[0]}" in
            jpg) jpgQuality="${toProcess[1]}";;
            jxl) jxlQuality="${toProcess[1]}";;
            avif) avifMinQuality="${toProcess[1]}";;
            x264) x264Quality="${toProcess[1]}";;
            x265) x265Quality="${toProcess[1]}";;
            vp9) vp9Quality="${toProcess[1]}";;
            av1) av1Quality="${toProcess[1]}";;
            vvc) vvcQuality="${toProcess[1]}";;
            mp3) mp3Quality="${toProcess[1]}";;
            opus) opusQuality="${toProcess[1]}";;
          esac ;;&

        3|4|5)
          case "${toProcess[0]}" in
            jpg) jpgEfficiency="${toProcess[2]}";;
            jxl) jxlEfficiency="${toProcess[2]}";;
            avif) avifMaxQuality="${toProcess[2]}";;
            x264) x264Efficiency="${toProcess[2]}";;
            x265) x265Efficiency="${toProcess[2]}";;
            vp9) vp9Efficiency="${toProcess[2]}";;
            av1) av1Efficiency="${toProcess[2]}";;
            vvc) vvcEfficiency="${toProcess[2]}";;
            mp3) mp3Efficiency="${toProcess[2]}";;
            opus) opusEfficiency="${toProcess[2]}";;
          esac ;;&

        4|5)
          case "${toProcess[0]}" in
            jpg) jpgDepth="${toProcess[3]}";;
            jxl) jxlDepth="${toProcess[3]}";;
            avif) avifEfficiency="${toProcess[3]}";;
            x264) x264Depth="${toProcess[3]}";;
            x265) x265Depth="${toProcess[3]}";;
            vp9) vp9Depth="${toProcess[3]}";;
            av1) av1Depth="${toProcess[3]}";;
            vvc) vvcDepth="${toProcess[3]}";;
          esac ;;&

        5)
          case "${toProcess[0]}" in
            avif) avifDepth="${toProcess[4]}";;
            x264) x264AudioQuality="${toProcess[4]}";;
            x265) x265AudioQuality="${toProcess[4]}";;
            vp9) vp9AudioQuality="${toProcess[4]}";;
            av1) av1AudioQuality="${toProcess[4]}";;
            vvc) vvcAudioQuality="${toProcess[4]}";;
          esac ;;

      esac

      unset toProcess
      ;;

    *) error "badCons" "$id or $name" "$name <type> or $name <type> <quality> or $name <type> <quality> <efficiency>";;

  esac

}

# UTILITIES FOR OPTIONS

checkCodecValue() {

  case "$3" in
    ffmpegPresets)
      case "$1" in
        ''|ultrafast|superfast|veryfast|faster|fast|medium|slow|slower|placebo) :;;
        *) error 'badValue' "$1" "$2" "$id or $name" "This value needs to be ultrafast, superfast, veryfast, faster, fast, medium, slow, slower or placebo"
      esac;;
    vvcPresets)
      case "$1" in
        ''|faster|fast|medium|slow|slower) :;;
        *) error 'badValue' "$1" "$2" "$id or $name" "This value needs to be faster, fast, medium, slow or slower"
      esac;;
    depth)
      case "$1" in
        ''|8|10|12) :;;
        *) error 'badValue' "$1" "$2" "$id or $name" "This value needs to be 8, 10 or 12"
      esac;;
  esac

}

checkCodecRange() {

  if [[ "$1" =~ [a-zA-Z0-9] ]]; then
    [[ "$1" =~ [a-zA-Z] ]] || (( "$1" <= "$3"-1 || "$1" >= "$4"+1 )) && error 'badValue' "$1" "$2" "$id or $name" "This value needs to be between $3 and $4"
  fi

}

addFFmpegArg() {

  ffmpegArgs+="-"
  while [[ "${nextArgs[index]:0:1}" != '-' && -n "${nextArgs[index]}" ]]; do
    ffmpegArgs+="${nextArgs[index]} "
    ((index++))
  done

}

# COMPRESSION

checkFiles() {

  if [ "$deepSearch" = 'true' ]; then

    # build file list
    [ "$recursive" = 'true' ] && shopt -s globstar && stars='**' || stars='*'
    for i in "${inputs[@]}"; do
      [[ "${i: -1}" != '/' && -d "$i" ]] && i+='/'
      inputList+=$(file -i "$i"$stars)
    done

    # exclude extentions
    if [[ -n "$excludeExtentions" ]]; then
      excludeExtentions="-e \.${excludeExtentions// /[^\/]+[^\\;]+[^c]+charset=.+$ -e \.}[^/]+[^\;]+[^c]+charset=.+$"
      inputList=$(grep -Eiv $excludeExtentions <<< "$inputList")
    fi

    # include custom extentions
    echo "1 - $includeExtentions"
    for i in "${includeExtentions[@]}"; do
      [[ "$i" =~ ${imageExtentions// /|} ]] && grepImageArgs+=" -e \.${i}[^\/]+[^\\;]+[^c]+charset=.+$"
      [[ "$i" =~ ${videoExtentions// /|} ]] && grepVideoArgs+=" -e \.${i}[^\/]+[^\\;]+[^c]+charset=.+$"
      [[ "$i" =~ ${audioExtentions// /|} ]] && grepAudioArgs+=" -e \.${i}[^\/]+[^\\;]+[^c]+charset=.+$"
    done
    echo "grep -Ei $grepImageArgs"
    [[ -n "$grepImageArgs" ]] && readarray -t imageList <<< $(grep -Ei $grepImageArgs <<< "$inputList")
    [[ -n "$grepVideoArgs" ]] && readarray -t videoList <<< $(grep -Ei $grepVideoArgs <<< "$inputList")
    [[ -n "$grepAudioArgs" ]] && readarray -t audioList <<< $(grep -Ei $grepAudioArgs <<< "$inputList")

    # sort files by type
    [ "$images" = 'true' ] && readarray -t imageList <<< $(grep -Po '.+(?=:[ ]*image/)' <<< "$inputList")
    [ "$videos" = 'true' ] && readarray -t videoList <<< $(grep -Po '.+(?=:[ ]*video/)' <<< "$inputList")
    [ "$audios" = 'true' ] && readarray -t audioList <<< $(grep -Po '.+(?=:[ ]*audio/)' <<< "$inputList")

  else

    # build file list
    [ "$recursive" != 'true' ] && toAdd=' -maxdepth 1 '
    for i in "${inputs[@]}"; do
      inputList+=$(find "$i" $toAdd -type f 2>/dev/null)
    done

     # exclude extentions
    if [[ -n "$excludeExtentions" ]]; then
      excludeExtentions="-e \.${excludeExtentions// /\$ -e \\.}\$"
      inputList=$(grep -Eiv $excludeExtentions <<< "$inputList")
    fi

    # include custom extentions
    includeExtentions=($includeExtentions)
    for i in "${includeExtentions[@]}"; do
      [[ "$i" =~ ${imageExtentions// /|} ]] && grepImageArgs+=" -e \.${i}$"
      [[ "$i" =~ ${videoExtentions// /|} ]] && grepVideoArgs+=" -e \.${i}$"
      [[ "$i" =~ ${audioExtentions// /|} ]] && grepAudioArgs+=" -e \.${i}$"
    done
    [[ -n "$grepImageArgs" ]] && readarray -t imageList <<< $(grep -Ei $grepImageArgs <<< "$inputList")
    [[ -n "$grepVideoArgs" ]] && readarray -t videoList <<< $(grep -Ei $grepVideoArgs <<< "$inputList")
    [[ -n "$grepAudioArgs" ]] && readarray -t audioList <<< $(grep -Ei $grepAudioArgs <<< "$inputList")

    # sort files by type
    grepImageExtentions="-e \.${imageExtentions// /\$ -e \\.}\$"
    grepVideoExtentions="-e \.${videoExtentions// /\$ -e \\.}\$"
    grepAudioExtentions="-e \.${audioExtentions// /\$ -e \\.}\$"
    [[ "$images" = 'true' || -n "$grepImageArgs" ]] && readarray -t -O "${#imageList[@]}" imageList <<< $(grep -Ei $grepImageExtentions <<< "$inputList")
    [[ "$videos" = 'true' || -n "$grepVideoArgs" ]] && readarray -t -O "${#videoList[@]}" videoList <<< $(grep -Ei $grepVideoExtentions <<< "$inputList")
    [[ "$audios" = 'true' || -n "$grepAudioArgs" ]] && readarray -t -O "${#audioList[@]}" audioList <<< $(grep -Ei $grepAudioExtentions <<< "$inputList")

  fi

  # get unique values
  IFS=$'\n'
  imageList=($(sort -u <<< "${imageList[*]}"))
  videoList=($(sort -u <<< "${videoList[*]}"))
  audioList=($(sort -u <<< "${audioList[*]}"))

  # return search results
  echo
  [[ -n "$imageList" ]] && echo "> Found ${#imageList[@]} images" || echo '> Found no images'
  [[ -n "$imageList" && "$verbose" = true ]] && echo -e '\e[36m' && printf "%s\n" "${imageList[@]}" && echo -e '\e[0m'
  [[ -n "$videoList" ]] && echo "> Found ${#videoList[@]} videos" || echo '> Found no videos'
  [[ -n "$videoList" && "$verbose" = true ]] && echo -e '\e[36m' && printf "%s\n" "${videoList[@]}" && echo -e '\e[0m'
  [[ -n "$audioList" ]] && echo "> Found ${#audioList[@]} audios" || echo '> Found no audios'
  [[ -n "$audioList" && "$verbose" = true ]] && echo -e '\e[36m' && printf "%s\n" "${audioList[@]}" && echo -en '\e[0m'
  echo

  exit

}

compress() {

#  read -p "Start compression ? (y/n) (default=y) : " answer
#  [[ "$answer" = 'n' || "$answer" = 'no' ]] && echo -e "Exiting...\n" && exit
  echo "Starting compression..."

}

# MAIN PROGRAM

optionBuilder
getConfig
processArgs "$@"
checkFiles
compress
echo; exit

# OPTIONS

INCLUDE
image*|photo*|picture*|pic*) images='true';;
movie*|video*|vid*) videos='true';;
music*|audio*) audios='true';;
default|all|everything) images='true'; videos='true'; audios='true';;
none|nothing) images='false'; videos='false'; audios='false';;
\.*) extention="${arg/\./}"; extention="${extention,,}"; includeExtentions+=" $extention"; excludeExtentions="${excludeExtentions// $extention}";;
*) error 'badParam' "$id or $name" "$arg";;

EXCLUDE
image*|photo*|picture*|pic*) images='false';;
movie*|video*|vid*) videos='false';;
music*|audio*) audios='false';;
default|all|everything) images='false'; videos='false'; audios='false';;
none|nothing) images='true'; videos='true'; audios='true';;
\.*) extention="${arg/\./}"; extention="${extention,,}"; excludeExtentions+=" $extention"; includeExtentions="${includeExtentions// $extention}";;
*) error 'badParam' "$id or $name" "$arg";;

RECURSIVE
default|y|yes|on|'true'|'enable') recursive='true';;
n|no|off|'false'|'disable') recursive='false';;
*) error 'badParam' "$id or $name" "$arg";;

DEEP SEARCH
default|y|yes|on|'true'|'enable') deepSearch='true';;
n|no|off|'false'|'disable') deepSearch='false';;
*) error 'badParam' "$id or $name" "$arg";;

OVERWRITE
default|y|yes|on|'true'|'enable') overwrite='true';;
n|no|off|'false'|'disable') overwrite='false';;
*) error 'badParam' "$id or $name" "$arg";;

CODEC
jpg|jxl|avif) imageCodec="$arg";;
x264|x265|vp9|av1|vvc) videoCodec="$arg";;
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

FFMPEG ARGS
default) error 'noParam' "$id or $name";;
*) addFFmpegArg;;

RENAME
image*|photo*|picture*|pic*) renameImages='true';;
movie*|video*|vid*) renameVideos='true';;
music*|audio*) renameAudios='true';;
default|all|everything) renameImages='true'; renameVideos='true'; renameAudios='true';;
none|nothing) renameImages='false'; renameVideos='false'; renameAudios='false';;
\.*) extention="${arg/\./}"; extention="${extention,,}"; renameExtentions="${renameExtentions// $extention}"; renameExtentions+=" $extention";;
*) error 'badParam' "$id or $name" "$arg";;

TREE
default|y|yes|on|'true'|'enable') tree='true';;
n|no|off|'false'|'disable') tree='false';;
*) error 'badParam' "$id or $name" "$arg";;

VERBOSE
default|y|yes|on|'true'|'enable') verbose='true';;
n|no|off|'false'|'disable') verbose='false';;
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
