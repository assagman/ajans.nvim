local Config = require("ajans.config")

---@alias ajans.cli.Action fun(terminal: ajans.cli.Terminal):string?
---@type table<string, ajans.cli.Action>
local M = {}

function M.prompt(t)
  vim.cmd.stopinsert() -- needed, since otherwise Neovim will do this

  vim.schedule(function()
    local Cli = require("ajans.cli")
    Cli.prompt(function(prompt)
      vim.schedule(function()
        vim.cmd.startinsert()
      end)
      if prompt then
        t:send(prompt .. "\n")
      end
    end)
  end)
end

function M.insert_cr()
  vim.schedule(function()
    vim.cmd.startinsert() -- needed, since otherwise Neovim will do this
    vim.api.nvim_feedkeys(vim.keycode("<cr>"), "nx", false)
  end)
end

---@param source string
---@param t ajans.cli.Terminal
local function picker(source, t)
  vim.cmd.stopinsert()
  vim.schedule(function()
    require("ajans.cli.picker").open(source, { filter = { session = t.id } }, {
      on_show = function()
        t.normal_mode = false
      end,
    })
  end)
end

function M.files(t)
  picker("files", t)
end

function M.buffers(t)
  picker("buffers", t)
end

---@param dir "h"|"j"|"k"|"l"
local function nav(dir)
  ---@type ajans.cli.Action
  return function(terminal)
    local at_edge = vim.fn.winnr() == vim.fn.winnr(dir)
    if at_edge or terminal:is_float() then
      return ("<c-%s>"):format(dir)
    end
    vim.schedule(function()
      (Config.cli.win.nav or vim.cmd.wincmd)(dir)
    end)
  end
end

M.nav_left = nav("h")
M.nav_down = nav("j")
M.nav_up = nav("k")
M.nav_right = nav("l")

return M
