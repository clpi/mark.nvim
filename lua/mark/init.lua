---@class Mark.Plugin
local M = {}

---Configure and initialize mark.nvim
---@param opts? Mark.UserOptions
M.setup = function(opts)
  require("mark.config").setup(opts)

  local config = require("mark.config").options

  local ok = pcall(vim.fn.mkdir, config.skills_dir, "p")
  if not ok then
    vim.notify("[mark.nvim] Failed to create skills directory: " .. config.skills_dir, vim.log.levels.ERROR)
  end

  require("mark.skills").init()

  if config.auto_detect then
    vim.schedule(function()
      require("mark.integrations").setup()
    end)
  end
end

---Open the skills browser UI
M.open = function()
  require("mark.ui").open()
end

---Close the skills browser UI
M.close = function()
  require("mark.ui").close()
end

---Toggle the skills browser UI
M.toggle = function()
  require("mark.ui").toggle()
end

---Install a skill by name
---@param name string
---@return boolean
M.install = function(name)
  return require("mark.skills").install(name)
end

---Uninstall a skill by name
---@param name string
---@return boolean
M.uninstall = function(name)
  return require("mark.skills").uninstall(name)
end

---Get a skill by name
---@param name string
---@return Mark.Skill|nil
M.get_skill = function(name)
  return require("mark.skills").get(name)
end

---List all known skills
---@return Mark.Skill[]
M.list_skills = function()
  return require("mark.skills").list()
end

---List skills with pending updates
---@return Mark.Skill[]
M.list_updatable = function()
  return require("mark.skills").list_updatable()
end

---Get all installed skills
---@return Mark.Skill[]
M.get_installed = function()
  return require("mark.skills").installed()
end

---Add a user-defined skill at runtime
---@param def table Skill definition table
---@return boolean success
M.add_skill = function(def)
  return require("mark.skills").add(def)
end

---Get the combined system prompt for all installed skills
---@return string
M.get_system_prompt = function()
  return require("mark.skills").get_combined_prompt()
end

---Update a skill to its latest version
---@param name string
---@return boolean
M.update = function(name)
  return require("mark.skills").update(name)
end

---Get the integration module for a specific AI plugin
---@param name string Integration name (mcphub, copilot_chat, codecompanion, avante, vectorcode, sidekick)
---@return table|nil
M.integration = function(name)
  return require("mark.integrations").get(name)
end

---Refresh remote registries (async) and reload all skills
---@param callback? fun(success: boolean)
M.refresh = function(callback)
  require("mark.skills").refresh(callback)
end

---List configured remote registries
---@return Mark.RemoteRegistryDefinition[]
M.registries = function()
  return require("mark.skills.remote").list_registries()
end

return M
