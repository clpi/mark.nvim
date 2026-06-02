local M = {}

---@type integer|nil
M.bufnr = nil

---@type integer|nil
M.winid = nil

---Create or return the scratch buffer
---@return integer
M.get_buf = function()
  if M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr) then
    return M.bufnr
  end
  M.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[M.bufnr].buftype = "nofile"
  vim.bo[M.bufnr].bufhidden = "wipe"
  vim.bo[M.bufnr].swapfile = false
  vim.bo[M.bufnr].filetype = "mark"
  return M.bufnr
end

---Calculate window dimensions from config
---@return { width: integer, height: integer, row: integer, col: integer }
M.get_dimensions = function()
  local opts = require("mark.config").options.ui
  local editor_w = vim.o.columns
  local editor_h = vim.o.lines - vim.o.cmdheight - 1

  local width = opts.width
  local height = opts.height

  if width <= 1 then
    width = math.floor(editor_w * width)
  end
  if height <= 1 then
    height = math.floor(editor_h * height)
  end

  width = math.min(math.max(width, 40), editor_w - 4)
  height = math.min(math.max(height, 10), editor_h - 2)

  local row = math.floor((editor_h - height) / 2)
  local col = math.floor((editor_w - width) / 2)

  return {
    width = math.floor(width),
    height = math.floor(height),
    row = math.floor(row),
    col = math.floor(col),
  }
end

---Open the floating window
---@return integer winid
M.open = function()
  if M.winid and vim.api.nvim_win_is_valid(M.winid) then
    vim.api.nvim_set_current_win(M.winid)
    return M.winid
  end

  local buf = M.get_buf()
  local dim = M.get_dimensions()
  local border = require("mark.config").options.ui.border

  M.winid = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = dim.width,
    height = dim.height,
    row = dim.row,
    col = dim.col,
    style = "minimal",
    border = border,
    title = " mark.nvim — Skills Manager ",
    title_pos = "center",
    footer = " g? help │ i install │ x uninstall │ / search │ q close ",
    footer_pos = "center",
  })

  vim.wo[M.winid].wrap = false
  vim.wo[M.winid].cursorline = true
  vim.wo[M.winid].number = false
  vim.wo[M.winid].relativenumber = false
  vim.wo[M.winid].signcolumn = "no"
  vim.wo[M.winid].winhighlight =
    "Normal:MarkNormal,FloatBorder:MarkBorder,CursorLine:MarkCursorLine,FloatTitle:MarkTitle,FloatFooter:MarkFooter"

  return M.winid
end

---Close the floating window
M.close = function()
  if M.winid and vim.api.nvim_win_is_valid(M.winid) then
    vim.api.nvim_win_close(M.winid, true)
  end
  M.winid = nil
  if M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr) then
    vim.api.nvim_buf_delete(M.bufnr, { force = true })
  end
  M.bufnr = nil
end

---Check if the window is open
---@return boolean
M.is_open = function()
  return M.winid ~= nil and vim.api.nvim_win_is_valid(M.winid)
end

return M
