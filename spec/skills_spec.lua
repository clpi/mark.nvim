local skill_mod = require("mark.skills.skill")
local registry = require("mark.skills.registry")

describe("Skills", function()
  describe("Skill creation", function()
    it("creates a valid skill", function()
      local s = skill_mod.new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "A test skill",
        category = "general",
      })
      assert.are.equal("test-skill", s.name)
      assert.are.equal("Test Skill", s.display_name)
      assert.are.equal("general", s.category)
      assert.are.equal("builtin", s.source)
      assert.is_false(s.installed)
    end)

    it("requires name, display_name, description, category", function()
      assert.has_errors(function()
        skill_mod.new({})
      end)
    end)

    it("serializes and preserves fields", function()
      local s = skill_mod.new({
        name = "test",
        display_name = "Test",
        description = "Desc",
        category = "coding",
        tags = { "a", "b" },
        system_prompt = "prompt",
      })
      local data = skill_mod.serialize(s)
      assert.are.equal("test", data.name)
      assert.are.same({ "a", "b" }, data.tags)
      assert.are.equal("prompt", data.system_prompt)
    end)
  end)

  describe("Registry", function()
    it("returns builtin skills", function()
      local skills = registry.get_builtin_skills()
      assert.is_true(#skills > 0)
    end)

    it("builtin skills have required fields", function()
      local skills = registry.get_builtin_skills()
      for _, s in ipairs(skills) do
        assert.is_string(s.name)
        assert.is_string(s.display_name)
        assert.is_string(s.description)
        assert.is_string(s.category)
        assert.are.equal("builtin", s.source)
      end
    end)

    it("builtin skills have system prompts", function()
      local skills = registry.get_builtin_skills()
      for _, s in ipairs(skills) do
        assert.is_string(s.system_prompt)
        assert.is_true(#s.system_prompt > 0)
      end
    end)
  end)
end)
