---@class Mark.Config
local M = {}

---@type Mark.DefaultOptions
M.defaults = {
  skills_dir = vim.fn.stdpath("data") .. "/mark/skills",
  auto_detect = true,
  default_skills = {},
  ui = {
    border = "rounded",
    width = 0.8,
    height = 0.75,
    icons = {
      installed = "●",
      not_installed = "○",
      pending = "◍",
      category = {
        coding = "󰅩",
        review = "󰈈",
        testing = "󰙨",
        documentation = "󰈙",
        refactoring = "󰑕",
        debugging = "󰃤",
        devops = "󰜫",
        architecture = "󰏗",
        security = "󰒃",
        general = "󰘦",
      },
    },
    keymaps = {
      toggle_help = "g?",
      install = "i",
      uninstall = "x",
      update = "u",
      close = "q",
      next_category = "]c",
      prev_category = "[c",
      search = "/",
    },
  },
  integrations = {
    mcphub = { enabled = true },
    copilot_chat = { enabled = true },
    codecompanion = { enabled = true },
    avante = { enabled = true },
    vectorcode = { enabled = true },
    sidekick = { enabled = true },
  },
}

---@type Mark.Options
M.options = {}

---@param opts? Mark.UserOptions
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
