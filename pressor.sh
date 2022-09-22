#!/bin/bash

#=-----=# CONFIG #=-----=#

workingDirectory='.'
timeAsNames='n'
overwrite='y'
warnings='y'
logging='n'

videoFormat='lowComplexity'
imageFormat='avif'

threads='12'
crf='45'

compressVideos='y'
compressImages='n'
compressMusics='n'

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

# initialisation
trap 'echo;exit' 2 3
if [[ "$compressVideos" != 'y' && "$compressImages" != 'y' && "$compressMusics" != 'y' ]]; then
  echo "Compression is disabled in the config"
  exit
fi
if [[ -z "$workingDirectory" ]]; then workingDirectory='.'; fi
readarray -t initDates <<< $(find "$workingDirectory" -printf '%Cy%Cm%Cd-%CH%CM%CS\n' -type f | sed -E 's:.{11}$::g')
readarray -t initNames <<< $(find "$workingDirectory" -type f)
readarray -t directories <<< $(find "$workingDirectory" -type d)
if [[ -n "$overwrite" ]]; then
  overwrite="-$overwrite"
fi
if [[ -z "${initNames[@]}" ]]; then
  echo "Nothing to compress"
  exit
fi
if [[ "$doCrop" == 'y' ]]; then
  if [[ "$crop" =~ [0-9]*':'[0-9]* ]]; then
    args=" -vf scale=$crop:force_original_aspect_ratio=increase,crop=$crop"
  fi
fi
if [[ "$doMaxSize" == 'y' ]]; then
  if [[ "$maxSize" =~ [0-9]* ]]; then
    args=" -vf scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)"
  fi
fi

