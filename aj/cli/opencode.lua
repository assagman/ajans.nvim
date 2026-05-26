---@type ajans.cli.Config
return {
  cmd = { "opencode" },
  env = {
    -- HACK: https://github.com/sst/opencode/issues/445
    OPENCODE_THEME = "system",
  },
  keys = {
    prompt = { "<a-p>", "prompt" },
  },
  is_proc = "\\<opencode\\>",
  url = "https://github.com/sst/opencode",
  continue = { "--continue" },
  native_scroll = true,
}
