local TS = require("ajans.treesitter")
local Text = require("ajans.text")

local M = {}

---@param ctx ajans.context.ctx
function M.get(ctx)
  if not ctx.range then
    return
  end
  local buf, from, to, kind = ctx.buf, ctx.range.from, ctx.range.to, ctx.range.kind

  local vl = TS.get_virtual_lines(buf, { start_row = from[1] - 1, end_row = to[1] })
  if #vl > 0 then
    if kind == "char" and vl[1] then
      vl[1] = Text.sub(vl[1], from[2] + 1, from[1] == to[1] and (to[2] + 1) or nil)
      if from[2] > 0 then
        table.insert(vl[1], 1, { string.rep(" ", from[2]) })
      end
      if #vl > 1 then
        vl[#vl] = Text.sub(vl[#vl], 1, to[2] + 1)
      end
    elseif kind == "block" then
      local offset = math.min(from[2], to[2])
      local offset_end = math.max(from[2], to[2])
      for i, line in ipairs(vl) do
        vl[i] = Text.sub(line, offset + 1, offset_end + 1)
      end
    end
  end
  return Text.fix_indent(vl)
end

return M
