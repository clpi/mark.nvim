---VectorCode integration
---Enhances VectorCode queries with skill-aware context.
local M = {}

---@type boolean
M._registered = false

---Register mark.nvim with VectorCode
M.setup = function()
  local ok, _ = pcall(require, "vectorcode")
  if not ok then
    return
  end

  if M._registered then
    return
  end

  M._registered = true
end

---Build a skill-augmented query for VectorCode
---Prepends relevant skill context to improve retrieval results.
---@param query string The original query text
---@param skill_names? string[] Specific skills to use (nil = all installed)
---@return string augmented_query
M.augment_query = function(query, skill_names)
  local skills_mgr = require("mark.skills")
  local skills

  if skill_names then
    skills = {}
    for _, name in ipairs(skill_names) do
      local s = skills_mgr.get(name)
      if s and s.installed then
        table.insert(skills, s)
      end
    end
  else
    skills = skills_mgr.installed()
  end

  if #skills == 0 then
    return query
  end

  local context_parts = {}
  for _, s in ipairs(skills) do
    if s.context_template then
      table.insert(context_parts, s.context_template)
    end
  end

  if #context_parts > 0 then
    return table.concat(context_parts, "\n") .. "\n\n" .. query
  end
  return query
end

---Get installed skills as VectorCode-compatible context
---@return string
M.get_context = function()
  local skills = require("mark.skills").installed()
  local parts = {}
  for _, s in ipairs(skills) do
    if s.system_prompt then
      table.insert(parts, "# " .. s.display_name .. "\n" .. s.description)
    end
  end
  return table.concat(parts, "\n\n")
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
