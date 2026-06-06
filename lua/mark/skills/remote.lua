local skill = require("mark.skills.skill")

local M = {}

---@type table<string, { data: table, fetched_at: number }>
M._cache = {}

---Get a safe file name from a URL (replace non-alphanumeric chars)
---@param url string
---@return string
local function url_to_filename(url)
  local name = url:gsub("[^%w_]", "_")
  if #name > 100 then
    name = name:sub(1, 100)
  end
  return name
end

---Get the cache file path for a registry URL
---@param cache_dir string
---@param url string
---@return string
local function cache_path(cache_dir, url)
  return cache_dir .. "/" .. url_to_filename(url) .. ".json"
end

---Read cached registry data from disk
---@param cache_dir string
---@param url string
---@return table|nil
local function read_cache(cache_dir, url)
  local path = cache_path(cache_dir, url)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return nil
  end
  return data
end

---Write registry data to disk cache
---@param cache_dir string
---@param url string
---@param data table
local function write_cache(cache_dir, url, data)
  vim.fn.mkdir(cache_dir, "p")
  local path = cache_path(cache_dir, url)
  local ok, encoded = pcall(vim.json.encode, data)
  if not ok then
    return
  end
  local fd = io.open(path, "w")
  if fd then
    fd:write(encoded)
    fd:close()
  end
end

---Check if cached data is stale based on TTL
---@param fetched_at number
---@param ttl number
---@return boolean
local function is_stale(fetched_at, ttl)
  return (vim.uv.now() - fetched_at) > ttl
end

---Detect available HTTP fetch command
---@return string|nil
local function detect_fetch_cmd()
  if vim.fn.executable("curl") == 1 then
    return "curl -sL"
  end
  if vim.fn.executable("wget") == 1 then
    return "wget -qO-"
  end
  return nil
end

---Fetch registry data from the given URL
---@param url string
---@param timeout? number Timeout in milliseconds (default: 10000)
---@return boolean success
---@return table|nil data
local function fetch_registry(url, timeout)
  local cmd_template = detect_fetch_cmd()
  if not cmd_template then
    return false, nil
  end

  timeout = timeout or 10000
  local cmd = cmd_template .. " " .. vim.fn.shellescape(url)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return false, nil
  end

  if #result == 0 then
    return false, nil
  end

  local ok, data = pcall(vim.json.decode, result)
  if not ok or type(data) ~= "table" then
    return false, nil
  end

  if type(data.version) ~= "number" or type(data.skills) ~= "table" then
    return false, nil
  end

  return true, data
end

---Parse skills from a registry response
---@param data table Registry response data
---@param source_name string Name of the source registry
---@return Mark.Skill[]
local function parse_skills(data, source_name)
  local skills = {}
  for _, def in ipairs(data.skills) do
    def.source = "remote"
    def.author = def.author or ("registry:" .. source_name)
    if not def.category then
      def.category = "general"
    end
    local ok, s = pcall(skill.new, def)
    if ok then
      table.insert(skills, s)
    end
  end
  return skills
end

---Fetch and cache a single remote registry
---@param registry Mark.RemoteRegistryDefinition
---@param cache_dir string
---@param default_ttl number
---@return Mark.Skill[]
local function process_registry(registry, cache_dir, default_ttl)
  if registry.enabled == false then
    return {}
  end

  local ttl = registry.cache_ttl or default_ttl
  local cached = read_cache(cache_dir, registry.url)

  if M._cache[registry.url] then
    if not is_stale(M._cache[registry.url].fetched_at, ttl) then
      return parse_skills(M._cache[registry.url].data, registry.name)
    end
  elseif cached and cached.fetched_at and not is_stale(cached.fetched_at, ttl) then
    M._cache[registry.url] = { data = cached.data, fetched_at = cached.fetched_at }
    return parse_skills(cached.data, registry.name)
  end

  local ok, data = fetch_registry(registry.url)
  if ok and data then
    write_cache(cache_dir, registry.url, { data = data, fetched_at = vim.uv.now() })
    M._cache[registry.url] = { data = data, fetched_at = now }
    return parse_skills(data, registry.name)
  end

  if cached and cached.data and cached.data.skills then
    return parse_skills(cached.data, registry.name)
  end

  return {}
end

---Fetch all enabled remote registries and return their skills
---This may block for network requests. Use sync_all for non-blocking.
---@return Mark.Skill[]
M.fetch_all = function()
  local config = require("mark.config").options
  local registries = config.registries or {}
  local cache_dir = config.registry_cache_dir
  local default_ttl = config.registry_cache_ttl or 3600

  if not registries or #registries == 0 then
    return {}
  end

  local fetch_cmd = detect_fetch_cmd()
  if not fetch_cmd then
    vim.notify("[mark.nvim] No HTTP client found (install curl or wget) for remote registries", vim.log.levels.WARN)
    return {}
  end

  local all_skills = {}
  for _, reg in ipairs(registries) do
    local skills = process_registry(reg, cache_dir, default_ttl)
    for _, s in ipairs(skills) do
      table.insert(all_skills, s)
    end
  end
  return all_skills
