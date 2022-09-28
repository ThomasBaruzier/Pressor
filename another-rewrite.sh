#!/bin/bash


#=-----=# CONFIG #=-----=#

input=''
output=''
codec=('')

rename=''
renamePhotos=''
renameVideos=''

crop=''
cropPhotos=''
cropVideos=''

overwrite=''
recursive=''
verbose=''
logging=''

videoFormat='lowComplexity'
imageFormat='avif'

threads='12'
crf='45'

compressVideos='y'
compressImages='n'
compressAudio='n'

musicBitrate='128'
audioBitrate='64'

av1Quality='2'
vp9Quality='-5'
avifQuality='0'

avifMaxQuality='63'
avifMinQuality='0'

crop='368:448'
doCrop='n'
maxSize='1280'
doMaxSize='y'

#=-=# END OF CONFIG #=-=#


# help menu
usage() {

  echo "USAGE : $0 <input> <output> [arguments] "
  echo
  echo "Arguments :"
  echo
  echo "  --codec or -c {vp9|av1|jpg|avif|mp3|opus}"
  echo "  --recursive or -r : Include subfolders"
  echo
  echo "  --debug or -d : print debug information"
  echo "  --help or -h : print this menu"
  echo
  echo "Not yet implemented :"
  echo
  echo "  --crop or --crop-{photos|videos} <width>x<height> : Crop to fit"
  echo "  --max or --max-{photos|videos} <pixels> : Set a maximum lenght size"
  echo
  echo "  --rename or --rename-{photos|videos} : rename output to files timestamps"
  echo "    --rename-photos : For photos only"
  echo "    --rename-videos : For videos only"
  echo "    --rename-audio : For audio only"
  echo
  echo "  --include-{videos|photos|audio} : will target videos"
  echo "  --exclude-{videos|photos|audio} : will target videos"
  echo
  echo "  --verbose or -v : print more information"
  echo "  --log or -l {file} : --verbose redirected to a file"
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
