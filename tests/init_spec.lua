---@module 'luassert'

local Ajans = require("ajans")

describe("init module", function()
  it("setup delegates to config", function()
    local called_opts
    local Config = require("ajans.config")
    local original_setup = Config.setup
    Config.setup = function(opts)
      called_opts = opts
    end

    Ajans.setup({ foo = true })
    Config.setup = original_setup

    assert.are.same({ foo = true }, called_opts)
  end)

  it("does not expose NES helpers", function()
    assert.is_nil(Ajans.clear)
    assert.is_nil(Ajans.nes_jump_or_apply)
  end)
end)
