local window = require("mark.ui.window")
local renderer = require("mark.ui.renderer")
local keymaps = require("mark.ui.keymaps")

local M = {}

---@type Mark.UiState
M.state = {
  view = "all",
  search_query = "",
  cursor_skill = nil,
  show_help = false,
  category_filter = nil,
}

---@type table<integer, string>|nil
M._skill_map = nil

---Open the skill browser
M.open = function()
  local skills_mgr = require("mark.skills")
  skills_mgr.init()

  window.open()
  M._refresh()
  M._setup_keymaps()
  M._setup_highlights()
end

---Close the skill browser
M.close = function()
  window.close()
  M.state = {
    view = "all",
    search_query = "",
    cursor_skill = nil,
    show_help = false,
    category_filter = nil,
  }
  M._skill_map = nil
end

---Toggle the skill browser
M.toggle = function()
  if window.is_open() then
    M.close()
  else
    M.open()
  end
end

---Refresh the rendered content
M._refresh = function()
  if not window.is_open() then
    return
  end
  local skills = require("mark.skills").list()
  M._skill_map = renderer.render(window.bufnr, M.state, skills)
end

---Get the skill name at the cursor position
---@return string|nil
M._skill_at_cursor = function()
  if not M._skill_map or not window.is_open() then
    return nil
  end
  local ok, cursor = pcall(vim.api.nvim_win_get_cursor, window.winid)
  if not ok then
    return nil
  end
  local line = cursor[1] - 1
  return M._skill_map[line]
end

---Set up keymaps
M._setup_keymaps = function()
  if not window.bufnr then
    return
  end
  keymaps.setup(window.bufnr, {
    install = function()
      local name = M._skill_at_cursor()
      if name then
        require("mark.skills").install(name)
        M._refresh()
      end
    end,
    uninstall = function()
      local name = M._skill_at_cursor()
      if name then
        require("mark.skills").uninstall(name)
        M._refresh()
      end
    end,
    update = function()
      local name = M._skill_at_cursor()
      if name then
        vim.notify("[mark.nvim] Skill is up to date: " .. name, vim.log.levels.INFO)
      end
    end,
    close = function()
      M.close()
    end,
    escape = function()
      if M.state.show_help then
        M.state.show_help = false
        M._refresh()
      elseif M.state.search_query ~= "" then
        M.state.search_query = ""
        M._refresh()
      elseif M.state.category_filter then
        M.state.category_filter = nil
        M._refresh()
      else
        M.close()
      end
    end,
    toggle_help = function()
      M.state.show_help = not M.state.show_help
      M._refresh()
    end,
    search = function()
      vim.ui.input({ prompt = "Filter skills: ", default = M.state.search_query }, function(input)
        if input ~= nil then
          M.state.search_query = input
          M._refresh()
        end
      end)
    end,
    next_category = function()
      M._jump_category(1)
    end,
    prev_category = function()
      M._jump_category(-1)
    end,
    details = function()
      local name = M._skill_at_cursor()
      if name then
        M._show_details(name)
      end
    end,
    view_all = function()
      M.state.view = "all"
      M._refresh()
    end,
    view_installed = function()
      M.state.view = "installed"
      M._refresh()
    end,
    view_available = function()
      M.state.view = "available"
      M._refresh()
    end,
  })
end

---Jump to the next/previous category header
---@param direction integer 1 for next, -1 for previous
M._jump_category = function(direction)
  if not window.is_open() or not window.bufnr then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(window.winid)
  local current_line = cursor[1]
  local total = vim.api.nvim_buf_line_count(window.bufnr)
  local lines = vim.api.nvim_buf_get_lines(window.bufnr, 0, total, false)

  local target = nil
  if direction > 0 then
    for i = current_line + 1, total do
      if lines[i] and lines[i]:match("^%s+[^%s].*%u") and not lines[i]:match("^%s+[●○◍]") then
        target = i
        break
      end
    end
  else
    for i = current_line - 1, 1, -1 do
      if lines[i] and lines[i]:match("^%s+[^%s].*%u") and not lines[i]:match("^%s+[●○◍]") then
        target = i
        break
      end
    end
  end

  if target then
    vim.api.nvim_win_set_cursor(window.winid, { target, 0 })
  end
end

---Show detail popup for a skill
---@param name string
M._show_details = function(name)
  local skill = require("mark.skills").get(name)
  if not skill then
    return
  end

  local lines = {
    " " .. skill.display_name,
    "",
    " Status:   " .. (skill.installed and "Installed" or "Available"),
    " Category: " .. require("mark.util").category_label(skill.category),
    " Author:   " .. skill.author,
    " Version:  " .. skill.version,
    " Source:   " .. skill.source,
    " Tags:     " .. table.concat(skill.tags, ", "),
    "",
    " Description:",
    " " .. skill.description,
  }

  if skill.long_description then
    table.insert(lines, "")
    for line in skill.long_description:gmatch("[^\n]+") do
      table.insert(lines, " " .. line)
    end
  end

  if skill.system_prompt then
    table.insert(lines, "")
    table.insert(lines, " System Prompt:")
    for line in skill.system_prompt:gmatch("[^\n]+") do
      table.insert(lines, "   " .. line)
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local max_w = 0
  for _, l in ipairs(lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(l))
  end

  local width = math.min(max_w + 4, vim.o.columns - 10)
  local height = math.min(#lines, vim.o.lines - 10)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Skill Details ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true })
end

---Set up highlight groups
M._setup_highlights = function()
  local set = function(name, opts)
    vim.api.nvim_set_hl(0, name, opts)
  end
  set("MarkNormal", { link = "NormalFloat", default = true })
  set("MarkBorder", { link = "FloatBorder", default = true })
  set("MarkTitle", { link = "Title", default = true })
  set("MarkFooter", { link = "Comment", default = true })
  set("MarkCursorLine", { link = "CursorLine", default = true })
  set("MarkHeaderLabel", { link = "Title", default = true })
  set("MarkHeaderCount", { link = "Number", default = true })
  set("MarkTabActive", { link = "TabLineSel", default = true })
  set("MarkTabInactive", { link = "TabLine", default = true })
  set("MarkSearchLabel", { link = "Search", default = true })
  set("MarkCategoryHeader", { link = "Statement", default = true })
  set("MarkInstalled", { fg = "#a6e3a1", default = true })
  set("MarkNotInstalled", { link = "Comment", default = true })
  set("MarkSkillName", { link = "Function", default = true })
  set("MarkSkillDescription", { link = "Comment", default = true })
  set("MarkDimmed", { link = "Comment", default = true })
  set("MarkHelpTitle", { link = "Title", default = true })
  set("MarkHelpKey", { link = "Special", default = true })
end

return M
