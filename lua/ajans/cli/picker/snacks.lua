---@module 'snacks'

local M = {}

---@param source string
---@param cb fun(items:ajans.context.Loc[])
---@param opts? snacks.picker.Config
function M.open(source, cb, opts)
  Snacks.picker.pick(
    source,
    vim.tbl_extend("force", {
      confirm = M.action(cb),
    }, opts or {})
  )
end

---@param cb fun(items:ajans.context.Loc[])
function M.action(cb)
  ---@type snacks.picker.Action.fn
  return function(picker)
    local ret = {} ---@type ajans.context.Loc[]
    for _, item in ipairs(picker:selected({ fallback = true })) do
      local pos, end_pos = item.pos, item.end_pos
      ret[#ret + 1] = {
        buf = item.buf,
        cwd = item.cwd,
        name = require("snacks.picker.util").path(item),
        row = pos and pos[1] or nil,
        col = pos and pos[2] or nil,
        range = (pos and end_pos) and { from = pos, to = end_pos } or nil,
      }
    end
    picker:close()
    cb(ret)
  end
end

---@type snacks.picker.Action.fn
function M.send(picker)
  M.action(require("ajans.cli.picker").send_cb())(picker)
end

return M
