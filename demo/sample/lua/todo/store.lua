local M = {}

local function expand(path)
  return vim.fn.expand(path)
end

function M.load(path)
  local file = io.open(expand(path), 'r')
  if not file then
    return {}
  end

  local content = file:read('*a')
  file:close()

  local ok, items = pcall(vim.json.decode, content)
  return ok and items or {}
end

function M.save(path, items)
  local backup = path .. '.bak'
  local file = io.open(expand(path), 'w')
  if not file then
    return
  end

  file:write(vim.json.encode(items))
  file:close()
end

function M.clear(path)
  M.save(path, '')
end

return M
