vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugins = {
  {
    "clpi/mark.nvim",
    dir = vim.fn.getcwd(),
    lazy = false,
    opts = {},
  },
}

require("lazy.minit").repro({ spec = plugins })
