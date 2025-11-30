#!/bin/bash
# run_custom_nvim_after_array_start.sh
# Run persistent Neovim installer after cache is mounted
# This should be run by the Unraid User Scripts plugin on:
#    "At Array Start"

set -euo pipefail

# Path to your real script
INSTALLER="/boot/config/custom_nvim_install.sh"

# Basic safety checks
if [ ! -f "$INSTALLER" ]; then
	echo "[nvim-after-array] ERROR: $INSTALLER not found."
	exit 1
fi

# Ensure cache is actually mounted (not just a directory)
# Optional: wait up to 20 seconds for cache mount
for _ in {1..60}; do
	if grep -q " /mnt/cache " /proc/mounts; then
		break
	fi
	sleep 1
done

if ! grep -q " /mnt/cache " /proc/mounts; then
	echo "[nvim-after-array] Cache still not mounted. Exiting."
	exit 0
fi

echo "[nvim-after-array] Running custom Neovim installer on cache..."
bash "$INSTALLER"

echo "[nvim-after-array] Complete."
exit 0
