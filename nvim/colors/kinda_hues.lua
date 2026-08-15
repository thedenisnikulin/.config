-- ┌─────────────┐
-- │ kinda_hues  │
-- └─────────────┘
--
-- The 'kinda_nvim' palette you used in Helix, rebuilt with 'mini.hues'.
--
-- Files in 'colors/' define a color scheme, which makes this one a first class
-- citizen: `:colorscheme kinda_hues` works, it shows up in `<Leader>oc` next to
-- every other installed scheme, and previewing something else then coming back
-- restores it. That is the only reason this lives in its own file instead of
-- being a `setup()` call inside 'plugin/30_mini.lua'.
--
-- The two base colors are copied verbatim from the `[palette]` section of
-- 'helix/themes/kinda_nvim_patched.toml'. From them 'mini.hues' derives a full
-- palette - every Mini module, tree-sitter capture, LSP group and diagnostic
-- severity - so nothing in this config is left with fallback colors.
--
-- To tweak: `saturation` accepts 'low', 'lowmedium', 'medium', 'mediumhigh',
-- 'high'; `n_hues` (default 8) sets how many distinct hues are used; `accent`
-- tints the UI. See `:h MiniHues.config`.

require('mini.hues').setup({
  background = '#00120C', -- 'bg' from the Helix palette
  foreground = '#B6BFBC', -- 'fg' from the Helix palette
  accent = 'green', -- 'fg_primary' (#12B27D)
  saturation = 'medium',
})

vim.g.colors_name = 'kinda_hues'
