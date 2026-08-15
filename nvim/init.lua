-- Neovim config, ported from a long-running helix setup.
-- Three files on purpose:
--   init.lua        <- helix config.toml   (options, keymaps)
--   lua/plugins.lua <- (no helix analogue) (vim.pack + plugin setup)
--   lua/lsp.lua     <- helix languages.toml (servers, diagnostics)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ====================================================================== pack

vim.pack.add({
  { src = 'https://github.com/echasnovski/mini.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/jake-stewart/multicursor.nvim', version = '1.0' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/strash/kinda_nvim' },
  { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
})

-- =================================================== options (config.toml)

local o = vim.o

o.number = true -- line-number = "relative"
o.relativenumber = true
o.numberwidth = 4
o.cursorline = true -- cursorline = true
o.signcolumn = 'yes'
o.scrolloff = 4

o.colorcolumn = '120' -- rulers = [120]
o.textwidth = 120 -- text-width = 120

o.winborder = 'rounded' -- popup-border = "all"
o.shell = 'bash' -- shell = ["bash", "-c"]

-- cursor-shape: normal/select underline, insert block
o.guicursor = table.concat({
  'n-v-sm:hor20-blinkwait700-blinkon500-blinkoff500',
  'i-ci-ve:block',
  'r-cr-o:hor20',
}, ',')

-- soft-wrap. NOTE: helix's `wrap-at-text-width` has no vim equivalent --
-- vim wraps at window width, so `linebreak` + the colorcolumn marker is the
-- closest honest approximation.
o.wrap = true
o.linebreak = true
o.breakindent = true
o.showbreak = '↳ '

-- indent-guides.render = true, without a plugin. The `leadmultispace` string
-- repeats across leading whitespace, so it has to match shiftwidth per buffer
-- (see the autocmd below).
o.list = true
vim.opt.listchars = { tab = '│ ', trail = '·', nbsp = '␣', leadmultispace = '│   ' }

-- Indentation. 4 covers rust/python/go-display; the 2-space family is set
-- per-filetype below. Projects with an .editorconfig override both -- nvim
-- reads those natively (:h editorconfig).
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4

o.ignorecase = true
o.smartcase = true
o.undofile = true
o.splitright = true
o.splitbelow = true
o.timeoutlen = 500 -- how long until mini.clue pops up
o.updatetime = 250
o.mouse = 'a'
o.confirm = true

-- ================================================= completion (built-in)

-- nvim 0.12 does this natively: `o` is the LSP omnifunc source, `.`/`w` are
-- buffer sources, `kspell` kicks in wherever 'spell' is on. The `^N` suffixes
-- cap each source. No completion plugin involved.
o.autocomplete = true
o.autocompletedelay = 60
o.complete = 'o^8,.^5,w^3,kspell'
o.completeopt = 'menuone,popup,fuzzy,nearest'

-- ===================================================== diagnostics display

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  virtual_lines = { current_line = true }, -- inline-diagnostics.cursor-line
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '●',
      [vim.diagnostic.severity.WARN] = '●',
      [vim.diagnostic.severity.INFO] = '●',
      [vim.diagnostic.severity.HINT] = '●',
    },
  },
})

-- ================================================================= keymaps

local map = vim.keymap.set

-- --- pickers ------------------------------------------------------------
map('n', '<Leader>f', function() MiniPick.builtin.files() end, { desc = 'Files (cwd)' })
map('n', '<Leader>F', function()
  local root = vim.fs.root(0, '.git') or vim.uv.cwd()
  MiniPick.builtin.files(nil, { source = { cwd = root } })
end, { desc = 'Files (git root)' })
map('n', '<Leader>b', function() MiniPick.builtin.buffers() end, { desc = 'Buffers' })
map('n', '<Leader>/', function() MiniPick.builtin.grep_live() end, { desc = 'Grep' })
map('n', '<Leader>h', function() MiniPick.builtin.help() end, { desc = 'Help' })
map('n', '<Leader>d', function() MiniExtra.pickers.diagnostic() end, { desc = 'Diagnostics' })
map('n', '<Leader>s', function() MiniExtra.pickers.lsp({ scope = 'document_symbol' }) end, { desc = 'Symbols' })
map('n', '<Leader>t', function() MiniExtra.pickers.colorschemes() end, { desc = 'Themes' })
map('n', '<Leader>e', function() MiniFiles.open(vim.api.nvim_buf_get_name(0)) end, { desc = 'Explorer' })

-- --- notes (~/Vault) ----------------------------------------------------
local vault = vim.fn.expand('~/Vault')
map('n', '<Leader>nf', function() MiniPick.builtin.files(nil, { source = { cwd = vault } }) end, { desc = 'Find note' })
map('n', '<Leader>ng', function() MiniPick.builtin.grep_live(nil, { source = { cwd = vault } }) end, { desc = 'Grep notes' })

