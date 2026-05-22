---@module 'luassert'

local Config = require("ajans.config")
local Session = require("ajans.cli.session")

local function setup_config(opts)
  pcall(vim.api.nvim_del_user_command, "Ajans")
  Config.setup(opts)
end

describe("session mux", function()
  local original_backends
  local original_did_setup
  local original_executable
  local original_attached

  before_each(function()
    original_backends = Session.backends
    original_did_setup = Session.did_setup
    original_executable = vim.fn.executable
    original_attached = Session._attached
    Session.backends = {}
    Session.did_setup = true
    Session._attached = {}
    Session.register("tmux", {})
  end)

  after_each(function()
    Session.backends = original_backends
    Session.did_setup = original_did_setup
    vim.fn.executable = original_executable
    Session._attached = original_attached
    pcall(vim.api.nvim_del_user_command, "Ajans")
  end)

  it("uses tmux regardless of legacy mux options", function()
    setup_config({
      cli = {
        mux = {
          enabled = false,
          backend = "screen",
        },
      },
    })

    local session = Session.new({
      tool = { name = "claude", cmd = { "claude" } },
      cwd = vim.uv.cwd(),
    })

    assert.are.equal("tmux", session.backend)
  end)

  it("uses tmux regardless of supplied state backend", function()
    setup_config()

    local session = Session.new({
      tool = { name = "claude", cmd = { "claude" } },
      cwd = vim.uv.cwd(),
      backend = "terminal",
    })

    assert.are.equal("tmux", session.backend)
  end)

  it("ignores non-tmux backend registration", function()
    Session.register("terminal", {})
    Session.register("screen", {})

    assert.are.same({ "tmux" }, vim.fn.sort(vim.tbl_keys(Session.backends)))
  end)

  it("sets up only tmux as a session backend", function()
    Session.backends = {}
    Session.did_setup = false
    vim.fn.executable = function()
      return 1
    end

    Session.setup()

    assert.are.same({ "tmux" }, vim.fn.sort(vim.tbl_keys(Session.backends)))
  end)

  it("keeps tmux terminal wrappers attached during session refresh", function()
    local cwd = vim.uv.cwd()
    local detached = false
    Session.backends = {}
    Session.register("tmux", {
      sessions = function()
        return {
          {
            id = "tmux 123",
            cwd = cwd,
            tool = { name = "claude", cmd = { "claude" } },
            mux_session = "claude abc",
            pids = { 42 },
          },
        }
      end,
    })
    Session._attached["terminal: claude abc"] = {
      id = "terminal: claude abc",
      sid = "claude abc",
      cwd = cwd,
      tool = { name = "claude", cmd = { "claude" } },
      backend = "terminal",
      mux_backend = "tmux",
      mux_session = "claude abc",
      priority = 100,
      pids = { 42 },
      is_running = function()
        return true
      end,
      detach = function()
        detached = true
      end,
    }

    local sessions = Session.sessions()

    assert.is_false(detached)
    assert.is_not_nil(Session._attached["terminal: claude abc"])
    assert.are.same(
      { "terminal: claude abc", "tmux 123" },
      vim.fn.sort(vim.tbl_map(function(session)
        return session.id
      end, sessions))
    )
  end)
end)
