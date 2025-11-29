#!/bin/bash
# Add a description of the app here. authored by Nicholas STafford. to be used with unraid. done on version unraid 7.1.4.
set -e

echo "=== Persistent Neovim Setup ==="

# Persistent base directory
PERSIST="/mnt/cache/nvim"

###############################################################
# 0. AppImage locations
###############################################################
# This is where your Neovim AppImage lives on the USB flash drive.
BOOT_APP="/boot/extra/nvim-linux-x86_64.appimage"

# This is the version stored on the cache drive, which is actually persistent and much faster than USB.
CACHE_APP="$PERSIST/bin/nvim.appimage"

# This is where the script restores the appimage into RAM every boot.
ROOT_APP="/root/nvim/nvim.appimage"

###############################################################
# 1. Restore NVIM binary every boot
# but lets change this
# Make Nvim first so that if the script fails at some point, at least nvim is installed. the goal is to get some version of nvim working, then try to fix it if possible
# If a copy of nvim exists in cache. lets load and use that first.
# then, lets download the latest version of neovim. and use that.
# wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
# if there is an easy way to test if it is working, do that. otherwise. use the newest version, and save the previous version as nvim-linux-x86_64.appimage.old (or something like that)
# maybe we should use the usb one as backup? idk. give me options and I will decide what to do.
###############################################################
if [ -f "$CACHE_APP" ]; then
	cp "$CACHE_APP" "$ROOT_APP"
	chmod 755 "$ROOT_APP"
	ln -sf "$ROOT_APP" /usr/local/bin/nvim
else
	echo "WARNING: No Neovim AppImage found in $CACHE_APP"
fi
###############################################################
# 1. Ensure persistent directories exist
###############################################################
mkdir -p $PERSIST/config
mkdir -p $PERSIST/data
mkdir -p $PERSIST/cache
mkdir -p $PERSIST/bin
mkdir -p /root/nvim
mkdir -p /root/.config
mkdir -p /root/.local/share
mkdir -p /root/.cache

###############################################################
# 2. my idea not sure
###############################################################
# here, lets look if the $PERSIST/config exists. if it does. use that neovim configuration. if not, download lazyvim from online and save it to that directory.
###############################################################
# 3. Move existing DATA (first-time-only)
###############################################################
ln -sf $PERSIST/data /root/.local/share/nvim

###############################################################
# 4. Move existing CACHE (first-time-only)
###############################################################
ln -sf $PERSIST/cache /root/.cache/nvim

###############################################################
# 5. Persistent AppImage (first-time-only)
###############################################################
if [ -f "$BOOT_APP" ] && [ ! -f "$CACHE_APP" ]; then
	echo "Copying AppImage to persistent storage..."
	cp "$BOOT_APP" "$CACHE_APP"
	chmod 755 "$CACHE_APP"
fi

echo "=== Neovim persistence ready ==="
