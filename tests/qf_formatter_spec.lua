local helpers = require('helpers')

local c = vim.fn.nr2char

describe('qf-formatter', function()
  local qf_formatter

  before_each(function()
    helpers.setup_mocks()
    package.loaded['qf-formatter'] = nil
    package.loaded['qf-formatter.init'] = nil
    qf_formatter = require('qf-formatter')
  end)

  after_each(function()
    helpers.teardown_mocks()
    _G._qf_formatter = nil
    vim.o.qftf = ''
  end)

  describe('setup', function()
    it('does not error with no arguments', function()
      assert.has_no.errors(function()
        qf_formatter.setup()
      end)
    end)

    it('registers global formatter function', function()
      qf_formatter.setup()
      assert.is_function(_G._qf_formatter)
    end)

    it('sets vim.o.qftf', function()
      qf_formatter.setup()
      assert.equals('{info -> v:lua._qf_formatter(info)}', vim.o.qftf)
    end)

    it('accepts custom options', function()
      assert.has_no.errors(function()
        qf_formatter.setup({ filename_width = 40 })
      end)
    end)

    it('accepts opts table for defaults', function()
      assert.has_no.errors(function()
        qf_formatter.setup({})
      end)
    end)
  end)

  describe('format', function()
    before_each(function()
      qf_formatter.setup()
    end)

    it('formats quickfix entries with filename, line, col', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 10, col = 5, type = '', text = 'some text' },
      })
      helpers.set_bufname({ [1] = 'src/main.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.equals(1, #result)
      assert.truthy(result[1]:find('src/main.lua'))
      assert.truthy(result[1]:find('10'))
      assert.truthy(result[1]:find('some text'))
    end)

    it('formats location list entries', function()
      helpers.set_loclist_items({
        { valid = 1, bufnr = 1, lnum = 5, col = 1, type = '', text = 'loc text' },
      })
      helpers.set_bufname({ [1] = 'src/lib.lua' })

      local result = _G._qf_formatter({ quickfix = 0, id = 1, winid = 1000, start_idx = 1, end_idx = 1 })

      assert.equals(1, #result)
      assert.truthy(result[1]:find('src/lib.lua'))
      assert.truthy(result[1]:find('loc text'))
    end)

    it('replaces HOME with ~', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = 'test' },
      })
      helpers.set_bufname({ [1] = vim.env.HOME .. '/project/file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find('~/project/file.lua'))
    end)

    it('truncates long filenames with ellipsis', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = 'test' },
      })
      helpers.set_bufname({ [1] = 'a/very/long/path/to/some/deeply/nested/file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find(c(0x2026)))
    end)

    it('shows [No Name] for empty buffer names', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = 'test' },
      })
      helpers.set_bufname({ [1] = '' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find('%[No Name%]'))
    end)

    it('decorates diagnostic type E with icon', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = 'E', text = 'error msg' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find(c(0xEA87), 1, true))
    end)

    it('decorates diagnostic type W with icon', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = 'W', text = 'warning msg' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find(c(0xEA6C), 1, true))
    end)

    it('preserves unknown diagnostic types', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = 'X', text = 'unknown' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find(' X'))
    end)

    it('decorates LSP kind symbols with codicons', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = '[Method] doSomething' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find(c(0xEA8C), 1, true))
      assert.truthy(result[1]:find('%[Method%] doSomething'))
    end)

    it('handles unknown LSP kind gracefully', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = '[Unknown] something' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find('%[Unknown%] something'))
    end)

    it('passes through invalid entries as plain text', function()
      helpers.set_qflist_items({
        { valid = 0, bufnr = 0, lnum = 0, col = 0, type = '', text = '|| raw line' },
      })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.equals('|| raw line', result[1])
    end)

    it('handles entries with no bufnr', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 0, lnum = 1, col = 1, type = '', text = 'no file' },
      })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find('no file'))
    end)

    it('caps large line numbers', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 100000, col = 1, type = '', text = 'big line' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find('%-1'))
    end)

    it('caps large column numbers', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1000, type = '', text = 'big col' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find('%-1'))
    end)

    it('formats multiple entries', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = 'first' },
        { valid = 1, bufnr = 2, lnum = 2, col = 2, type = '', text = 'second' },
        { valid = 1, bufnr = 3, lnum = 3, col = 3, type = '', text = 'third' },
      })
      helpers.set_bufname({ [1] = 'a.lua', [2] = 'b.lua', [3] = 'c.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 3 })

      assert.equals(3, #result)
      assert.truthy(result[1]:find('a.lua'))
      assert.truthy(result[2]:find('b.lua'))
      assert.truthy(result[3]:find('c.lua'))
    end)

    it('uses separator characters', function()
      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 10, col = 5, type = '', text = 'test' },
      })
      helpers.set_bufname({ [1] = 'file.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      assert.truthy(result[1]:find(c(0x2502), 1, true))
    end)

    it('respects custom filename_width', function()
      qf_formatter.setup({ filename_width = 10 })

      helpers.set_qflist_items({
        { valid = 1, bufnr = 1, lnum = 1, col = 1, type = '', text = 'test' },
      })
      helpers.set_bufname({ [1] = 'short.lua' })

      local result = _G._qf_formatter({ quickfix = 1, id = 1, start_idx = 1, end_idx = 1 })

      -- short.lua is 9 chars, fits within width 10
      assert.truthy(result[1]:find('short.lua'))
    end)
  end)

  describe('_on_qf_filetype', function()
    it('adds Directory highlight for filenames', function()
      qf_formatter.setup()
      qf_formatter._on_qf_filetype()

      local found = false
      for _, call in ipairs(helpers.matchadd_calls) do
        if call.group == 'Directory' then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it('adds Delimiter highlight for separators', function()
      qf_formatter.setup()
      qf_formatter._on_qf_filetype()

      local found = false
      for _, call in ipairs(helpers.matchadd_calls) do
        if call.group == 'Delimiter' then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it('adds LineNr highlight for line:col', function()
      qf_formatter.setup()
      qf_formatter._on_qf_filetype()

      local found = false
      for _, call in ipairs(helpers.matchadd_calls) do
        if call.group == 'LineNr' then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it('adds DiagnosticSign highlights', function()
      qf_formatter.setup()
      qf_formatter._on_qf_filetype()

      local diagnostic_groups = {}
      for _, call in ipairs(helpers.matchadd_calls) do
        if call.group:match('^DiagnosticSign') then
          diagnostic_groups[call.group] = true
        end
      end
      assert.is_true(diagnostic_groups['DiagnosticSignError'] or false)
      assert.is_true(diagnostic_groups['DiagnosticSignWarn'] or false)
      assert.is_true(diagnostic_groups['DiagnosticSignInfo'] or false)
      assert.is_true(diagnostic_groups['DiagnosticSignHint'] or false)
    end)

    it('adds QfFormatterKind highlights for LSP kinds', function()
      qf_formatter.setup()
      qf_formatter._on_qf_filetype()

      local kind_groups = {}
      for _, call in ipairs(helpers.matchadd_calls) do
        if call.group:match('^QfFormatterKind') then
          kind_groups[call.group] = true
        end
      end
      assert.is_true(kind_groups['QfFormatterKindMethod'] or false)
      assert.is_true(kind_groups['QfFormatterKindClass'] or false)
      assert.is_true(kind_groups['QfFormatterKindFunction'] or false)
      assert.is_true(kind_groups['QfFormatterKindVariable'] or false)
      assert.is_true(kind_groups['QfFormatterKindConstant'] or false)
    end)

    it('defines QfFormatterKind highlight groups during setup', function()
      qf_formatter.setup()

      local hl_names = {}
      for _, call in ipairs(helpers.set_hl_calls) do
        if call.name:match('^QfFormatterKind') then
          hl_names[call.name] = call.val
        end
      end
      assert.is_not_nil(hl_names['QfFormatterKindMethod'])
      assert.equals('Function', hl_names['QfFormatterKindMethod'].link)
      assert.is_true(hl_names['QfFormatterKindMethod'].default)

      assert.is_not_nil(hl_names['QfFormatterKindClass'])
      assert.equals('Type', hl_names['QfFormatterKindClass'].link)
    end)
  end)
end)
