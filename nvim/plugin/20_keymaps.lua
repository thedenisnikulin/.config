-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--
-- This file contains definitions of custom general and Leader mappings.

-- General mappings ===========================================================

-- Use this section to add custom general mappings. See `:h vim.keymap.set()`.

-- An example helper to create a Normal mode mapping
local nmap = function(lhs, rhs, desc)
  -- See `:h vim.keymap.set()`
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

-- Paste linewise before/after current line
-- Usage: `yiw` to yank a word and `]p` to put it on the next line.
nmap('[p', '<Cmd>exe "iput! " . v:register<CR>', 'Paste Above')
nmap(']p', '<Cmd>exe "iput "  . v:register<CR>', 'Paste Below')

-- Many general mappings are created by 'mini.basics'. See 'plugin/30_mini.lua'

-- Helix leftovers ============================================================
--
-- This whole section exists for one reason: a year of Helix muscle memory.
-- Everything here is a direct port of a binding from 'helix/config.toml'.
-- None of it is required for the config to work - delete any line that stops
-- earning its place, the rest keeps functioning.
--
-- Deliberately NOT ported, because Vim already does the same thing:
-- - `0` / `^` / `$` - identical in both editors.
-- - `space z` (gutter width toggle)  -> `\n` from 'mini.basics' toggles numbers.
-- - `space m` (soft wrap toggle)     -> `\w` from 'mini.basics' toggles 'wrap'.
-- - `<A-w>` / `<A-e>` / `<A-b>` (sub word motions) - these need a plugin to
--   work properly, so they live in 'plugin/40_plugins.lua' with 'nvim-spider'.

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- `x` extends the selection line-wise downward, `X` upward. In Normal mode both
-- start a line-wise selection, which is what Helix's `select_line_below` does.
-- Note this shadows Vim's `x` ("delete character") - use `dl`, or just `d`,
-- which is what you were already doing in Helix.
map('n', 'x', 'V', 'Select line below')
map('x', 'x', 'j', 'Extend selection down')
map('n', 'X', 'V', 'Select line above')
map('x', 'X', 'k', 'Extend selection up')

-- The `g` goto family, as in Helix.
--
-- These are not Vim defaults and are not provided by the LSP client either:
-- - Vim's own `gd` means "go to local declaration" - a text search within the
--   current function. That is why it never jumped into the standard library.
-- - Neovim 0.11+ does ship built-in LSP mappings, but they live under the `gr`
--   prefix (`grr` references, `gri` implementation, `grn` rename, `grt` type).
--   Mapping `gr` itself to an action shadows all of them, since `gr` now fires
--   immediately instead of waiting for a second key. The `<Leader>l` group
--   covers what is left (rename, code action, ...).
-- - `gr` also used to be the "replace" operator from 'mini.operators'. That
--   moved to `gR` in 'plugin/30_mini.lua' to free this key.
--
-- These go through 'mini.pick' rather than `vim.lsp.buf.*` directly. The plain
-- functions dump multiple results into the quickfix list, which is a different
-- UI with different keys - exactly the inconsistency Helix does not have.
-- Routed through the picker, every one of these lands in the same window with
-- the same `<Tab>` / `<S-Tab>` / `<Esc>` keys as every other picker.
--
-- A single result still jumps straight to it without showing a picker at all;
-- the picker only appears when there is a genuine choice to make. See
-- `:h MiniExtra.pickers.lsp()`.
--
-- Requires an attached language server; without one they report as much.
map('n', 'gd', '<Cmd>Pick lsp scope="definition"<CR>', 'Goto definition')
map('n', 'gD', '<Cmd>Pick lsp scope="declaration"<CR>', 'Goto declaration')
map('n', 'gr', '<Cmd>Pick lsp scope="references"<CR>', 'Goto references')
map('n', 'gy', '<Cmd>Pick lsp scope="type_definition"<CR>', 'Goto type definition')
map('n', 'gi', '<Cmd>Pick lsp scope="implementation"<CR>', 'Goto implementation')

-- Scroll three lines at a time
map({ 'n', 'x' }, '<C-e>', '3<C-e>', 'Scroll down')
map({ 'n', 'x' }, '<C-y>', '3<C-y>', 'Scroll up')

