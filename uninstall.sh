#!/bin/bash
#
# uninstall.sh – Removes Unraid Persistent Neovim cleanly
# Safe to re-run; removes only files installed by install.sh.
#

set -Eeuo pipefail

BOOTCFG="/boot/config"
TARGET_DIR="$BOOTCFG/nvim"
INSTALL_SCRIPT="$BOOTCFG/custom_nvim_install.sh"
GO_FILE="$BOOTCFG/go"
NVIM_CACHE="/mnt/cache/nvim"
WRAPPER_SYMLINK="/usr/local/bin/nvim"
USER_SCRIPTS_DIR="/boot/config/plugins/user.scripts/scripts"
AFTER_ARRAY_SCRIPT_NAME="Run-Nvim-Installer-After-Array"
AFTER_ARRAY_SCRIPT_PATH="$USER_SCRIPTS_DIR/$AFTER_ARRAY_SCRIPT_NAME"

log() {
	printf "[uninstall] %s\n" "$*"
}

fail() {
	printf "[UNINSTALL ERROR] %s\n" "$*" >&2
	exit 1
}

# ---------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
	fail "Please run uninstall.sh as root."
fi

if [ ! -d "$BOOTCFG" ]; then
	fail "/boot/config not found — this does not look like Unraid."
fi

log "Starting Unraid Persistent Neovim removal..."

# ---------------------------------------------------------
# Remove startup hook from /boot/config/go
# ---------------------------------------------------------
if grep -q "custom_nvim_install.sh" "$GO_FILE"; then
	log "Removing startup hook from $GO_FILE..."

	# Keep everything except the lines between the Start/End markers
	sed -i '/# Start Unraid Persistent Neovim/,/# End Unraid Persistent Neovim/d' "$GO_FILE"

	log "Startup hook removed."
else
	log "No go file entry found — skipping."
fi

# ---------------------------------------------------------
# Remove scripts under /boot/config
# ---------------------------------------------------------
if [ -f "$INSTALL_SCRIPT" ]; then
	log "Removing $INSTALL_SCRIPT..."
	rm -f "$INSTALL_SCRIPT"
else
	log "custom_nvim_install.sh not found — skipping."
fi

# Remove entire /boot/config/nvim directory (safe—only your files live there)
if [ -d "$TARGET_DIR" ]; then
	log "Removing $TARGET_DIR..."
	rm -rf "$TARGET_DIR"
else
	log "/boot/config/nvim directory not found — skipping."
fi

# ---------------------------------------------------------
# Remove persistent data under /mnt/cache/nvim
# ---------------------------------------------------------
if [ -d "$NVIM_CACHE" ]; then
	log "Removing persistent Neovim data at $NVIM_CACHE..."
	rm -rf "$NVIM_CACHE"
else
	log "No persistent nvim cache dir found — skipping."
fi

# ---------------------------------------------------------
# Remove wrapper symlink
# ---------------------------------------------------------
if [ -L "$WRAPPER_SYMLINK" ]; then
	log "Removing nvim symlink at $WRAPPER_SYMLINK..."
	rm -f "$WRAPPER_SYMLINK"
else
	log "No nvim symlink found in /usr/local/bin — skipping."
fi

# ---------------------------------------------------------
# Remove User Scripts entry (Array Start script)
# ---------------------------------------------------------
if [ -d "$AFTER_ARRAY_SCRIPT_PATH" ]; then
	log "Removing User Script: $AFTER_ARRAY_SCRIPT_PATH..."
	rm -rf "$AFTER_ARRAY_SCRIPT_PATH"
else
	log "No User Script for Neovim found — skipping."
fi

# ---------------------------------------------------------
# Complete
# ---------------------------------------------------------
log "Uninstall complete!"
log "Neovim persistence has been fully removed from this system."

exit 0
