local util = require("mark.util")

local M = {}

---@type string Namespace for extmarks
local ns = vim.api.nvim_create_namespace("mark_ui")

---Fuzzy search skills by name, display_name, description and tags
---@param skills Mark.Skill[]
---@param query string
---@return Mark.Skill[] matching, table<Mark.Skill, {[1]: integer, [2]: integer}[]> match_positions
local function fuzzy_filter(skills, query)
  if query == "" then
    return skills, {}
  end

  local q_lower = query:lower()
  local matching = {}
  local positions = {}

  -- Try matchfuzzy first for name/display_name
  local names = {}
  local name_to_skill = {}
  for _, s in ipairs(skills) do
    table.insert(names, s.display_name .. " " .. s.name)
    name_to_skill[s.display_name .. " " .. s.name] = s
  end

  local fuzzy_results = vim.fn.matchfuzzy(names, query)
  local fuzzy_set = {}
  if fuzzy_results and #fuzzy_results > 0 then
    for _, r in ipairs(fuzzy_results) do
      local s = name_to_skill[r]
      if s then
        table.insert(matching, s)
        fuzzy_set[s.name] = true
      end
    end
  end

  -- Fall back to substring matching for remaining skills (description, tags)
  for _, s in ipairs(skills) do
    if not fuzzy_set[s.name] then
      local desc_match = s.description:lower():find(q_lower, 1, true)
      if desc_match then
        table.insert(matching, s)
      else
        for _, t in ipairs(s.tags) do
          if t:lower():find(q_lower, 1, true) then
            table.insert(matching, s)
            break
          end
        end
      end
    end
  end

  return matching, positions
end

---Sort skills by the given mode
---@param skills Mark.Skill[]
---@param mode Mark.SortMode
---@return Mark.Skill[] sorted
local function sort_skills(skills, mode)
  local sorted = vim.deepcopy(skills)
  if mode == "name" then
    table.sort(sorted, function(a, b)
      return a.display_name:lower() < b.display_name:lower()
    end)
  elseif mode == "status" then
    table.sort(sorted, function(a, b)
      if a.installed ~= b.installed then
        return a.installed
      end
      return a.display_name:lower() < b.display_name:lower()
    end)
  elseif mode == "category" then
    table.sort(sorted, function(a, b)
      if a.category == b.category then
        return a.name < b.name
      end
      return a.category < b.category
    end)
  end
  return sorted