-- Scroll the hover/documentation float with <C-d> / <C-u>.
--
-- Hover output (`K`, `<Leader>k`) opens a floating window that the cursor is
-- not inside, so plain <C-d> scrolls the buffer underneath instead. This sends
-- the scroll to the float when one is open, and behaves normally otherwise.
--
-- Alternative without any mapping: press `K` a second time to jump *into* the
-- hover window, then scroll and close it with `q`.
--
-- `vim.b.lsp_floating_preview` is set by Neovim to the window id of the hover
-- float belonging to this buffer (see `:h vim.lsp.util.open_floating_preview()`).
-- Keying off it rather than "any floating window" means pickers, notifications
-- and the clue window keep their own scrolling.
local scroll_float = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  return function()
    local win = vim.b.lsp_floating_preview
    if win ~= nil and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function() vim.cmd('normal! ' .. keys) end)
    else
      vim.cmd('normal! ' .. keys)
    end
  end
end
map('n', '<C-d>', scroll_float('<C-d>'), 'Scroll down (float aware)')
map('n', '<C-u>', scroll_float('<C-u>'), 'Scroll up (float aware)')

-- Cycle buffers. `[b` / `]b` from 'mini.bracketed' do the same thing.
map('n', '<A-[>', '<Cmd>bprevious<CR>', 'Previous buffer')
map('n', '<A-]>', '<Cmd>bnext<CR>', 'Next buffer')

-- Shell integration, the thing Helix does better than most editors.
-- These are all built on Vim's `:!` filter (see `:h :range!`), which reads the
-- selected range, pipes it through a command, and replaces it with the output.
-- The shell used is bash, set in 'plugin/10_options.lua'.
--
-- Usage: select some lines, press `|`, type `sort -u`, press Enter.
--
-- These mappings intentionally leave the command line open (no `<CR>`) so you
-- can type the command. Mapping `!` shadows Vim's filter operator (`!ap`,
-- `!!`); the `:{range}!{cmd}` command form is unaffected and still available.
map('x', '|', ':!', 'Pipe selection through command')
map('x', '<A-|>', ':w !', 'Send selection to command')
map('n', '!', ':.-1read !', 'Insert command output above')
map('n', '<A-!>', ':read !', 'Insert command output below')

-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.

-- Leader mappings ============================================================

-- Neovim has the concept of a Leader key (see `:h <Leader>`). It is a configurable
-- key that is primarily used for "workflow" mappings (opposed to text editing).
-- Like "open file explorer", "create scratch buffer", "pick from buffers".
--
-- In 'plugin/10_options.lua' <Leader> is set to <Space>, i.e. press <Space>
-- whenever there is a suggestion to press <Leader>.
--
-- This config uses a "two key Leader mappings" approach: first key describes
-- semantic group, second key executes an action. Both keys are usually chosen
-- to create some kind of mnemonic.
-- Example: `<Leader>f` groups "find" type of actions; `<Leader>ff` - find files.
-- Use this section to add Leader mappings in a structural manner.
--
-- Usually if there are global and local kinds of actions, lowercase second key
-- denotes global and uppercase - local.
-- Example: `<Leader>fs` / `<Leader>fS` - find workspace/document LSP symbols.
--
-- Many of the mappings use 'mini.nvim' modules set up in 'plugin/30_mini.lua'.

-- Create a global table with information about Leader groups in certain modes.
-- This is used to provide 'mini.clue' with extra clues.
-- Add an entry if you create a new group.
Config.leader_group_clues = {
  { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
  { mode = 'n', keys = '<Leader>e', desc = '+Explore/Edit' },
  { mode = 'n', keys = '<Leader>f', desc = '+Find' },
  { mode = 'n', keys = '<Leader>g', desc = '+Git' },
  { mode = 'n', keys = '<Leader>l', desc = '+Language' },
  { mode = 'n', keys = '<Leader>m', desc = '+Map' },
  { mode = 'n', keys = '<Leader>o', desc = '+Other' },
  { mode = 'n', keys = '<Leader>t', desc = '+Terminal' },
  { mode = 'n', keys = '<Leader>v', desc = '+Visits' },
  { mode = 'n', keys = '<Leader>w', desc = '+Workspace' },
  { mode = 'n', keys = '<Leader>x', desc = '+Multicursor' },

  { mode = 'x', keys = '<Leader>g', desc = '+Git' },
  { mode = 'x', keys = '<Leader>l', desc = '+Language' },
  { mode = 'x', keys = '<Leader>x', desc = '+Multicursor' },
}

-- Helpers for a more concise `<Leader>` mappings.
-- Most of the mappings use `<Cmd>...<CR>` string as a right hand side (RHS) in
-- an attempt to be more concise yet descriptive. See `:h <Cmd>`.
-- This approach also doesn't require the underlying commands/functions to exist
-- during mapping creation: a "lazy loading" approach to improve startup time.
local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, { desc = desc })
end
local xmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
end

