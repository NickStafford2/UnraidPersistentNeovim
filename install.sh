#!/bin/bash
#
# install.sh – Installer for Unraid Persistent Neovim
# Written By Nicholas Stafford.
# Copies all required files into the correct Unraid locations,
# configures /boot/config/go, and verifies environment compatibility.
#
# This script is BusyBox-friendly and safe to re-run (idempotent).

set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

BOOTCFG="/boot/config"
TARGET_DIR="$BOOTCFG/nvim"
INSTALL_SCRIPT_SRC="$REPO_DIR/custom_nvim_install.sh"
INSTALL_SCRIPT_DEST="$BOOTCFG/custom_nvim_install.sh"

WRAPPER_SRC="$REPO_DIR/nvim-wrapper.sh"
MINIMAL_INIT_SRC="$REPO_DIR/minimal_init.lua"
UNRAID_CONFIG_SRC="$REPO_DIR/unraid_config.lua"

GO_FILE="/boot/config/go"
USER_SCRIPTS_DIR="/boot/config/plugins/user.scripts/scripts"
AFTER_ARRAY_SCRIPT_NAME="Run-Nvim-Installer-After-Array"
AFTER_ARRAY_SCRIPT="$USER_SCRIPTS_DIR/$AFTER_ARRAY_SCRIPT_NAME/script"
AFTER_ARRAY_CRON="$USER_SCRIPTS_DIR/$AFTER_ARRAY_SCRIPT_NAME/cron"
AFTER_ARRAY_SRC="$REPO_DIR/run_custom_nvim_after_array_start.sh"

# ---------------------------------------------------------
# Helper logging
# ---------------------------------------------------------
log() {
	printf "[install] %s\n" "$*"
}

fail() {
	printf "[INSTALL ERROR] %s\n" "$*" >&2
	exit 1
}

# ---------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------
if [ ! -d "$BOOTCFG" ]; then
	fail "/boot/config does not exist — this is not an Unraid system."
fi

if [ "$(id -u)" -ne 0 ]; then
	fail "Please run install.sh as root."
fi

# ---------------------------------------------------------
# Create target directory
# ---------------------------------------------------------
log "Creating $TARGET_DIR..."
mkdir -p "$TARGET_DIR"

# ---------------------------------------------------------
# Copy core files
# ---------------------------------------------------------
copy_file() {
	local src="$1"
	local dest="$2"

	if [ ! -f "$src" ]; then
		fail "Required file missing: $src"
	fi

	cp "$src" "$dest"
	chmod 755 "$dest"
	log "Installed $(basename "$dest")"
}

log "Copying core files..."

copy_file "$INSTALL_SCRIPT_SRC" "$INSTALL_SCRIPT_DEST"
copy_file "$WRAPPER_SRC" "$TARGET_DIR/nvim-wrapper.sh"
copy_file "$MINIMAL_INIT_SRC" "$TARGET_DIR/minimal_init.lua"

# unraid_config.lua is optional but recommended
if [ -f "$UNRAID_CONFIG_SRC" ]; then
	cp "$UNRAID_CONFIG_SRC" "$TARGET_DIR/unraid_config.lua"
	chmod 644 "$TARGET_DIR/unraid_config.lua"
	log "Installed unraid_config.lua"
else
	log "Optional: unraid_config.lua not found — continuing."
fi

# ---------------------------------------------------------
# Insert into /boot/config/go if missing
# ---------------------------------------------------------
log "Ensuring custom_nvim_install.sh is in $GO_FILE..."

if grep -q "custom_nvim_install.sh" "$GO_FILE"; then
	log "Entry already exists in go file."
else
	printf "\n# Start Unraid Persistent Neovim\nbash /boot/config/custom_nvim_install.sh\n# End Unraid Persistent Neovim\n" >>"$GO_FILE"
	log "Added startup hook to $GO_FILE"
fi

# ---------------------------------------------------------
# Install User Scripts hook: run installer at Array Start
# ---------------------------------------------------------
log "Setting up User Scripts integration..."

mkdir -p "$(dirname "$AFTER_ARRAY_SCRIPT")"

if [ -f "$AFTER_ARRAY_SRC" ]; then
	cp "$AFTER_ARRAY_SRC" "$AFTER_ARRAY_SCRIPT"
	chmod 755 "$AFTER_ARRAY_SCRIPT"
	log "User Script installed: $AFTER_ARRAY_SCRIPT"
else
	log "run_custom_nvim_after_array_start.sh not found in repo; skipping User Script install."
fi

# Create User Scripts scheduling file (At Array Start)
cat >"$AFTER_ARRAY_CRON" <<'EOF'
custom
At Startup of Array
EOF

log "Schedule set to: At Array Start"

# ---------------------------------------------------------
# Final confirmation
# ---------------------------------------------------------
log "Installation complete!"
log "On next boot, Neovim will persist and auto-configure."
log "You can run it now via: nvim"

exit 0
