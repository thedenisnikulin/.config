-- ┌──────────────────────────────┐
-- │ harper-ls (prose / spelling) │
-- └──────────────────────────────┘
--
-- Files in 'after/lsp/' are merged on top of the config that 'nvim-lspconfig'
-- provides for a server of the same name. Only the differences go here.
-- See `:h vim.lsp.config()` and `:h lsp-config`.
--
-- This is a direct port of the `[language-server.harper-ls...]` sections of
-- 'helix/languages.toml', so prose linting behaves identically in both editors.

return {
  -- 'nvim-lspconfig' attaches harper-ls to ~30 filetypes by default, including
  -- Go, Rust, Python and Lua, where it lints prose inside comments. In Helix it
  -- was a markdown-only language server, so keep it to prose here too.
  -- (A list like this replaces the default outright, it is not appended to.)
  filetypes = { 'markdown', 'gitcommit', 'text' },

  settings = {
    ['harper-ls'] = {
      dialect = 'American',

      -- Personal notes are drafts - don't lint them
      excludePatterns = {
        '/Users/denisnikulin/todo/*',
        '/Users/denisnikulin/Vault/TODO/*',
      },

      linters = {
        -- Headings and titles are written however they're written
        UseTitleCase = false,
      },

      markdown = {
        IgnoreLinkTitle = false,
      },
    },
  },
}
