local M = {}

local c = vim.fn.nr2char

-- Diagnostic sign icons (abbreviated for formatter, full for highlighter)
local diagnostic_signs_abbreviated = {
  E = c(0xEA87),
  W = c(0xEA6C),
  I = c(0xEA74),
  N = c(0xEB32),
}

local diagnostic_signs_full = {
  Error = c(0xEA87),
  Warn = c(0xEA6C),
  Info = c(0xEA74),
  Hint = c(0xEB32),
}

-- LSP kind icons (codicons)
local kind_icons = {
  Text = c(0xEA93),
  Method = c(0xEA8C),
  Function = c(0xEA8C),
  Constructor = c(0xEA8C),
  Field = c(0xEB5F),
  Variable = c(0xEA88),
  Class = c(0xEB5B),
  Interface = c(0xEB61),
  Module = c(0xEA8B),
  Property = c(0xEB65),
  Unit = c(0xEA96),
  Value = c(0xEA95),
  Enum = c(0xEA95),
  Keyword = c(0xEB62),
  Snippet = c(0xEB66),
  Color = c(0xEB5C),
  File = c(0xEA7B),
  Reference = c(0xEA94),
  Folder = c(0xEA83),
  EnumMember = c(0xEA95),
  Constant = c(0xEB5D),
  Struct = c(0xEA91),
  Event = c(0xEA86),
  Operator = c(0xEB64),
  TypeParameter = c(0xEA92),
}

-- Default highlight links for each LSP kind
local kind_hl_links = {
  Text = 'String',
  Method = 'Function',
  Function = 'Function',
  Constructor = 'Function',
  Field = 'Identifier',
  Variable = 'Identifier',
  Class = 'Type',
  Interface = 'Type',
  Module = 'Include',
  Property = 'Identifier',
  Unit = 'Number',
  Value = 'Number',
  Enum = 'Type',
  Keyword = 'Keyword',
  Snippet = 'Special',
  Color = 'Special',
  File = 'Directory',
  Reference = 'Identifier',
  Folder = 'Directory',
  EnumMember = 'Constant',
  Constant = 'Constant',
  Struct = 'Type',
  Event = 'Special',
  Operator = 'Operator',
  TypeParameter = 'Type',
}

-- Pre-computed format characters (avoid vim.fn calls inside qftf callback)
local ellipsis = c(0x2026)
local sep = c(0x2502)

local defaults = {
  filename_width = 32,
}

local config = {}
local fname_fmt1, fname_fmt2, valid_fmt

local function build_format_strings()
  local limit = config.filename_width
  fname_fmt1 = '%-' .. limit .. 's'
  fname_fmt2 = ellipsis .. '%.' .. (limit - 1) .. 's'
  valid_fmt = '%s ' .. sep .. '%5d:%-3d' .. sep .. '%s %s'
end

local function format(info)
  local items
  local ret = {}

  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end

  local limit = config.filename_width

  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local fname = ''
    local str

    if e.valid == 1 then
      if e.bufnr > 0 then
        fname = vim.fn.bufname(e.bufnr)
        if fname == '' then
          fname = '[No Name]'
        else
          fname = fname:gsub('^' .. vim.env.HOME, '~')
        end
        if #fname <= limit then
          fname = fname_fmt1:format(fname)
        else
          fname = fname_fmt2:format(fname:sub(1 - limit))
        end
      end

      local lnum = e.lnum > 99999 and -1 or e.lnum
      local col = e.col > 999 and -1 or e.col

      local qtype = e.type
      local qtext = e.text

      if qtype ~= '' then
        local icon = diagnostic_signs_abbreviated[qtype]
        qtype = ' ' .. (icon or qtype)
      else
        local symbol = qtext:match('^%[(.*)%]')
        if symbol then
          local icon = kind_icons[symbol]
          if icon and icon ~= '' then
            qtext = icon .. ' ' .. qtext
          else
            qtext = '  ' .. qtext
          end
        end
      end

      str = valid_fmt:format(fname, lnum, col, qtype, qtext)
    else
      str = e.text
    end

    table.insert(ret, str)
  end

  return ret
end

function M._on_qf_filetype()
  local sep = c(0x2502)
  local sep_pat = vim.fn.escape(sep, [[\]])

  vim.fn.matchadd('Directory', '^[^' .. sep .. ']*')
  vim.fn.matchadd('Delimiter', sep_pat)
  vim.fn.matchadd('LineNr', sep_pat .. [[\zs[^]] .. sep .. [[]*\ze]] .. sep_pat)

  -- Diagnostic sign highlights
  local diagnostic_map = {
    Error = 'DiagnosticSignError',
    Warn = 'DiagnosticSignWarn',
    Info = 'DiagnosticSignInfo',
    Hint = 'DiagnosticSignHint',
  }

  local after_sep = sep_pat .. '[^' .. sep .. ']*' .. sep_pat .. [[\zs ]]

  for name, hl in pairs(diagnostic_map) do
    local icon = diagnostic_signs_full[name]
    if icon then
      vim.fn.matchadd(hl, after_sep .. vim.fn.escape(icon, [[\]]))
    end
  end

  -- LSP kind highlights
  for kind, icon in pairs(kind_icons) do
    if icon ~= '' then
      vim.fn.matchadd('QfFormatterKind' .. kind, after_sep .. vim.fn.escape(icon, [[\]]))
    end
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', defaults, opts or {})
  build_format_strings()

  for kind, link in pairs(kind_hl_links) do
    vim.api.nvim_set_hl(0, 'QfFormatterKind' .. kind, { link = link, default = true })
  end

  _G._qf_formatter = function(info)
    local ok, result = pcall(format, info)
    if ok then
      return result
    end
    vim.notify('qf-formatter: ' .. result, vim.log.levels.ERROR)
    return {}
  end

  vim.o.qftf = '{info -> v:lua._qf_formatter(info)}'
end

return M
