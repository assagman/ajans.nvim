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

  it("exposes only supported mux options", function()
    local opts = {
      cli = {
        mux = {
          enabled = false,
          backend = "screen",
          ignored = true,
          create = "split",
          split = {
            vertical = false,
            size = 20,
            extra = true,
          },
          dump = 100,
        },
      },
    }

    setup_config(opts)

    assert.is_nil(Config.cli.mux["enabled"])
    assert.is_nil(Config.cli.mux["backend"])
    assert.is_nil(Config.cli.mux["ignored"])
    assert.is_nil(Config.cli.mux.split["extra"])
    assert.are.equal("split", Config.cli.mux.create)
    assert.are.equal(false, Config.cli.mux.split.vertical)
    assert.are.equal(20, Config.cli.mux.split.size)
    assert.are.equal(100, Config.cli.mux.dump)
    assert.is_false(opts.cli.mux["enabled"])
    assert.are.equal("screen", opts.cli.mux["backend"])
    assert.is_true(opts.cli.mux["ignored"])
    assert.is_true(opts.cli.mux.split["extra"])
  end)
end)
