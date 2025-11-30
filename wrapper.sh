#!/bin/bash
# Smart wrapper: prefer cache, fall back to USB

# shellcheck disable=SC1091
. /boot/config/nvim/paths.env

# --- Verbosity system (future-proof) ---
# 0 = silent, 1 = basic, 2 = more, 3 = full debug
VERBOSE_LEVEL=3 # <-- always max verbosity for now

log() {
	if [ "$VERBOSE_LEVEL" -ge "$1" ] && [ -t 1 ]; then
		# Only print if running in an interactive terminal
		shift
		echo "[nvim-wrapper] $*"
	fi
}

CACHE_MOUNTED=false
if grep -q " /mnt/cache " /proc/mounts 2>/dev/null; then
	CACHE_MOUNTED=true
fi

CACHE_APP="$CACHE_ROOT/bin/nvim.appimage"
USB_APP="$USB_ROOT/bin/nvim.appimage"

# --- Auto-recovery: if cache exists but is missing the AppImage, repair it ---
if $CACHE_MOUNTED && [ ! -f "$CACHE_APP" ] && [ -f "$USB_APP" ]; then
	log 1 "Cache missing nvim.appimage; restoring from USB..."
	mkdir -p "$CACHE_ROOT/bin"
	cp "$USB_APP" "$CACHE_APP" 2>/dev/null
	chmod 755 "$CACHE_APP"
fi

# --- Select root (prefer cache if mounted and has an AppImage) ---
if $CACHE_MOUNTED && [ -f "$CACHE_APP" ]; then
	ROOT="$CACHE_ROOT"
	APP="$CACHE_APP"
	SOURCE="CACHE"
elif [ -f "$USB_APP" ]; then
	ROOT="$USB_ROOT"
	APP="$USB_APP"
	SOURCE="USB"
else
	echo "ERROR: nvim.appimage not found in cache or USB."
	exit 1
fi

# Export XDG dirs for the selected root
export XDG_CONFIG_HOME="$ROOT/config"
export XDG_DATA_HOME="$ROOT/data"
export XDG_STATE_HOME="$ROOT/state"
export XDG_CACHE_HOME="$ROOT/cache"

# --- Debug output based on verbosity ---
log 1 "  Source: $SOURCE"
log 2 "  Using ROOT: $ROOT"
log 3 "  AppImage: $APP"

exec "$APP" "$@"
