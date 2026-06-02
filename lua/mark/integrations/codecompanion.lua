---CodeCompanion.nvim integration
---Provides mark.nvim skills as slash commands and system prompt extensions.
local M = {}

---@type boolean
M._registered = false

---Register mark.nvim with CodeCompanion
M.setup = function()
  local ok, _ = pcall(require, "codecompanion")
  if not ok then
    return
  end

  if M._registered then
    return
  end

  local cc_config_ok, cc_config = pcall(require, "codecompanion.config")
  if not cc_config_ok then
    return
  end

  M._register_slash_commands(cc_config)
  M._registered = true
end

---Register slash commands for installed skills
---@param cc_config table
M._register_slash_commands = function(cc_config)
  if not cc_config.interactions then
    return
  end
  local slash_cmds = cc_config.interactions.chat and cc_config.interactions.chat.slash_commands or nil

  if not slash_cmds then
    return
  end

  local skills = require("mark.skills").installed()
  for _, skill in ipairs(skills) do
    if skill.system_prompt then
      slash_cmds["mark_" .. skill.name:gsub("-", "_")] = {
        description = "[mark.nvim] " .. skill.description,
        callback = function(chat)
          if chat and chat.add_message then
            chat:add_message({
              role = "system",
              content = skill.system_prompt,
            })
          end
          return skill.system_prompt
        end,
      }
    end
  end
end

---Get the CodeCompanion extension definition for mark.nvim
---@return table
M.get_extension = function()
  return {
    setup = function(opts)
      local _ = opts
      M.setup()
    end,
    exports = {
      get_skills = function()
        return require("mark.skills").installed()
      end,
      get_system_prompt = function()
        return require("mark.skills").get_combined_prompt()
      end,
    },
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
