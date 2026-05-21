local Config = require("ajans.config")
local Nes = require("ajans.nes")
local Util = require("ajans.util")

local M = {}

---@param edit ajans.NesEdit
function M.render(edit)
  vim.b[edit.buf].ajans_nes_ui = true
  local diff = edit:diff()

  if #diff.hunks == 0 then
    Util.debug("No hunks in edit", edit)
    return
  end

  local from, to = edit.from, edit.to

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local at_edit = vim.api.nvim_get_current_buf() == edit.buf and row >= from[1] and row <= to[1]

  local show_sign = Config.nes.signs or Config.nes.diff.show == "cursor"
  local show_diff = Config.nes.diff.show == "always" or at_edit

  if show_sign then
    -- Add the sign at the first position
    Util.set_extmark(edit.buf, Config.ns, from[1], 0, {
      sign_text = Config.ui.icons.nes,
      sign_hl_group = "AjansSign",
    })
  end

  if not show_diff then
    return
  end

  local rows = {} ---@type table<number, true>
  for _, hunk in ipairs(diff.hunks) do
    if not hunk.inline then
      for r = hunk.pos[1], hunk.pos[1] + hunk.cover - 1 do
        rows[r] = true
      end
    end
    for _, extmark in ipairs(hunk.extmarks) do
      local opts = vim.tbl_extend("force", {}, extmark) ---@type ajans.Extmark
      opts.row, opts.col = nil, nil
      Util.set_extmark(edit.buf, Config.ns, extmark.row, extmark.col, opts)
    end
  end

  -- Only add the context bg for lines not yet touched by the rest including inline
  -- This is to fix an issue with extmarks otherwise not displayig correctly
  -- Additionally line_hl_group seems broken in some cases, so don't use that.
  for r = from[1], math.min(vim.api.nvim_buf_line_count(edit.buf) - 1, to[1]) do
    if not rows[r] then
      Util.set_extmark(edit.buf, Config.ns, r, 0, {
        end_row = r + 1,
        hl_group = "AjansDiffContext",
        hl_eol = true,
      })
    end
  end
end

---@param buf number
function M._hide(buf)
  if vim.b[buf].ajans_nes_ui then
    vim.b[buf].ajans_nes_ui = nil
    vim.api.nvim_buf_clear_namespace(buf, Config.ns, 0, -1)
  end
end

function M.update()
  local edits = Nes.get()
  M.hide()
  vim.tbl_map(M.render, edits)

  vim.schedule(function()
    Util.emit("AjansNes" .. (#edits == 0 and "Hide" or "Show"))
  end)
end

function M.hide()
  vim.tbl_map(M._hide, vim.api.nvim_list_bufs())
end

return M
