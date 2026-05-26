---@module 'luassert'

describe("cli picker", function()
  local original_snacks
  local original_snacks_picker
  local original_telescope_actions
  local original_telescope_state

  before_each(function()
    original_snacks = package.loaded.snacks
    original_snacks_picker = package.loaded["ajans.cli.picker.snacks"]
    original_telescope_actions = package.loaded["telescope.actions"]
    original_telescope_state = package.loaded["telescope.actions.state"]
  end)

  after_each(function()
    package.loaded.snacks = original_snacks
    package.loaded["ajans.cli.picker.snacks"] = original_snacks_picker
    package.loaded["telescope.actions"] = original_telescope_actions
    package.loaded["telescope.actions.state"] = original_telescope_state
    pcall(vim.api.nvim_del_user_command, "Ajans")
  end)

  it("falls back when configured picker module is unavailable", function()
    local Config = require("ajans.config")
    local Picker = require("ajans.cli.picker")
    local fake = { open = function() end }

    package.loaded["ajans.cli.picker.snacks"] = fake
    package.loaded.snacks = {}
    Config.setup({ cli = { picker = "missing-picker" } })

    assert.are.equal(fake, Picker.get())
  end)

  it("formats snacks picker items through state fallback", function()
    local Select = require("ajans.cli.ui.select")
    package.loaded.snacks = {
      picker = {
        format = {
          filename = function(item)
            assert.are.equal("claude", item.tool.name)
            return { { item.file, "Directory" } }
          end,
        },
      },
    }

    local ret = Select.format({
      idx = 1,
      installed = true,
      tool = { name = "claude" },
      session = { cwd = "/tmp/project", backend = "tmux" },
    }, {
      count = function()
        return 1
      end,
    })

    assert.are.equal("/tmp/project", ret[#ret][1])
  end)

  it("validates required select options", function()
    local ok, err = pcall(function()
      require("ajans.cli.ui.select").select({ filter = {} })
    end)

    assert.is_false(ok)
    assert.matches("opts.cb must be a function", tostring(err))
  end)

  it("ignores empty Telescope selections", function()
    local Telescope = require("ajans.cli.picker.telescope")
    package.loaded["telescope.actions"] = { close = function() end }
    package.loaded["telescope.actions.state"] = {
      get_current_picker = function()
        return {
          get_multi_selection = function()
            return {}
          end,
        }
      end,
      get_selected_entry = function()
        return nil
      end,
    }

    local called = false
    Telescope.action(function()
      called = true
    end)(1)

    assert.is_false(called)
  end)
end)
