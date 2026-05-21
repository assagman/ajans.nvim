---@type ajans.cli.Config
return {
  cmd = { "gemini" },
  is_proc = "\\<gemini\\>",
  url = "https://github.com/google-gemini/gemini-cli",
  format = function(text)
    require("ajans.text").transform(text, function(str)
      return str:gsub("([^%w/_%.%-])", "\\%1")
    end, "AjansLocFile")
  end,
}