-- --- buffers ------------------------------------------------------------
map('n', '<Leader>c', function() MiniBufremove.delete() end, { desc = 'Close buffer' })
map('n', '<Leader>C', function() MiniBufremove.delete(0, true) end, { desc = 'Close buffer!' })
map('n', '<A-[>', '<Cmd>bprevious<CR>', { desc = 'Prev buffer' })
map('n', '<A-]>', '<Cmd>bnext<CR>', { desc = 'Next buffer' })

-- --- scrolling (helix C-e / C-y move 3 lines) ---------------------------
map('n', '<C-e>', '3<C-e>')
map('n', '<C-y>', '3<C-y>')

-- --- toggles ------------------------------------------------------------
map('n', '<Leader>z', function()
  vim.wo.numberwidth = vim.wo.numberwidth > 6 and 4 or 24
end, { desc = 'Toggle gutter width' })
map('n', '<Leader>m', function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = 'Toggle soft-wrap' })

-- --- treesitter selection (helix A-o / A-i / A-n / A-p) -----------------
-- These are 0.12 built-ins (:h v_an), not a plugin.
map('n', '<A-o>', 'van', { remap = true, desc = 'Select node' })
map('x', '<A-o>', 'an', { remap = true, desc = 'Expand selection' })
map('x', '<A-i>', 'in', { remap = true, desc = 'Shrink selection' })
map('x', '<A-n>', ']N', { remap = true, desc = 'Next sibling node' })
map('x', '<A-p>', '[N', { remap = true, desc = 'Prev sibling node' })

-- --- subword motions (helix A-w / A-e / A-b) ----------------------------
-- Matches a subword start at: word start, after `_`, or a camelCase hump.
local SUBWORD_START = [[\v<\w|_@<=\w|\l@<=\u|\u@<=\u\l]]
local SUBWORD_END = [[\v\l\u@=|\w_@=|\w>]]

local function search(pat, back)
  return function()
    vim.fn.search(pat, back and 'bW' or 'W')
  end
end

map({ 'n', 'x' }, '<A-w>', search(SUBWORD_START), { desc = 'Next subword' })
map({ 'n', 'x' }, '<A-b>', search(SUBWORD_START, true), { desc = 'Prev subword' })
map({ 'n', 'x' }, '<A-e>', search(SUBWORD_END), { desc = 'End of subword' })

-- --- shell integration --------------------------------------------------
-- helix `|`: pipe the selection through a command and replace it. In visual
-- mode `:` prefills `'<,'>`, so this lands on `:'<,'>!` with the cursor ready.
map('x', '|', ':!', { desc = 'Pipe selection through command' })

-- helix `!`: read a command's output in at the cursor.
map('n', '<Leader>!', ':r !', { desc = 'Insert command output' })

-- helix `A-|` / `:sh`: run and discard. `%f` -> file path, `%l` -> cursor line,
-- mirroring helix's %{buffer_name} / %{cursor_line}.
map('n', '<Leader>|', function()
  vim.ui.input({ prompt = 'run: ' }, function(cmd)
    if not cmd or cmd == '' then
      return
    end
    cmd = cmd:gsub('%%f', vim.fn.expand('%:p')):gsub('%%l', tostring(vim.fn.line('.')))
    vim.system({ vim.o.shell, '-c', cmd }, { text = true }, function(res)
      local out = ((res.stdout or '') .. (res.stderr or '')):gsub('%s+$', '')
      vim.schedule(function()
        vim.notify(out == '' and '(no output)' or out)
      end)
    end)
  end)
end, { desc = 'Run shell command' })

-- --- git (helix had `space B b` for blame) ------------------------------
map('n', '<Leader>gb', function()
  local line = tostring(vim.fn.line('.'))
  local file = vim.fn.expand('%:p')
  vim.system({ 'git', 'blame', '-L', line .. ',' .. line, '--', file }, { text = true }, function(res)
    local out = ((res.stdout or '') .. (res.stderr or '')):gsub('%s+$', '')
    vim.schedule(function()
      vim.notify(out == '' and '(no blame)' or out)
    end)
  end)
end, { desc = 'Blame line' })
map('n', '<Leader>gs', function() MiniGit.show_at_cursor() end, { desc = 'Show at cursor' })
map('n', '<Leader>gd', function() MiniDiff.toggle_overlay() end, { desc = 'Diff overlay' })

-- =============================================================== autocmds

local group = vim.api.nvim_create_augroup('init', {})

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'lua', 'json', 'jsonc', 'yaml', 'html', 'css', 'markdown', 'toml' },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Indent guides have to track shiftwidth, since `leadmultispace` repeats a
-- fixed-width string across the leading whitespace.
vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
  group = group,
  callback = function()
    local sw = vim.fn.shiftwidth()
    if sw > 1 then
      vim.opt_local.listchars:append({ leadmultispace = '│' .. string.rep(' ', sw - 1) })
    end
  end,
})

-- LSP source for the built-in completion.
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
  end,
})

-- Prose mode. ~/Vault is bilingual, hence spelllang.
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'markdown', 'text', 'gitcommit' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = 'en,ru'
    vim.opt_local.conceallevel = 2
    vim.opt_local.colorcolumn = ''
    vim.opt_local.list = false
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- ================================================================= modules

require('plugins')
require('lsp')
