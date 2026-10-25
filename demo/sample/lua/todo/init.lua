local store = require('todo.store')
local ui = require('todo.ui')

local M = {}

local defaults = {
  path = '~/.local/share/todo.json',
  sort = 'due',
  show_done = false,
}

local config = {}

local function by_due(a, b)
  return (a.due or math.huge) < (b.due or math.huge)
end

local function visible(items)
  local result = {}
  for _, item in ipairs(items) do
    if config.show_done or not item.done then
      table.insert(result, item)
    end
  end
  return result
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', defaults, opts or {})
end

function M.add(title, due)
  local items = store.load(config.path)
  table.insert(items, { title = title, due = due, done = false })
  store.save(config.path, items)
  notify('Added ' .. title)
end

function M.complete(index)
  local items = store.load(config.path)
  for i, item in ipairs(items) do
    if i == index then
      item.done = true
    end
  end
  store.save(config.path, items)
end

function M.list()
  local items = visible(store.load(config.path))
  table.sort(items, by_due)
  ui.render(items)
end

return M
