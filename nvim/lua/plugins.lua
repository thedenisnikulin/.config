-- Plugin setup. `vim.pack.add` lives in init.lua and runs before this file.
-- Nothing here is lazy-loaded on purpose: 8 plugins start fast enough that
-- lazy-loading would cost more config than it saves.

-- ---------------------------------------------------------------- mini.nvim

require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons() -- render-markdown expects the old module name

require('mini.pick').setup()
require('mini.extra').setup()
require('mini.files').setup()
require('mini.tabline').setup() -- helix `bufferline = "always"`
require('mini.surround').setup() -- helix `ms` / `md` / `mr` -> `sa` / `sd` / `sr`
-- mini.ai's `next`/`last` variants default to `an`/`in`/`al`/`il`, which
-- shadow Neovim 0.12's built-in treesitter selection (:h v_an) -- the thing
-- <A-o>/<A-i> below rely on. Upstream documents this collision and suggests
-- exactly this remap (:h MiniAi-default-an-in).
require('mini.ai').setup({
  mappings = {
    around_next = 'aN',
    inside_next = 'iN',
    around_last = 'aL',
    inside_last = 'iL',
  },
})
require('mini.pairs').setup()
require('mini.splitjoin').setup() -- `gS`
require('mini.diff').setup() -- sign column git diff
require('mini.git').setup() -- `:Git`, blame at cursor
require('mini.bufremove').setup() -- close buffers without wrecking the layout

-- Statusline, carrying over the kaomoji mode names from helix config.toml.
-- mini's own mode table is private, so this substitutes the label while
-- keeping mini's highlight group.
local kaomoji = {
  n = 'N („• ᴗ •„)',
  i = 'I ｡ﾟ･ (>﹏<) ･ﾟ｡',
  v = 'S (｡•̀ᴗ-)✧☆*:・ﾟ',
  V = 'S (｡•̀ᴗ-)✧☆*:・ﾟ',
  ['\22'] = 'S (｡•̀ᴗ-)✧☆*:・ﾟ', -- <C-v>
  R = 'R (╯°□°)╯',
  c = 'C (・_・)ノ',
  t = 'T >_',
}

require('mini.statusline').setup({
  content = {
    active = function()
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local label = kaomoji[vim.fn.mode()] or mode
      local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local filename = MiniStatusline.section_filename({ trunc_width = 140 })
      local git = MiniStatusline.section_git({ trunc_width = 75 })
      local diff = MiniStatusline.section_diff({ trunc_width = 75 })
      local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })

      return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { label } },
        { hl = 'MiniStatuslineDevinfo', strings = { git, diff } },
        '%<%=',
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%=',
        { hl = 'MiniStatuslineDevinfo', strings = { diagnostics } },
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
        { hl = mode_hl, strings = { '%l:%v', '%P' } },
      })
    end,
  },
})

-- which-key equivalent. Triggers must be declared explicitly (unlike
-- which-key, which auto-detects them).
local clue = require('mini.clue')
clue.setup({
  triggers = {
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },
    { mode = 'n', keys = 's' },
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-x>' },
  },
  clues = {
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.square_brackets(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
    { mode = 'n', keys = '<Leader>f', desc = '+find' },
    { mode = 'n', keys = '<Leader>g', desc = '+git' },
    { mode = 'n', keys = '<Leader>n', desc = '+notes' },
    { mode = 'n', keys = '<Leader>l', desc = '+lsp' },
  },
  window = { config = { width = 'auto' } },
})

-- --------------------------------------------------------------- treesitter

local ts = require('nvim-treesitter')
ts.setup()

local wanted = {
  'bash', 'css', 'diff', 'git_config', 'gitcommit', 'go', 'gomod', 'gosum',
  'gotmpl', 'html', 'json', 'lua', 'luadoc', 'markdown',
  'markdown_inline', 'python', 'query', 'regex', 'rust', 'sql', 'toml',
  'vim', 'vimdoc', 'yaml',
}
local have = {}
for _, p in ipairs(ts.get_installed()) do
  have[p] = true
