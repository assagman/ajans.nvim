---@module 'snacks'

local M = {}

---@type snacks.picker.Action.fn
function M.send(picker)
  local Util = require("ajans.util")
  Util.deprecate('require("ajans.cli.snacks").send()', 'require("ajans.cli.picker.snacks").send()')
  require("ajans.cli.picker.snacks").send(picker)
end

return M
