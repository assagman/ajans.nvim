local Config = require("ajans.config")

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

  if Config.cli.mux.enabled then
    ok("Terminal multiplexer integration is enabled")
  else
    ok("Terminal multiplexer integration is disabled")
  end

  for _, mux in ipairs({ "tmux", "zellij" }) do
    if vim.fn.executable(mux) == 1 then
      ok("`" .. mux .. "` is installed")
    elseif mux == Config.cli.mux.backend then
      error("Multiplexer backend `" .. mux .. "` is not installed")
    else
      ok("`" .. mux .. "` is not installed, but it's not the configured backend")
    end
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
    if vim.fn.executable(tool.cmd[1]) == 1 then
      ok("`" .. tool.name .. "` is installed")
    else
      warn("`" .. tool.name .. "` is not installed")
    end
  end
end

return M
