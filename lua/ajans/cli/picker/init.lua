local Config = require("ajans.config")
local Util = require("ajans.util")

local M = {}

---@class ajans.Picker
local P = {}

---@param source string
---@param cb fun(items:ajans.context.Loc[])
---@param opts? table
function P.open(source, cb, opts) end

---@param cb fun(items:ajans.context.Loc[])
---@return fun()
function P.action(cb) end

---@param picker? string
function M.get(picker)
  local pickers = picker and { picker } or { Config.cli.picker, "snacks", "telescope", "fzf-lua" }
  for _, name in ipairs(pickers) do
    ---@type boolean, ajans.Picker
    local ok, mod = pcall(require, "ajans.cli.picker." .. name)
    if not ok then
      return Util.error("Invalid picker: " .. name)
    end
    if pcall(require, name) then
      return mod
    end
  end
  Util.error("No valid picker found")
end

---@param opts? ajans.context.loc.Opts|ajans.cli.Send
function M._send_cb(opts)
  opts = opts or {}
  ---@param items ajans.context.Loc[]
  return function(items)
    local Loc = require("ajans.cli.context.location")
    local ret = { { " " } } ---@type ajans.Text
    for _, item in ipairs(items) do
      local file = Loc.get(item, { kind = opts.kind or "file" })[1]
      if file then
        vim.list_extend(ret, file)
        ret[#ret + 1] = { " " }
      end
    end
    vim.schedule(function()
      opts = vim.tbl_deep_extend("force", vim.deepcopy(opts or {}), { text = { ret } })
      ---@cast opts ajans.cli.Send
      require("ajans.cli").send(opts)
    end)
  end
end

---@param source string
---@param opts? ajans.context.loc.Opts|ajans.cli.Send
---@param popts? table
function M.open(source, opts, popts)
  local picker = M.get()
  return picker and picker.open(source, M._send_cb(opts), popts)
end

return M