end
local missing = vim.tbl_filter(function(p)
  return not have[p]
end, wanted)
if #missing > 0 then
  ts.install(missing)
end

-- Highlighting is Neovim's; nvim-treesitter only supplies the queries.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter.start', {}),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if lang and pcall(vim.treesitter.start, ev.buf, lang) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- -------------------------------------------------------------- multicursor

local mc = require('multicursor-nvim')
mc.setup()

-- Helix uses bare `C` / `A-C`, but `C` is change-to-end-of-line in vim and
-- shadowing it would be a bad trade. The helix letter is kept under Alt.
vim.keymap.set({ 'n', 'x' }, '<A-c>', function() mc.lineAddCursor(1) end, { desc = 'Cursor below' })
vim.keymap.set({ 'n', 'x' }, '<A-C>', function() mc.lineAddCursor(-1) end, { desc = 'Cursor above' })
vim.keymap.set({ 'n', 'x' }, '<C-n>', function() mc.matchAddCursor(1) end, { desc = 'Cursor at next match' })
vim.keymap.set({ 'n', 'x' }, '<Leader>N', function() mc.matchAddCursor(-1) end, { desc = 'Cursor at prev match' })
vim.keymap.set({ 'n', 'x' }, 'ga', mc.addCursorOperator, { desc = 'Add cursors over motion' })
vim.keymap.set('x', 'S', mc.splitCursors, { desc = 'Split selection by regex' }) -- helix A-s
vim.keymap.set('x', 'M', mc.matchCursors, { desc = 'Match within selection' }) -- helix s
vim.keymap.set({ 'n', 'x' }, '<C-q>', mc.toggleCursor, { desc = 'Toggle cursor' })

-- These only bind while multiple cursors exist, so they can overlap.
mc.addKeymapLayer(function(layer)
  layer({ 'n', 'x' }, '<Left>', mc.prevCursor)
  layer({ 'n', 'x' }, '<Right>', mc.nextCursor)
  layer('n', '<Esc>', function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)

-- ------------------------------------------------------------------ conform

require('conform').setup({
  formatters_by_ft = {
    sql = { 'sleek' }, -- from languages.toml
    json = { 'jq' }, -- from languages.toml
    jsonc = { 'jq' },
    go = { 'goimports', 'gofumpt' },
    python = { 'ruff_format' },
    lua = { 'stylua' },
    rust = { 'rustfmt' },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = 1000 },
})

-- ---------------------------------------------------------------- rendering

require('render-markdown').setup({
  completions = { lsp = { enabled = true } },
})

-- ------------------------------------------------------------------- themes

-- Both themes key off `background`, and per `:h 'background'` changing it
-- reloads the colorscheme, so the sync below sets exactly one option.

-- Upstream bug workaround: kinda_nvim ships its helpers in `<root>/util/`
-- rather than `<root>/lua/util/`, and Neovim only puts `<plugin>/lua/` on
-- package.path -- so its `require('util.color')` cannot resolve. Add the
-- plugin root explicitly. Drop this if upstream ever moves the directory.
local kinda = vim.api.nvim_get_runtime_file('colors/kinda_nvim.lua', false)[1]
if kinda then
  local root = vim.fs.dirname(vim.fs.dirname(kinda))
  package.path = root .. '/?.lua;' .. package.path
end

vim.cmd.colorscheme('kinda_nvim')

local function sync_background()
  vim.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' }, { text = true }, function(out)
    local want = (out.stdout or ''):match('Dark') and 'dark' or 'light'
    vim.schedule(function()
      if vim.o.background ~= want then
        vim.o.background = want
      end
    end)
  end)
end

-- Nvim only detects the terminal background at startup, so re-check on focus.
sync_background()
vim.api.nvim_create_autocmd({ 'FocusGained', 'VimResume' }, {
  group = vim.api.nvim_create_augroup('theme.sync', {}),
  callback = sync_background,
})
