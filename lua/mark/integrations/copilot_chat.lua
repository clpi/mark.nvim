---CopilotChat.nvim integration
---Injects installed skill prompts into CopilotChat's prompt system.
local M = {}

---@type boolean
M._registered = false

---Register mark.nvim skills as CopilotChat prompts
M.setup = function()
  local ok, copilot_chat = pcall(require, "CopilotChat")
  if not ok then
    return
  end

  if M._registered then
    return
  end

  local skills = require("mark.skills").installed()
  local prompts = {}

  for _, skill in ipairs(skills) do
    if skill.system_prompt then
      prompts["Mark" .. skill.display_name:gsub("%s+", "")] = {
        prompt = skill.instruction or ("Apply the " .. skill.display_name .. " skill to the selected code."),
        system_prompt = skill.system_prompt,
        description = "[mark.nvim] " .. skill.description,
      }
    end
  end

  -- Merge into CopilotChat config if available
  local config_ok, cc_config = pcall(function()
    return copilot_chat.config or {}
  end)
  if config_ok and cc_config then
    cc_config.prompts = vim.tbl_deep_extend("keep", cc_config.prompts or {}, prompts)
  end

  M._registered = true
end

---Get a system prompt combining all installed skills
---@return string
M.get_system_prompt = function()
  return require("mark.skills").get_combined_prompt()
end

---Handle skill state changes
---@param action "install"|"uninstall"
---@param skill Mark.Skill
M.on_change = function(action, skill)
  local _ = action
  local __ = skill
  -- Re-register on next setup call
  M._registered = false
end

return M