end

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

  -- Filter by view
  local view_filtered = {}
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
    if show then
      table.insert(view_filtered, s)
    end
  end

  -- Fuzzy search filter
  local searched, _ = fuzzy_filter(view_filtered, state.search_query)

  -- Sort
  local sorted = sort_skills(searched, state.sort_mode)

  -- Header stats (from filtered/sorted list)
  local installed_count = 0
  local total_visible = #sorted
  for _, s in ipairs(sorted) do
    if s.installed then
      installed_count = installed_count + 1
    end
  end

  local updatable_count = 0
  for _, s in ipairs(sorted) do
    if s.installed and s.pending_update then
      updatable_count = updatable_count + 1
    end
  end

  table.insert(lines, "")
  local header_text = "  Skills: " .. installed_count .. " / " .. #skills .. " installed"
  if #sorted ~= #skills then
    header_text = "  Skills: " .. installed_count .. " / " .. total_visible .. " shown"
  end
  if updatable_count > 0 then
    header_text = header_text .. "  (" .. updatable_count .. " updates)"
  end
  local sort_labels = { category = "group", name = "alpha", status = "status" }
  header_text = header_text .. "  │ sort: " .. (sort_labels[state.sort_mode] or state.sort_mode)
  table.insert(lines, header_text)
  table.insert(highlights, { line = 1, col = 2, end_col = 10, hl = "MarkHeaderLabel" })
  table.insert(highlights, {
    line = 1,
    col = 10,
    end_col = 10 + #tostring(installed_count) + #tostring(total_visible) + 15,
    hl = "MarkHeaderCount",
  })

  -- View tabs row
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

  -- Category filter tabs row
  table.insert(lines, "")
  local cat_tab_line = "  "
  for idx, cat in ipairs(util.categories) do
    local label = " " .. util.category_label(cat) .. " "
    if idx > 1 then
      cat_tab_line = cat_tab_line .. " "
    end
    local start = #cat_tab_line
    cat_tab_line = cat_tab_line .. label
    if state.category_filter == cat then
      table.insert(highlights, { line = #lines + 1, col = start, end_col = start + #label, hl = "MarkTabActive" })
    else
      table.insert(highlights, { line = #lines + 1, col = start, end_col = start + #label, hl = "MarkTabInactive" })
    end
  end
  table.insert(lines, cat_tab_line)
  table.insert(lines, "")

  -- Search query display
  if state.search_query ~= "" then
    table.insert(lines, "  Filter: " .. state.search_query)
    table.insert(highlights, { line = #lines - 1, col = 2, end_col = 10, hl = "MarkSearchLabel" })
    table.insert(lines, "")
  end

  -- Group by category for rendering (even for name/status sort, we still group visually)
  local categories = {}
  local cat_order = {}
  for _, s in ipairs(sorted) do
    if not categories[s.category] then
      categories[s.category] = {}
      table.insert(cat_order, s.category)
    end
    table.insert(categories[s.category], s)
  end

  local icons = require("mark.config").options.ui.icons

  if #sorted == 0 then
    table.insert(lines, "  No skills match the current filter.")
    table.insert(highlights, { line = #lines - 1, col = 2, end_col = #lines[#lines], hl = "MarkDimmed" })
  end

  for _, cat in ipairs(cat_order) do
    local cat_icon = icons.category[cat] or ""
    local cat_label = " " .. cat_icon .. "  " .. util.category_label(cat) .. "  (" .. #categories[cat] .. ")"
    table.insert(lines, cat_label)
    table.insert(highlights, { line = #lines - 1, col = 0, end_col = #cat_label, hl = "MarkCategoryHeader" })
    table.insert(lines, "")

    for _, s in ipairs(categories[cat]) do
      local has_update = s.installed and s.pending_update
      local icon = has_update and icons.pending or (s.installed and icons.installed or icons.not_installed)
      local icon_hl = has_update and "MarkPendingUpdate" or (s.installed and "MarkInstalled" or "MarkNotInstalled")
      local source_tag = ""
      local source_hl = nil
      if s.source == "remote" then
        source_tag = " "
        source_hl = "MarkDimmed"
      elseif s.source == "user" then
        source_tag = " 󰠠"
        source_hl = "MarkDimmed"
      end
      local version_tag = ""
      if has_update then
        version_tag = " v" .. s.version .. "→v" .. s.pending_update.version
      end
      local line = "    "
        .. icon
        .. "  "
        .. util.pad_right(s.display_name, 30)
        .. " "
        .. s.description
        .. source_tag
        .. version_tag
      local line_idx = #lines
      table.insert(lines, line)
      skill_map[line_idx] = s.name

      table.insert(highlights, { line = line_idx, col = 4, end_col = 4 + #icon, hl = icon_hl })
      table.insert(highlights, { line = line_idx, col = 7, end_col = 7 + #s.display_name, hl = "MarkSkillName" })
      table.insert(
        highlights,
        { line = line_idx, col = 38, end_col = 38 + #s.description, hl = "MarkSkillDescription" }
      )
      if source_hl then
        table.insert(
          highlights,
          { line = line_idx, col = #line - #source_tag - #version_tag, end_col = #line - #version_tag, hl = source_hl }
        )
      end
      if has_update then
        table.insert(
          highlights,
          { line = line_idx, col = #line - #version_tag, end_col = #line, hl = "MarkPendingUpdate" }
        )
      end
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
    "  " .. keymaps.search .. "       Search / filter skills (fuzzy)",
    "  <Esc>    Clear search / filter",
    "  " .. keymaps.next_category .. "      Jump to next category",
    "  " .. keymaps.prev_category .. "      Jump to previous category",
    "  1        View: All skills",
    "  2        View: Installed skills",
    "  3        View: Available skills",
    "  s        Toggle sort: group / alpha / status",
    "  c        Cycle category filter",
    "  C        Clear category filter",
    "  r        Refresh remote registries",
    "  " .. keymaps.toggle_help .. "      Toggle this help",
    "  " .. keymaps.close .. "       Close window",
    "",
    "  Press any key to dismiss this help.",
  }
end

return M