# compression
for ((i=0; i < "${#initNames[@]}"; i++)); do

  if [[ ! "${initNames[i]}" =~ 'ffmpeg' ]]; then

    if [[ "$timeAsNames" == 'y' ]]; then
      finalName="${initNames[i]%/*}/${initDates[i]}"
    else
      finalName="${initNames[i]%.[a-z]*}"
    fi

    type=$(file -i "${initNames[i]}")
    type="${type#*: }"

    case "$type" in

      *"image"*)
        if [[ "$compressImages" == 'y' ]]; then

          if [[ "$finalName" =~ 'DCIM/' ]]; then
            finalName="${finalName/DCIM\//DCIM-ffmpeg\/}"
            mkdir -p "${finalName%/*}"
          fi
          if [[ -z "$checkDCIM" ]]; then
            echo "DCIM folder detected. Saving to ${finalName%/*}"
            checkDCIM='true'
          fi

          if [[ "$imageFormat" == 'avif' ]]; then
            if [[ -f "$finalName-ffmpeg.avif" ]]; then echo "This file was already compressed. Skipping"; continue; fi
            if [[ "$doMaxSize" == 'y' && "$maxSize" =~ [0-9]* ]]; then
              ffmpeg -loglevel error -stats -i "${initNames[i]}" -crf 0 -vf "scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)" "$finalName-temp.png"
              toDel="$finalName-temp.png"
              initNames[i]="$finalName-temp.png"
            fi
            avifenc --codec aom --jobs "$threads" --depth 8 --yuv 420 --min "$avifMinQuality" --max "$avifMaxQuality" --speed "$avifQuality" "${initNames[i]}" "$finalName-ffmpeg.avif"
            rm "$toDel"
          elif [[ "$imageFormat" == 'jpg' ]]; then
            if [[ -f "$finalName-ffmpeg.jpg" ]]; then echo "This file was already compressed. Skipping"; continue; fi
            ffmpeg -i "${initNames[i]}" "$finalName-ffmpeg.jpg"
          else
            echo "No valid image format specified"
          fi
        fi
      ;;

      *"audio"*)
        if [[ "$compressMusics" == 'y' ]]; then
          echo "> ${initNames[i]}"
          if [[ "$finalName" =~ [Mm]'usic/' ]]; then
            if [[ "$finalName" =~ 'Music/' ]]; then
              finalName="${finalName/Music\//Music-ffmpeg\/}"
            elif [[ "$finalName" =~ 'music/' ]]; then
              finalName="${finalName/music\//music-ffmpeg\/}"
            fi
            if [[ -z "$checkMusic" ]]; then
              echo "Music folder detected. Saving to ${finalName%/*}"
              checkMusic='true'
            fi
          fi
          if [[ -f "$finalName-ffmpeg.opus" || "${initNames[i]##*.}" == 'opus' ]]; then
            echo "This file was already compressed. Skipping"
          else
            metadata=$(mediainfo --Output=JSON "${initNames[i]}")
            bitrate=$(jq -r .media.track[1].BitRate <<< "$metadata")
            metadata=$(jq .media.track[0] <<< "$metadata")
            title=$(jq -r .Title <<< "$metadata")
            album=$(jq -r .Album <<< "$metadata")
            artist=$(jq -r .Performer <<< "$metadata")
            genre=$(jq -r .Genre <<< "$metadata")
            tracknumber=$(jq -r .Track_Position <<< "$metadata")
            date=$(jq -r .Recorded_Date <<< "$metadata")
            lyrics=$(jq -r .Lyrics <<< "$metadata")
            comment=$(jq -r .Comment <<< "$metadata")
            if [[ -z "$title" || -z "$album" || -z "$artist" || -z "$date" || -z "$genre" || -z "$lyrics" || -z "$tracknumber" ]]; then
              echo 'WARNING : Metadata is incomplete'
            fi
            if (( "${bitrate:0:-3}" < "$musicBitrate" )); then
              musicBitrate="${bitrate:0:-3}"
              echo "WARNING : birate in config > bitrate of music : selecting the original bitrate"
            fi
            mkdir -p "${finalName%/*}"
            ffmpeg -i "${initNames[i]}" -y -loglevel error -r 1 '/tmp/cover.jpg'
            ffmpeg -i "${initNames[i]}" -loglevel error -f wav - | opusenc --quiet --bitrate "$musicBitrate" --picture '/tmp/cover.jpg' --title "$title" --artist "$artist" --album "$album" --genre "$genre" --date "$date" --tracknumber "$tracknumber" --comment lyrics="$lyrics" --comment comment="$comment" - "$finalName-ffmpeg.opus" 2> /dev/null
            if [[ "$?" == '1' ]]; then
              echo DEBUG : ffmpeg -i "${initNames[i]}" -loglevel error -f wav - \| opusenc --quiet --bitrate "$musicBitrate" --picture '/tmp/cover.jpg' --title "$title" --artist "$artist" --album "$album" --genre "$genre" --date "$date" --tracknumber "$tracknumber" --comment lyrics="$lyrics" --comment comment="$comment" - "$finalName-ffmpeg.opus" 2> /dev/null
            fi
            rm -f '/tmp/cover.jpg'
          fi
        fi
      ;;

      *"video"*|*"binary"*)

        if [[ "$compressVideos" == 'y' ]]; then
          if [[ "$type" =~ "video" || "${initNames[i]##*.}" == 'y4m' || "${initNames[i]##*.}" == 'yuv' ]]; then
            if [[ -f "$finalName-ffmpeg.mkv" ]]; then echo "This file was already compressed. Skipping"; continue; fi

            if [[ "$finalName" =~ 'DCIM/' ]]; then
              finalName="${finalName/DCIM\//DCIM-ffmpeg\/}"
              mkdir -p "${finalName%/*}"
            fi
            if [[ -z "$checkDCIM" ]]; then
              echo "DCIM folder detected. Saving to ${finalName%/*}"
              checkDCIM='true'
            fi

            if [[ "$videoFormat" == 'vp9' ]]; then

              nice ffmpeg -y -i "${initNames[i]}" -loglevel error -stats \
                -c:v libvpx-vp9 -b:v 0 -crf "$crf" $args \
                -aq-mode 2 -an -pix_fmt yuv420p \
                -tile-columns 0 -tile-rows 0 \
                -frame-parallel 0 -cpu-used 8 \
                -auto-alt-ref 1 -lag-in-frames 25 -g 999 \
                -pass 1 -f webm -threads "$threads" \
                /dev/null && \
              nice ffmpeg "$overwrite" -i "${initNames[i]}" -loglevel error -stats \
                -c:v libvpx-vp9 -b:v 0 -crf "$crf" $args \
                -aq-mode 2 -pix_fmt yuv420p -c:a libopus -b:a "$audioBitrate"k \
                -tile-columns 2 -tile-rows 2 \
                -frame-parallel 0 -cpu-used "$vp9Quality" \
                -auto-alt-ref 1 -lag-in-frames 25 \
                -pass 2 -g 999 -threads "$threads" \
                "$finalName-ffmpeg.mkv" && \
              rm ffmpeg2pass-0.log

            elif [[ "$videoFormat" == 'av1' ]]; then

              random="$RANDOM"
              nice ffmpeg -y -i "${initNames[i]}" -strict -1 -loglevel error $args \
                -f yuv4mpegpipe - | aomenc - --passes=2 --pass=1 \
                --cpu-used="$av1Quality" --threads="$threads" \
                --end-usage=q --cq-level="$crf" --bit-depth=8 \
                --enable-fwd-kf=1 --kf-max-dist=300 --kf-min-dist=12 \
                --tile-columns=0 --tile-rows=0 --sb-size=64 \
                --lag-in-frames=48 \
                --arnr-strength=2 --arnr-maxframes=3 \
                --aq-mode=0 --deltaq-mode=1 --enable-qm=1 \
                --tune=psnr --tune-content=default \
                --fpf="/tmp/pass-$random" -o NUL && \
              nice ffmpeg "$overwrite" -i "${initNames[i]}" -strict -1 -loglevel error $args \
                -f yuv4mpegpipe - | aomenc - --passes=2 --pass=2 \
                --cpu-used="$av1Quality" --threads="$threads" \
                --end-usage=q --cq-level="$crf" --bit-depth=8 \
                --enable-fwd-kf=1 --kf-max-dist=300 --kf-min-dist=12 \
                --tile-columns=0 --tile-rows=0 --sb-size=64 \
                --lag-in-frames=48 \
                --arnr-strength=2 --arnr-maxframes=3 \
                --aq-mode=0 --deltaq-mode=1 --enable-qm=1 \
                --tune=psnr --tune-content=default \
                --fpf="/tmp/pass-$random" -o "$finalName-video.mkv" && \
              ffmpeg "$overwrite" -loglevel error -i "$finalName-video.mkv" -i "${initNames[i]}" -map 0:v -c:v copy -map 1:a? -c:a libopus -b:a "$audioBitrate"k -map 0:s? -max_interleave_delta 0 "$finalName-ffmpeg.mkv" && \
              rm "$finalName-video.mkv"

            # for video editors
            elif [[ "$videoFormat" == 'lowComplexity' ]]; then
              ffmpeg "$overwrite" -i "${initNames[i]}" -strict -1 -stats -loglevel error $args \
              -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p -c:a pcm_s16le -f mov "$finalName-ffmpeg.mov"
#              ffmpeg "$overwrite" -i "${initNames[i]}" -strict -1 -stats -loglevel error -preset ultrafast -crf 20 -tune fastdecode $args \
#              -map 0:v -c:v libx264 -map 0:a? -c:a aac -b:a 128k -map 0:s? -max_interleave_delta 0 "$finalName-ffmpeg.mp4"

            # elif [[ "$videoFormat" == 'vvc' ]]; then

              # DOES NOT WORK FOR NOW
              # vvenc -i "${initNames[i]}" -c yuv420 --preset medium --qp 31 --qpa 0 -ip 64 -t 4 -o "$finalName-ffmpeg.vvc"

            else
              echo "No valid video format specified"
            fi
          fi
        fi
      ;;

      *)
        if [[ "$logging" == 'y' ]]; then
          echo "unsupported -> ${initNames[i]} ($type)" >> log
        fi
        if [[ "$warnings" == 'y' ]]; then
          echo -e "\e[31munsupported -> ${initNames[i]} ($type) \e[0m"
#          echo "DEBUG : ${initNames[i]##*.} $compressVideos"
        fi
      ;;

    esac

  else
    echo "> ${initNames[i]} (skipped)"
  fi

done
