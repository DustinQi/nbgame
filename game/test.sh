#!/bin/bash
# 运行全部自动化测试
cd "$(dirname "$0")"
output=$(/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PWD" -s tests/test_runner.gd 2>&1)
status=$?
echo "$output"
# Godot 对部分脚本错误仍返回 0，必须自己检查输出，避免假绿
if [ $status -ne 0 ]; then
    exit $status
fi
if ! printf '%s\n' "$output" | grep -q "测试完成："; then
    echo "测试未正常结束：没有看到完成汇总" >&2
    exit 1
fi
if printf '%s\n' "$output" | grep -q "SCRIPT ERROR"; then
    echo "测试输出包含 SCRIPT ERROR，判定为失败" >&2
    exit 1
fi
exit 0
