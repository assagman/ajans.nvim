local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error

function M.check()
  start("Ajans")

  if vim.fn.has("nvim-0.11.2") == 1 then
    ok("Using Neovim >= 0.11.2")
  else
    error("Neovim >= 0.11.2 is required")
    return
  end

  start("Ajans AI CLI")
  if vim.o.autoread then
    ok("autoread is enabled")
  else
    warn("autoread is disabled, file changes from AI CLI tools will not be detected automatically")
  end

  if vim.fn.executable("tmux") == 1 then
    ok("Terminal multiplexer `tmux` is installed")
  else
    error("Terminal multiplexer `tmux` is not installed")
  end

  if vim.fn.has("win32") == 0 then
    for _, c in ipairs({ "ps", "lsof" }) do
      if vim.fn.executable(c) == 1 then
        ok("`" .. c .. "` is installed")
      else
        warn("`" .. c .. "` is not installed, running processes and ports will not be detected")
      end
    end
  end

  start("Ajans AI CLI Tools")
  local tools = require("ajans.config").tools()
  local tool_names = vim.tbl_keys(tools) ---@type string[]
  table.sort(tool_names)
  for _, name in ipairs(tool_names) do
    local tool = tools[name]
    local tool_name = tool.name or name
    if tool.cmd and #tool.cmd > 0 and vim.fn.executable(tool.cmd[1]) == 1 then
      ok("`" .. tool_name .. "` is installed")
    else
      warn("`" .. tool_name .. "` is not installed")
    end
  end
end

return M
