#!/bin/bash
# Smart wrapper: prefer cache, fall back to USB

USB_ROOT="/boot/config/nvim"
CACHE_ROOT="/mnt/cache/nvim"

if grep -q " /mnt/cache " /proc/mounts 2>/dev/null; then
	ROOT="$CACHE_ROOT"
else
	ROOT="$USB_ROOT"
fi

export XDG_CONFIG_HOME="$ROOT/config"
export XDG_DATA_HOME="$ROOT/data"
export XDG_STATE_HOME="$ROOT/state"
export XDG_CACHE_HOME="$ROOT/cache"

exec "$ROOT/bin/nvim.appimage" "$@"
