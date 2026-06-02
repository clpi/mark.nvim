---sidekick.nvim integration
---Provides installed skills as sidekick prompt library entries and context.
local M = {}

---@type boolean
M._registered = false

---Register mark.nvim skills with sidekick.nvim
M.setup = function()
  local ok, _ = pcall(require, "sidekick")
  if not ok then
    return
  end

  if M._registered then
    return
  end

  M._registered = true
end

---Get installed skills as sidekick-compatible prompt library entries
---@return table[] prompts
M.get_prompts = function()
  local skills = require("mark.skills").installed()
  local prompts = {}

  for _, skill in ipairs(skills) do
    if skill.system_prompt then
      table.insert(prompts, {
        name = "mark:" .. skill.name,
        description = skill.description,
        prompt = skill.instruction or skill.system_prompt,
        system_prompt = skill.system_prompt,
      })
    end
  end

  return prompts
end

---Get a combined system prompt for sidekick context injection
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
  M._registered = false
end

return M
