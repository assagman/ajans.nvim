---@module 'luassert'

local Config = require("ajans.config")

describe("config", function()
  it("does not expose NES or Copilot LSP options", function()
    assert.is_nil(Config.nes)
    assert.is_nil(Config.copilot)
    assert.is_nil(Config.get_client)
    assert.is_nil(Config.get_clients)
    assert.is_nil(Config.is_copilot)
  end)

  it("ignores stale NES and Copilot LSP setup options", function()
    Config.setup({
      nes = { enabled = true },
      copilot = { status = { enabled = true } },
    })

    assert.is_nil(Config.nes)
    assert.is_nil(Config.copilot)
  end)
end)
