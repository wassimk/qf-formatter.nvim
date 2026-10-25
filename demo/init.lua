--
-- Minimal config for recording the README demo with VHS (see demo/qf-formatter.tape)
--
-- Diagnostics and document symbols are staged so the demo needs no language server.
--

local onedark_dir = os.getenv('ONEDARK_DIR') or '/tmp/onedark.nvim'

if vim.fn.isdirectory(onedark_dir) == 0 then
  vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/navarasu/onedark.nvim',
    onedark_dir,
  })
end

-- The tape runs nvim from demo/sample, so find the plugin root from this file's location
local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

vim.opt.rtp:prepend(plugin_dir)
vim.opt.rtp:append(plugin_dir .. '/after')
vim.opt.rtp:append(onedark_dir)

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.wrap = false
vim.opt.shortmess:append('I')

-- Plain statusline: the default one shows diagnostic counts with icons that VHS renders cramped
vim.opt.statusline = ' %f %m%=%l:%c '

require('onedark').setup({ style = 'darker' })
require('onedark').load()

require('qf-formatter').setup()

-- VHS draws Nerd Font icons wider than one cell, so they overlap the space after them.
-- Pad icons with an extra space for the recording only; the plugin output is otherwise unchanged.
local qf_formatter = _G._qf_formatter
_G._qf_formatter = function(info)
  local lines = qf_formatter(info)
  for i, line in ipairs(lines) do
    -- Codicons live at U+EA00-U+EBFF, which is \238\168-\238\175 in UTF-8
    lines[i] = line:gsub('(\238[\168-\175][\128-\191]) ', '%1  ')
  end
  return lines
end

-- Match the gutter signs to qf-formatter's diagnostic icons
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = vim.fn.nr2char(0xEA87),
      [vim.diagnostic.severity.WARN] = vim.fn.nr2char(0xEA6C),
      [vim.diagnostic.severity.INFO] = vim.fn.nr2char(0xEA74),
      [vim.diagnostic.severity.HINT] = vim.fn.nr2char(0xEB32),
    },
  },
})

-- Staged diagnostics, placed on the first line matching each pattern
local diagnostics = {
  { 'lua/todo/init.lua', 'notify%(', 'ERROR', 'Undefined global `notify`.' },
  { 'lua/todo/init.lua', 'return %(a%.due', 'INFO', 'Comparison operand may be `nil`.' },
  { 'lua/todo/init.lua', 'for i, item in ipairs', 'HINT', 'Loop can be replaced with `items[index]`.' },
  { 'lua/todo/store.lua', 'local backup', 'WARN', 'Unused local `backup`.' },
  { 'lua/todo/store.lua', "M%.save%(path, ''%)", 'ERROR', 'Cannot assign `string` to `table`.' },
  { 'lua/todo/store.lua', 'file:close%(%)', 'INFO', 'Return value of `close` is ignored.' },
  { 'lua/todo/ui.lua', 'local width', 'WARN', 'Unused local `width`.' },
  { 'lua/todo/ui.lua', "vim%.cmd%('botright", 'WARN', 'Window is never closed.' },
}

local ns = vim.api.nvim_create_namespace('qf-formatter-demo')

-- Staged after startup so the buffers get filetype detection and syntax highlighting
local function stage_diagnostics()
  local by_buf = {}

  for _, d in ipairs(diagnostics) do
    local file, pattern, severity, message = unpack(d)
    local bufnr = vim.fn.bufadd(file)
    vim.fn.bufload(bufnr)
    vim.bo[bufnr].buflisted = true

    for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
      local col = line:find(pattern)
      if col then
        by_buf[bufnr] = by_buf[bufnr] or {}
        table.insert(by_buf[bufnr], {
          lnum = lnum - 1,
          col = col - 1 + #line:sub(col):match('^%s*'),
          severity = vim.diagnostic.severity[severity],
          message = message,
          source = 'Lua Diagnostics.',
        })
        break
      end
    end
  end

  for bufnr, items in pairs(by_buf) do
    vim.diagnostic.set(ns, bufnr, items)
  end
end

vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = stage_diagnostics })

-- Staged document symbols for gO, in the `[Kind] name` format the LSP client produces
local symbol_patterns = {
  { '^local ([%w_]+) = require', 'Module' },
  { '^local (M) = {}', 'Module' },
  { '^local function ([%w_]+)', 'Function' },
  { '^function M%.([%w_]+)', 'Method' },
  { '^local ([%w_]+) = {', 'Variable' },
  { '^  ([%w_]+) = .+,$', 'Field' },
}

vim.keymap.set('n', 'gO', function()
  local items = {}
  local bufnr = vim.api.nvim_get_current_buf()

  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    for _, sp in ipairs(symbol_patterns) do
      local name = line:match(sp[1])
      if name then
        local col = line:find(name, 1, true)
        table.insert(items, { bufnr = bufnr, lnum = lnum, col = col, text = '[' .. sp[2] .. '] ' .. name })
        break
      end
    end
  end

  vim.fn.setloclist(0, {}, ' ', { title = 'Document Symbols', items = items })
  vim.cmd('lopen')
end, { desc = 'document symbols (staged for the demo)' })
