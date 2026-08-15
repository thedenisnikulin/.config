-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
  -- Define hook to update tree-sitter parsers after plugin is updated
  local ts_update = function() vim.cmd('TSUpdate') end
  Config.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')

  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  })

  -- Define languages which will have parsers installed and auto enabled
  -- After changing this, restart Neovim once to install necessary parsers. Wait
  -- for the installation to finish before opening a file for added language(s).
  local languages = {
    -- These are already pre-installed with Neovim.
    'lua',
    'vimdoc',
    'markdown',
    'markdown_inline',
    -- Languages you actually work in
    'go',
    'gomod',
    'gosum',
    'gowork',
    'python',
    'rust',
    -- Config and data formats, mirroring 'helix/languages.toml'
    'json',
    'sql',
    'toml',
    'yaml',
    -- Shells and Git
    'bash',
    'diff',
    'gitcommit',
    -- Add here more languages with which you want to use tree-sitter
    -- To see available languages:
    -- - Execute `:=require('nvim-treesitter').get_available()`
    -- - Visit 'SUPPORTED_LANGUAGES.md' file at
    --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev) vim.treesitter.start(ev.buf) end
  Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.lsp` to see potential issues.
now_if_args(function()
  add({ 'https://github.com/neovim/nvim-lspconfig' })

  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
  --
  -- Every server below is installed system-wide (brew / rustup / go / uv), not
  -- by Neovim. That is deliberate: they keep working in other editors and in
  -- CI, and this config stays a list of names instead of a package manager.
  -- If one goes missing, Neovim just doesn't attach it - nothing breaks.
  --
  -- The set mirrors 'helix/languages.toml', so the same language tooling
  -- follows you across both editors.
  vim.lsp.enable({
    'lua_ls', -- lua-language-server
    'gopls',
    'rust_analyzer', -- via `rustup component add rust-analyzer`
    'basedpyright', -- types
    'ruff', -- lint + format, Python
    'marksman', -- markdown
    'harper_ls', -- prose linting, configured in 'after/lsp/harper_ls.lua'
    'tombi', -- toml
  })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add({ 'https://github.com/stevearc/conform.nvim' })

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require('conform').setup({
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = 'fallback',
    },
    -- Map of filetype to formatters, ported from 'helix/languages.toml' plus
    -- the standard formatter for each language you work in.
    -- Each CLI tool here is installed system-wide; a missing one is skipped.
    -- Run with `<Leader>lf`. Only markdown formats on save - see
    -- 'after/ftplugin/markdown.lua'.
    formatters_by_ft = {
      lua = { 'stylua' },
      go = { 'goimports', 'gofumpt' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      rust = { 'rustfmt' },
      sql = { 'sleek' },
      json = { 'jq' },
    },
  })
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function() add({ 'https://github.com/rafamadriz/friendly-snippets' }) end)

-- Multiple cursors ===========================================================

-- The one Helix feature MINI has no module for. 'multicursor.nvim' is the
-- closest equivalent: real cursors that run normal Vim verbs in parallel.
--
-- Helix -> here:
-- - `C` / `A-C`  (cursor below/above)      -> `<C-Down>` / `<C-Up>`
-- - `C` on a word (next occurrence)        -> `<C-n>`, skip one with `<C-x>`
-- - `%` then `s` (all matches in file)     -> `<Leader>xa`
-- - `s` (matches inside selection)         -> `<Leader>xm`
-- - `A-s` (split selection into lines)     -> `<Leader>xs`
-- - `,` (collapse to one cursor)           -> `<Esc>`
--
-- `<Esc>` and the cursor-navigation keys live in a "keymap layer", which is
-- only active while several cursors exist - so `<Esc>` keeps its normal
-- meaning the rest of the time.
--
-- See also: `:h multicursor`
later(function()
  add({ 'https://github.com/jake-stewart/multicursor.nvim' })

  local mc = require('multicursor-nvim')
  mc.setup()

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end
  local nx = { 'n', 'x' }

  map(nx, '<C-Down>', function() mc.lineAddCursor(1) end, 'Add cursor below')
  map(nx, '<C-Up>', function() mc.lineAddCursor(-1) end, 'Add cursor above')
  map(nx, '<C-n>', function() mc.matchAddCursor(1) end, 'Add cursor at next match')
  map(nx, '<C-x>', function() mc.matchSkipCursor(1) end, 'Skip to next match')

  map(nx, '<Leader>xa', mc.matchAllAddCursors, 'All matches in buffer')
  map(nx, '<Leader>xm', mc.matchCursors, 'Match inside selection')
  map(nx, '<Leader>xs', mc.splitCursors, 'Split selection into cursors')

  -- Only in effect while there is more than one cursor
  mc.addKeymapLayer(function(layer)
    layer(nx, '<Left>', mc.prevCursor, 'Previous cursor')
    layer(nx, '<Right>', mc.nextCursor, 'Next cursor')
    layer('n', '<Esc>', function()
      if mc.cursorsEnabled() then
        mc.clearCursors()
      else
        mc.enableCursors()
      end
    end, 'Collapse to one cursor')
  end)
end)

-- Sub word motions ===========================================================

-- Your `<A-w>` / `<A-e>` / `<A-b>` bindings from Helix: move by parts of
-- camelCase and snake_case words instead of whole words.
--
-- This is the smallest plugin in the config and exists purely for these three
-- keys. If they stop being worth a dependency, delete this whole block - plain
-- `w` / `e` / `b` keep working, they were never remapped.
--
-- NOTE: mapped as `<Cmd>` strings rather than Lua functions, which is what
-- makes dot-repeat work. See the plugin's readme.
later(function()
  add({ 'https://github.com/chrisgrieser/nvim-spider' })

  local modes = { 'n', 'o', 'x' }
  local motion = function(key) return "<Cmd>lua require('spider').motion('" .. key .. "')<CR>" end
  vim.keymap.set(modes, '<A-w>', motion('w'), { desc = 'Sub word forward' })
  vim.keymap.set(modes, '<A-e>', motion('e'), { desc = 'Sub word end' })
  vim.keymap.set(modes, '<A-b>', motion('b'), { desc = 'Sub word back' })
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
-- now_if_args(function()
--   add({ 'https://github.com/mason-org/mason.nvim' })
--   require('mason').setup()
-- end)

-- Color schemes ==============================================================

-- 'strash/kinda_nvim' is the Neovim original that your Helix theme
-- ('kinda_nvim_patched') was ported from. The active color scheme is a
-- 'mini.hues' rebuild of the same palette - see 'plugin/30_mini.lua' for why.
--
-- Uncomment to install it and compare the two. Once installed, `<Leader>oc`
-- previews both live; whichever `colorscheme` call runs last in config wins on
-- the next startup.
--
-- Heads up: it defines no `Mini*` highlight groups, so Mini windows (picker,
-- explorer, statusline, clue) fall back to generic colors under it.
-- Config.now(function()
--   add({ 'https://github.com/strash/kinda_nvim' })
--   vim.cmd('colorscheme kinda_nvim')
-- end)

-- Other well maintained color schemes outside of 'mini.nvim' that have full
-- support of its highlight groups.
-- Config.now(function()
--  -- Install only those that you need
--  add({
--    'https://github.com/sainnhe/everforest',
--    'https://github.com/Shatur/neovim-ayu',
--    'https://github.com/ellisonleao/gruvbox.nvim',
--  })
--
--   -- Enable only one
--   vim.cmd('color everforest')
-- end)
