local M = {}

function M.update()
  local Docs = require("lazy.docs")
  local config = Docs.extract("lua/ajans/config.lua", "\n(--@class ajans%.Config.-\n})")
  config = config:gsub("%s*debug = false,.-\n", "\n")

  -- Save generated config reference into CONFIG.md.
  Docs.save({
    config = config,
  }, "CONFIG.md")

  -- Save suggested user keymaps into KEYMAPS.md.
  Docs.save({
    setup_base = Docs.extract("tests/fixtures/readme.lua", "local base = ({.-\n})"),
  }, "KEYMAPS.md")

  -- Save CLI API, statusline, and picker references into USAGE.md.
  Docs.save({
    api_cli = { content = M.mod("cli") },
    setup_lualine = Docs.extract("tests/fixtures/readme.lua", "local lualine = ({.-\n})"),
    snacks_picker = Docs.extract("tests/fixtures/readme.lua", "local snacks_picker = ({.-\n})"),
  }, "USAGE.md")
end

---@param mod string
function M.mod(mod)
  local commands = vim.tbl_keys(require("ajans.commands").commands[mod]) ---@type string[]
  table.sort(commands)

  local lines = {} ---@type string[]
  local methods = {} ---@type table<string,{name:string,args:string,comment:string}>
  local comment = {} ---@type string[]

  for _, line in ipairs(vim.fn.readfile("lua/ajans/" .. mod .. "/init.lua")) do
    if line:find("^%-%-") then
      comment[#comment + 1] = line
    else
      local name, args = line:match("^function M%.([%w_]+)%((.*)%)")
      if name and not table.concat(comment, "\n"):find("@deprecated", 1, true) then
        methods[name] = {
          name = name,
          args = args,
          comment = table.concat(comment, "\n"),
        }
      end
      if line:match("%S") then
        comment = {}
      end
    end
  end

  lines[#lines + 1] = "<table><tr><th>Cmd</th><th>Lua</th></tr>"

  local names = vim.deepcopy(commands)
  for n in pairs(methods) do
    if not vim.tbl_contains(names, n) then
      names[#names + 1] = n
    end
  end
  table.sort(names)

  for _, cmd in ipairs(names) do
    local method = methods[cmd]
    assert(method, "Missing method: " .. cmd)
    local comments = {} ---@type string[]
    local desc = {} ---@type string[]
    for _, line in ipairs(vim.split(method.comment or "", "\n")) do
      if line:find("^%-%-") and not line:find("^%-%-%-%s*@") then
        desc[#desc + 1] = line:gsub("^%-%-%-?%s?", "")
      else
        comments[#comments + 1] = line
      end
    end

    local code = {} ---@type string[]
    code[#code + 1] = #comments > 0 and table.concat(comments, "\n") or nil
    code[#code + 1] = ('require("ajans.%s").%s(%s)'):format(mod, method.name, method.args or "")
    lines[#lines + 1] = string.format(
      "<tr><td>%s %s</td><td>\n\n\n%s\n\n</td></tr>",
      vim.tbl_contains(commands, cmd) and ("<code>:Ajans %s %s</code>"):format(mod, cmd) or "",
      table.concat(desc, "\n"),
      ("```lua\n%s\n```"):format(table.concat(code, "\n"))
    )
  end
  lines[#lines + 1] = "</table>"
  return table.concat(lines, "\n")
end

M.update()
print("Updated docs")

return M
