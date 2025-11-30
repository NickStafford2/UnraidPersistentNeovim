# Unraid Persistent Neovim – Architecture & Internals

This document explains how the system works internally:
USB fallback, cache mode, wrapper behavior, boot sequence, and LazyVim integration.

If you're only installing the tool, see `README.md`.

---

# 1. Overview

Unraid runs entirely from RAM and mounts the array later in the boot process.
This creates several constraints:

- Neovim must work **before array mount**
- LazyVim plugin state must be stored **somewhere persistent**
- USB flash drives cannot handle heavy write workloads
- BusyBox git may not clone LazyVim reliably

This system solves all these problems via **two-tier persistence**:

```

USB → fallback config (always available)
Cache → full LazyVim + plugins (fast, safe for writes)

```

The wrapper chooses the correct runtime automatically.

---

# 2. USB vs Cache Architecture

## USB Root (always available)

```

/boot/config/nvim

```

Contains:

- wrapper.sh
- minimal_init.lua
- paths.env
- unraid_config.lua
- fallback LazyVim config
- logs

Used when:

- Array is offline
- Early boot
- Maintenance mode
- Cache is missing, degraded, or unmounted

## Cache Root (array only)

```

/mnt/cache/nvim

```

Contains:

- nvim.appimage
- XDG dirs:
  - config/
  - data/
  - state/
  - cache/
- full LazyVim installation

This is where:

- plugins live
- LSP servers install
- treesitter (if enabled) compiles
- Lazy.nvim tracks state
- logs are written

The cache drive is SSD/NVMe → perfect for plugin write activity.

---

# 3. Wrapper Logic

The wrapper installed at:

```

/usr/local/bin/nvim

```

runs:

```bash
if cache is mounted:
    ROOT=$CACHE_ROOT
else:
    ROOT=$USB_ROOT
```

then sets:

```
XDG_CONFIG_HOME=$ROOT/config
XDG_DATA_HOME=$ROOT/data
XDG_STATE_HOME=$ROOT/state
XDG_CACHE_HOME=$ROOT/cache
```

and executes:

```
$ROOT/bin/nvim.appimage "$@"
```

This guarantees:

- Same `nvim` command everywhere
- Correct configuration source
- Fallback is automatic and invisible to the user

---

# 4. Boot Sequence

## A. During early boot

Unraid runs `/boot/config/go` → which calls:

```
bash /boot/config/custom_nvim_install.sh
```

Cache is not mounted yet → Neovim runs from USB.

Installer ensures:

- USB structure exists
- USB fallback config is valid
- Wrapper is installed
- AppImage is present (download or fallback)

## B. After array start

The User Script runs the installer again.

This time cache **is** mounted:

- If `/mnt/cache/nvim` does not exist, USB → cache migration happens
- LazyVim bootstraps fully into cache
- USB fallback config is synced for consistency

You now have full LazyVim running off SSD.

---

# 5. LazyVim Behavior on Unraid

BusyBox git may fail to clone LazyVim starter.
The installer handles this:

## If git + internet available:

- Clone LazyVim starter into `config/`
- Install Unraid overrides

## If cloning fails:

- Use `minimal_init.lua`
- Plugins remain disabled, but Neovim works

## Unraid-specific overrides disable:

- tree-sitter
- Mason
- DAP
- Some formatters

This prevents errors due to missing compilers on Unraid.

---

# 6. persistent directories

Cache stores all Neovim XDG paths:

```
/mnt/cache/nvim/config
/mnt/cache/nvim/data
/mnt/cache/nvim/state
/mnt/cache/nvim/cache
```

These hold:

- Installed plugins
- LSP servers
- treesitter (if ever enabled)
- lua bytecode
- undo history
- logs
- Lazy.nvim state
- plugin metadata

USB stores only the lightweight fallback.

---

# 7. Update Flow

Running:

```
bash install.sh
```

will:

- Replace the installer
- Replace the wrapper
- Replace fallback minimal config
- Replace Unraid overrides
- Update `go` and User Script hooks
- Re-run the installer immediately

This updates both USB fallback and cache environments.

---

# 8. Uninstall Flow

`uninstall.sh` removes:

- `/boot/config/custom_nvim_install.sh`
- `/boot/config/nvim/`
- `/usr/local/bin/nvim`
- `/mnt/cache/nvim/`
- User Script directory
- go-file entry

System returns to stock Unraid with no Neovim overrides.

---

# 9. Terminal Color Behavior

Some SSH terminals (including WezTerm) do not forward truecolor capability.
Set:

```bash
export TERM=xterm-256color
```

in `~/.bash_profile` to fix Neovim color issues.

---

# 10. Notes for Developers

- All scripts are BusyBox-safe
- Wrapper must remain at `/usr/local/bin/nvim`
- Only `/boot/config/nvim` and `/mnt/cache/nvim` are used
- LazyVim bootstrap is intentionally conservative
- All data writes occur on cache, not USB
