#!/bin/bash

CLICK_SOUND="./click.au"
CLINK_SOUND="./clink.au"

# 检查依赖
command -v bpftrace >/dev/null || { echo "❌ bpftrace not installed"; exit 1; }
command -v aplay >/dev/null || { echo "❌ aplay not installed"; exit 1; }

for f in "$CLICK_SOUND" "$CLINK_SOUND"; do
    [[ -f "$f" ]] || { echo "❌ Missing sound file: $f"; exit 1; }
done


# 1. 用 stdbuf -oL 强制 bpftrace 输出行缓冲
# 2. 在 while 循环中用 sudo -u $USER_NAME 运行 aplay，确保音频权限正确
stdbuf -oL sudo -E bpftrace ./key_sound.bt 2>&1 | while IFS= read -r line; do
    case "$line" in
        KEY_ENTER)
		aplay -q ./clink.au >/dev/null 2>&1 &
            ;;
        KEY_OTHER)
		aplay -q ./click.au >/dev/null 2>&1 &
            ;;
    esac
done
