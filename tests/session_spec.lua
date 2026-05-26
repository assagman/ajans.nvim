---@module 'luassert'

local Config = require("ajans.config")
local Session = require("ajans.cli.session")
local State = require("ajans.cli.state")
local Util = require("ajans.util")

local function setup_config(opts)
  pcall(vim.api.nvim_del_user_command, "Ajans")
  Config.setup(opts)
end

local function test_tool()
  local tool = { name = "claude", cmd = { "claude" } }
  function tool:clone(opts)
    local clone = vim.tbl_deep_extend("force", {
      name = self.name,
      cmd = vim.deepcopy(self.cmd),
    }, opts or {})
    clone.clone = self.clone
    return clone
  end
  return tool
end

local function assert_cmd_pair(cmd, key, value)
  for index = 1, #cmd - 1 do
    if cmd[index] == key and cmd[index + 1] == value then
      return
    end
  end
  error(("expected command to contain %s %s, got %s"):format(key, value, table.concat(cmd, " ")))
end

describe("session mux", function()
  local original_backends
  local original_did_setup
  local original_executable
  local original_attached
  local original_tmux
  local original_exec
  local original_info
  local original_terminal

  before_each(function()
    original_backends = Session.backends
    original_did_setup = Session.did_setup
    original_executable = vim.fn.executable
    original_attached = Session._attached
    original_tmux = vim.env.TMUX
    original_exec = Util.exec
    original_info = Util.info
    original_terminal = package.loaded["ajans.cli.terminal"]
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
    vim.env.TMUX = original_tmux
    Util.exec = original_exec
    Util.info = original_info
    package.loaded["ajans.cli.terminal"] = original_terminal
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

  it("reports attached tmux terminal wrappers through state refresh", function()
    setup_config()
    local Terminal = require("ajans.cli.terminal")
    Terminal.terminals = {}
    local terminal = Terminal.new({
      tool = test_tool(),
      cwd = vim.uv.cwd(),
      id = "terminal: claude abc",
      mux_backend = "tmux",
      mux_session = "claude abc",
      parent = { dump = function() end },
    })
    terminal.is_running = function()
      return true
    end
    Session._attached[terminal.id] = terminal

    local states = State.get({ attached = true })

    assert.are.equal(1, #states)
    assert.is_true(states[1].attached)
    assert.are.equal(terminal, states[1].session)
  end)

  it("rejects direct non-tmux terminal sessions", function()
    setup_config()

    local ok, err = pcall(function()
      require("ajans.cli.terminal").new({
        tool = test_tool(),
        cwd = vim.uv.cwd(),
      })
    end)

    assert.is_false(ok)
    assert.matches("terminal sessions require tmux", tostring(err))
  end)

  it("wraps tmux start commands in terminal sessions", function()
    local cwd = vim.uv.cwd()
    local started = 0
    local terminal_opts
    local backend = {}
    backend.__index = backend
    function backend:start()
      self.mux_session = self.sid
      return { cmd = { "tmux", "new", "-A", "-s", self.sid } }
    end
    Session.backends = {}
    Session.register("tmux", backend)
    package.loaded["ajans.cli.terminal"] = {
      new = function(opts)
        terminal_opts = opts
        opts.backend = "terminal"
        opts.start = function(self)
          started = started + 1
          self.started = true
        end
        opts.is_running = function()
          return true
        end
        return opts
      end,
    }

    local parent = Session.new({ tool = test_tool(), cwd = cwd })
    local attached = Session.attach(parent)

    assert.are.equal(1, started)
    assert.are.equal("terminal: " .. parent.sid, attached.id)
    assert.are.equal("tmux", attached.mux_backend)
    assert.are.equal(parent.mux_session, attached.mux_session)
    assert.are.equal(parent, attached.parent)
    assert.are.equal(attached, Session._attached[attached.id])
    assert.are.same({ "tmux", "new", "-A", "-s", parent.sid }, terminal_opts.tool.cmd)
  end)

  it("returns a terminal tmux command outside tmux", function()
    local cwd = vim.uv.cwd()
    vim.env.TMUX = nil
    setup_config({ cli = { mux = { create = "terminal" } } })
    Session.backends = {}
    Session.register("tmux", require("ajans.cli.session.tmux"))

    local session = Session.new({ tool = test_tool(), cwd = cwd })
    local cmd = session:start()

    assert.is_nil(session.external)
    assert.are.equal("tmux", cmd.cmd[1])
    assert.are.equal("new", cmd.cmd[2])
    assert_cmd_pair(cmd.cmd, "-c", cwd)
    assert.is_true(vim.tbl_contains(cmd.cmd, "claude"))
  end)

  it("returns a terminal tmux command inside tmux when create is terminal", function()
    local cwd = vim.uv.cwd()
    vim.env.TMUX = "/tmp/tmux-1000/default,1,0"
    setup_config({ cli = { mux = { create = "terminal" } } })
    Session.backends = {}
    Session.register("tmux", require("ajans.cli.session.tmux"))

    local session = Session.new({ tool = test_tool(), cwd = cwd })
    local cmd = session:start()

    assert.is_false(session.external)
    assert.are.equal("tmux", cmd.cmd[1])
    assert.are.equal("new", cmd.cmd[2])
    assert_cmd_pair(cmd.cmd, "-c", cwd)
    assert.is_true(vim.tbl_contains(cmd.cmd, "claude"))
  end)

  it("starts a tmux window inside tmux", function()
    local cwd = vim.uv.cwd()
    local exec_calls = {}
    vim.env.TMUX = "/tmp/tmux-1000/default,1,0"
    setup_config({ cli = { mux = { create = "window" } } })
    Session.backends = {}
    Session.register("tmux", require("ajans.cli.session.tmux"))
    Util.exec = function(cmd, opts)
      exec_calls[#exec_calls + 1] = { cmd = vim.deepcopy(cmd), opts = vim.deepcopy(opts or {}) }
      return { ("$1:%%2:4321:main:%s"):format(cwd) }
    end
    Util.info = function() end

    local session = Session.new({ tool = test_tool(), cwd = cwd })
    local cmd = session:start()

    assert.is_nil(cmd)
    assert.is_true(session.external)
    assert.are.equal("tmux 4321", session.id)
    assert.are.equal("%2", session.tmux_pane_id)
    assert.are.equal(4321, session.tmux_pid)
    assert.are.equal("new-window", exec_calls[1].cmd[2])
    assert_cmd_pair(exec_calls[1].cmd, "-c", cwd)
    assert.is_true(vim.tbl_contains(exec_calls[1].cmd, "claude"))
  end)

  for _, case in ipairs({
    { name = "vertical percent", split = { vertical = true, size = 0.5 }, flag = "-h", size = "50%" },
    { name = "horizontal cells", split = { vertical = false, size = 20 }, flag = "-v", size = "20" },
  }) do
    it("starts a tmux split inside tmux with " .. case.name, function()
      local cwd = vim.uv.cwd()
      local exec_calls = {}
      vim.env.TMUX = "/tmp/tmux-1000/default,1,0"
      setup_config({ cli = { mux = { create = "split", split = case.split } } })
      Session.backends = {}
      Session.register("tmux", require("ajans.cli.session.tmux"))
      Util.exec = function(cmd, opts)
        exec_calls[#exec_calls + 1] = { cmd = vim.deepcopy(cmd), opts = vim.deepcopy(opts or {}) }
        return { ("$1:%%3:4322:main:%s"):format(cwd) }
      end
      Util.info = function() end

      local session = Session.new({ tool = test_tool(), cwd = cwd })
      local cmd = session:start()

      assert.is_nil(cmd)
      assert.is_true(session.external)
      assert.are.equal("tmux 4322", session.id)
      assert.are.equal("%3", session.tmux_pane_id)
      assert.are.equal("split-window", exec_calls[1].cmd[2])
      assert.is_true(vim.tbl_contains(exec_calls[1].cmd, case.flag))
      assert_cmd_pair(exec_calls[1].cmd, "-l", case.size)
      assert_cmd_pair(exec_calls[1].cmd, "-c", cwd)
    end)
  end
end)