end

---Refresh all remote registries asynchronously
---@param callback fun(success: boolean, skills: Mark.Skill[])?
M.refresh_async = function(callback)
  local config = require("mark.config").options
  local registries = config.registries or {}
  local cache_dir = config.registry_cache_dir
  local default_ttl = config.registry_cache_ttl or 3600

  if not registries or #registries == 0 then
    if callback then
      callback(true, {})
    end
    return
  end

  local fetch_cmd = detect_fetch_cmd()
  if not fetch_cmd then
    vim.notify("[mark.nvim] No HTTP client found (install curl or wget) for remote registries", vim.log.levels.WARN)
    if callback then
      callback(false, {})
    end
    return
  end

  vim.schedule(function()
    local all_skills = {}
    local any_ok = false

    for _, reg in ipairs(registries) do
      if reg.enabled ~= false then
        local ttl = reg.cache_ttl or default_ttl
        local cached = read_cache(cache_dir, reg.url)

        if M._cache[reg.url] and not is_stale(M._cache[reg.url].fetched_at, ttl) then
          for _, s in ipairs(parse_skills(M._cache[reg.url].data, reg.name)) do
            table.insert(all_skills, s)
          end
          any_ok = true
        elseif cached and cached.fetched_at and not is_stale(cached.fetched_at, ttl) then
          M._cache[reg.url] = { data = cached.data, fetched_at = cached.fetched_at }
          for _, s in ipairs(parse_skills(cached.data, reg.name)) do
            table.insert(all_skills, s)
          end
          any_ok = true
        else
          local ok, data = fetch_registry(reg.url)
          if ok and data then
            write_cache(cache_dir, reg.url, { data = data, fetched_at = vim.uv.now() })
            M._cache[reg.url] = { data = data, fetched_at = vim.uv.now() }
            for _, s in ipairs(parse_skills(data, reg.name)) do
              table.insert(all_skills, s)
            end
            any_ok = true
          elseif cached and cached.data and cached.data.skills then
            M._cache[reg.url] = { data = cached.data, fetched_at = cached.fetched_at }
            for _, s in ipairs(parse_skills(cached.data, reg.name)) do
              table.insert(all_skills, s)
            end
            if cached.data.skills and #cached.data.skills > 0 then
              any_ok = true
            end
          end
        end
      end
    end

    if callback then
      callback(any_ok, all_skills)
    end
  end)
end

---Force refresh all registries (ignore cache) asynchronously
---@param callback fun(success: boolean, skills: Mark.Skill[])?
M.force_refresh_async = function(callback)
  M._cache = {}
  M.refresh_async(callback)
end

---Get cached skills without fetching
---@return Mark.Skill[]
M.get_cached_skills = function()
  local all_skills = {}
  for url, cache in pairs(M._cache) do
    if cache.data and cache.data.skills then
      local registry_name = "unknown"
      for _, reg in ipairs(require("mark.config").options.registries or {}) do
        if reg.url == url then
          registry_name = reg.name
          break
        end
      end
      for _, s in ipairs(parse_skills(cache.data, registry_name)) do
        table.insert(all_skills, s)
      end
    end
  end
  return all_skills
end

---Clear all cached registry data
M.clear_cache = function()
  M._cache = {}
  local cache_dir = require("mark.config").options.registry_cache_dir
  if vim.fn.isdirectory(cache_dir) == 1 then
    vim.fn.delete(cache_dir, "rf")
  end
end

---Check if the registry cache has data
---@return boolean
M.has_cached_data = function()
  if next(M._cache) then
    return true
  end
  local cache_dir = require("mark.config").options.registry_cache_dir
  if vim.fn.isdirectory(cache_dir) == 1 then
    local files = vim.fn.glob(cache_dir .. "/*.json", false, true)
    return #files > 0
  end
  return false
end

---List configured registries
---@return Mark.RemoteRegistryDefinition[]
M.list_registries = function()
  return require("mark.config").options.registries or {}
end

---Check installed skills against remote skills for available updates.
---Mutates skills in-place, setting `pending_update` when a newer version exists.
---@param skills table<string, Mark.Skill> Current skill map (name -> skill)
---@param remote_skills Mark.Skill[] Freshly fetched remote skills
M.check_updates = function(skills, remote_skills)
  local util = require("mark.util")
  local remote_index = {}
  for _, rs in ipairs(remote_skills) do
    remote_index[rs.name] = rs
  end

  for name, skill_obj in pairs(skills) do
    if skill_obj.installed then
      local remote = remote_index[name]
      if remote and remote.source == "remote" then
        if util.version_lt(skill_obj.version, remote.version) then
          skill_obj.pending_update = remote
        elseif skill_obj.pending_update then
          local current_remote = skill_obj.pending_update
          if util.version_lt(current_remote.version, remote.version) then
            skill_obj.pending_update = remote
          end
        end
      end
    end
  end
end

return M
