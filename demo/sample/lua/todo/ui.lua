local M = {}

local function format_item(item)
  local check = item.done and '[x]' or '[ ]'
  local due = item.due and os.date('%b %d', item.due) or ''
  return string.format('%s %-40s %s', check, item.title, due)
end

function M.render(items)
  local width = vim.o.columns
  local lines = {}

  for _, item in ipairs(items) do
    table.insert(lines, format_item(item))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.cmd('botright split')
  vim.api.nvim_win_set_buf(0, buf)
end

return M
