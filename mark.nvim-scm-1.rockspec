---@diagnostic disable: lowercase-global

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
version = _MODREV .. _SPECREV

local user = "clpi"
package = "mark.nvim"

description = {
  summary = "AI skills manager for Neovim with Mason-style UI",
  detailed = [[
mark.nvim is an AI skills manager for Neovim that provides a Mason-style
floating browser UI to discover, install, and manage reusable AI instruction
packages. Integrates with mcphub.nvim, CopilotChat.nvim, CodeCompanion.nvim,
Avante.nvim, VectorCode, and sidekick.nvim.
  ]],
  labels = { "neovim", "plugin", "lua", "ai", "skills", "mason", "mcp" },
  homepage = "https://github.com/" .. user .. "/" .. package,
  license = "MIT",
}

dependencies = {
  "lua >= 5.1",
}

test_dependencies = {
  "nlua",
}

source = {
  url = "git://github.com/" .. user .. "/" .. package,
}

build = {
  type = "builtin",
}
