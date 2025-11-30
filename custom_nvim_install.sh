#!/bin/bash
###############################################################
# custom_nvim_install.sh
# Authored by Nicholas Stafford
# Persistent Neovim + LazyVim setup for Unraid 7.x
#
# One script handles:
#   - Early boot (USB only)
#   - Normal runtime (prefers cache)
#   - Array start migration (USB → cache)
#
# Key guarantees:
#   - Wrapper script always works (dynamic USB/cache root)
#   - Config paths always correct
#   - LazyVim bootstrap works when possible; minimal config otherwise
#   - BusyBox-safe
#
###############################################################

set -Eeuo pipefail

###############################################################
# Initial default paths (USB-first)
###############################################################

cache_is_mounted() {
	grep -q " /mnt/cache " /proc/mounts 2>/dev/null
}

if [ -f "/boot/config/nvim/paths.env" ]; then
	# shellcheck disable=SC1091
	. /boot/config/nvim/paths.env
else
	echo "ERROR: paths.env missing."
	exit 1
fi

# Default NVIM_ROOT → USB
NVIM_ROOT="$USB_ROOT"

if cache_is_mounted; then
	NVIM_ROOT="$CACHE_ROOT"
fi

# Paths bound to NVIM_ROOT
NVIM_BIN_DIR="$NVIM_ROOT/bin"
NVIM_CONFIG_DIR="$NVIM_ROOT/config"
NVIM_DATA_DIR="$NVIM_ROOT/data"
NVIM_CACHE_DIR="$NVIM_ROOT/cache"
NVIM_STATE_DIR="$NVIM_ROOT/state"
NVIM_LOG_DIR="$NVIM_ROOT/logs"

NVIM_APPIMAGE="$NVIM_BIN_DIR/nvim.appimage"
NVIM_OLD_APPIMAGE="$NVIM_BIN_DIR/nvim.appimage.old"
NVIM_WRAPPER="/usr/local/bin/nvim"

# Optional offline fallback AppImage path
FALLBACK_APPIMAGE="/boot/config/extra/nvim-linux-x86_64.appimage"

LOGFILE="$NVIM_LOG_DIR/nvim_setup.log"

###############################################################
# Logging setup
###############################################################
mkdir -p "$NVIM_LOG_DIR"

if [ -t 1 ]; then
	# Log to file and to console if running interactively
	exec > >(tee -a "$LOGFILE") 2>&1
else
	# Log only to file when run from go script
	exec >>"$LOGFILE" 2>&1
fi

log() {
	# Simple timestamped logger
	printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

log "=== Unraid Neovim persistence setup starting ==="
log "Using NVIM_ROOT: $NVIM_ROOT"

###############################################################
# Optional one-time migration USB → cache
###############################################################
if cache_is_mounted && [ -d "$USB_ROOT" ] && [ ! -d "$CACHE_ROOT/config" ]; then
	log "Cache mounted and no cache nvim folder — migrating USB → cache..."
	mkdir -p "$CACHE_ROOT"
	cp -a "$USB_ROOT"/. "$CACHE_ROOT/" 2>/dev/null || true
	log "Migration complete."
fi

###############################################################
# Helpers
###############################################################
check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		log "ERROR: This script must be run as root."
		exit 1
	fi
}

have_internet() {
	# Cheap connectivity check
	ping -c1 -W1 github.com >/dev/null 2>&1 || return 1
	return 0
}

have_cmd() {
	command -v "$1" >/dev/null 2>&1
}

ensure_dirs() {
	mkdir -p "$NVIM_BIN_DIR" "$NVIM_CONFIG_DIR" "$NVIM_DATA_DIR" \
		"$NVIM_CACHE_DIR" "$NVIM_STATE_DIR" "$NVIM_LOG_DIR"
}

###############################################################
# Neovim AppImage install/update
###############################################################
download_latest_appimage() {
	local tmpfile="$NVIM_BIN_DIR/nvim.appimage.new"
	local url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"

	log "--- Downloading latest Neovim AppImage ---"

	rm -f "$tmpfile"

	if have_cmd wget; then
		wget -q -O "$tmpfile" "$url" || return 1
	elif have_cmd curl; then
		curl -fsSL -o "$tmpfile" "$url" || return 1
	else
		log "No wget or curl available; cannot download Neovim."
		return 1
	fi

	if [ ! -s "$tmpfile" ]; then
		log "Downloaded file is empty; aborting update."
		rm -f "$tmpfile"
		return 1
	fi

	chmod 755 "$tmpfile"

	# If we already have an AppImage, keep a backup
	if [ -f "$NVIM_APPIMAGE" ]; then
		mv -f "$NVIM_APPIMAGE" "$NVIM_OLD_APPIMAGE"
		log "Existing Neovim saved as $NVIM_OLD_APPIMAGE"
	fi

	mv -f "$tmpfile" "$NVIM_APPIMAGE"
	log "Installed latest Neovim to $NVIM_APPIMAGE"
	return 0
}

