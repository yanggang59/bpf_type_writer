#!/bin/bash

set -euo pipefail

CLICK="./click.au"
CLINK="./clink.au"

# 检查
for f in "$CLICK" "$CLINK"; do [[ -f "$f" ]] || { echo "Missing $f"; exit 1; }; done
command -v aplay >/dev/null || { echo "aplay missing"; exit 1; }

#echo "🔍 Debug mode: printing ALL lines from bpftrace"

# 直接用 -e 避免文件/here doc 问题
stdbuf -oL sudo -E bpftrace -e '
kprobe:input_event
/arg1 == 1 && arg3 == 1/
{
    if (arg2 == 28) {
        printf("KEY_ENTER\n");
    } else {
        printf("KEY_OTHER\n");
    }
}
' 2>&1 | while IFS= read -r line; do
    # 调试：打印每一行（包括空行）
    # printf ">>> Received: [%s]\n" "$line"
    
    case "$line" in
        KEY_ENTER)
            aplay -q "$CLINK" >/dev/null 2>&1 &
            ;;
        KEY_OTHER)
            aplay -q "$CLICK" >/dev/null 2>&1 &
            ;;
    esac
done