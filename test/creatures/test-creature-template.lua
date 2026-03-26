-- test/creatures/test-creature-template.lua
-- WAVE-1 TDD: Validates creature.lua template loads correctly and has
-- all required fields for the NPC system.
-- Must be run from repository root: lua test/creatures/test-creature-template.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the creature template via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local template_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "templates" .. SEP .. "creature.lua"

local ok, creature = pcall(dofile, template_path)
if not ok then
    print("WARNING: creature.lua template not found — tests will fail (TDD: expected)")
    creature = nil
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("CREATURE TEMPLATE: structure validation (WAVE-1)")

test("1. creature.lua loads successfully", function()
    h.assert_truthy(ok, "creature.lua failed to load: " .. tostring(creature))
    h.assert_truthy(type(creature) == "table", "creature.lua must return a table")
end)

test("2. Template has id = 'creature'", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("creature", creature.id, "template id")
end)

test("3. Template has guid", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.guid, "creature template must have a guid")
    h.assert_eq("string", type(creature.guid), "guid must be a string")
end)

test("4. animate is true by default", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq(true, creature.animate, "creature animate default")
end)

test("5. health and max_health are numbers", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("number", type(creature.health), "health must be a number")
    h.assert_eq("number", type(creature.max_health), "max_health must be a number")
    h.assert_truthy(creature.health > 0, "health must be positive")
    h.assert_truthy(creature.max_health > 0, "max_health must be positive")
end)

test("6. size is a string enum", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("string", type(creature.size), "size must be a string")
end)

test("7. behavior table exists with defaults", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("table", type(creature.behavior), "behavior must be a table")
    h.assert_truthy(creature.behavior.default ~= nil, "behavior.default must exist")
end)

test("8. drives table exists", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("table", type(creature.drives), "drives must be a table")
end)

test("9. reactions table exists", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("table", type(creature.reactions), "reactions must be a table")
end)

test("10. movement table exists", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("table", type(creature.movement), "movement must be a table")
end)

test("11. on_feel exists (mandatory sensory property)", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.on_feel, "on_feel is mandatory for all objects")
    h.assert_eq("string", type(creature.on_feel), "on_feel must be a string")
end)

test("12. initial_state is set", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.initial_state, "initial_state must exist")
    h.assert_eq("string", type(creature.initial_state), "initial_state must be a string")
end)

test("13. FSM states table exists", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_eq("table", type(creature.states), "states must be a table")
end)

test("14. FSM has alive-idle state", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.states["alive-idle"], "alive-idle state must exist")
end)

test("15. FSM has alive-wander state", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.states["alive-wander"], "alive-wander state must exist")
end)

test("16. FSM has alive-flee state", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.states["alive-flee"], "alive-flee state must exist")
end)

test("17. FSM has dead state", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.states["dead"], "dead state must exist")
end)

test("18. dead state sets animate = false", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.states["dead"], "dead state must exist")
    h.assert_eq(false, creature.states["dead"].animate, "dead state must set animate = false")
end)

test("19. dead state sets portable = true", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_truthy(creature.states["dead"], "dead state must exist")
    h.assert_eq(true, creature.states["dead"].portable, "dead state must set portable = true")
end)

test("20. NO body_tree field (WAVE-4 — D-COMBAT-NPC-PHASE-SEQUENCING)", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_nil(creature.body_tree,
        "body_tree must NOT exist in WAVE-1 (deferred to WAVE-4)")
end)

test("21. NO combat field (WAVE-4 — D-COMBAT-NPC-PHASE-SEQUENCING)", function()
    h.assert_truthy(creature, "creature not loaded")
    h.assert_nil(creature.combat,
        "combat must NOT exist in WAVE-1 (deferred to WAVE-4)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
