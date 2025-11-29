#!/bin/bash
# Wrapper so Neovim uses persistent XDG paths on Unraid.

export XDG_CONFIG_HOME="/mnt/cache/nvim/config"
export XDG_DATA_HOME="/mnt/cache/nvim/data"
export XDG_STATE_HOME="/mnt/cache/nvim/state"
export XDG_CACHE_HOME="/mnt/cache/nvim/cache"

exec /mnt/cache/nvim/bin/nvim.appimage "$@"
