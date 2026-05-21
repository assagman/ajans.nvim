local M = {}

M.sources = {
  files = "files",
  grep = "live_grep",
}

---@param source string
---@param cb fun(items:ajans.context.Loc[])
---@param opts? table
function M.open(source, cb, opts)
  opts = opts or {}
  opts.actions = opts.actions or {}
  opts.actions["default"] = M.action(cb)
  source = M.sources[source] or source
  require("fzf-lua")[source](opts)
end

---@param cb fun(items:ajans.context.Loc[])
function M.action(cb)
  return function(selected, fzf_opts)
    if not selected or #selected == 0 then
      return
    end

    local path = require("fzf-lua.path")
    local items = {} ---@type ajans.context.Loc[]

    for _, item in ipairs(selected) do
      -- Use fzf-lua's path.entry_to_file to properly parse entries
      local entry = path.entry_to_file(item, fzf_opts)

      ---@type ajans.context.Loc
      local loc = {
        name = entry.path or entry.file,
        row = entry.line and tonumber(entry.line) or nil,
        col = entry.col and tonumber(entry.col) or nil,
        cwd = fzf_opts and fzf_opts.cwd or vim.fn.getcwd(),
        buf = entry.bufnr,
      }
      items[#items + 1] = loc
    end
    vim.schedule(function()
      cb(items)
    end)
  end
end

function M.send(selected, opts)
  M.action(require("ajans.cli.picker")._send_cb())(selected, opts)
end

return M
