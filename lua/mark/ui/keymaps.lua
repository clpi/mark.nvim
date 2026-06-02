local M = {}

---Set up keymaps for the skill browser buffer
---@param bufnr integer
---@param actions table<string, function>
M.setup = function(bufnr, actions)
  local keymaps = require("mark.config").options.ui.keymaps
  local map = function(lhs, cb, desc)
    vim.keymap.set("n", lhs, cb, { buffer = bufnr, nowait = true, silent = true, desc = desc })
  end

  map(keymaps.install, actions.install, "Install skill")
  map(keymaps.uninstall, actions.uninstall, "Uninstall skill")
  map(keymaps.update, actions.update, "Update skill")
  map(keymaps.close, actions.close, "Close mark.nvim")
  map("<Esc>", actions.escape, "Clear filter / close help")
  map(keymaps.toggle_help, actions.toggle_help, "Toggle help")
  map(keymaps.search, actions.search, "Search skills")
  map(keymaps.next_category, actions.next_category, "Next category")
  map(keymaps.prev_category, actions.prev_category, "Previous category")
  map("<CR>", actions.details, "Show skill details")

  map("1", actions.view_all, "View all skills")
  map("2", actions.view_installed, "View installed skills")
  map("3", actions.view_available, "View available skills")
end

return M
