---@type ajans.cli.Config
return {
  cmd = { "gemini" },
  is_proc = "\\<gemini\\>",
  url = "https://github.com/google-gemini/gemini-cli",
  format = function(text)
    local Text = require("ajans.text")
    Text.transform(text, function(str)
      return str:gsub("([^%w/_%.%-])", "\\%1")
    end, "AjansLocFile")
    return Text.to_string(text)
  end,
}
