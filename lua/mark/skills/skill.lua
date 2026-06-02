local M = {}

---Create a new skill definition
---@param def table Partial skill definition
---@return Mark.Skill
M.new = function(def)
  vim.validate({
    name = { def.name, "string" },
    display_name = { def.display_name, "string" },
    description = { def.description, "string" },
    category = { def.category, "string" },
  })
  ---@type Mark.Skill
  return {
    name = def.name,
    display_name = def.display_name,
    description = def.description,
    long_description = def.long_description or nil,
    category = def.category or "general",
    tags = def.tags or {},
    author = def.author or "mark.nvim",
    version = def.version or "1.0.0",
    system_prompt = def.system_prompt or nil,
    instruction = def.instruction or nil,
    tools = def.tools or nil,
    context_template = def.context_template or nil,
    integrations = def.integrations or nil,
    source = def.source or "builtin",
    installed = def.installed or false,
  }
end

---Serialize a skill to a saveable table
---@param skill Mark.Skill
---@return table
M.serialize = function(skill)
  return {
    name = skill.name,
    display_name = skill.display_name,
    description = skill.description,
    long_description = skill.long_description,
    category = skill.category,
    tags = skill.tags,
    author = skill.author,
    version = skill.version,
    system_prompt = skill.system_prompt,
    instruction = skill.instruction,
    context_template = skill.context_template,
    integrations = skill.integrations,
    source = skill.source,
    installed = skill.installed,
  }
end

return M
