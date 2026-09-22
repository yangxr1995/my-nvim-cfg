#!/bin/sh
# yazi edit opener：先解析为绝对路径，再 cd 到 yazi 启动目录后打开 nvim
target=$(realpath -- "$1") || exit 1
if [ -n "$YAZI_ORIG_CWD" ] && [ -d "$YAZI_ORIG_CWD" ]; then
	cd -- "$YAZI_ORIG_CWD" || exit 1
fi
exec nvim -- "$target"
