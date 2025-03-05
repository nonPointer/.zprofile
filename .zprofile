# SAP Privilege
export PRIVILEGES_CLI_LOCATION=/Applications/Privileges.app/Contents/MacOS/PrivilegesCLI 
function please() {
  if [[ $(groups "$USER") != *admin* ]]; then
    echo "Elevate to root privilege"
    ${PRIVILEGES_CLI_LOCATION} -a -n "For some reasons" &> /dev/null
  fi
  sudo $@
}

# shortcut to whisper
function whisper() {
  dir="/Users/${USER}/Downloads/whisper.cpp/"
  filename=$@
  ffmpeg -i "$filename" -ar 16000 -ac 1 -c:a pcm_s16le "${filename%.*}.wav" 
  "$dir/build/bin/whisper-cli" -m "$dir/models/ggml-medium.en.bin" -f "${filename%.*}.wav" -ovtt -otxt
  mv "${filename%.*}.wav.txt" "${filename%.*}.txt"
  mv "${filename%.*}.wav.vtt" "${filename%.*}.vtt"
  rm "${filename%.*}.wav"
}

# shortcut to whisper-stream
function stream() {
  dir="/Users/${USER}/Downloads/whisper.cpp/"
  "$dir/build/bin/whisper-stream" -m "$dir/models/ggml-medium.en.bin" -t 0 -f "./$(date "+%Y-%m-%d %H-%M-%S").txt"
}
