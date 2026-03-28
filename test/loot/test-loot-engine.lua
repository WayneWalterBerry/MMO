-- test/loot/test-loot-engine.lua
-- WAVE-2 TDD: Loot engine unit tests.
-- Tests: weighted_select, roll_loot_table (always, weighted, variable, conditional).
-- Implementation by Bart (loot engine) may not exist yet — TDD: tests define the
-- contract, failures are expected until engine is complete.
--
-- Must be run from repository root: lua test/loot/test-loot-engine.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load loot engine (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local loot_ok, loot = pcall(require, "engine.creatures.loot")
if not loot_ok then
    print("WARNING: engine.creatures.loot not loadable — " .. tostring(loot))
    loot = nil
end

---------------------------------------------------------------------------
-- TESTS: weighted_select
---------------------------------------------------------------------------
suite("LOOT ENGINE: weighted_select (WAVE-2 TDD)")

test("1. weighted_select picks correct option with seeded RNG", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")
    h.assert_truthy(loot.weighted_select, "weighted_select function must exist")

    local options = {
        { item = { template = "silver-coin" }, weight = 20 },
        { item = { template = "torn-cloth" },  weight = 30 },
        { item = nil,                          weight = 50 },
    }

    -- Seed RNG for determinism, then roll once
    math.randomseed(42)
    local result = loot.weighted_select(options)
    h.assert_truthy(result, "weighted_select must return a result")
    h.assert_truthy(result.weight, "result must have a weight field")

    -- Run again with same seed — must get identical result
    math.randomseed(42)
    local result2 = loot.weighted_select(options)
    h.assert_eq(result.weight, result2.weight,
        "Same seed must produce same selection")
end)

test("2. weighted_select returns nil when all weights are zero", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    local options = {
        { item = { template = "coin" }, weight = 0 },
        { item = { template = "cloth" }, weight = 0 },
    }

    local result = loot.weighted_select(options)
    h.assert_nil(result, "All-zero weights must return nil")
end)

---------------------------------------------------------------------------
-- TESTS: roll_loot_table
---------------------------------------------------------------------------
suite("LOOT ENGINE: roll_loot_table (WAVE-2 TDD)")

test("3. roll_loot_table always field produces guaranteed drops", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")
    h.assert_truthy(loot.roll_loot_table, "roll_loot_table function must exist")

    local creature = {
        loot_table = {
            always = {
                { template = "gnawed-bone" },
                { template = "fur-scrap", quantity = 2 },
            },
        },
    }

    local drops = loot.roll_loot_table(creature, {})
    h.assert_truthy(drops, "roll_loot_table must return a table")
    h.assert_eq(2, #drops, "Always block with 2 entries must produce 2 drop specs")

    -- First always item
    h.assert_eq("gnawed-bone", drops[1].template,
        "First always drop must be gnawed-bone")
    h.assert_eq(1, drops[1].quantity,
        "Default quantity must be 1")

    -- Second always item with explicit quantity
    h.assert_eq("fur-scrap", drops[2].template,
        "Second always drop must be fur-scrap")
    h.assert_eq(2, drops[2].quantity,
        "Explicit quantity=2 must be preserved")
end)

test("4. roll_loot_table weighted drops select correctly with seed", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    local creature = {
        loot_table = {
            on_death = {
                { item = { template = "silver-coin" }, weight = 20 },
                { item = { template = "torn-cloth" },  weight = 30 },
                { item = nil,                          weight = 50 },
            },
        },
    }

    -- Seed and roll
    math.randomseed(42)
    local drops1 = loot.roll_loot_table(creature, {})

    -- Re-seed and roll — must be identical
    math.randomseed(42)
    local drops2 = loot.roll_loot_table(creature, {})

    h.assert_eq(#drops1, #drops2,
        "Same seed must produce same number of drops")

    -- If drops exist, templates must match
    if #drops1 > 0 and #drops2 > 0 then
        h.assert_eq(drops1[1].template, drops2[1].template,
            "Same seed must produce same template selection")
    end
end)

test("5. roll_loot_table variable quantity respects min/max range", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    local creature = {
        loot_table = {
            variable = {
                { template = "copper-coin", min = 1, max = 5 },
            },
        },
    }

    -- Run 20 rolls to check bounds
    for i = 1, 20 do
        math.randomseed(i)
        local drops = loot.roll_loot_table(creature, {})
        h.assert_truthy(#drops >= 1,
            "variable with min=1 must always produce at least 1 drop spec")
        local qty = drops[1].quantity
        h.assert_truthy(qty >= 1 and qty <= 5,
            "Quantity must be in [1,5], got: " .. tostring(qty))
    end
end)

test("6. roll_loot_table conditional drops based on kill_method", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    local creature = {
        loot_table = {
            conditional = {
                fire_kill = {
                    { template = "charred-hide" },
                },
                poison_kill = {
                    { template = "tainted-meat" },
                },
            },
        },
    }

    -- Fire kill
    local drops_fire = loot.roll_loot_table(creature, { kill_method = "fire_kill" })
    h.assert_eq(1, #drops_fire, "fire_kill must produce exactly 1 drop")
    h.assert_eq("charred-hide", drops_fire[1].template,
        "fire_kill must produce charred-hide")

    -- Poison kill
    local drops_poison = loot.roll_loot_table(creature, { kill_method = "poison_kill" })
    h.assert_eq(1, #drops_poison, "poison_kill must produce exactly 1 drop")
    h.assert_eq("tainted-meat", drops_poison[1].template,
        "poison_kill must produce tainted-meat")

    -- Normal kill (no special method) — no conditional drops
    local drops_normal = loot.roll_loot_table(creature, {})
    h.assert_eq(0, #drops_normal,
        "No kill_method means no conditional drops")
end)

test("7. roll_loot_table returns empty table when creature has no loot_table", function()
    h.assert_truthy(loot, "engine.creatures.loot must load")

    local creature = { id = "rat", name = "a rat" }
    local drops = loot.roll_loot_table(creature, {})
    h.assert_truthy(drops, "Must return a table (not nil)")
    h.assert_eq(0, #drops, "Creature without loot_table must produce 0 drops")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
