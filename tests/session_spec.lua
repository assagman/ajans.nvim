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

  before_each(function()
    original_backends = Session.backends
    original_did_setup = Session.did_setup
    original_executable = vim.fn.executable
    Session.backends = {}
    Session.did_setup = true
    Session.register("tmux", {})
    Session.register("screen", {})
    Session.register("terminal", {})
  end)

  after_each(function()
    Session.backends = original_backends
    Session.did_setup = original_did_setup
    vim.fn.executable = original_executable
    pcall(vim.api.nvim_del_user_command, "Ajans")
  end)

  it("uses tmux when mux is enabled regardless of supplied backend", function()
    setup_config({
      cli = {
        mux = {
          enabled = true,
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

  it("sets up only tmux and terminal backends", function()
    Session.backends = {}
    Session.did_setup = false
    vim.fn.executable = function()
      return 1
    end

    Session.setup()

    assert.are.same({ "terminal", "tmux" }, vim.fn.sort(vim.tbl_keys(Session.backends)))
  end)
end)
