<div align="center">
  <h1>🎯&nbsp;&nbsp;mark.nvim&nbsp;&nbsp;🎯</h1>

  <p align="center">
    <a href="https://github.com/clpi/mark.nvim/actions/workflows/run-tests.yml">
      <img alt="Run Tests badge" src="https://img.shields.io/github/actions/workflow/status/clpi/mark.nvim/run-tests.yml?style=for-the-badge&label=Tests"/>
    </a>
    <a href="https://github.com/clpi/mark.nvim/releases">
      <img alt="GitHub badge" src="https://img.shields.io/github/v/release/clpi/mark.nvim?style=for-the-badge&label=GitHub"/>
    </a>
  </p>
  <p><em>AI skills manager for Neovim — browse, install, and manage AI assistant skills with a Mason-style UI</em></p>
</div>

______________________________________________________________________

## What is mark.nvim?

**mark.nvim** is a skills management plugin for Neovim's AI ecosystem. Think of it as **mason.nvim for AI skills** — it provides a floating browser UI to discover, install, and manage reusable AI instruction packages ("skills") that integrate with your favorite AI coding plugins.

Skills are curated prompt/instruction bundles that teach AI assistants *how* to approach specific tasks: code review, test generation, refactoring, security audits, and more.

### Key Features

- **Mason-style browsing UI** — floating window with categories, search/filter, install/uninstall
- **20+ built-in skills** spanning coding, review, testing, documentation, debugging, devops, architecture, security
- **Deep integrations** with the Neovim AI plugin ecosystem:
  - [mcphub.nvim](https://github.com/ravitemer/mcphub.nvim) — registers as a native MCP server
  - [CopilotChat.nvim](https://github.com/CopilotC-Nvim/CopilotChat.nvim) — injects skills as custom prompts
  - [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim) — provides slash commands and extensions
  - [Avante.nvim](https://github.com/yetone/avante.nvim) — system prompt augmentation
  - [VectorCode](https://github.com/Davidyz/VectorCode) — skill-aware code retrieval context
  - [sidekick.nvim](https://github.com/folke/sidekick.nvim) — prompt library entries
- **User-defined skills** — drop `.lua` files in your skills directory
- **Persistent state** — installed skills are saved across sessions
- **Health checks** — `:checkhealth mark` validates config, skills, and detected integrations

## Requirements

- **[Neovim](https://github.com/neovim/neovim)** >= 0.11
- One or more AI plugins (optional but recommended):
  - mcphub.nvim, CopilotChat.nvim, CodeCompanion.nvim, Avante.nvim, VectorCode, sidekick.nvim

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "clpi/mark.nvim",
  lazy = false,
  opts = {},
  keys = {
    { "<leader>sm", "<cmd>Mark toggle<cr>", desc = "Toggle Skills Manager" },
    { "<leader>si", "<cmd>Mark install<cr>", desc = "Install skill" },
  },
  dependencies = {
    -- Add whichever AI plugins you use:
    -- "ravitemer/mcphub.nvim",
    -- "CopilotC-Nvim/CopilotChat.nvim",
    -- "olimorris/codecompanion.nvim",
    -- "yetone/avante.nvim",
    -- "Davidyz/VectorCode",
    -- "folke/sidekick.nvim",
  },
}
```

## Configuration

```lua
require("mark").setup({
  -- Directory for user-defined skill files and install state
  skills_dir = vim.fn.stdpath("data") .. "/mark/skills",

  -- Auto-detect installed AI plugins and register integrations
  auto_detect = true,

  -- Skills to install automatically on first run
  default_skills = {},

  -- UI options (Mason-style floating window)
  ui = {
    border = "rounded",   -- Border style
    width = 0.8,          -- 80% of editor width
    height = 0.75,        -- 75% of editor height
    icons = {
      installed = "●",
      not_installed = "○",
      pending = "◍",
    },
    keymaps = {
      toggle_help = "g?",
      install = "i",
      uninstall = "x",
      update = "u",
      close = "q",
      next_category = "]c",
      prev_category = "[c",
      search = "/",
    },
  },

  -- Per-integration toggle
  integrations = {
    mcphub = { enabled = true },
    copilot_chat = { enabled = true },
    codecompanion = { enabled = true },
    avante = { enabled = true },
    vectorcode = { enabled = true },
    sidekick = { enabled = true },
  },
})
```

## Usage

### Commands

| Command | Description |
| --- | --- |
| `:Mark` or `:Mark toggle` | Toggle the skills browser |
| `:Mark open` | Open the skills browser |
| `:Mark close` | Close the skills browser |
| `:Mark install <name>` | Install a skill by name |
| `:Mark uninstall <name>` | Uninstall a skill by name |
| `:Mark list` | List all available skills |
| `:Mark installed` | List installed skills |

### Browser Keymaps

| Key | Action |
| --- | --- |
| `i` | Install skill under cursor |
| `x` | Uninstall skill under cursor |
| `u` | Update skill under cursor |
| `/` | Search / filter skills |
| `<Esc>` | Clear filter or close |
| `<CR>` | Show skill details |
| `1` / `2` / `3` | View: All / Installed / Available |
| `]c` / `[c` | Jump to next / previous category |
| `g?` | Toggle keyboard shortcuts help |
| `q` | Close the browser |

### Skill Categories

| Category | Description |
| --- | --- |
| Coding | Code generation, design patterns, API design |
| Review | Code review, PR review |
| Testing | Test generation, test strategy |
| Documentation | Doc generation, code comments |
| Refactoring | Code refactoring, performance optimization |
| Debugging | Bug analysis, error handling |
| DevOps | CI/CD, Docker & containers |
| Architecture | System design, database design |
| Security | Security review, auth patterns |
| General | Code explanation, Git workflows, Neovim plugin dev |

## Creating Custom Skills

Drop a `.lua` file in your skills directory (default: `~/.local/share/nvim/mark/skills/`):

```lua
-- ~/.local/share/nvim/mark/skills/my-skill.lua
return {
  name = "my-custom-skill",
  display_name = "My Custom Skill",
  description = "A custom skill for my workflow",
  category = "coding",
  tags = { "custom", "workflow" },
  author = "me",
  version = "1.0.0",
  system_prompt = [[
You are an expert at my specific workflow.
When working on code:
- Follow our team conventions
- Use our internal libraries
- Reference our architecture docs
  ]],
}
```

## Lua API

```lua
local mark = require("mark")

-- Core API
mark.setup(opts)                    -- Configure the plugin
mark.open()                         -- Open skills browser
mark.close()                        -- Close skills browser
mark.toggle()                       -- Toggle skills browser

-- Skill management
mark.install("code-review")         -- Install a skill
mark.uninstall("code-review")       -- Uninstall a skill
mark.get_skill("code-review")       -- Get skill info
mark.list_skills()                  -- List all skills
mark.get_installed()                -- List installed skills
mark.add_skill({ ... })             -- Add a skill at runtime
mark.get_system_prompt()            -- Combined prompt for all installed skills

-- Integration access
mark.integration("mcphub")          -- Get mcphub integration module
mark.integration("copilot_chat")    -- Get CopilotChat integration module
mark.integration("codecompanion")   -- Get CodeCompanion integration module
mark.integration("avante")          -- Get Avante integration module
mark.integration("vectorcode")      -- Get VectorCode integration module
mark.integration("sidekick")        -- Get sidekick integration module
```

## Integration Examples

### With CopilotChat.nvim

Installed skills are automatically registered as CopilotChat prompts. After installing a skill, you can use it via `:CopilotChat` with the skill name prefixed by "Mark".

### With CodeCompanion.nvim

Skills are registered as slash commands. Type `/mark_code_review` (or any installed skill) in a CodeCompanion chat buffer to inject the skill's system prompt.

### With mcphub.nvim

mark.nvim registers as a native MCP server named "mark-skills". Each installed skill becomes an MCP tool that can be called by any MCP-compatible client.

### With Avante.nvim

Access the combined skills system prompt for custom provider integration:

```lua
local avante_int = require("mark").integration("avante")
local prompt = avante_int.get_system_prompt()
```

### With VectorCode

Augment VectorCode queries with skill-aware context:

```lua
local vc_int = require("mark").integration("vectorcode")
local enhanced_query = vc_int.augment_query("find authentication logic")
```

### With sidekick.nvim

Get skills as sidekick-compatible prompts:

```lua
local sk_int = require("mark").integration("sidekick")
local prompts = sk_int.get_prompts()
```

## Health Check

Run `:checkhealth mark` to verify:
- Neovim version compatibility
- Configuration validity
- Skills directory status
- Loaded skills count
- Detected AI plugin integrations

## Acknowledgments

- [mason.nvim](https://github.com/williamboman/mason.nvim) — UI inspiration
- [mcphub.nvim](https://github.com/ravitemer/mcphub.nvim) — MCP integration patterns
- [base.nvim](https://github.com/S1M0N38/base.nvim) — Plugin template foundation
- [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices) — Plugin development conventions

## License

[MIT](LICENSE)
