
eval "$(/opt/homebrew/bin/brew shellenv)"

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

function wav() {
  local f
  for f in "$@"; do
    ffmpeg -i "$f" -ar 16000 -ac 1 -c:a pcm_s16le "${f%.*}.wav"
  done
}

# shortcut to whisper
function whisper() {
    local dir="/Users/${USER}/Downloads/whisper.cpp/"
    local filename=""
    local prompt_text=""

    # --- 1. 参数解析 (用户依然输入 -p) ---
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--prompt) # 兼容用户输入 -p 或 --prompt
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "❌ 错误: -p/--prompt 参数后面必须跟提示词文本。"
                    return 1
                fi
                prompt_text="$2"
                shift 2
                ;;
            *)
                filename="$1"
                shift 1
                ;;
        esac
    done

    # --- 2. 检查文件名 ---
    if [[ -z "$filename" ]]; then
        echo "❌ 错误: 未提供文件名。"
        echo "用法: whisper <filename> [-p \"提示词\"]"
        return 1
    fi

    # --- 3. 音频转换 ---
    local basename="${filename%.*}"
    # -y: 覆盖同名文件, -v error: 减少干扰信息
    ffmpeg -y -v error -i "$filename" -ar 16000 -ac 1 -c:a pcm_s16le "${basename}.wav"

    # --- 4. 构建参数数组 ---
    local cmd_args=(
        -m "$dir/models/ggml-medium.en.bin"
        -f "${basename}.wav"
        -ovtt
        -otxt
    )

    # --- 关键修改：这里明确使用 --prompt ---
    if [[ -n "$prompt_text" ]]; then
        echo "💡 使用提示词: $prompt_text"
        cmd_args+=(--prompt "$prompt_text")
    fi

    echo "🎙️  正在转录: $filename ..."
    
    # --- 5. 执行命令 ---
    "$dir/build/bin/whisper-cli" "${cmd_args[@]}"

    # --- 6. 清理 ---
    mv "${basename}.wav.txt" "${basename}.txt"
    mv "${basename}.wav.vtt" "${basename}.vtt"
    rm "${basename}.wav"
    
    echo "✅ 完成！"
}
function whispercn() {
  local dir="/Users/${USER}/Downloads/whisper.cpp/"
  local filename="$1"
  ffmpeg -i "$filename" -ar 16000 -ac 1 -c:a pcm_s16le "${filename%.*}.wav"
  local model='ggml-large-v3.bin'
  "$dir/build/bin/whisper-cli" -m "$dir/models/$model" -l chinese -f "${filename%.*}.wav" -ovtt -otxt
  mv "${filename%.*}.wav.txt" "${filename%.*}.txt"
  mv "${filename%.*}.wav.vtt" "${filename%.*}.vtt"
  rm "${filename%.*}.wav"
}

function stream() {
  local dir="/Users/${USER}/Downloads/whisper.cpp/"
  "$dir/build/bin/whisper-stream" -m "$dir/models/ggml-medium.en.bin" -f "./$(date "+%Y-%m-%d %H-%M-%S").txt" "$@"
}

function ld_ssh_key() {
  echo "Checking if private key loaded..."
  if [[ $(ssh-add -l) == *"no identities"* ]]; then
    echo "Load private key..."
    ssh-add ~/.ssh/id_*
  fi
  echo "Private key loaded!"
  command ssh "$@"
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
  echo "[MD5   ] $(md5sum "$1" | awk '{print $1}')"
  echo "[SHA1  ] $(shasum -a 1 "$1" | awk '{print $1}')"
  echo "[SHA256] $(shasum -a 256 "$1" | awk '{print $1}')"
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
# Added by Toolbox App
case ":$PATH:" in
  *":/Users/xicheng.li/Library/Application Support/JetBrains/Toolbox/scripts:"*) ;;
  *) export PATH="$PATH:/Users/xicheng.li/Library/Application Support/JetBrains/Toolbox/scripts" ;;
esac

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
