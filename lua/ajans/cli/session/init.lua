local Config = require("ajans.config")
local Util = require("ajans.util")

local M = {}

M.backends = {} ---@type table<string,ajans.cli.Session>
M.did_setup = false
M._attached = {} ---@type table<string,ajans.cli.Session>

---@class ajans.cli.session.State
---@field id string unique id of the running tool (typically pid of tool)
---@field cwd string
---@field tool ajans.cli.Tool|string
---@field pids? integer[] list of pids associated with this session
---@field started? boolean
---@field external? boolean external sessions won't be opened in a terminal
---@field parent? ajans.cli.Session
---@field mux_session? string
---@field mux_backend? string

---@alias ajans.cli.session.Opts ajans.cli.session.State|{cwd?:string,id?:string}

---@class ajans.cli.Session: ajans.cli.session.State
---@field sid string unique id based on tool and cwd
---@field tool ajans.cli.Tool
---@field backend string
---@field dump? fun(self:ajans.cli.Session):string?
local B = {}
B.__index = B
B.priority = 0

--- Send text to the session
---@param text string
function B:send(text)
  error("Backend:send() not implemented")
end

--- Initialize the session backend (optional hook)
function B:init() end

--- Submit the current input to the session
function B:submit()
  error("Backend:submit() not implemented")
end

--- Attach to an existing session
--- If the backend returns a Cmd, a new terminal session will be spawned
---@return ajans.cli.terminal.Cmd?
function B:attach() end

--- Detach from an existing session
function B:detach() end

--- Start a new session
--- If the backend returns a Cmd, a new terminal session will be spawned
---@return ajans.cli.terminal.Cmd?
function B:start()
  error("Backend:start() not implemented")
end

--- Check if the session is still running
--- @return boolean
function B:is_running()
  error("Backend:is_running() not implemented")
end

function B:is_attached()
  return M._attached[self.id] ~= nil
end

--- List all active sessions for this backend
---@return ajans.cli.session.State[]
function B.sessions()
  error("Backend:sessions() not implemented")
end

---@param state ajans.cli.session.Opts
function M.new(state)
  local tool = state.tool
  tool = type(tool) == "string" and Config.get_tool(tool) or tool --[[@as ajans.cli.Tool]]
  local backend = "tmux"
  local super = assert(M.backends[backend], "unknown backend: " .. backend)
  local meta = getmetatable(state)
  local self = setmetatable(state, super) --[[@as ajans.cli.Session]]
  self.tool = tool
  self.cwd = M.cwd(state)
  -- self.cmd = state.cmd or { cmd = tool.cmd, env = tool.env }
  self.backend = backend
  self.sid = M.sid({ tool = tool.name, cwd = self.cwd })
  self.id = self.id or self.sid
  if meta ~= super and self.init then
    self:init()
  end
  return self
end

---@param opts? {cwd?:string}
function M.cwd(opts)
  return vim.fs.normalize(vim.fn.fnamemodify(opts and opts.cwd or vim.fn.getcwd(0), ":p"))
end

---@param opts {tool:string, cwd?:string}
function M.sid(opts)
  local tool = assert(opts and opts.tool, "missing tool")
  local cwd = M.cwd(opts)
  return ("%s %s"):format(tool, vim.fn.sha256(cwd):sub(1, 16 - #tool))
end

---@param name string
---@param backend ajans.cli.Session
function M.register(name, backend)
  if name ~= "tmux" then
    return
  end
  setmetatable(backend, B)
  backend.backend = name
  M.backends[name] = backend
end

function M.setup()
  if M.did_setup then
    return
  end
  M.did_setup = true
  Config.tools() -- load tool configs
  M.register("tmux", require("ajans.cli.session.tmux"))
end

function M.sessions()
  M.setup()
  local ret = {} ---@type ajans.cli.Session[]
  local ids = {} ---@type table<string,boolean>
  for name, backend in pairs(M.backends) do
    for _, s in pairs(backend:sessions()) do
      s.backend = name
      s.started = true
      if ids[s.id] then
        Util.error("duplicate session id: " .. s.id)
      else
        ret[#ret + 1] = M.new(s)
        ids[s.id] = true
        if M._attached[s.id] then
          M._attached[s.id] = ret[#ret] -- update to latest session instance
        end
      end
    end
  end
  for id, session in pairs(M._attached) do
    if session.backend == "terminal" and session.mux_backend == "tmux" and session:is_running() then
      if ids[id] then
        Util.error("duplicate session id: " .. id)
      else
        ret[#ret + 1] = session
        ids[id] = true
      end
    end
  end
  for id in pairs(M._attached) do
    if not ids[id] then -- session is no longer running
      M.detach(M._attached[id])
    end
  end
  return ret
end

---@param session ajans.cli.Session
function M.detach(session)
  if M._attached[session.id] then
    M._attached[session.id] = nil
    session:detach()
    vim.schedule(function()
      Util.emit("AjansCliDetach", { id = session.id })
    end)
  end
  return session
end

---@param session ajans.cli.Session
function M.attach(session)
  if M._attached[session.id] then
    return session
  end
  ---@type ajans.cli.terminal.Cmd?
  local cmd
  if session.started then
    cmd = session:attach()
  else
    cmd = session:start()
  end
  if cmd then
    session = require("ajans.cli.terminal").new({
      tool = session.tool:clone({ cmd = cmd.cmd, env = cmd.env }),
      cwd = session.cwd,
      id = "terminal: " .. session.sid,
      mux_backend = session.backend,
      mux_session = session.mux_session,
      parent = session,
    })
    session:start()
  end
  M._attached[session.id] = session
  vim.schedule(function()
    Util.emit("AjansCliAttach", { id = session.id })
  end)
  return session
end

function M.attached()
  local ret = {} ---@type table<string,ajans.cli.Session>
  for id, s in pairs(M._attached) do
    if s:is_running() then
      ret[id] = s
    else
      M.detach(s)
    end
  end
  return ret
end

return M