install_fallback_appimage() {
	if [ -f "$NVIM_APPIMAGE" ]; then
		# Already have something; don't overwrite
		return 0
	fi

	if [ -f "$FALLBACK_APPIMAGE" ]; then
		log "--- Using fallback AppImage from $FALLBACK_APPIMAGE ---"
		mkdir -p "$NVIM_BIN_DIR"
		cp "$FALLBACK_APPIMAGE" "$NVIM_APPIMAGE"
		chmod 755 "$NVIM_APPIMAGE"
		log "Copied fallback Neovim AppImage."
		return 0
	fi

	log "No AppImage available (no download, no fallback)."
	return 1
}

ensure_nvim_appimage() {
	if have_internet; then
		if ! download_latest_appimage; then
			log "Download failed; will try fallback AppImage if available."
			install_fallback_appimage || log "WARNING: Neovim binary missing."
		fi
	else
		log "--- No internet; skipping online Neovim update ---"
		install_fallback_appimage || log "WARNING: Neovim binary missing."
	fi
}

###############################################################
# Wrapper script in /usr/local/bin
###############################################################
install_nvim_wrapper() {
	local src="$USB_ROOT/wrapper.sh"

	if [ ! -f "$src" ]; then
		log "ERROR: Wrapper script missing at $src"
	else
		cp "$src" "$NVIM_WRAPPER"
		chmod 755 "$NVIM_WRAPPER"
		log "Installed wrapper script to $NVIM_WRAPPER"
	fi
}

###############################################################
# LazyVim / config bootstrap
###############################################################
write_minimal_init() {
	local src="/boot/config/nvim/minimal_init.lua"

	if [ ! -f "$src" ]; then
		log "ERROR: $src not found."
		log "FATAL: Cannot create Neovim config. Aborting."
		exit 1
	fi

	mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"
	cp "$src" "$NVIM_CONFIG_DIR/init.lua"
	log "Installed minimal init.lua and created /lua/plugins directory."
}

install_unraid_plugin_config() {
	local src="/boot/config/nvim/unraid_config.lua"
	local dest_dir="$NVIM_CONFIG_DIR/lua/plugins"
	if [ -f "$src" ]; then
		mkdir -p "$dest_dir"
		cp "$src" "$dest_dir/unraid_config.lua"
		log "Installed Unraid-specific plugin overrides to $dest_dir/unraid_config.lua"
	else
		log "unraid_config.lua not found at /boot/config/nvim; skipping Unraid plugin overrides."
	fi
}

bootstrap_lazyvim() {
	# If user already has a config, do not touch it.
	if [ -f "$NVIM_CONFIG_DIR/init.lua" ]; then
		log "Existing Neovim config detected; skipping LazyVim bootstrap."
		install_unraid_plugin_config
		return
	fi

	# Try to bootstrap LazyVim starter if git + internet are available.
	if have_cmd git && have_internet; then
		log "--- Bootstrapping LazyVim starter config ---"
		local tmp_dir="$NVIM_ROOT/tmp_lazyvim"
		rm -rf "$tmp_dir"
		mkdir -p "$tmp_dir"

		if git clone --depth 1 https://github.com/LazyVim/starter "$tmp_dir"; then
			# Move all files (including dotfiles) into the config directory.
			shopt -s dotglob
			mkdir -p "$NVIM_CONFIG_DIR"
			mv "$tmp_dir"/* "$NVIM_CONFIG_DIR"/
			shopt -u dotglob
			rm -rf "$tmp_dir"
			log "LazyVim starter installed into $NVIM_CONFIG_DIR"
		else
			log "git clone of LazyVim starter failed; falling back to minimal init.lua."
			rm -rf "$tmp_dir"
			write_minimal_init
		fi
	else
		log "git not available or no internet; creating minimal init.lua instead of LazyVim."
		write_minimal_init
	fi

	# Add Unraid-specific overrides if available.
	install_unraid_plugin_config
}

###############################################################
# Main
###############################################################
main() {
	check_root
	ensure_dirs
	ensure_nvim_appimage
	install_nvim_wrapper
	bootstrap_lazyvim
	log "=== Neovim persistence setup complete ==="
}

main "$@"
