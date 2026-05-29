---@type ajans.cli.Config
return {
  cmd = { "agy" },
  is_proc = "\\<agy\\>",
  url = "https://antigravity.google",
  format = function(text)
    local Text = require("ajans.text")
    Text.transform(text, function(str)
      return str:gsub("([^%w/_%.%-])", "\\%1")
    end, "AjansLocFile")
    return Text.to_string(text)
  end,
}
