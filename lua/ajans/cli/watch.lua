local Util = require("ajans.util")

local M = {}

M.watches = {} ---@type table<string, uv.uv_fs_event_t>>
M.enabled = false
M.changes = {} ---@type table<string, boolean>

local MAX_CHANGES = 1000

--- Refresh checktime and clear the changes log
function M.refresh()
  local changes = vim.tbl_keys(M.changes)
  M.changes = {}
  vim.cmd.checktime()
  if #changes > 0 then
    Util.debug("# Changes\n- " .. table.concat(changes, "\n- "))
  end
end

--- Start watching a specific path
---@param path string
function M.start(path)
  if M.watches[path] ~= nil then
    return
  end
  Util.debug("Watching `" .. path .. "`")
  local watch = assert(vim.uv.new_fs_event())
  local ok, err = watch:start(path, {}, function(_, file)
    if file then
      if vim.tbl_count(M.changes) >= MAX_CHANGES then
        M.changes = {}
      end
      M.changes[vim.fs.joinpath(path, file)] = true
      pcall(M.refresh)
    end
  end)
  if not ok then
    Util.error("Failed to watch " .. path .. ": " .. err)
    return watch:is_closing() or watch:close()
  end
  M.watches[path] = watch
end

---@param buf number
---@return string?
local function dirname(buf)
  local fname = vim.api.nvim_buf_get_name(buf)
  if
    vim.api.nvim_buf_is_loaded(buf)
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].buflisted
    and fname ~= ""
    and vim.uv.fs_stat(fname) ~= nil
  then
    local path = vim.fs.dirname(fname)
    return path and path ~= "" and path or nil
  end
end

--- Update watches based on currently loaded buffers
--- Starts watches for new buffer directories and stops watches for removed ones
function M.update()
  local dirs = {} ---@type table<string, boolean>
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    local dir = dirname(buf)
    if dir then
      dirs[dir] = true
      M.start(dir)
    end
  end
  for path in pairs(M.watches) do
    if not dirs[path] then
      M.stop(path)
    end
  end
end

M.refresh = Util.debounce(M.refresh, 100)
M.update = Util.debounce(M.update, 100)

--- Stop watching a specific path
---@param path string
function M.stop(path)
  local w = M.watches[path]
  if w then
    M.watches[path] = nil
    Util.debug("Stopped watching `" .. path .. "`")
    return w:is_closing() or w:close()
  end
end

--- Disable file system watching and stop all active watches
function M.disable()
  if not M.enabled then
    return
  end
  M.enabled = false
  pcall(vim.api.nvim_clear_autocmds, { group = "ajans.watch" })
  pcall(vim.api.nvim_del_augroup_by_name, "ajans.watch")
  for path in pairs(M.watches) do
    M.stop(path)
  end
end

--- Enable file system watching for all loaded buffers
function M.enable()
  if M.enabled then
    return
  end
  M.enabled = true
  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("ajans.watch", { clear = true }),
    callback = M.update,
  })
  M.update()
end

return M
