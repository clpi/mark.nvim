local registry = require("mark.skills.registry")
local loader = require("mark.skills.loader")
local remote = require("mark.skills.remote")

---@class Mark.SkillManager
local M = {}

---@type table<string, Mark.Skill>
M._skills = {}

---@type boolean
M._initialized = false

---@type boolean
M._refreshing = false

---Initialize the skill manager: load builtin + user + remote skills, restore install state
M.init = function()
  if M._initialized then
    return
  end
  M._skills = {}

  for _, s in ipairs(registry.get_builtin_skills()) do
    M._skills[s.name] = s
  end

  local config = require("mark.config").options

  local user_skills = loader.load_directory(config.skills_dir)
  for _, s in ipairs(user_skills) do
    M._skills[s.name] = s
  end

  local remote_skills = remote.fetch_all()
  for _, s in ipairs(remote_skills) do
    if not M._skills[s.name] then
      M._skills[s.name] = s
    end
  end

  local installed_names = loader.load_installed(config.skills_dir)
  for _, name in ipairs(installed_names) do
    if M._skills[name] then
      M._skills[name].installed = true
    end
  end

  if #installed_names == 0 and #config.default_skills > 0 then
    for _, name in ipairs(config.default_skills) do
      if M._skills[name] then
        M._skills[name].installed = true
      end
    end
    M._save_state()
  end

  remote.check_updates(M._skills, remote_skills)

  M._initialized = true
end

---Get a skill by name
---@param name string
---@return Mark.Skill|nil
M.get = function(name)
  M.init()
  return M._skills[name]
end

---List all skills
---@return Mark.Skill[]
M.list = function()
  M.init()
  local result = {}
  for _, s in pairs(M._skills) do
    table.insert(result, s)
  end
  table.sort(result, function(a, b)
    if a.category == b.category then
      return a.name < b.name
    end
    return a.category < b.category
  end)
  return result
end

---List installed skills
---@return Mark.Skill[]
M.installed = function()
  M.init()
  local result = {}
  for _, s in pairs(M._skills) do
    if s.installed then
      table.insert(result, s)
    end
  end
  table.sort(result, function(a, b)
    return a.name < b.name
  end)
  return result
end

---Install a skill
---@param name string
---@return boolean success
M.install = function(name)
  M.init()
  local s = M._skills[name]
  if not s then
    vim.notify("[mark.nvim] Skill not found: " .. name, vim.log.levels.WARN)
    return false
  end
  if s.installed then
    return true
  end
  s.installed = true
  M._save_state()
  M._notify_integrations("install", s)
  vim.notify("[mark.nvim] Installed: " .. s.display_name, vim.log.levels.INFO)
  return true
end

---Uninstall a skill
---@param name string
---@return boolean success
M.uninstall = function(name)
  M.init()
  local s = M._skills[name]
  if not s then
    vim.notify("[mark.nvim] Skill not found: " .. name, vim.log.levels.WARN)
    return false
  end
  if not s.installed then
    return true
  end
  s.installed = false
  M._save_state()
  M._notify_integrations("uninstall", s)
  vim.notify("[mark.nvim] Uninstalled: " .. s.display_name, vim.log.levels.INFO)
  return true
end

---Toggle a skill's installed state
---@param name string
---@return boolean new_state
M.toggle = function(name)
  M.init()
  local s = M._skills[name]
  if not s then
    return false
  end
  if s.installed then
    M.uninstall(name)
    return false
  else
    M.install(name)
    return true
  end
end

---Refresh remote registries asynchronously, updating skills in-place
---@param callback fun(success: boolean)?
M.refresh = function(callback)
  if M._refreshing then
    return
  end
  M._refreshing = true
  M.init()
  vim.notify("[mark.nvim] Refreshing remote registries...", vim.log.levels.INFO)
  remote.force_refresh_async(function(success)
    M._initialized = false
    M._refreshing = false
    M.init()
    local updatable = M.list_updatable()
    if #updatable > 0 then
      vim.notify(
        "[mark.nvim] " .. #updatable .. " skill(s) have updates available (press 'u' to update)",
        vim.log.levels.INFO
      )
    end
    M._notify_integrations("refresh", nil)
    if callback then
      callback(success)
    end
  end)
end

---Update a skill to its latest version from the remote registry
---@param name string
---@return boolean success
M.update = function(name)
  M.init()
  local s = M._skills[name]
  if not s then
    vim.notify("[mark.nvim] Skill not found: " .. name, vim.log.levels.WARN)
    return false
  end
  if not s.pending_update then
    vim.notify("[mark.nvim] No update available for: " .. s.display_name, vim.log.levels.INFO)
    return false
  end

  local update = s.pending_update
  s.name = update.name
  s.display_name = update.display_name
  s.description = update.description
  s.long_description = update.long_description
  s.category = update.category
  s.tags = update.tags
  s.author = update.author
  s.version = update.version
  s.system_prompt = update.system_prompt
  s.instruction = update.instruction
  s.context_template = update.context_template
  s.integrations = update.integrations
  s.pending_update = nil

  vim.notify("[mark.nvim] Updated: " .. s.display_name .. " to v" .. s.version, vim.log.levels.INFO)
  return true
end

---List skills that have pending updates available
---@return Mark.Skill[]
M.list_updatable = function()
  M.init()
  local result = {}
  for _, s in pairs(M._skills) do
    if s.installed and s.pending_update then
      table.insert(result, s)
    end
  end
  table.sort(result, function(a, b)
    return a.name < b.name
  end)
  return result
end

---Add a user-defined skill at runtime
---@param def table Skill definition
---@return boolean success
M.add = function(def)
  M.init()
  local ok, s = pcall(require("mark.skills.skill").new, def)
  if not ok then
    vim.notify("[mark.nvim] Invalid skill definition", vim.log.levels.ERROR)
    return false
  end
  s.source = "user"
  M._skills[s.name] = s
  return true
end

---Get the combined system prompt for all installed skills
---@return string
M.get_combined_prompt = function()
  local parts = {}
  for _, s in pairs(M._skills) do
    if s.installed and s.system_prompt then
      table.insert(parts, "## " .. s.display_name .. "\n" .. s.system_prompt)
    end
  end
  table.sort(parts)
  return table.concat(parts, "\n\n")
end

---Persist install state
M._save_state = function()
  local config = require("mark.config").options
  local names = {}
  for _, s in pairs(M._skills) do
    if s.installed then
      table.insert(names, s.name)
    end
  end
  table.sort(names)
  loader.save_installed(config.skills_dir, names)
end

---Notify integrations of skill state change
---@param action "install"|"uninstall"|"refresh"
---@param s Mark.Skill|nil
M._notify_integrations = function(action, s)
  local integrations = require("mark.integrations")
  integrations.on_skill_change(action, s)
end

return M
