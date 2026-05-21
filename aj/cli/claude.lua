---@type ajans.cli.Config
return {
  cmd = { "claude" },
  is_proc = "\\<claude\\>",
  url = "https://github.com/anthropics/claude-code",
  resume = { "--resume" },
  continue = { "--continue" },
  format = function(text)
    local Text = require("ajans.text")

    Text.transform(text, function(str)
      return str:find("[^%w/_%.%-]") and ('"' .. str .. '"') or str
    end, "AjansLocFile")

    local ret = Text.to_string(text)

    -- transform line ranges to a format that Claude understands
    ret = ret:gsub("@([^@]-) :L(%d+)%-L(%d+)", "@%1#L%2-%3")

    return ret
  end,
}
