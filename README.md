# Unraid Persistent Neovim

A fully persistent, AppImage-based Neovim setup for Unraid.  
Includes optional LazyVim support, sensible defaults, and a clean wrapper that stores all configuration on your cache drive instead of RAM.

This project solves the core Unraid constraints:

- Unraid runs from RAM → all config must be on /mnt/cache
- AppImages work reliably → perfect for Neovim
- BusyBox git cannot clone most GitHub repos → LazyVim must fall back gracefully

This system boots Neovim **every time** with consistent configuration, treesitter-safe settings, and optional LazyVim plugin overrides.

---

## Features

- Fully persistent Neovim installation
- AppImage stored on cache drive
- Wrapper script exposes Neovim as `nvim`
- Built-in fallback minimal config
- LazyVim auto-bootstrap (if internet + non-BusyBox git)
- Safe fallback for BusyBox git environments
- Custom plugin overrides for Unraid
- Fully automated installation (via `install.sh`)

---

# Installation

### 1. Copy or clone the repo onto your Unraid system

Option A — Clone repo (git should be installed)

```bash
cd /boot/config
git clone https://github.com/NickStafford2/UnraidPersistentNeovim.git
cd UnraidPersistentNeovim
bash install.sh
```

Option B — Download ZIP

```bash
cd /boot/config
wget https://github.com/NickStafford2/UnraidPersistentNeovim/archive/refs/heads/main.zip -O upnvim.zip
unzip upnvim.zip
cd UnraidPersistentNeovim-main
bash install.sh

```

### 2. Run install.sh

```

bash install.sh

```

This performs all of the following:

- Creates `/boot/config/nvim/`
- Copies:
  - `custom_nvim_install.sh`
  - `nvim-wrapper.sh`
  - `minimal_init.lua`
  - (optional) `unraid_config.lua`
- Configures `/boot/config/go`
- Sets correct permissions
- Makes installation fully persistent
- Adds a User Script that reruns custom_nvim_install.sh after the array starts to finish setup on /mnt/cache.

### 3. Reboot (optional)

After reboot, your Neovim will be available at:

```

nvim

```

You can also run without rebooting since the installer places the wrapper immediately.

---

# File Layout (after installation)

```

/boot/config/custom_nvim_install.sh     # Main persistent Neovim manager
/boot/config/nvim/
minimal_init.lua                        # Fallback minimal config
nvim-wrapper.sh                         # Wrapper for AppImage + XDG paths
unraid_config.lua                       # Optional LazyVim override config
/mnt/cache/nvim/                        # AppImage + persistent XDG dirs
/usr/local/bin/nvim → wrapper           # Symlink installed by main script

```

---

# How It Works

### On boot

`/boot/config/go` runs:

```

bash /boot/config/custom_nvim_install.sh

```

That script:

1. Ensures `/mnt/cache/nvim` exists
2. Downloads the newest Neovim AppImage (if internet is available)
3. Creates persistent XDG directories
4. Installs a wrapper at `/usr/local/bin/nvim`
5. Attempts LazyVim bootstrap
6. Falls back to `minimal_init.lua` if GitHub clone fails

This makes the system both **smart when online** and **stable when offline**.
A User Script runs the installer again at Array Start to migrate Neovim from USB → /mnt/cache.

---

# LazyVim on Unraid

Because Unraid uses BusyBox git, HTTPS cloning often fails.

This repo includes:

```

unraid_config.lua

```

Which:

- Disables Tree-sitter
- Disables Mason
- Disables DAP
- Removes formatter by filetype errors

LazyVim becomes lightweight and fully compatible with Unraid.

---

# Updating

Just re-run:

```

cd /boot/config/UnraidPersistentNeovim
bash install.sh

```

Updates:

- wrapper
- minimal config
- fallback configs
- installation script
- go file entry (idempotent)

---

# Uninstallation

To remove automatic persistence:

1. Edit `/boot/config/go` and delete:

```

bash /boot/config/custom_nvim_install.sh

```

2. Remove:

```

/boot/config/custom_nvim_install.sh
/boot/config/nvim/
/mnt/cache/nvim/
/usr/local/bin/nvim

```
