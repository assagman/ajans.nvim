---@module 'luassert'

local Config = require("ajans.config")
local Nes = require("ajans.nes")

describe("nes enabled option", function()
  local buf
  local original_enabled

  before_each(function()
    original_enabled = Config.nes.enabled
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local foo" })
    vim.api.nvim_set_current_buf(buf)
    vim.g.ajans_nes = nil
    vim.b[buf].ajans_nes = nil
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.g.ajans_nes = nil
    vim.b.ajans_nes = nil
    Config.nes.enabled = original_enabled
    Nes._edits = {}
  end)

  it("is enabled by default", function()
    assert.is_true(Config.nes.enabled(buf))
  end)

  it("honors global toggle", function()
    vim.g.ajans_nes = false
    assert.is_false(Config.nes.enabled(buf))
  end)

  it("honors buffer toggle", function()
    vim.b[buf].ajans_nes = false
    assert.is_false(Config.nes.enabled(buf))
  end)

  it("filters pending edits when disabled", function()
    local version = vim.lsp.util.buf_versions[buf] or 0
    vim.lsp.util.buf_versions[buf] = version
    ---@type ajans.NesEdit
    Nes._edits = {
      {
        buf = buf,
        from = { 0, 0 },
        to = { 0, 0 },
        text = "",
        range = {
          start = { line = 0, character = 0 },
          ["end"] = { line = 0, character = 0 },
        },
        textDocument = { uri = "", version = version },
        command = { title = "", command = "" },
      },
    }

    vim.g.ajans_nes = false
    assert.are.same({}, Nes.get(buf))
  end)
end)
