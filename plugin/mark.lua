local sub_cmds = {
  open = function()
    require("mark").open()
  end,
  close = function()
    require("mark").close()
  end,
  toggle = function()
    require("mark").toggle()
  end,
  install = function(args)
    if args[1] then
      require("mark").install(args[1])
    else
      vim.notify("[mark.nvim] Usage: :Mark install <skill-name>", vim.log.levels.WARN)
    end
  end,
  uninstall = function(args)
    if args[1] then
      require("mark").uninstall(args[1])
    else
      vim.notify("[mark.nvim] Usage: :Mark uninstall <skill-name>", vim.log.levels.WARN)
    end
  end,
  list = function()
    local skills = require("mark").list_skills()
    local lines = {}
    for _, s in ipairs(skills) do
      local status = s.installed and "●" or "○"
      table.insert(lines, string.format("  %s %s — %s", status, s.display_name, s.description))
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end,
  installed = function()
    local skills = require("mark").get_installed()
    if #skills == 0 then
      vim.notify("[mark.nvim] No skills installed", vim.log.levels.INFO)
      return
    end
    local lines = {}
    for _, s in ipairs(skills) do
      table.insert(lines, "  ● " .. s.display_name .. " — " .. s.description)
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end,
  update = function(args)
    if args[1] then
      require("mark").update(args[1])
    else
      local updatable = require("mark").list_updatable()
      if #updatable == 0 then
        vim.notify("[mark.nvim] No skills with updates available", vim.log.levels.INFO)
      else
        local lines = {}
        for _, s in ipairs(updatable) do
          table.insert(lines, "  ◍ " .. s.display_name .. " v" .. s.version .. " → v" .. s.pending_update.version)
        end
        vim.notify("[mark.nvim] Skills with updates:\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
      end
    end
  end,
  refresh = function()
    vim.notify("[mark.nvim] Refreshing remote registries...", vim.log.levels.INFO)
    require("mark").refresh(function(success)
      if success then
        vim.notify("[mark.nvim] Remote registries updated", vim.log.levels.INFO)
      else
        vim.notify("[mark.nvim] Failed to fetch remote registries (using cached)", vim.log.levels.WARN)
      end
    end)
  end,
}

local sub_cmds_keys = {}
for k, _ in pairs(sub_cmds) do
  table.insert(sub_cmds_keys, k)
end
table.sort(sub_cmds_keys)

local function main_cmd(opts)
  local args = vim.split(opts.args, "%s+", { trimempty = true })
  local sub_cmd_name = args[1] or "toggle"
  local sub_cmd = sub_cmds[sub_cmd_name]

  if sub_cmd == nil then
    vim.notify("[mark.nvim] Unknown subcommand: " .. sub_cmd_name, vim.log.levels.ERROR)
    return
  end

  local rest = {}
  for i = 2, #args do
    table.insert(rest, args[i])
  end
  sub_cmd(rest)
end

vim.api.nvim_create_user_command("Mark", main_cmd, {
  nargs = "*",
  desc = "mark.nvim skills manager",
  complete = function(arg_lead, cmd_line, _)
    local parts = vim.split(cmd_line, "%s+", { trimempty = true })
    local sub = parts[2]
    -- Complete subcommand name
    if (#parts <= 2 and not cmd_line:match("%s$")) or not sub then
      return vim
        .iter(sub_cmds_keys)
        :filter(function(key)
          return key:find(arg_lead, 1, true) == 1
        end)
        :totable()
    end
    if sub == "refresh" then
      return {}
    end
    -- Complete skill names for install/uninstall/update
    if sub == "install" or sub == "uninstall" or sub == "update" then
      local skills = require("mark").list_skills()
      local last_arg = parts[#parts] or ""
      if cmd_line:match("%s$") then
        last_arg = ""
      end
      return vim
        .iter(skills)
        :map(function(s)
          return s.name
        end)
        :filter(function(name)
          return name:find(last_arg, 1, true) == 1
        end)
        :totable()
    end
    return {}
  end,
})
