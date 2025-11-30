# Unraid Persistent Neovim

A fully persistent Neovim + LazyVim setup designed specifically for Unraid.  
Provides fast LazyVim on cache, plus a USB-based fallback so `nvim` always works — even before the array is mounted.

This system installs Neovim as an AppImage, maintains persistent configuration, and automatically switches between USB and cache depending on array state.

---

## Features

- Persistent Neovim AppImage
- USB fallback mode for early-boot or array-offline use
- Cache-backed LazyVim when array is online
- Automatic USB → cache migration at array start
- Wrapper auto-selects correct runtime root
- Optional Unraid-specific LazyVim plugin overrides
- Minimal config fallback if git/internet unavailable
- BusyBox-friendly, idempotent installer
- One-command installation

---

# Installation (One Command)

## Clone

```bash
cd /boot/config
git clone https://github.com/NickStafford2/UnraidPersistentNeovim.git
cd UnraidPersistentNeovim
bash install.sh
```

## Or download ZIP

```bash
cd /boot/config
wget https://github.com/NickStafford2/UnraidPersistentNeovim/archive/refs/heads/main.zip -O upnvim.zip
unzip upnvim.zip
cd UnraidPersistentNeovim-main
bash install.sh
```

### After install

The installer:

- Installs all files to `/boot/config/nvim`
- Ensures Neovim runs at boot via `/boot/config/go`
- Installs an Array Start hook via User Scripts
- **Runs `custom_nvim_install.sh` immediately**

Neovim is ready right away:

```bash
nvim
```

---

# Updating

```bash
cd /boot/config/UnraidPersistentNeovim
bash install.sh
```

This updates:

- wrapper
- install scripts
- minimal config
- Unraid LazyVim overrides
- boot hooks

---

# Uninstallation

```bash
bash uninstall.sh
```

Removes:

- `/boot/config/nvim`
- `/boot/config/custom_nvim_install.sh`
- `/usr/local/bin/nvim`
- `/mnt/cache/nvim`
- User Script + go-file entry

---

### Terminal Color Note (Optional)

If vi or Neovim does not look/work properly, or if Neovim looks monochrome or your SSH session shows limited colors, your terminal may not advertise 256-color support.
You can fix this by adding the following line to your shell profile:

```bash
echo 'export TERM=xterm-256color' >> ~/.bash_profile
```

Modern terminals like WezTerm support full 256-color and truecolor, but when connecting over SSH they do not always forward their capabilities. Setting TERM=xterm-256color ensures Neovim receives the correct color information.
This setting is **not part of the installer** and is only needed on some SSH clients (e.g., PuTTY, old macOS Terminal).