-- b is for 'Buffer'. Common usage:
-- - `<Leader>bs` - create scratch (temporary) buffer
-- - `<Leader>ba` - navigate to the alternative buffer
-- - `<Leader>bw` - wipeout (fully delete) current buffer
local new_scratch_buffer = function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end

nmap_leader('ba', '<Cmd>b#<CR>',                                 'Alternate')
nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>',         'Delete')
nmap_leader('bD', '<Cmd>lua MiniBufremove.delete(0, true)<CR>',  'Delete!')
nmap_leader('bs', new_scratch_buffer,                            'Scratch')
nmap_leader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>',        'Wipeout')
nmap_leader('bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', 'Wipeout!')

-- Helix leftover: `space c` / `space C` were `:buffer-close` / `:buffer-close!`.
-- Same actions as `<Leader>bd` / `<Leader>bD` above, kept as single-key aliases.
nmap_leader('c', '<Cmd>lua MiniBufremove.delete()<CR>',         'Close buffer')
nmap_leader('C', '<Cmd>lua MiniBufremove.delete(0, true)<CR>',  'Close buffer!')

-- e is for 'Explore' and 'Edit'. Common usage:
-- - `<Leader>ed` - open explorer at current working directory
-- - `<Leader>ef` - open directory of current file (needs to be present on disk)
-- - `<Leader>ei` - edit 'init.lua'
-- - All mappings that use `edit_plugin_file` - edit 'plugin/' config files
local edit_plugin_file = function(filename)
  return string.format('<Cmd>edit %s/plugin/%s<CR>', vim.fn.stdpath('config'), filename)
end
local explore_at_file = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>'
local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end
local explore_locations = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true }).winid ~= 0 and 'lclose' or 'lopen')
end

nmap_leader('ed', '<Cmd>lua MiniFiles.open()<CR>',          'Directory')
nmap_leader('ef', explore_at_file,                          'File directory')
nmap_leader('ei', '<Cmd>edit $MYVIMRC<CR>',                 'init.lua')
nmap_leader('ek', edit_plugin_file('20_keymaps.lua'),       'Keymaps config')
nmap_leader('em', edit_plugin_file('30_mini.lua'),          'MINI config')
nmap_leader('en', '<Cmd>lua MiniNotify.show_history()<CR>', 'Notifications')
nmap_leader('eo', edit_plugin_file('10_options.lua'),       'Options config')
nmap_leader('ep', edit_plugin_file('40_plugins.lua'),       'Plugins config')
nmap_leader('eq', explore_quickfix,                         'Quickfix list')
nmap_leader('eQ', explore_locations,                        'Location list')

-- f is for 'Fuzzy Find'. Common usage:
-- - `<Leader>ff` - find files; for best performance requires `ripgrep`
-- - `<Leader>fg` - find inside files; requires `ripgrep`
-- - `<Leader>fh` - find help tag
-- - `<Leader>fr` - resume latest picker
-- - `<Leader>fv` - all visited paths; requires 'mini.visits'
--
-- All these use 'mini.pick'. See `:h MiniPick-overview` for an overview.
local pick_added_hunks_buf = '<Cmd>Pick git_hunks path="%" scope="staged"<CR>'
local pick_workspace_symbols_live = '<Cmd>Pick lsp scope="workspace_symbol_live"<CR>'

