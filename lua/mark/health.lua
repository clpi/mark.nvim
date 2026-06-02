---@class Mark.Health
local M = {}

---Validate configuration options
local function validate_config()
  local config = require("mark.config")
  local opts = config.options

  if not opts or not opts.skills_dir then
    vim.health.error("mark.nvim is not configured. Call require('mark').setup() first.")
    return
  end

  local ok, err = pcall(function()
    vim.validate({
      skills_dir = { opts.skills_dir, "string" },
      auto_detect = { opts.auto_detect, "boolean" },
    })
  end)

  if not ok then
    vim.health.error("Invalid configuration: " .. tostring(err))
  else
    vim.health.ok("Configuration is valid")
  end
end

---Check skills directory
local function check_skills_dir()
  local config = require("mark.config").options
  if not config.skills_dir then
    vim.health.warn("Skills directory not configured")
    return
  end

  if vim.fn.isdirectory(config.skills_dir) == 1 then
    vim.health.ok("Skills directory exists: " .. config.skills_dir)
  else
    vim.health.info("Skills directory does not exist yet (will be created on first install): " .. config.skills_dir)
  end
end

---Check installed skills
local function check_skills()
  local skills = require("mark.skills")
  skills.init()
  local all = skills.list()
  local installed = skills.installed()
  vim.health.ok(string.format("Skills loaded: %d total, %d installed", #all, #installed))
end

---Check for AI plugin integrations
local function check_integrations()
  local integration_checks = {
    { name = "mcphub", module = "mcphub", label = "MCPHub.nvim" },
    { name = "copilot_chat", module = "CopilotChat", label = "CopilotChat.nvim" },
    { name = "codecompanion", module = "codecompanion", label = "CodeCompanion.nvim" },
    { name = "avante", module = "avante", label = "Avante.nvim" },
    { name = "vectorcode", module = "vectorcode", label = "VectorCode" },
    { name = "sidekick", module = "sidekick", label = "sidekick.nvim" },
  }

  local found = 0
  for _, check in ipairs(integration_checks) do
    local ok = pcall(require, check.module)
    local config = require("mark.config").options.integrations[check.name]
    local enabled = config and config.enabled

    if ok then
      if enabled then
        vim.health.ok(check.label .. " detected and integration enabled")
      else
        vim.health.info(check.label .. " detected but integration disabled in config")
      end
      found = found + 1
    else
      vim.health.info(check.label .. " not installed (optional)")
    end
  end

  if found == 0 then
    vim.health.warn(
      "No AI plugins detected. Install one of: mcphub.nvim, CopilotChat.nvim, "
        .. "codecompanion.nvim, avante.nvim, vectorcode, sidekick.nvim"
    )
  end
end

---Check Neovim version
local function check_neovim()
  if vim.fn.has("nvim-0.11") == 1 then
    vim.health.ok("Neovim >= 0.11")
  else
    vim.health.error("mark.nvim requires Neovim >= 0.11")
  end
end

---Run all health checks
M.check = function()
  vim.health.start("mark.nvim health check")

  check_neovim()
  validate_config()
  check_skills_dir()
  check_skills()
  check_integrations()
end

return M
