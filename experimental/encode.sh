#!/bin/bash

# Both
maxFps=60
threads=12

# VVC
preset=medium     # efficiency
qp=30             # 1 pass quality
bitrate=1.75M     # 2 pass quality

# AV1
cpuUsed=3         # efficiency
crf=43            # quality

# Initialisation
[[ -z "$1" ]] && input='test.mp4' || input="$1"
[[ -z "$2" ]] && maxSize=1920 || maxSize="$2"
fps=$(($(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nw=1:nk=1 "$input")))
(( "$maxFps" > "$fps" )) && maxFps="$fps" && echo -e "\nINFO : maxFps > fps, using fps value instead"
echo; trap "rm -rf pass-stats; exit" 2

compressVVC-1pass() {

  echo -e "\e[33mRunning vvencapp\e[0m"
  ffmpeg -i "$input" -y -strict -1 -y -loglevel error -stats -pix_fmt yuv420p -r "$maxFps" \
    -vf "scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)" \
    -f yuv4mpegpipe - | ./vvencapp --y4m -i - --threads "$threads" --verbosity 2 \
    --preset="$preset" --qp="$qp" -o "$1"
  echo -e "\e[A\e[2K\e[A\e[2K\e[32mRunning vvencapp - Done\e[0m"

}

compressVVC-2pass() {

  echo -e "\e[33mRunning vvencapp - phase 1...\e[0m"
  ffmpeg -i "$input" -y -strict -1 -y -loglevel error -stats -pix_fmt yuv420p -r "$maxFps" \
    -vf "scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)" \
    -f yuv4mpegpipe - | ./vvencapp --y4m -i - --passes=2 --pass=1 --threads "$threads" --verbosity 2 \
    --preset="$preset" --bitrate="$bitrate" --rcstatsfile="pass-stats" && \
  echo -e "\e[A\e[2K\e[A\e[2K\e[33mRunning vvencapp - phase 2...\e[0m" && \
  ffmpeg -i "$input" -y -strict -1 -y -loglevel error -stats -pix_fmt yuv420p -r "$maxFps" \
    -vf "scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)" \
    -f yuv4mpegpipe - | ./vvencapp --y4m -i - --passes=2 --pass=2 --threads "$threads" --verbosity 2 \
    --preset="$preset" --bitrate="$bitrate" --rcstatsfile="pass-stats" -o "$1"
  echo -e "\e[A\e[2K\e[A\e[2K\e[32mRunning vvencapp - Done\e[0m"
  rm 'pass-stats'

}

compressAV1() {

  echo -e "\e[33mRunning aomenc - pass 1...\e[0m"
  ffmpeg -y -i "$input" -strict -1 -loglevel error -pix_fmt yuv420p -r "$maxFps" \
    -vf "scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)" \
    -f yuv4mpegpipe - | aomenc - --passes=2 --pass=1 --cpu-used="$cpuUsed" --threads="$threads" \
    --end-usage=q --cq-level="$crf" --bit-depth=8 --enable-fwd-kf=1 --kf-max-dist=300 --kf-min-dist=12 \
    --tile-columns=0 --tile-rows=0 --sb-size=64 --lag-in-frames=48 --arnr-strength=2 --arnr-maxframes=3 \
    --aq-mode=0 --deltaq-mode=1 --enable-qm=1 --tune=psnr --tune-content=default --fpf="pass-stats" -o NUL && \
  echo -e "\e[A\e[2K\e[A\e[2K\e[33mRunning aomenc - pass 2...\e[0m" && \
  ffmpeg -y -i "$input" -strict -1 -loglevel error -pix_fmt yuv420p -r "$maxFps" \
    -vf "scale=if(gte(iw\,ih)\,min($maxSize\,iw)\,-2):if(lt(iw\,ih)\,min($maxSize\,ih)\,-2)" \
    -f yuv4mpegpipe - | aomenc - --passes=2 --pass=2 --cpu-used="$cpuUsed" --threads="$threads" \
    --end-usage=q --cq-level="$crf" --bit-depth=8 --enable-fwd-kf=1 --kf-max-dist=300 --kf-min-dist=12 \
    --tile-columns=0 --tile-rows=0 --sb-size=64 --lag-in-frames=48 --arnr-strength=2 --arnr-maxframes=3 \
    --aq-mode=0 --deltaq-mode=1 --enable-qm=1 --tune=psnr --tune-content=default \
    --fpf="pass-stats" -o "$1"
  echo -e "\e[A\e[2K\e[A\e[2K\e[32mRunning aomenc - Done\e[0m"
  rm 'pass-stats'

}

run() {

  SECONDS=0
  "$1" "$2"
  outputSize=$(du -h "$2")
  outputSize="${outputSize%%\t*}"
  echo -e "\e[2KTime: ${SECONDS}s, Size: ${outputSize::-1}, Output: $2\n";
  adb push "$2" "/sdcard/Download/$2" >/dev/null #&& rm "$2"

}

#run compressVVC-1pass "${input%.*}-${maxFps}fps-${preset}-${qp}qp.vvc"
#run compressVVC-2pass "${input%.*}-${maxFps}fps-${preset}-${bitrate}.vvc"
run compressAV1 "${input%.*}-${maxFps}fps-${cpuUsed}cpu-${crf}crf.mkv"
