-- unraid_config.lua
--
-- Add this file to your LazyVim user configuration so Neovim runs correctly on Unraid.
--
-- In LazyVim, the correct path for user plugins is:
--   ~/.config/nvim/lua/plugins/unraid_config.lua
--
-- NOTE:
-- Unraid ships with a very minimal Linux environment.
-- Several LazyVim components require tools that are NOT available by default:
--   • Tree-sitter requires a C compiler (missing in Unraid)
--   • DAP (Debug Adapter Protocol) requires various linters/debuggers
--     that are not present, and usually installed through Mason (also not available)
--
-- This file disables these components so Neovim runs smoothly without errors.

return {

	---------------------------------------------------------------------------
	-- Disable DAP (Debug Adapter Protocol)
	---------------------------------------------------------------------------
	-- DAP requires external debugger binaries (Python, LLDB, Node, etc.)
	-- which do not exist on Unraid by default unless manually installed.
	-- Disabling prevents startup warnings and broken keymaps.
	{
		"mfussenegger/nvim-dap",
		enabled = false,
	},
	{
		"jay-babu/mason-nvim-dap.nvim",
		enabled = false,
	},

	---------------------------------------------------------------------------
	-- Disable Tree-sitter
	---------------------------------------------------------------------------
	-- Tree-sitter requires a compiler toolchain and build system
	-- (GCC or Clang, Make, etc.), which Unraid does not include.
	--
	-- If you *later* install compilers manually inside a container
	-- or with NerdPack / devpack plugins, you can remove these lines.
	{
		"nvim-treesitter/nvim-treesitter",
		enabled = false,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		enabled = false,
	},

	---------------------------------------------------------------------------
	-- OPTIONAL:
	-- Improve startup performance in low-toolchain environments.
	-- LazyVim includes many plugins that rely on external tools.
	-- These cannot run on base Unraid unless you install dependencies manually.
	---------------------------------------------------------------------------

	-- Recommended: disable Mason entirely if you're not using LSP tools.
	{
		"williamboman/mason.nvim",
		enabled = false,
	},

	-- Recommended: disable auto-formatting if dependent binaries are missing.
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {}, -- prevent “missing formatter” errors
		},
	},
}

-- NOTE: Unraid includes only a minimal BusyBox git, so advanced git features
-- (auth, branches, submodules, SSH, etc.) do not work. Avoid plugins that
-- auto-clone repos or require full git support.
