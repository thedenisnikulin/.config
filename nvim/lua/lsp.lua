-- Language servers -- the helix languages.toml equivalent.
--
-- nvim-lspconfig is used purely as a bag of `lsp/<name>.lua` definitions;
-- `vim.lsp.enable()` picks them up off the runtimepath. Overrides below go
-- through `vim.lsp.config()`, which outranks those files (:h lsp-config-merge).
--
-- Keymaps are almost all 0.12 defaults and are deliberately not redefined:
--   K hover   grn rename   gra code action   grr references
--   gri impl  grt type def grx codelens      gO symbols   <C-s> signature

-- harper-ls is a prose checker. lspconfig attaches it to go/rust/python/lua/c
-- and friends, which would put grammar diagnostics all over real code --
-- helix only had it on markdown, so restrict it back down.
vim.lsp.config('harper_ls', {
  filetypes = { 'markdown', 'gitcommit', 'text' },
  settings = {
    ['harper-ls'] = {
      dialect = 'American',
      excludePatterns = {
        vim.fn.expand('~/todo') .. '/*',
        vim.fn.expand('~/Vault/TODO') .. '/*',
      },
      linters = { UseTitleCase = false },
      markdown = { IgnoreLinkTitle = false },
    },
  },
})

-- basedpyright handles types, ruff handles lint/format. Turn off the overlap
-- so they don't both report the same thing.
vim.lsp.config('basedpyright', {
  settings = {
    basedpyright = {
      analysis = { diagnosticMode = 'openFilesOnly', typeCheckingMode = 'standard' },
    },
  },
})

vim.lsp.config('ruff', {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false -- basedpyright owns hover
  end,
})

-- The Mini* globals are set by mini.nvim modules; without this lua_ls flags
-- every use of them in this config as undefined.
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim', 'MiniPick', 'MiniExtra', 'MiniFiles', 'MiniGit', 'MiniDiff', 'MiniBufremove', 'MiniStatusline', 'MiniIcons' } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.enable({
  'gopls',
  'rust_analyzer',
  'basedpyright',
  'ruff',
  'marksman',
  'harper_ls',
  'lua_ls',
  'tombi', -- toml, per languages.toml
})
