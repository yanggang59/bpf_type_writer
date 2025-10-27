#!/bin/bash

CLICK_SOUND="./click.au"
CLINK_SOUND="./clink.au"

# 检查依赖
command -v bpftrace >/dev/null || { echo "❌ bpftrace not installed"; exit 1; }
command -v aplay >/dev/null || { echo "❌ aplay not installed"; exit 1; }

for f in "$CLICK_SOUND" "$CLINK_SOUND"; do
    [[ -f "$f" ]] || { echo "❌ Missing sound file: $f"; exit 1; }
done

# 获取当前用户（用于后续以正确用户身份播放声音）
USER=$(whoami)
export USER
export CLICK_SOUND
export CLINK_SOUND
UID=$(id -u "$USER")  # 通常是 1000

# 关键：设置 XDG_RUNTIME_DIR
export XDG_RUNTIME_DIR="/run/user/$UID"

echo "🎧 Listening for keypresses... (Ctrl+C to quit)"
echo "USER : $USER, XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

# 关键修复：
# 1. 用 stdbuf -oL 强制 bpftrace 输出行缓冲
# 2. 在 while 循环中用 sudo -u $USER_NAME 运行 aplay，确保音频权限正确
stdbuf -oL sudo bpftrace ./key_sound.bt 2>&1 | while IFS= read -r line; do
    case "$line" in
        KEY_ENTER)
		sudo -u "$USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" aplay -q ./clink.au >/dev/null 2>&1 &
		echo "Enter"
            ;;
        KEY_OTHER)
		sudo -u "$USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" aplay -q ./click.au >/dev/null 2>&1 &
		echo "Key"
            ;;
    esac
done
