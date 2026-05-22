---@module 'luassert'

local Config = require("ajans.config")

local function setup_config(opts)
  pcall(vim.api.nvim_del_user_command, "Ajans")
  Config.setup(opts)
end

describe("health", function()
  local original_executable
  local original_has
  local original_health

  before_each(function()
    original_executable = vim.fn.executable
    original_has = vim.fn.has
    original_health = vim.health
  end)

  after_each(function()
    vim.fn.executable = original_executable
    vim.fn.has = original_has
    vim.health = original_health
    package.loaded["ajans.health"] = nil
    pcall(vim.api.nvim_del_user_command, "Ajans")
  end)

  it("reports missing tmux even when user supplies legacy mux options", function()
    setup_config({
      cli = {
        mux = {
          enabled = false,
          backend = "screen",
        },
      },
    })

    local oks = {}
    local errors = {}
    vim.health = {
      start = function() end,
      ok = function(message)
        oks[#oks + 1] = message
      end,
      warn = function() end,
      error = function(message)
        errors[#errors + 1] = message
      end,
    }
    vim.fn.has = function(feature)
      return feature == "nvim-0.11.2" and 1 or 0
    end
    vim.fn.executable = function(name)
      return name == "tmux" and 0 or 1
    end

    package.loaded["ajans.health"] = nil
    require("ajans.health").check()

    assert.are.same({ "`tmux` is not installed" }, errors)
    assert.is_false(vim.tbl_contains(oks, "Terminal multiplexer integration is disabled"))
  end)
end)
