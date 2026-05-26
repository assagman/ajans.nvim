---@module 'luassert'

describe("cli", function()
  local original_select

  before_each(function()
    original_select = package.loaded["ajans.cli.ui.select"]
  end)

  after_each(function()
    package.loaded["ajans.cli.ui.select"] = original_select
  end)

  it("selects with an empty default filter", function()
    local selected_opts
    package.loaded["ajans.cli.ui.select"] = {
      select = function(opts)
        selected_opts = opts
      end,
    }

    require("ajans.cli").select()

    assert.are.same({}, selected_opts.filter)
    assert.is_function(selected_opts.cb)
  end)
end)
