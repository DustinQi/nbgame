#!/bin/bash
# 运行嘉悦云上游戏
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD" "$@"
