---@module 'luassert'

describe("cli tool runtime configs", function()
  local get_runtime_file

  before_each(function()
    get_runtime_file = vim.api.nvim_get_runtime_file
    package.loaded["ajans.cli.tool"] = nil
  end)

  after_each(function()
    vim.api.nvim_get_runtime_file = get_runtime_file
    package.loaded["ajans.cli.tool"] = nil
  end)

  it("loads bundled tool configs from aj runtime path", function()
    local requested
    vim.api.nvim_get_runtime_file = function(path, all)
      requested = { path = path, all = all }
      return {}
    end

    require("ajans.cli.tool").get("claude")

    assert.are.same({ path = "aj/cli/claude.lua", all = false }, requested)
  end)
end)
