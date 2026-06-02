---@meta
--- Type definitions for mark.nvim

-- Skill types ----------------------------------------------------------------

---@class Mark.Skill
---@field name string Unique skill identifier (e.g. "code-review")
---@field display_name string Human-readable name
---@field description string Short description of the skill
---@field long_description? string Extended description
---@field category Mark.SkillCategory Skill category
---@field tags string[] Searchable tags
---@field author string Author name
---@field version string Semver version string
---@field system_prompt? string System prompt text for AI assistants
---@field instruction? string User-facing instruction/prompt text
---@field tools? Mark.ToolDef[] Tool definitions the skill provides
---@field context_template? string Template for additional context injection
---@field integrations? table<string, table> Per-integration config overrides
---@field source Mark.SkillSource Where the skill comes from
---@field installed boolean Whether the skill is currently installed

---@alias Mark.SkillCategory
---| "coding" Code writing, generation, patterns
---| "review" Code review and analysis
---| "testing" Test generation and strategies
---| "documentation" Documentation and comments
---| "refactoring" Code refactoring and optimization
---| "debugging" Bug finding and debugging
---| "devops" CI/CD, infrastructure, deployment
---| "architecture" System design and architecture
---| "security" Security analysis and best practices
---| "general" General-purpose skills

---@alias Mark.SkillSource
---| "builtin" Ships with mark.nvim
---| "user" User-defined in config or skill directory
---| "remote" Fetched from a remote registry

---@class Mark.ToolDef
---@field name string Tool name
---@field description string Tool description
---@field parameters? table JSON Schema for tool parameters
---@field handler? fun(params: table): string Tool execution handler

-- Config types ---------------------------------------------------------------

---@class Mark.UserOptions
---@field skills_dir? string Directory for user-defined skills
---@field auto_detect? boolean Auto-detect and register with AI plugins
---@field default_skills? string[] Skills to install by default on first run
---@field ui? Mark.UiOptions UI configuration
---@field integrations? Mark.IntegrationOptions Integration settings

---@class Mark.DefaultOptions
---@field skills_dir string
---@field auto_detect boolean
---@field default_skills string[]
---@field ui Mark.UiOptions
---@field integrations Mark.IntegrationOptions

---@class Mark.Options
---@field skills_dir string
---@field auto_detect boolean
---@field default_skills string[]
---@field ui Mark.UiOptions
---@field integrations Mark.IntegrationOptions

---@class Mark.UiOptions
---@field border? string Border style: "none"|"single"|"double"|"rounded"|"solid"|"shadow"
---@field width? number Window width (0-1 for percentage, >1 for columns)
---@field height? number Window height (0-1 for percentage, >1 for rows)
---@field icons? Mark.Icons Icon configuration
---@field keymaps? Mark.Keymaps Keymap configuration

---@class Mark.Icons
---@field installed? string Icon for installed skills
---@field not_installed? string Icon for available skills
---@field pending? string Icon for skills being installed
---@field category? table<string, string> Per-category icons

---@class Mark.Keymaps
---@field toggle_help? string Toggle help view
---@field install? string Install skill under cursor
---@field uninstall? string Uninstall skill under cursor
---@field update? string Update skill under cursor
---@field close? string Close the window
---@field next_category? string Jump to next category
---@field prev_category? string Jump to previous category
---@field search? string Start search/filter

---@class Mark.IntegrationOptions
---@field mcphub? Mark.McpHubOptions
---@field copilot_chat? Mark.CopilotChatOptions
---@field codecompanion? Mark.CodeCompanionOptions
---@field avante? Mark.AvanteOptions
---@field vectorcode? Mark.VectorCodeOptions
---@field sidekick? Mark.SidekickOptions

---@class Mark.McpHubOptions
---@field enabled? boolean

---@class Mark.CopilotChatOptions
---@field enabled? boolean

---@class Mark.CodeCompanionOptions
---@field enabled? boolean

---@class Mark.AvanteOptions
---@field enabled? boolean

---@class Mark.VectorCodeOptions
---@field enabled? boolean

---@class Mark.SidekickOptions
---@field enabled? boolean

-- UI types -------------------------------------------------------------------

---@class Mark.UiState
---@field view Mark.View Current view
---@field search_query string Current search/filter text
---@field cursor_skill? string Skill name under cursor
---@field show_help boolean Whether help overlay is visible
---@field category_filter? Mark.SkillCategory Active category filter

---@alias Mark.View
---| "all" All skills
---| "installed" Installed skills only
---| "available" Available (not installed) skills only

-- Health types ---------------------------------------------------------------

---@class Mark.Health
---@field check fun(): nil

-- Plugin module --------------------------------------------------------------

---@class Mark.Plugin
---@field setup fun(opts?: Mark.UserOptions) Configure the plugin
---@field open fun() Open the skills browser
---@field close fun() Close the skills browser
---@field toggle fun() Toggle the skills browser
---@field install fun(name: string) Install a skill by name
---@field uninstall fun(name: string) Uninstall a skill by name
---@field get_skill fun(name: string): Mark.Skill|nil Get skill info
---@field list_skills fun(): Mark.Skill[] List all known skills
---@field get_installed fun(): Mark.Skill[] List installed skills
