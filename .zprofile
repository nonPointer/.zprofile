# SAP Privilege
export PRIVILEGES_CLI_LOCATION=/Applications/Privileges.app/Contents/MacOS/PrivilegesCLI 

function sudo() {
  # 1. 检查当前用户是否在 admin 组（Privileges.app 的逻辑）
  if [[ $(groups "$USER") != *admin* ]]; then
    echo "Checking privileges... Elevating to admin."
    
    # 确保变量存在，若不存在则尝试默认路径
    local priv_cli="${PRIVILEGES_CLI_LOCATION:-/Applications/Privileges.app/Contents/Resources/PrivilegesCLI}"
    
    # 执行提权操作
    if [[ -f "$priv_cli" ]]; then
      "$priv_cli" -a -n "Automatic elevation for sudo" &> /dev/null
    else
      echo "Warning: Privileges CLI not found at $priv_cli"
    fi
  fi

  # 2. 使用 'command' 关键字调用真正的 /usr/bin/sudo
  # "$@" 确保所有参数（包括空格和引号）原封不动传递
  command sudo "$@"
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

# ssh wrapper
function ld_ssh_key() {
  echo "Checking if private key loaded..."
  if [[ $(ssh-add -l) == *"no identities"* ]]; then
    echo "Load private key..."
    ssh-add
  fi
  echo "Private key loaded!"
  command ssh $@
} 
alias ssh=ld_ssh_key

function checksum() {
  if [[ -z "$1" ]]; then
    echo "Usage: checksum <filename>"
    return 1
  fi

  if [[ ! -f "$1" ]]; then
    echo "Error: File '$1' not found!"
    return 1
  fi

  echo "Checksums for: $1"
  echo "MD5:    $(md5sum "$1" | awk '{print $1}')"
  echo "SHA1:   $(shasum -a 1 "$1" | awk '{print $1}')"
  echo "SHA256: $(shasum -a 256 "$1" | awk '{print $1}')"
}

diffupdate() {
  local depth="${1:-1}"   # use provided value or default to 1
  (find . -maxdepth "$depth" -type f ! -name "checksum.txt" \
    -exec md5sum {} + | sed 's|^\./||' | sort) > checksum.txt
}

diffcheck() {
  local depth="${1:-1}"   # use provided value or default to 1
  diff <(find . -maxdepth "$depth" -type f ! -name "checksum.txt" \
          -exec md5sum {} + | sed 's|^\./||' | sort) <(sort checksum.txt)
}

venv() {
  python3 -m venv .venv
}
activate() {
  source .venv/bin/activate
}

function marp-pdf() {
    if [ -z "$1" ]; then
        echo "Usage: marp-pdf <filename.md>"
        return 1
    fi
    
    local output_file="${1%.*}.pdf"
    
    echo "Converting $1 to $output_file..."
    marp "$1" --pdf --allow-local-files -o "$output_file"
}

function marp-pptx() {
    if [ -z "$1" ]; then
        echo "Usage: marp-pptx <filename.md>"
        return 1
    fi
  
    local output_file="${1%.*}.pptx"
  
    echo "Converting $1 to $output_file (editable)..."
    marp "$1" --pptx --pptx-editable --allow-local-files -o "$output_file"
}

# jrnl shortcut
function j() {
  local dir="$HOME/Downloads/jrnl"
  "$dir/sync.sh"
  jrnl "$@"
  "$dir/sync.sh"
}

function claude-yolo () {
  claude --dangerously-skip-permissions
}
