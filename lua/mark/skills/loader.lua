local skill = require("mark.skills.skill")

local M = {}

---Load a skill from a Lua file
---@param path string Absolute path to a .lua skill file
---@return Mark.Skill|nil
M.load_file = function(path)
  local ok, def = pcall(dofile, path)
  if not ok or type(def) ~= "table" then
    vim.notify("[mark.nvim] Failed to load skill file: " .. path, vim.log.levels.WARN)
    return nil
  end
  def.source = def.source or "user"
  local s_ok, s = pcall(skill.new, def)
  if not s_ok then
    vim.notify("[mark.nvim] Invalid skill definition in: " .. path, vim.log.levels.WARN)
    return nil
  end
  return s
end

---Load all skills from a directory
---@param dir string Directory path to scan
---@return Mark.Skill[]
M.load_directory = function(dir)
  local skills = {}
  if vim.fn.isdirectory(dir) == 0 then
    return skills
  end
  local files = vim.fn.glob(dir .. "/*.lua", false, true)
  for _, file in ipairs(files) do
    local s = M.load_file(file)
    if s then
      table.insert(skills, s)
    end
  end
  return skills
end

---Save the installed skills list to disk
---@param dir string Skills directory
---@param installed_names string[] List of installed skill names
M.save_installed = function(dir, installed_names)
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/installed.json"
  local ok, data = pcall(vim.json.encode, installed_names)
  if not ok then
    vim.notify("[mark.nvim] Failed to encode installed skills", vim.log.levels.ERROR)
    return
  end
  local fd = io.open(path, "w")
  if fd then
    fd:write(data)
    fd:close()
  else
    vim.notify("[mark.nvim] Failed to write installed.json", vim.log.levels.ERROR)
  end
end

---Load installed skill names from disk
---@param dir string Skills directory
---@return string[]
M.load_installed = function(dir)
  local path = dir .. "/installed.json"
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local fd = io.open(path, "r")
  if not fd then
    return {}
  end
  local content = fd:read("*a")
  fd:close()
  local ok, names = pcall(vim.json.decode, content)
  if not ok or type(names) ~= "table" then
    vim.notify("[mark.nvim] Corrupted installed.json, resetting install state", vim.log.levels.WARN)
    return {}
  end
  return names
end

return M
