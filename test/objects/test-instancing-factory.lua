-- test/objects/test-instancing-factory.lua
-- Tests for engine/factory — Core Principle 5 instancing.
-- Covers: unique GUIDs, independent state, per-instance overrides.
-- Must be run from repository root: lua test/objects/test-instancing-factory.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local factory = require("engine.factory")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- A minimal base object definition (like match.lua)
local function make_base()
    return {
        guid = "550e8400-e29b-41d4-a716-446655440000",
        template = "small-item",
        id = "match",
        name = "a wooden match",
        keywords = {"match", "wooden match"},
        description = "A thin stick of wood tipped with sulfur.",
        on_feel = "A thin stick, rough at one end.",
        initial_state = "unlit",
        _state = "unlit",
        states = {
            unlit = { description = "An unlit match." },
            lit   = { description = "A burning match.", casts_light = true },
            spent = { description = "A spent, blackened match." },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light", requires_tool = "fire_source" },
            { from = "lit", to = "spent", verb = "extinguish" },
        },
        weight = 0.1,
        size = 1,
    }
end

---------------------------------------------------------------------------
-- SUITE: Basic instancing
---------------------------------------------------------------------------
suite("FACTORY: Basic instancing (Core Principle 5)")

test("1. create_instances returns correct count", function()
    local base = make_base()
    local instances = factory.create_instances(base, 3)
    h.assert_eq(3, #instances, "should create exactly 3 instances")
end)

test("2. Each instance gets a unique instance_guid", function()
    local base = make_base()
    local instances = factory.create_instances(base, 5)
    local seen = {}
    for _, inst in ipairs(instances) do
        h.assert_truthy(inst.instance_guid, "instance must have instance_guid")
        h.assert_truthy(type(inst.instance_guid) == "string", "guid must be string")
        h.assert_nil(seen[inst.instance_guid], "duplicate guid: " .. inst.instance_guid)
        seen[inst.instance_guid] = true
    end
end)

test("3. Instance GUIDs look like valid UUIDs", function()
    local base = make_base()
    local instances = factory.create_instances(base, 3)
    for _, inst in ipairs(instances) do
        local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89ab]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
        h.assert_truthy(inst.instance_guid:match(pattern),
            "guid does not match UUID v4 pattern: " .. inst.instance_guid)
    end
end)

test("4. Each instance gets a sequential id", function()
    local base = make_base()
    local instances = factory.create_instances(base, 3)
    h.assert_eq("match-1", instances[1].id)
    h.assert_eq("match-2", instances[2].id)
    h.assert_eq("match-3", instances[3].id)
end)

test("5. type_id points back to base guid", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2)
    for _, inst in ipairs(instances) do
        h.assert_eq(base.guid, inst.type_id, "type_id must reference base guid")
    end
end)

test("6. Base guid is cleared on instances", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2)
    for _, inst in ipairs(instances) do
        h.assert_nil(inst.guid, "instance should not carry base guid")
    end
end)

test("7. Instances inherit all base properties", function()
    local base = make_base()
    local instances = factory.create_instances(base, 1)
    local inst = instances[1]
    h.assert_eq("a wooden match", inst.name)
    h.assert_eq("A thin stick of wood tipped with sulfur.", inst.description)
    h.assert_eq("unlit", inst._state)
    h.assert_eq(0.1, inst.weight)
    h.assert_eq(1, inst.size)
    h.assert_eq("A thin stick, rough at one end.", inst.on_feel)
end)

---------------------------------------------------------------------------
-- SUITE: Independent state
---------------------------------------------------------------------------
suite("FACTORY: Independent state")

test("8. Mutating one instance does not affect others", function()
    local base = make_base()
    local instances = factory.create_instances(base, 3)

    -- Mutate instance 1 to "lit"
    instances[1]._state = "lit"
    instances[1].casts_light = true

    -- Others must still be "unlit"
    h.assert_eq("lit", instances[1]._state, "instance 1 should be lit")
    h.assert_eq("unlit", instances[2]._state, "instance 2 should be unlit")
    h.assert_eq("unlit", instances[3]._state, "instance 3 should be unlit")
    h.assert_nil(instances[2].casts_light, "instance 2 should not cast light")
end)

test("9. Nested tables are deep-copied (independent)", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2)

    -- Modify states table on instance 1
    instances[1].states.unlit.description = "MODIFIED"

    -- Instance 2 must be unchanged
    h.assert_eq("An unlit match.", instances[2].states.unlit.description)
end)

test("10. Keywords arrays are independent", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2)

    -- Add a keyword to instance 1
    instances[1].keywords[#instances[1].keywords + 1] = "extra"

    -- Instance 2 should not have the extra keyword
    h.assert_eq(2, #instances[2].keywords, "instance 2 keywords unchanged")
end)

test("11. Mutating instances does not affect original base", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2)

    instances[1]._state = "lit"
    instances[1].name = "MODIFIED"

    h.assert_eq("unlit", base._state, "base _state must be unchanged")
    h.assert_eq("a wooden match", base.name, "base name must be unchanged")
    h.assert_truthy(base.guid, "base guid must survive")
end)

