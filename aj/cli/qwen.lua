---@type ajans.cli.Config
return {
  cmd = { "qwen" },
  is_proc = "\\<qwen\\>",
  url = "https://github.com/QwenLM/qwen-code",
  mux_focus = true, -- qwen needs focus in order to process input
  format = function(text)
    local Text = require("ajans.text")
    Text.transform(text, function(str)
      return str:gsub("([^%w/_%.%-])", "\\%1")
    end, "AjansLocFile")
    return Text.to_string(text)
  end,
}
