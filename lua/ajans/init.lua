local M = {}

---@param opts? ajans.Config
function M.setup(opts)
  require("ajans.config").setup(opts)
end

return M
