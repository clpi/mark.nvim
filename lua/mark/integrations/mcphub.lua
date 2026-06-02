---mcphub.nvim integration
---Registers installed skills as an MCP native server with tools and resources.
local M = {}

---@type boolean
M._registered = false

---Register mark.nvim as a native MCP server in mcphub
M.setup = function()
  local ok, mcphub = pcall(require, "mcphub")
  if not ok then
    return
  end

  if M._registered then
    return
  end

  local add_server = mcphub.add_server
  if not add_server then
    return
  end

  pcall(add_server, "mark-skills", {
    name = "mark-skills",
    displayName = "Mark.nvim Skills",
    description = "AI skills managed by mark.nvim",
    capabilities = {
      tools = true,
      resources = true,
    },
  })

  M._register_tools(mcphub)
  M._register_resources(mcphub)
  M._registered = true
end

---Register tools for each installed skill
---@param mcphub table
M._register_tools = function(mcphub)
  local skills = require("mark.skills").installed()
  for _, skill in ipairs(skills) do
    if skill.system_prompt then
      pcall(mcphub.add_tool, "mark-skills", {
        name = "mark_skill_" .. skill.name:gsub("-", "_"),
        description = skill.display_name .. ": " .. skill.description,
        inputSchema = {
          type = "object",
          properties = {
            query = { type = "string", description = "The question or task for this skill" },
          },
          required = { "query" },
        },
        handler = function(params)
          local prompt = skill.system_prompt .. "\n\nUser: " .. (params.query or "")
          return { content = { { type = "text", text = prompt } } }
        end,
      })
    end
  end
end

---Register resources for browsing skills
---@param mcphub table
M._register_resources = function(mcphub)
  pcall(mcphub.add_resource, "mark-skills", {
    uri = "mark://skills/installed",
    name = "Installed Skills",
    mimeType = "text/plain",
    description = "List of currently installed mark.nvim skills",
    handler = function()
      local skills = require("mark.skills").installed()
      local lines = {}
      for _, s in ipairs(skills) do
        table.insert(lines, "- " .. s.display_name .. ": " .. s.description)
      end
      return { content = { { type = "text", text = table.concat(lines, "\n") } } }
    end,
  })
end

---Handle skill install/uninstall events
---@param action "install"|"uninstall"
---@param skill Mark.Skill
M.on_change = function(action, skill)
  local _ = action
  local __ = skill
  if not M._registered then
    return
  end
  -- Re-register tools when skills change
  local ok, mcphub = pcall(require, "mcphub")
  if ok then
    M._register_tools(mcphub)
  end
end

return M
