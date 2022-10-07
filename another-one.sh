#!/bin/bash


#=-------=# CONFIG #=-------=#







#=--------------------------=#


printHelp() {

  echo
  echo "USAGE : $0 <input> <output> [arguments]"
  echo
  echo "INPUT OPTIONS :"
  echo
  echo "  -i, --include {videos|photos|audio}"
  echo "  -e, --exclude {videos|photos|audio}"
  echo "      > Include or exclude file types"
  echo "      > Default : include everything"
  echo
  echo "  -r, --recursive"
  echo "      > Include subfolders"
  echo "      > Default : true"
  echo "  -o, --overwrite"
  echo "      > Overwrites already compressed files"
  echo "      > Default : false"
  echo "  -t, --threads <all|number-of-threads>"
  echo "      > Number of threads to use"
  echo "      > Default : all"
  echo
#  echo "Output options :"
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
#  echo "  -R, --rename {all|photos|videos|audio}"
#  echo "      > Rename the output files to their timestamps"
#  echo "      > Default : "
#  echo
#  echo "Other"
#  echo
#  echo "  -v, --verbose : print more information"
#  echo "  -l, --log {file} : --verbose redirected to a file"
#  echo "  -h, --help : print this menu"
#  echo
  exit

}


argsParsing() {

  args=($*); [[ -z "${args[0]}" ]] && error 'noArg'
  for ((i=0; i < "${#args[@]}"; i++)); do
    previousArg="${args[i]}"
    echo ""
    case "${args[i]}" in
      '-i'|'--include'|'-e'|'--exclude') getNextArgs; ieOptions;;
      '-r'|'--recursive') recursive='true';;
      '-o'|'--overwrite') overwrite='true';;
#      '-t'|'--threads') threads="${args[i+1]}";;
#      *) error 'badArg' "${args[i]}";;
    esac
    [ "${args[i+1]}" = '' ] && exit
  done

}


ieOptions() {

  [[ "$previousArg" =~ '-i' ]] && ieVar='include' || ieVar='exclude'
  for ((i=0; i < "${#nextArgs[@]}"; i++)); do
    case "${nextArgs[i]}" in
      'movie'|'movies'|'video'|'videos') echo "Videos : ${ieVar}d";;
      'image'|'images'|'photo'|'photos') echo "Photos : ${ieVar}d";;
      'music'|'musics'|'audio'|'audios') echo "Audio files : ${ieVar}d";;
      '') error 'noParam' "-${ieVar:0:1} or --$ieVar";;
      *) error 'badParam' "-${ieVar:0:1} or --$ieVar" "${nextArgs[i]}";;
    esac
  done

}


getNextArgs() {

  unset nextArgs
  while [[ "${args[i+1]:0:1}" != '-' && -n "${args[i+1]}" ]]; do
    ((i++))
    nextArgs+=("${args[i]}")
  done

}


error() {

  echo -en '\e[31m\n> ERROR : '
  case "$1" in
    'badArg') echo "Unknown argument provided : $2";;
    'noArg') echo "No arguments provided";;
    'badParam') echo "Wrong parameter provided for argument $2 : $3";;
    'noParam') echo "No parameter provided for argument $2";;
  esac
  echo -en '\e[0m'
  printHelp

}


argsParsing "$@"
