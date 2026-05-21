local Util = require("ajans.util")

local M = {}

---@alias ajans.command.Args table<string, any>
---@alias ajans.command.Fn fun(args: ajans.command.Args)
---@alias ajans.command.Cmd ajans.command.Fn | table<string, ajans.command.Cmd>

---@type ajans.command.Cmd
M.commands = {
  nes = {
    apply = function()
      require("ajans.nes").apply()
    end,
    enable = function()
      require("ajans.nes").enable(true)
    end,
    disable = function()
      require("ajans.nes").enable(false)
    end,
    toggle = function()
      require("ajans.nes").toggle()
    end,
    update = function()
      require("ajans.nes").update()
    end,
    clear = function()
      require("ajans.nes").clear()
    end,
    jump = function()
      require("ajans.nes").jump()
    end,
  },
  cli = {
    show = function(opts)
      require("ajans.cli").show(opts)
    end,
    toggle = function(opts)
      require("ajans.cli").toggle(opts)
    end,
    hide = function(opts)
      require("ajans.cli").hide(opts)
    end,
    close = function(opts)
      require("ajans.cli").close(opts)
    end,
    focus = function(opts)
      require("ajans.cli").focus(opts)
    end,
    select = function(opts)
      require("ajans.cli").select(opts)
    end,
    send = function(opts)
      require("ajans.cli").send(opts)
    end,
    prompt = function()
      require("ajans.cli").prompt()
    end,
  },
  debug = {
    nes = {
      add = function()
        require("ajans.debug").nes_add()
      end,
      del = function()
        require("ajans.debug").nes_del()
      end,
      patch = function()
        require("ajans.debug").nes_patch()
      end,
      edit = function()
        require("ajans.debug").nes_edit()
      end,
      inspect = function()
        require("ajans.debug").nes_inspect()
      end,
    },
  },
}

---@param str string
---@param opts? {error?: boolean}
function M.argparse(str, opts)
  ---@type ajans.command.Args
  local ret, ok = {}, true
  local env = setmetatable({ vim = vim }, {
    __newindex = function(_, k, v)
      ret[k] = v
    end,
    __index = function(_, k)
      return k
    end,
  })
  local function on_error(err)
    ok = false
    return (opts or {}).error ~= false and Util.error(("Invalid args: `%s`\nError: %s"):format(str, err))
  end
  xpcall(function()
    local chunk, err = load(str, "ajans", "t", env)
    return chunk and (chunk() or true) or on_error(err)
  end, on_error)
  return ok and ret or nil
end

---@param str string
---@param opts? {error?: boolean}
---@overload fun(str: string): ajans.command.Fn, ajans.command.Args?
---@overload fun(str: string): string[]
function M.parse(str, opts)
  local parts = vim.split(str, "%s+")
  local cmd = M.commands
  while #parts > 0 and type(cmd) == "table" do
    if cmd[parts[1]] then
      cmd = cmd[table.remove(parts, 1)]
    else
      break
    end
  end
  if type(cmd) == "function" then
    return cmd, M.argparse(table.concat(parts, " "), opts)
  end
  local prefix = #parts > 0 and parts[1] or ""
  ---@param key string
  return vim.tbl_filter(function(key)
    return key:find(prefix) == 1 and key ~= "debug"
  end, vim.tbl_keys(cmd))
end

---@param line string
function M.complete(line)
  line = line:gsub("^%s*Ajans%s+", "")
  local cmd = M.parse(line, { error = false })
  return type(cmd) == "table" and cmd or {}
end

---@param line vim.api.keyset.create_user_command.command_args
function M.cmd(line)
  local cmd, args = M.parse(line.args or "")
  if type(cmd) == "function" and args then
    if line.range and line.range > 0 then
      vim.fn.feedkeys("gv", "nx") -- restore visual selection
    end
    cmd(args)
  elseif type(cmd) == "table" and #cmd > 0 then
    Util.error(("Incomplete command: `%s`\nExpecting: `[%s]`"):format(line.args or "", table.concat(cmd, "|")))
  elseif type(cmd) ~= "function" then
    Util.error(("Invalid command: `%s`"):format(line.args or ""))
  end
end

return M
