local remote = require("mark.skills.remote")
local util = require("mark.util")
local mark = require("mark")

describe("Remote Registry", function()
  before_each(function()
    mark.setup({
      registries = {},
    })
  end)

  describe("Version comparison", function()
    it("1.0.0 < 2.0.0", function()
      assert.is_true(util.version_lt("1.0.0", "2.0.0"))
    end)

    it("2.0.0 not < 1.0.0", function()
      assert.is_false(util.version_lt("2.0.0", "1.0.0"))
    end)

    it("1.0.0 not < 1.0.0", function()
      assert.is_false(util.version_lt("1.0.0", "1.0.0"))
    end)

    it("1.0.0 < 1.1.0", function()
      assert.is_true(util.version_lt("1.0.0", "1.1.0"))
    end)

    it("handles short versions (1 < 2)", function()
      assert.is_true(util.version_lt("1", "2"))
    end)

    it("handles short versions (1.0 < 1.1)", function()
      assert.is_true(util.version_lt("1.0", "1.1"))
    end)
  end)

  describe("Registry listing", function()
    it("returns empty list when no registries configured", function()
      assert.are.same({}, remote.list_registries())
    end)

    it("returns configured registries", function()
      mark.setup({
        registries = {
          { name = "test-reg", url = "https://example.com/registry.json" },
        },
      })
      local regs = remote.list_registries()
      assert.are.equal(1, #regs)
      assert.are.equal("test-reg", regs[1].name)
      assert.are.equal("https://example.com/registry.json", regs[1].url)
    end)
  end)

  describe("Cache management", function()
    it("starts with no cache", function()
      assert.is_false(remote.has_cached_data())
    end)

    it("clear_cache is safe to call on empty cache", function()
      assert.has_no_errors(function()
        remote.clear_cache()
      end)
      assert.is_false(remote.has_cached_data())
    end)

    it("get_cached_skills returns empty when no cache", function()
      assert.are.same({}, remote.get_cached_skills())
    end)
  end)

  describe("fetch_all with no registries", function()
    it("returns empty skills list", function()
      local skills = remote.fetch_all()
      assert.are.same({}, skills)
    end)
  end)

  describe("check_updates", function()
    before_each(function()
      mark.setup({ registries = {} })
    end)

    it("does not error with empty skill map", function()
      assert.has_no_errors(function()
        remote.check_updates({}, {})
      end)
    end)

    it("marks skill with newer remote version", function()
      local skill_a = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "A test skill",
        version = "1.0.0",
        installed = true,
      })
      local remote_skill = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "Updated description",
        version = "2.0.0",
        source = "remote",
      })
      local skills = { ["test-skill"] = skill_a }
      remote.check_updates(skills, { remote_skill })
      assert.is_not_nil(skill_a.pending_update)
      assert.are.equal("2.0.0", skill_a.pending_update.version)
    end)

    it("does not mark skill with same version", function()
      local skill_a = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "A test skill",
        version = "1.0.0",
        installed = true,
      })
      local remote_skill = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "Same version",
        version = "1.0.0",
        source = "remote",
      })
      local skills = { ["test-skill"] = skill_a }
      remote.check_updates(skills, { remote_skill })
      assert.is_nil(skill_a.pending_update)
    end)

    it("does not mark uninstalled skills", function()
      local skill_a = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "A test skill",
        version = "1.0.0",
        installed = false,
      })
      local remote_skill = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "Newer version",
        version = "2.0.0",
        source = "remote",
      })
      local skills = { ["test-skill"] = skill_a }
      remote.check_updates(skills, { remote_skill })
      assert.is_nil(skill_a.pending_update)
    end)

    it("does not mark skills with older remote version", function()
      local skill_a = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "A test skill",
        version = "2.0.0",
        installed = true,
      })
      local remote_skill = require("mark.skills.skill").new({
        name = "test-skill",
        display_name = "Test Skill",
        description = "Older version",
        version = "1.0.0",
        source = "remote",
      })
      local skills = { ["test-skill"] = skill_a }
      remote.check_updates(skills, { remote_skill })
      assert.is_nil(skill_a.pending_update)
    end)
  end)
end)
