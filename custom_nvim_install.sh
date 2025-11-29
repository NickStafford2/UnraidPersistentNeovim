#!/bin/bash
# Persistent Neovim + LazyVim setup for Unraid 7.1.4
# Authored by Nicholas Stafford

set -e

###############################################################
# Logging
# All output (stdout + stderr) is saved to:
#   /mnt/cache/nvim/logs/nvim_setup.log
#
# Logs persist across reboots and are appended on each run.
###############################################################
LOGFILE="/mnt/cache/nvim/logs/nvim_setup.log"
mkdir -p /mnt/cache/nvim/logs

exec > >(tee -a "$LOGFILE") 2>&1
echo "--- Neovim Setup Run: $(date) ---"

echo "=== Persistent Neovim Setup (Unraid 7.1.4) ==="

###############################################################
# Explanation: Why there are three AppImage paths
#
# 1. BOOT_APP  (USB flash drive)
#    - Manually placed by you
#    - Backup copy
#    - FAT32 filesystem removes permissions
#    - Not suitable for runtime use
#
# 2. CACHE_APP (SSD cache drive)
#    - Persistent, safe storage
#    - Fast read access
#    - Holds the "installed" Neovim version
#
# 3. ROOT_APP  (/root in RAM)
#    - Runtime copy restored on every boot
#    - /usr/local/bin/nvim symlink points here
#    - Required because Unraid wipes /root on reboot
#
# Flow:
#   USB (backup) → CACHE (installed) → ROOT (runtime)
###############################################################

PERSIST="/mnt/cache/nvim"

BOOT_APP="/boot/extra/nvim-linux-x86_64.appimage"
CACHE_APP="$PERSIST/bin/nvim.appimage"
ROOT_APP="/root/nvim/nvim.appimage"

###############################################################
# Ensure required directories exist
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
# Neovim auto-update using GitHub API
###############################################################
echo "--- Checking for latest Neovim release ---"

LATEST_URL=$(curl -sL https://api.github.com/repos/neovim/neovim/releases/latest |
	grep browser_download_url |
	grep appimage |
	cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
	echo "Could not check GitHub for latest Neovim release."
else
	TMP_DL="/tmp/nvim-latest.appimage"
	echo "Downloading latest Neovim..."
	curl -L -o "$TMP_DL" "$LATEST_URL"
	chmod 755 "$TMP_DL"

	NEW_VER=$("$TMP_DL" --version | head -n 1 | awk '{print $2}')
	OLD_VER="none"

	if [ -f "$CACHE_APP" ]; then
		OLD_VER=$("$CACHE_APP" --version | head -n 1 | awk '{print $2}')
	fi

	echo "Installed version: $OLD_VER"
	echo "Available version: $NEW_VER"

	if [ "$NEW_VER" != "$OLD_VER" ]; then
		echo "Updating Neovim to $NEW_VER..."
		mv "$CACHE_APP" "$CACHE_APP.old" 2>/dev/null || true
		mv "$TMP_DL" "$CACHE_APP"
		chmod 755 "$CACHE_APP"
	else
		echo "Already up to date."
		rm -f "$TMP_DL"
	fi
fi

###############################################################
# Restore NVIM runtime binary every boot
###############################################################
if [ -f "$CACHE_APP" ]; then
	echo "Restoring Neovim runtime binary..."
	cp "$CACHE_APP" "$ROOT_APP"
	chmod 755 "$ROOT_APP"
	ln -sf "$ROOT_APP" /usr/local/bin/nvim
else
	echo "WARNING: No persistent Neovim AppImage found at $CACHE_APP"
	echo "         Place one manually at: $BOOT_APP"
fi

###############################################################
# First-time setup — load USB version if persistent missing
###############################################################
if [ ! -f "$CACHE_APP" ] && [ -f "$BOOT_APP" ]; then
	echo "Copying USB AppImage into persistent cache..."
	cp "$BOOT_APP" "$CACHE_APP"
	chmod 755 "$CACHE_APP"
fi

###############################################################
# LazyVim auto-install (only if config directory is empty)
###############################################################
if [ ! "$(ls -A $PERSIST/config)" ]; then
	echo "LazyVim not found; installing starter configuration..."
	git clone https://github.com/LazyVim/starter $PERSIST/config
	rm -rf $PERSIST/config/.git
else
	echo "LazyVim configuration already exists."
fi

###############################################################
# Symlinks for NVIM config/data/cache
###############################################################
ln -sf $PERSIST/config /root/.config/nvim
ln -sf $PERSIST/data /root/.local/share/nvim
ln -sf $PERSIST/cache /root/.cache/nvim

###############################################################
# Sync local config with GitHub repo (if internet available)
#
# This keeps your local /mnt/cache/nvim/config in sync with your
# GitHub repo. Requires the repo to be public because Unraid has
# only a minimal BusyBox git with limited features.
###############################################################
REPO_URL="https://github.com/NickStafford2/UnraidPersistentNeovim.git"
LOCAL_REPO="$PERSIST/config"

if ping -c 1 -W 1 github.com >/dev/null 2>&1; then
	echo "--- Internet detected: syncing config from GitHub ---"

	# If config folder does not exist, do a fresh clone
	if [ ! -d "$LOCAL_REPO/.git" ]; then
		echo "Config not a git repo — cloning fresh copy..."
		rm -rf "$LOCAL_REPO"
		git clone "$REPO_URL" "$LOCAL_REPO" || echo "Clone failed; using local copy."
	else
		echo "Updating existing config repo..."
		git -C "$LOCAL_REPO" pull --rebase || echo "Pull failed; keeping local version."
	fi
else
	echo "--- No internet; skipping GitHub sync ---"
fi

echo "=== Neovim persistence setup complete ==="
