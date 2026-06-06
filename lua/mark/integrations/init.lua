---Integration manager: detects available AI plugins and registers skills
local M = {}

---@type table<string, table>
local modules = {
  mcphub = require("mark.integrations.mcphub"),
  copilot_chat = require("mark.integrations.copilot_chat"),
  codecompanion = require("mark.integrations.codecompanion"),
  avante = require("mark.integrations.avante"),
  vectorcode = require("mark.integrations.vectorcode"),
  sidekick = require("mark.integrations.sidekick"),
}

---Set up all enabled integrations
M.setup = function()
  local opts = require("mark.config").options.integrations
  for name, mod in pairs(modules) do
    if opts[name] and opts[name].enabled then
      local ok, err = pcall(mod.setup)
      if not ok then
        vim.notify("[mark.nvim] Integration " .. name .. " error: " .. tostring(err), vim.log.levels.DEBUG)
      end
    end
  end
end

---Notify all integrations of a skill state change
---@param action "install"|"uninstall"|"refresh"
---@param skill Mark.Skill|nil
M.on_skill_change = function(action, skill)
  local opts = require("mark.config").options.integrations
  for name, mod in pairs(modules) do
    if opts[name] and opts[name].enabled and mod.on_change then
      pcall(mod.on_change, action, skill)
    end
  end
end

---Get the combined system prompt from all installed skills
---@return string
M.get_system_prompt = function()
  return require("mark.skills").get_combined_prompt()
end

---Get the integration module by name
---@param name string
---@return table|nil
M.get = function(name)
  return modules[name]
end

---List detected AI plugins
---@return string[]
M.detected = function()
  local result = {}
  local checks = {
    mcphub = "mcphub",
    copilot_chat = "CopilotChat",
    codecompanion = "codecompanion",
    avante = "avante",
    vectorcode = "vectorcode",
    sidekick = "sidekick",
  }
  for key, mod_name in pairs(checks) do
    if pcall(require, mod_name) then
      table.insert(result, key)
    end
  end
  table.sort(result)
  return result
end

return M