nmap_leader('f/', '<Cmd>Pick history scope="/"<CR>',            '"/" history')
nmap_leader('f:', '<Cmd>Pick history scope=":"<CR>',            '":" history')
nmap_leader('fa', '<Cmd>Pick git_hunks scope="staged"<CR>',     'Added hunks (all)')
nmap_leader('fA', pick_added_hunks_buf,                         'Added hunks (buf)')
nmap_leader('fb', '<Cmd>Pick buffers<CR>',                      'Buffers')
nmap_leader('fc', '<Cmd>Pick git_commits<CR>',                  'Commits (all)')
nmap_leader('fC', '<Cmd>Pick git_commits path="%"<CR>',         'Commits (buf)')
nmap_leader('fd', '<Cmd>Pick diagnostic scope="all"<CR>',       'Diagnostic workspace')
nmap_leader('fD', '<Cmd>Pick diagnostic scope="current"<CR>',   'Diagnostic buffer')
nmap_leader('ff', '<Cmd>Pick files<CR>',                        'Files')
nmap_leader('fg', '<Cmd>Pick grep_live<CR>',                    'Grep live')
nmap_leader('fG', '<Cmd>Pick grep pattern="<cword>"<CR>',       'Grep current word')
nmap_leader('fh', '<Cmd>Pick help<CR>',                         'Help tags')
nmap_leader('fH', '<Cmd>Pick hl_groups<CR>',                    'Highlight groups')
nmap_leader('fl', '<Cmd>Pick buf_lines scope="all"<CR>',        'Lines (all)')
nmap_leader('fL', '<Cmd>Pick buf_lines scope="current"<CR>',    'Lines (buf)')
nmap_leader('fm', '<Cmd>Pick git_hunks<CR>',                    'Modified hunks (all)')
nmap_leader('fM', '<Cmd>Pick git_hunks path="%"<CR>',           'Modified hunks (buf)')
nmap_leader('fr', '<Cmd>Pick resume<CR>',                       'Resume')
nmap_leader('fR', '<Cmd>Pick lsp scope="references"<CR>',       'References (LSP)')
nmap_leader('fs', pick_workspace_symbols_live,                  'Symbols workspace (live)')
nmap_leader('fS', '<Cmd>Pick lsp scope="document_symbol"<CR>',  'Symbols document')
nmap_leader('fv', '<Cmd>Pick visit_paths cwd=""<CR>',           'Visit paths (all)')
nmap_leader('fV', '<Cmd>Pick visit_paths<CR>',                  'Visit paths (cwd)')

-- g is for 'Git'. Common usage:
-- - `<Leader>gs` - show information at cursor
-- - `<Leader>go` - toggle 'mini.diff' overlay to show in-buffer unstaged changes
-- - `<Leader>gd` - show unstaged changes as a patch in separate tabpage
-- - `<Leader>gL` - show Git log of current file
local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]
local git_log_buf_cmd = git_log_cmd .. ' --follow -- %'

-- Helix leftover: `space B b` ran `git blame` for the line under the cursor.
local git_blame_line = function()
  local l, path = vim.fn.line('.'), vim.fn.fnameescape(vim.fn.expand('%:p'))
  vim.cmd(string.format('Git blame -L %d,%d -- %s', l, l, path))
end

nmap_leader('ga', '<Cmd>Git diff --cached<CR>',             'Added diff')
nmap_leader('gA', '<Cmd>Git diff --cached -- %<CR>',        'Added diff buffer')
nmap_leader('gb', git_blame_line,                           'Blame line')
nmap_leader('gB', '<Cmd>Git blame -- %<CR>',                'Blame buffer')
nmap_leader('gc', '<Cmd>Git commit<CR>',                    'Commit')
nmap_leader('gC', '<Cmd>Git commit --amend<CR>',            'Commit amend')
nmap_leader('gd', '<Cmd>Git diff<CR>',                      'Diff')
nmap_leader('gD', '<Cmd>Git diff -- %<CR>',                 'Diff buffer')
nmap_leader('gl', '<Cmd>' .. git_log_cmd .. '<CR>',         'Log')
nmap_leader('gL', '<Cmd>' .. git_log_buf_cmd .. '<CR>',     'Log buffer')
nmap_leader('go', '<Cmd>lua MiniDiff.toggle_overlay()<CR>', 'Toggle overlay')
nmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>',  'Show at cursor')

xmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', 'Show at selection')

-- l is for 'Language'. Common usage:
-- - `<Leader>ld` - show more diagnostic details in a floating window
-- - `<Leader>lr` - perform rename via LSP
-- - `<Leader>ls` - navigate to source definition of symbol under cursor
--
-- NOTE: most LSP mappings represent a more structured way of replacing built-in
-- LSP mappings (like `:h gra` and others). This is needed because `gr` is mapped
-- by an "replace" operator in 'mini.operators' (which is more commonly used).
nmap_leader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>',     'Actions')
nmap_leader('ld', '<Cmd>lua vim.diagnostic.open_float()<CR>',   'Diagnostic popup')
nmap_leader('lf', '<Cmd>lua require("conform").format()<CR>',   'Format')
nmap_leader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>',  'Implementation')
nmap_leader('lh', '<Cmd>lua vim.lsp.buf.hover()<CR>',           'Hover')
nmap_leader('ll', '<Cmd>lua vim.lsp.codelens.run()<CR>',        'Lens')
nmap_leader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>',          'Rename')
nmap_leader('lR', '<Cmd>lua vim.lsp.buf.references()<CR>',      'References')
nmap_leader('ls', '<Cmd>lua vim.lsp.buf.definition()<CR>',      'Source definition')
nmap_leader('lt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', 'Type definition')

