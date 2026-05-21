local Util = require("ajans.util")

local M = {}

local patch_file = vim.fn.stdpath("state") .. "/ajans-patch.json"
local patched = false

M.patches = {} ---@type table<string, ajans.NesEdit>

function M.nes_edit()
  vim.cmd.edit(patch_file)
end

function M.nes_save()
  Util.info("Ajans nes patches saved")
  vim.fn.writefile(vim.split(vim.json.encode(M.patches), "\n", { plain = true }), patch_file)
end

function M.nes_load()
  local ok, data = pcall(vim.fn.readfile, patch_file)
  if ok then
    Util.info("Ajans nes patches loaded")
    M.patches = vim.json.decode(table.concat(data, "\n"))
  end
end

function M.nes_add()
  M.nes_load()
  local edit = M.nes_inspect(false)
  if edit then
    M.patches[vim.api.nvim_buf_get_name(0)] = edit
    M.nes_save()
    Util.info("Ajans nes patch added")
  else
    Util.error("No edit found?")
  end
end

function M.nes_del()
  M.nes_load()
  local name = vim.api.nvim_buf_get_name(0)
  if M.patches[name] then
    M.patches[name] = nil
    M.nes_save()
    Util.info("Ajans nes patch removed")
  else
    Util.error("No patch found for this file")
  end
end

---@param show boolean?
function M.nes_inspect(show)
  local edit = require("ajans.nes")._edits[1]
  if not edit then
    return
  end
  edit._diff = nil
  edit.command = nil
  if show ~= false then
    Snacks.debug.inspect(edit)
  end
  return edit
end

function M.nes_patch()
  if patched then
    return Util.error("NES already patched")
  end
  patched = true
  M.nes_load()
  local nes = require("ajans.nes")
  local handler = nes._handler
  ---@diagnostic disable-next-line: duplicate-set-field
  nes._handler = function(err, res, ctx)
    local buf = ctx.bufnr or 0
    local name = vim.api.nvim_buf_get_name(buf)
    local edit = M.patches[name]
    if edit then
      vim.schedule(function()
        Util.warn("Patched `" .. name .. "`")
      end)
      edit.buf = buf
      edit.textDocument = vim.lsp.util.make_text_document_params(buf)
      edit.textDocument.version = vim.lsp.util.buf_versions[buf]
      res = vim.deepcopy({ edits = { edit } })
    end
    return handler(err, res, ctx)
  end
  require("ajans.nes").update()
  Util.warn("Ajans nes patched!")
end

return M
