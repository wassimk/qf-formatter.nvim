local M = {}

-- Tracked values
M.matchadd_calls = {}

-- Original functions
local originals = {}

function M.setup_mocks()
  M.matchadd_calls = {}

  originals.getqflist = vim.fn.getqflist
  originals.getloclist = vim.fn.getloclist
  originals.bufname = vim.fn.bufname
  originals.matchadd = vim.fn.matchadd
  originals.nvim_get_hl = vim.api.nvim_get_hl

  vim.fn.matchadd = function(group, pattern)
    table.insert(M.matchadd_calls, { group = group, pattern = pattern })
    return #M.matchadd_calls
  end

  -- Default: no completion plugin detected
  vim.api.nvim_get_hl = function(ns, opts)
    return {}
  end
end

function M.set_qflist_items(items)
  vim.fn.getqflist = function(opts)
    return { items = items }
  end
end

function M.set_loclist_items(items)
  vim.fn.getloclist = function(winid, opts)
    return { items = items }
  end
end

function M.set_bufname(map)
  vim.fn.bufname = function(bufnr)
    return map[bufnr] or ''
  end
end

function M.set_hl_groups(groups)
  vim.api.nvim_get_hl = function(ns, opts)
    return groups[opts.name] or {}
  end
end

function M.teardown_mocks()
  vim.fn.getqflist = originals.getqflist
  vim.fn.getloclist = originals.getloclist
  vim.fn.bufname = originals.bufname
  vim.fn.matchadd = originals.matchadd
  vim.api.nvim_get_hl = originals.nvim_get_hl
end

return M
