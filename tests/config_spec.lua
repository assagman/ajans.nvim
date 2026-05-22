---@module 'luassert'

local Config = require("ajans.config")

local function setup_config(opts)
  pcall(vim.api.nvim_del_user_command, "Ajans")
  Config.setup(opts)
end

describe("config", function()
  after_each(function()
    pcall(vim.api.nvim_del_user_command, "Ajans")
  end)

  it("does not export unknown top-level setup options", function()
    setup_config({
      cli = { watch = false },
      extra = true,
    })

    assert.is_false(Config.cli.watch)
    assert.is_nil(Config.extra)
  end)

  it("does not expose legacy mux toggles as config options", function()
    local opts = {
      cli = {
        mux = {
          enabled = false,
          backend = "screen",
        },
      },
    }

    setup_config(opts)

    assert.is_nil(Config.cli.mux["enabled"])
    assert.is_nil(Config.cli.mux["backend"])
    assert.is_false(opts.cli.mux["enabled"])
    assert.are.equal("screen", opts.cli.mux["backend"])
  end)
end)
