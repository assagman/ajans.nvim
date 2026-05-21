---@module 'luassert'

local Config = require("ajans.config")
local Status = require("ajans.status")

describe("status handler", function()
  local notify
  local orig_notify
  local orig_get_client

  before_each(function()
    orig_notify = require("ajans.util").notify
    orig_get_client = Config.get_client
    notify = {}
    require("ajans.util").notify = function(msg, level)
      table.insert(notify, { msg = msg, level = level })
    end
    Config.get_client = function()
      return { id = 42 }
    end
  end)

  after_each(function()
    require("ajans.util").notify = orig_notify
    Config.get_client = orig_get_client
  end)

  it("stores status and warns on message", function()
    Status.on_status(nil, {
      busy = true,
      kind = "Warning",
      message = "issue detected",
    }, {
      client_id = 42,
    })

    assert.are.same({
      { msg = "**Copilot:** issue detected", level = vim.log.levels.WARN },
    }, notify)

    assert.are.same({ busy = true, kind = "Warning", message = "issue detected" }, Status.get())
  end)

  it("appends sign-in hint when message mentions not signed", function()
    Status.on_status(nil, {
      busy = false,
      kind = "Error",
      message = "User not signed in",
    }, {
      client_id = 42,
    })

    assert.is_truthy(notify[1])
    assert.matches("SignIn", notify[1].msg)
    assert.are.equal(vim.log.levels.ERROR, notify[1].level)
  end)

  it("get() returns nil when no client", function()
    Config.get_client = function()
      return nil
    end
    assert.is_nil(Status.get())
  end)

  it("attach installs handler", function()
    local handlers = {}
    local client = { handlers = handlers }
    Status.attach(client)
    assert.are.equal(Status.on_status, handlers.didChangeStatus)
  end)
end)
