local M = {}

---@type Mark.SkillCategory[]
M.categories = {
  "coding",
  "review",
  "testing",
  "documentation",
  "refactoring",
  "debugging",
  "devops",
  "architecture",
  "security",
  "general",
}

---@param name string
---@return string
M.category_label = function(name)
  return name:sub(1, 1):upper() .. name:sub(2)
end

---Check if a module can be required
---@param mod string
---@return boolean
M.has_module = function(mod)
  local ok = pcall(require, mod)
  return ok
end

---Pad string to width
---@param str string
---@param width integer
---@return string
M.pad_right = function(str, width)
  local len = vim.fn.strdisplaywidth(str)
  if len >= width then
    return str
  end
  return str .. string.rep(" ", width - len)
end

---Truncate string to max width with ellipsis
---@param str string
---@param max integer
---@return string
M.truncate = function(str, max)
  if vim.fn.strdisplaywidth(str) <= max then
    return str
  end
  return str:sub(1, max - 1) .. "…"
end

return M
