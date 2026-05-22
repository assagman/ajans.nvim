---@module 'luassert'

local Config = require("ajans.config")

describe("config", function()
  it("does not export unknown top-level setup options", function()
    Config.setup({
      cli = { watch = false },
      extra = true,
    })

    assert.is_false(Config.cli.watch)
    assert.is_nil(Config.extra)
  end)
end)
