#!/bin/bash


#=-------=# CONFIG #=-------=#







#=--------------------------=#


printHelp() {

  echo "USAGE : $0 <input> <output> [arguments]"
  echo
  echo "Input options :"
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


argumentParsing() {

  args=($*); [[ -z "${args[0]}" ]] && printHelp
  for ((i=0; i < "${#args[@]}"; i++)); do
    case "${args[i]}" in
      '-i'|'--include') nextArgs=$(getNextArgs); i="$?"; echo "i=$i, args=${nextArgs[@]}";;
      '-e'|'--exclude') nextArgs=$(getNextArgs); i="$?"; echo "i=$i, args=${nextArgs[@]}";;
      '-r'|'--recursive') echo "Recursive on";;
      '-o'|'--overwrite') echo "Overwrite on";;
      '-t'|'--threads') echo "Threads";;
#      *) printHelp;;
    esac
  done

}

getNextArgs() {

  unset nextArgs
  while [[ "${args[i+1]:0:1}" != '-' && -n "${args[i+1]}" ]]; do
    ((i++))
    nextArgs+=("${args[i]}")
  done
  echo "$((i+2)) ${nextArgs[@]}"

}

argumentParsing "$@"
