---@module 'luassert'

describe("cli tool runtime configs", function()
  before_each(function()
    package.loaded["ajans.cli.tool"] = nil
  end)

  after_each(function()
    package.loaded["ajans.cli.tool"] = nil
  end)

  it("loads bundled tool configs from aj runtime path", function()
    local tool = require("ajans.cli.tool").get("claude")

    assert.are.same({ "claude" }, tool.cmd)
  end)

  it("matches bundled tool processes by executable name", function()
    local tool = require("ajans.cli.tool").get("copilot")

    assert.is_true(tool:is_proc({ cmd = "/opt/bin/copilot --banner" }))
    assert.is_false(tool:is_proc({ cmd = "/opt/bin/copilot-helper" }))
  end)
end)
