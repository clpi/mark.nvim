---Avante.nvim integration
---Injects installed skill prompts into Avante's system prompt and context.
local M = {}

---@type boolean
M._registered = false

---Register mark.nvim skills with Avante
M.setup = function()
  local ok, _ = pcall(require, "avante")
  if not ok then
    return
  end

  if M._registered then
    return
  end

  M._registered = true
end

---Build an Avante system prompt extension from installed skills
---@return string
M.get_system_prompt = function()
  local skills = require("mark.skills").installed()
  if #skills == 0 then
    return ""
  end

  local parts = { "## Active Skills (via mark.nvim)\n" }
  for _, skill in ipairs(skills) do
    if skill.system_prompt then
      table.insert(parts, "### " .. skill.display_name)
      table.insert(parts, skill.system_prompt)
      table.insert(parts, "")
    end
  end
  return table.concat(parts, "\n")
end

---Get a custom provider configuration snippet that wraps an existing provider
---with mark.nvim skills injected. Users add this to their Avante config.
---@param base_provider? string Base provider to inherit from (default: "openai")
---@return table
M.get_provider_wrapper = function(base_provider)
  return {
    __inherited_from = base_provider or "openai",
    -- Users should set their own endpoint, model, api_key_name
    -- This wrapper demonstrates how to inject skills into the system prompt
    _mark_skills_prompt = M.get_system_prompt(),
  }
end

---Handle skill state changes
---@param action "install"|"uninstall"
---@param skill Mark.Skill
M.on_change = function(action, skill)
  local _ = action
  local __ = skill
  M._registered = false
end

return M