---------------------------------------------------------------------------
-- SUITE: Per-instance overrides
---------------------------------------------------------------------------
suite("FACTORY: Per-instance overrides")

test("12. Global overrides apply to all instances", function()
    local base = make_base()
    local instances = factory.create_instances(base, 3, {
        overrides = { location = "matchbox" },
    })
    for _, inst in ipairs(instances) do
        h.assert_eq("matchbox", inst.location, "all should be in matchbox")
    end
end)

test("13. Per-instance overrides apply individually", function()
    local base = make_base()
    local instances = factory.create_instances(base, 3, {
        per_instance_overrides = {
            [1] = { _state = "lit" },
            [3] = { _state = "spent" },
        },
    })
    h.assert_eq("lit", instances[1]._state)
    h.assert_eq("unlit", instances[2]._state, "no override = base value")
    h.assert_eq("spent", instances[3]._state)
end)

test("14. Per-instance overrides merge nested tables", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2, {
        per_instance_overrides = {
            [1] = { states = { unlit = { description = "Custom desc" } } },
        },
    })
    h.assert_eq("Custom desc", instances[1].states.unlit.description)
    -- Other state entries preserved
    h.assert_truthy(instances[1].states.lit, "lit state must survive merge")
    -- Instance 2 unchanged
    h.assert_eq("An unlit match.", instances[2].states.unlit.description)
end)

test("15. location option sets default location", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2, {
        location = "chest",
    })
    h.assert_eq("chest", instances[1].location)
    h.assert_eq("chest", instances[2].location)
end)

test("16. Per-instance override can override location", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2, {
        location = "chest",
        per_instance_overrides = {
            [2] = { location = "floor" },
        },
    })
    h.assert_eq("chest", instances[1].location)
    h.assert_eq("floor", instances[2].location)
end)

test("17. Custom id_prefix works", function()
    local base = make_base()
    local instances = factory.create_instances(base, 2, {
        id_prefix = "candle",
    })
    h.assert_eq("candle-1", instances[1].id)
    h.assert_eq("candle-2", instances[2].id)
end)

---------------------------------------------------------------------------
-- SUITE: create_one convenience
---------------------------------------------------------------------------
suite("FACTORY: create_one convenience")

test("18. create_one returns a single instance", function()
    local base = make_base()
    local inst = factory.create_one(base)
    h.assert_truthy(inst, "must return an instance")
    h.assert_truthy(inst.instance_guid, "must have guid")
    h.assert_eq(base.guid, inst.type_id)
end)

test("19. create_one applies overrides", function()
    local base = make_base()
    local inst = factory.create_one(base, { _state = "lit", location = "hand" })
    h.assert_eq("lit", inst._state)
    h.assert_eq("hand", inst.location)
end)

---------------------------------------------------------------------------
-- SUITE: Edge cases
---------------------------------------------------------------------------
suite("FACTORY: Edge cases")

test("20. Count of 1 works", function()
    local base = make_base()
    local instances = factory.create_instances(base, 1)
    h.assert_eq(1, #instances)
    h.assert_truthy(instances[1].instance_guid)
end)

test("21. generate_guid returns unique values across calls", function()
    local seen = {}
    for _ = 1, 100 do
        local g = factory.generate_guid()
        h.assert_nil(seen[g], "duplicate guid in 100 calls: " .. g)
        seen[g] = true
    end
end)

test("22. Base with no guid still works (type_id is nil)", function()
    local base = { id = "simple", name = "simple thing" }
    local instances = factory.create_instances(base, 2)
    h.assert_eq(2, #instances)
    h.assert_nil(instances[1].type_id, "no base guid = nil type_id")
    h.assert_truthy(instances[1].instance_guid, "still gets instance_guid")
end)

---------------------------------------------------------------------------
-- SUITE: Registry integration
---------------------------------------------------------------------------
suite("FACTORY: Registry integration")

test("23. Instances can be registered independently", function()
    local registry = require("engine.registry")
    local reg = registry.new()
    local base = make_base()
    local instances = factory.create_instances(base, 3)

    for _, inst in ipairs(instances) do
        reg:register(inst.id, inst)
    end

    h.assert_eq(3, #reg:list(), "registry should have 3 objects")
    h.assert_truthy(reg:get("match-1"), "match-1 should be retrievable")
    h.assert_truthy(reg:get("match-2"), "match-2 should be retrievable")
    h.assert_truthy(reg:get("match-3"), "match-3 should be retrievable")
end)

test("24. Registered instances maintain independent state", function()
    local registry = require("engine.registry")
    local reg = registry.new()
    local base = make_base()
    local instances = factory.create_instances(base, 2)

    for _, inst in ipairs(instances) do
        reg:register(inst.id, inst)
    end

    -- Mutate one via registry
    local m1 = reg:get("match-1")
    m1._state = "lit"

    -- Other must be unchanged
    local m2 = reg:get("match-2")
    h.assert_eq("unlit", m2._state, "match-2 must remain unlit")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
