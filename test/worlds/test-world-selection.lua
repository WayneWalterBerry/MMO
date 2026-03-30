-- test/worlds/test-world-selection.lua
-- TDD tests for world selection with world_id parameter (WAVE-0).
-- Spec: projects/wyatt-world/plan.md §4.0.2, §5.1
--
-- NEW BEHAVIOR (Bart implements): select(worlds, world_id)
--   - world_id provided → find by world.id match
--   - world_id nil + 1 world → auto-select
--   - world_id nil + 2+ worlds → error listing available IDs
-- Tests for new behavior will FAIL until implementation (TDD red→green).

package.path = "src/?.lua;src/?/init.lua;" .. package.path
local t = require("test.parser.test-helpers")
local world_mod = require("engine.world")

-- Mock worlds matching the real shape
local manor = {
    guid = "fbfaf0de-c263-4c05-b827-209fac43bb20",
    id = "world-1",
    name = "The Manor",
    starting_room = "start-room",
    levels = { 1 },
    theme = { pitch = "Gothic", era = "Medieval" },
    rating = "M",
}

local wyatt = {
    guid = "6F129CCE-4798-446D-9CD8-198B36F04EF0",
    id = "wyatt-world",
    name = "Wyatt's World",
    starting_room = "beast-studio",
    levels = { 1 },
    theme = { pitch = "MrBeast challenge", era = "Modern" },
    rating = "E",
}

-----------------------------------------------------------------------
-- Suite 1: select by world_id (NEW WAVE-0 behavior)
-----------------------------------------------------------------------
t.suite("world selection — select by id")

t.test("select('world-1') finds manor from multiple worlds", function()
    local result, err = world_mod.select({ manor, wyatt }, "world-1")
    t.assert_truthy(result, "should find manor by id: " .. tostring(err))
    t.assert_eq("world-1", result.id, "selected world should be manor")
end)

t.test("select('wyatt-world') finds wyatt world", function()
    local result, err = world_mod.select({ manor, wyatt }, "wyatt-world")
    t.assert_truthy(result, "should find wyatt by id: " .. tostring(err))
    t.assert_eq("wyatt-world", result.id, "selected world should be wyatt")
end)

t.test("select('nonexistent') returns nil + error", function()
    local result, err = world_mod.select({ manor, wyatt }, "nonexistent")
    t.assert_nil(result, "nonexistent world should return nil")
    t.assert_truthy(err, "should return error message")
end)

t.test("select by id works with single-world list", function()
    local result, err = world_mod.select({ manor }, "world-1")
    t.assert_truthy(result, "should find manor even in single-world list: " .. tostring(err))
    t.assert_eq("world-1", result.id)
end)

-----------------------------------------------------------------------
-- Suite 2: auto-select (backward compatibility)
-----------------------------------------------------------------------
t.suite("world selection — auto-select backward compat")

t.test("auto-selects when only one world and no id", function()
    local result, err = world_mod.select({ manor })
    t.assert_truthy(result, "should auto-select single world")
    t.assert_eq("world-1", result.id)
    t.assert_nil(err, "no error expected")
end)

t.test("returns FATAL for zero worlds", function()
    local result, err = world_mod.select({})
    t.assert_nil(result, "should return nil for 0 worlds")
    t.assert_truthy(err and err:find("FATAL"), "error should be FATAL")
end)

t.test("no id + 2 worlds returns error listing available IDs", function()
    local result, err = world_mod.select({ manor, wyatt })
    t.assert_nil(result, "should return nil when 2+ worlds and no id")
    t.assert_truthy(err, "should return error message")
    -- §5.1: "If nil + 2+ worlds → return error listing IDs"
    local mentions_ids = err:find("world%-1") or err:find("wyatt%-world")
        or err:find("available") or err:find("choose") or err:find("select")
    t.assert_truthy(mentions_ids,
        "error should reference available worlds or prompt selection: " .. tostring(err))
end)

-----------------------------------------------------------------------
-- Suite 3: context.world shape after selection
-----------------------------------------------------------------------
t.suite("world selection — context.world population")

t.test("selected world has all required fields for context.world", function()
    local result, err = world_mod.select({ manor })
    t.assert_truthy(result, "should return world")
    t.assert_truthy(result.id, "world.id required")
    t.assert_truthy(result.name, "world.name required")
    t.assert_truthy(result.starting_room, "world.starting_room required")
    t.assert_truthy(result.levels, "world.levels required")
    t.assert_truthy(result.theme, "world.theme required")
end)

t.test("selected world preserves rating field", function()
    local result, _ = world_mod.select({ manor })
    t.assert_eq("M", result.rating, "rating should survive selection")
end)

t.test("E-rated world preserves rating through selection", function()
    local result, err = world_mod.select({ wyatt }, "wyatt-world")
    t.assert_truthy(result, "should select wyatt: " .. tostring(err))
    t.assert_eq("E", result.rating, "E rating should survive selection")
end)

local exit_code = t.summary()
os.exit(exit_code > 0 and 1 or 0)
