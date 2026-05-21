local re = vim.regex("\\<copilot\\>")

---@type ajans.cli.Config
return {
  cmd = { "copilot", "--banner" },
  is_proc = function(_, proc)
    return re:match_str(proc.cmd) and not proc.cmd:find("language%-server") or false
  end,
  url = "https://github.com/github/copilot-cli",
  resume = { "--resume" },
  continue = { "--continue" },
}
