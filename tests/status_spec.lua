---@module 'luassert'

local Session = require("ajans.cli.session")
local Status = require("ajans.status")

describe("status", function()
  local original_attached

  before_each(function()
    original_attached = Session.attached
  end)

  after_each(function()
    Session.attached = original_attached
  end)

  it("returns attached CLI sessions", function()
    Session.attached = function()
      return {
        claude = {
          id = "claude",
          tool = { name = "claude" },
          cwd = "/tmp/project",
        },
      }
    end

    Status.setup()

    assert.are.same({
      {
        id = "claude",
        tool = "claude",
        cwd = "/tmp/project",
      },
    }, Status.cli())
  end)

  it("does not expose Copilot LSP status helpers", function()
    assert.is_nil(Status.get)
    assert.is_nil(Status.attach)
    assert.is_nil(Status.on_status)
  end)
end)