xmap_leader('lf', '<Cmd>lua require("conform").format()<CR>', 'Format selection')

-- Helix leftover: `space k` showed documentation for the symbol under cursor.
-- Same action as `<Leader>lh` above. Note that plain `K` also does this - it is
-- a built-in LSP mapping in Neovim 0.11+, no config needed (see `:h K`).
nmap_leader('k', '<Cmd>lua vim.lsp.buf.hover()<CR>', 'Hover docs')

-- m is for 'Map'. Common usage:
-- - `<Leader>mt` - toggle map from 'mini.map' (closed by default)
-- - `<Leader>mf` - focus on the map for fast navigation
-- - `<Leader>ms` - change map's side (if it covers something underneath)
nmap_leader('mf', '<Cmd>lua MiniMap.toggle_focus()<CR>', 'Focus (toggle)')
nmap_leader('mr', '<Cmd>lua MiniMap.refresh()<CR>',      'Refresh')
nmap_leader('ms', '<Cmd>lua MiniMap.toggle_side()<CR>',  'Side (toggle)')
nmap_leader('mt', '<Cmd>lua MiniMap.toggle()<CR>',       'Toggle')

-- o is for 'Other'. Common usage:
-- - `<Leader>oz` - toggle between "zoomed" and regular view of current buffer
-- - `<Leader>oc` - pick a colorscheme with live preview (Helix's `:theme`)
nmap_leader('oc', '<Cmd>Pick colorschemes<CR>',            'Colorscheme')
nmap_leader('or', '<Cmd>lua MiniMisc.resize_window()<CR>', 'Resize to default width')
nmap_leader('ot', '<Cmd>lua MiniTrailspace.trim()<CR>',    'Trim trailspace')
nmap_leader('oz', '<Cmd>lua MiniMisc.zoom()<CR>',          'Zoom toggle')

-- s is for 'Symbols', as in Helix: `space s` for this file, `space S` for the
-- whole workspace. These are single actions, not groups.
-- The same pickers also live at `<Leader>fS` / `<Leader>fs` in the Find group.
nmap_leader('s', '<Cmd>Pick lsp scope="document_symbol"<CR>', 'Symbols document')
nmap_leader('S', pick_workspace_symbols_live,                 'Symbols workspace')

-- w is for 'Workspace', which is where sessions moved to when `<Leader>s`
-- became Symbols. Common usage:
-- - `<Leader>wn` - start new session
-- - `<Leader>wr` - read previously started session
-- - `<Leader>wR` - restart Neovim preserving current session
local session_new = 'vim.ui.input({ prompt = "Session name: " }, MiniSessions.write)'

nmap_leader('wd', '<Cmd>lua MiniSessions.select("delete")<CR>', 'Delete')
nmap_leader('wn', '<Cmd>lua ' .. session_new .. '<CR>',         'New')
nmap_leader('wr', '<Cmd>lua MiniSessions.select("read")<CR>',   'Read')
nmap_leader('wR', '<Cmd>lua MiniSessions.restart()<CR>',        'Restart')
nmap_leader('ww', '<Cmd>lua MiniSessions.write()<CR>',          'Write current')

-- t is for 'Terminal'
nmap_leader('tT', '<Cmd>horizontal term<CR>', 'Terminal (horizontal)')
nmap_leader('tt', '<Cmd>vertical term<CR>',   'Terminal (vertical)')

-- v is for 'Visits'. Common usage:
-- - `<Leader>vv` - add    "core" label to current file.
-- - `<Leader>vV` - remove "core" label to current file.
-- - `<Leader>vc` - pick among all files with "core" label.
local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end

nmap_leader('vc', make_pick_core('',  'Core visits (all)'),       'Core visits (all)')
nmap_leader('vC', make_pick_core(nil, 'Core visits (cwd)'),       'Core visits (cwd)')
nmap_leader('vv', '<Cmd>lua MiniVisits.add_label("core")<CR>',    'Add "core" label')
nmap_leader('vV', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
nmap_leader('vl', '<Cmd>lua MiniVisits.add_label()<CR>',          'Add label')
nmap_leader('vL', '<Cmd>lua MiniVisits.remove_label()<CR>',       'Remove label')
-- stylua: ignore end
