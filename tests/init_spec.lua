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

  it("nes_jump_or_apply returns true only when actions succeed", function()
    local Nes = require("ajans.nes")
    local original_have, original_jump, original_apply = Nes.have, Nes.jump, Nes.apply

    Nes.have = function()
      return true
    end
    Nes.jump = function()
      return false
    end
    Nes.apply = function()
      return true
    end

    assert.is_true(Ajans.nes_jump_or_apply())

    Nes.have = function()
      return false
    end
    Nes.jump = function()
      return true
    end
    Nes.apply = function()
      return false
    end

    assert.is_false(Ajans.nes_jump_or_apply())

    Nes.have, Nes.jump, Nes.apply = original_have, original_jump, original_apply
  end)
end)
