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
---Compare two semver strings. Returns true if v1 < v2.
---Supports "1.0.0", "1.0", "1" formats with optional pre-release suffixes.
---@param v1 string
---@param v2 string
---@return boolean
M.version_lt = function(v1, v2)
  local function parse(v)
    local parts = {}
    for num in v:gmatch("%d+") do
      table.insert(parts, tonumber(num))
    end
    while #parts < 3 do
      table.insert(parts, 0)
    end
    return parts
  end
  local a = parse(v1)
  local b = parse(v2)
  for i = 1, 3 do
    if a[i] ~= b[i] then
      return a[i] < b[i]
    end
  end
  return false
end

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
