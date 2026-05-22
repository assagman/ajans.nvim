local function command_name(cmd)
  local first = cmd:match("^%s*(%S+)") or ""
  return vim.fs.basename(first)
end

---@type ajans.cli.Config
return {
  cmd = { "copilot", "--banner" },
  is_proc = function(_, proc)
    return command_name(proc.cmd) == "copilot"
  end,
  url = "https://github.com/github/copilot-cli",
  resume = { "--resume" },
  continue = { "--continue" },
}
