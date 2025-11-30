#!/bin/bash
# Smart wrapper: prefer cache, fall back to USB

# shellcheck disable=SC1091
. /boot/config/nvim/paths.env

# Determine active root (cache preferred)
if grep -q " /mnt/cache " /proc/mounts 2>/dev/null; then
	ROOT="$CACHE_ROOT"
else
	ROOT="$USB_ROOT"
fi

APP="$ROOT/bin/nvim.appimage"

# Fallback logic: if chosen root doesn't have the AppImage, try USB
if [ ! -f "$APP" ]; then
	# Try USB fallback
	if [ -f "$USB_ROOT/bin/nvim.appimage" ]; then
		ROOT="$USB_ROOT"
		APP="$USB_ROOT/bin/nvim.appimage"
	else
		echo "ERROR: nvim.appimage not found in cache or USB."
		exit 1
	fi
fi

# Export XDG dirs
export XDG_CONFIG_HOME="$ROOT/config"
export XDG_DATA_HOME="$ROOT/data"
export XDG_STATE_HOME="$ROOT/state"
export XDG_CACHE_HOME="$ROOT/cache"

exec "$APP" "$@"
