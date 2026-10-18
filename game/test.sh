#!/bin/bash
# 运行全部自动化测试
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PWD" -s tests/test_runner.gd
