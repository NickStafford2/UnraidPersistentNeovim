# Persistent Neovim + LazyVim for Unraid (7.x)

This repository contains a boot-safe script that installs **persistent Neovim** and **LazyVim** on Unraid.  
Because Unraid runs from RAM and wipes `/root` on every reboot, normal installations disappear.  
This script makes Neovim fully persistent and automatically updated.

---

## How It Works

### Persistent Storage

All Neovim files are stored on the cache drive:
Only **one directory is meant for user editing**: the `config` folder.

```
/mnt/cache/nvim/
├── config/   → NVIM config (LazyVim)
├── data/     → Plugins, treesitter, session data
├── cache/    → LSP cache, swap/undo files
└── bin/      → Persistent Neovim AppImage

```

---

## What the Script Does

- Creates all required persistent folders
- Auto-updates Neovim by checking the latest GitHub release
- Saves previous version as `nvim.appimage.old`
- Auto-installs LazyVim starter config (first run only)
- Recreates Neovim symlinks on every boot
- Writes a persistent log to: `/mnt/cache/nvim/logs/nvim_setup.log`

**Modify only:**  
`/mnt/cache/nvim/config/`

This contains your LazyVim configuration, keymaps, plugins, settings, etc.

## Everything else is generated and maintained automatically by Neovim and the script.

## Installation (Unraid)

1. Copy `custom_nvim_install.sh` to:

```

/boot/config/custom_nvim_install.sh

```

2. Make executable:

```

chmod +x /boot/config/custom_nvim_install.sh

```

3. Add this line to your `/boot/config/go` file:

```

/boot/config/custom_nvim_install.sh

```

5. Reboot Unraid.

---

## After Reboot

Run:

```

nvim

```

LazyVim should load, and updates will occur automatically on future boots.

---

## Logs

Review setup logs here:

```

tail -f /mnt/cache/nvim/logs/nvim_setup.log

```

## Git Limitations on Unraid

Unraid ships with a **minimal BusyBox version of `git`**, not the full Git client found on normal Linux systems.
Because of this:

- Cloning GitHub repositories
- Checking out branches
- Updating submodules
- Using HTTPS authentication
- Using SSH keys for Git operations

**does not work out of the box.**

This means any plugin or script that tries to automatically download configuration files or GitHub repos (including some LazyVim bootstrappers) will fail unless you install a full Git package manually through a container or third-party addon.

## For this reason, the Neovim setup script installs LazyVim **only once**, using the simplest possible `git clone` call, and does not rely on advanced Git features or GitHub integrations.

## License

MIT License. Free to modify. I accept pull requests.
