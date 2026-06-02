local util = require("mark.util")

local M = {}

---@type string Namespace for extmarks
local ns = vim.api.nvim_create_namespace("mark_ui")

---Render the skill browser into the buffer
---@param bufnr integer
---@param state Mark.UiState
---@param skills Mark.Skill[]
M.render = function(bufnr, state, skills)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = {}
  local highlights = {}
  local skill_map = {}

  -- Header
  local installed_count = 0
  local total_count = #skills
  for _, s in ipairs(skills) do
    if s.installed then
      installed_count = installed_count + 1
    end
  end

  table.insert(lines, "")
  table.insert(lines, "  Skills: " .. installed_count .. " installed / " .. total_count .. " available")
  table.insert(highlights, { line = 1, col = 2, end_col = 9, hl = "MarkHeaderLabel" })
  table.insert(highlights, { line = 1, col = 10, end_col = #lines[2], hl = "MarkHeaderCount" })

  -- View tabs
  local views = { "all", "installed", "available" }
  local tab_line = "  "
  for idx, v in ipairs(views) do
    local label = " " .. v:sub(1, 1):upper() .. v:sub(2) .. " "
    if idx > 1 then
      tab_line = tab_line .. "  "
    end
    local start = #tab_line
    tab_line = tab_line .. label
    if v == state.view then
      table.insert(highlights, { line = #lines + 1, col = start, end_col = start + #label, hl = "MarkTabActive" })
    else
      table.insert(highlights, { line = #lines + 1, col = start, end_col = start + #label, hl = "MarkTabInactive" })
    end
  end
  table.insert(lines, "")
  table.insert(lines, tab_line)
  table.insert(lines, "")

  if state.search_query ~= "" then
    table.insert(lines, "  Filter: " .. state.search_query)
    table.insert(highlights, { line = #lines - 1, col = 2, end_col = 10, hl = "MarkSearchLabel" })
    table.insert(lines, "")
  end

  -- Filter skills by view and search
  local filtered = {}
  for _, s in ipairs(skills) do
    local show = true
    if state.view == "installed" and not s.installed then
      show = false
    end
    if state.view == "available" and s.installed then
      show = false
    end
    if state.category_filter and s.category ~= state.category_filter then
      show = false
    end
    if state.search_query ~= "" then
      local q = state.search_query:lower()
      local match = s.name:lower():find(q, 1, true)
        or s.display_name:lower():find(q, 1, true)
        or s.description:lower():find(q, 1, true)
      if not match then
        local tag_match = false
        for _, t in ipairs(s.tags) do
          if t:lower():find(q, 1, true) then
            tag_match = true
            break
          end
        end
        if not tag_match then
          show = false
        end
      end
    end
    if show then
      table.insert(filtered, s)
    end
  end

  -- Group by category
  local categories = {}
  local cat_order = {}
  for _, s in ipairs(filtered) do
    if not categories[s.category] then
      categories[s.category] = {}
      table.insert(cat_order, s.category)
    end
    table.insert(categories[s.category], s)
  end

  local icons = require("mark.config").options.ui.icons

  if #cat_order == 0 then
    table.insert(lines, "  No skills match the current filter.")
    table.insert(highlights, { line = #lines - 1, col = 2, end_col = #lines[#lines], hl = "MarkDimmed" })
  end

  for _, cat in ipairs(cat_order) do
    local cat_icon = icons.category[cat] or ""
    local cat_label = " " .. cat_icon .. "  " .. util.category_label(cat)
    table.insert(lines, cat_label)
    table.insert(highlights, { line = #lines - 1, col = 0, end_col = #cat_label, hl = "MarkCategoryHeader" })
    table.insert(lines, "")

    for _, s in ipairs(categories[cat]) do
      local icon = s.installed and icons.installed or icons.not_installed
      local icon_hl = s.installed and "MarkInstalled" or "MarkNotInstalled"
      local line = "    " .. icon .. "  " .. util.pad_right(s.display_name, 30) .. " " .. s.description
      local line_idx = #lines
      table.insert(lines, line)
      skill_map[line_idx] = s.name

      table.insert(highlights, { line = line_idx, col = 4, end_col = 4 + #icon, hl = icon_hl })
      table.insert(highlights, { line = line_idx, col = 7, end_col = 7 + #s.display_name, hl = "MarkSkillName" })
      table.insert(
        highlights,
        { line = line_idx, col = 38, end_col = 38 + #s.description, hl = "MarkSkillDescription" }
      )
    end

    table.insert(lines, "")
  end

  -- Help overlay
  if state.show_help then
    lines = M._render_help(state)
    highlights = {}
    skill_map = {}
    table.insert(highlights, { line = 0, col = 0, end_col = #lines[1], hl = "MarkHelpTitle" })
    for i = 2, #lines do
      if lines[i]:match("^  %S") then
        table.insert(highlights, { line = i - 1, col = 2, end_col = 20, hl = "MarkHelpKey" })
      end
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  for _, hl in ipairs(highlights) do
    pcall(vim.api.nvim_buf_add_highlight, bufnr, ns, hl.hl, hl.line, hl.col, hl.end_col)
  end

  return skill_map
end

---Render help overlay
---@param state Mark.UiState
---@return string[]
M._render_help = function(state)
  local _ = state
  local keymaps = require("mark.config").options.ui.keymaps
  return {
    "  mark.nvim — Keyboard Shortcuts",
    "",
    "  " .. keymaps.install .. "       Install skill under cursor",
    "  " .. keymaps.uninstall .. "       Uninstall skill under cursor",
    "  " .. keymaps.update .. "       Update skill under cursor",
    "  " .. keymaps.search .. "       Search / filter skills",
    "  <Esc>    Clear search filter",
    "  " .. keymaps.next_category .. "      Jump to next category",
    "  " .. keymaps.prev_category .. "      Jump to previous category",
    "  1        View: All skills",
    "  2        View: Installed skills",
    "  3        View: Available skills",
    "  " .. keymaps.toggle_help .. "      Toggle this help",
    "  " .. keymaps.close .. "       Close window",
    "",
    "  Press any key to dismiss this help.",
  }
end

return M
