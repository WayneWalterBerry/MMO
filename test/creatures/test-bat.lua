-- test/creatures/test-bat.lua
-- WAVE-1 TDD: Validates bat.lua object definition loads correctly, inherits
-- from creature template, and has all required NPC metadata.
-- Must be run from repository root: lua test/creatures/test-bat.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the bat object via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local bat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "bat.lua"

local ok, bat = pcall(dofile, bat_path)
if not ok then
    print("WARNING: bat.lua not found — tests will fail (TDD: expected)")
    bat = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function contains(tbl, val)
    if type(tbl) ~= "table" then return false end
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

local valid_materials = {
    flesh = true, bone = true, hide = true,
    ["tooth-enamel"] = true, tooth_enamel = true,
    keratin = true, chitin = true,
}

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BAT OBJECT: definition validation (WAVE-1)")

-- Basic loading
test("1. bat.lua loads successfully", function()
    h.assert_truthy(ok, "bat.lua failed to load: " .. tostring(bat))
    h.assert_truthy(type(bat) == "table", "bat.lua must return a table")
end)

test("2. id is 'bat'", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("bat", bat.id, "bat id")
end)

test("3. template is 'creature'", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("creature", bat.template, "bat template must be 'creature'")
end)

test("4. guid exists and is a string", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.guid, "bat must have a guid")
    h.assert_eq("string", type(bat.guid), "guid must be a string")
end)

test("5. size is 'tiny'", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("tiny", bat.size, "bat size must be 'tiny'")
end)

test("6. weight is 0.02", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq(0.02, bat.weight, "bat weight must be 0.02")
end)

test("7. material is 'flesh'", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("flesh", bat.material, "bat material must be 'flesh'")
end)

-- Name and keywords
test("8. name is a non-empty string", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("string", type(bat.name), "name must be a string")
    h.assert_truthy(#bat.name > 0, "name must not be empty")
end)

test("9. keywords include 'bat'", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.keywords), "keywords must be a table")
    h.assert_truthy(contains(bat.keywords, "bat"), "keywords must include 'bat'")
end)

-- Animate / portable
test("10. animate is true and portable is false", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq(true, bat.animate, "bat must be animate")
    h.assert_eq(false, bat.portable, "bat must not be portable")
end)

-- Sensory properties
test("11. on_feel exists (mandatory for all objects)", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.on_feel, "on_feel is mandatory — primary sense in darkness")
    h.assert_eq("string", type(bat.on_feel), "on_feel must be a string")
end)

test("12. description exists", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.description, "description must exist")
    h.assert_eq("string", type(bat.description), "description must be a string")
end)

test("13. on_smell, on_listen, on_taste exist", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.on_smell, "on_smell should exist for a creature")
    h.assert_eq("string", type(bat.on_smell), "on_smell must be a string")
    h.assert_truthy(bat.on_listen, "on_listen should exist for a creature")
    h.assert_eq("string", type(bat.on_listen), "on_listen must be a string")
    h.assert_truthy(bat.on_taste, "on_taste should exist for a creature")
    h.assert_eq("string", type(bat.on_taste), "on_taste must be a string")
end)

-- FSM states
test("14. states table exists with alive-flee and dead", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.states), "states must be a table")
    h.assert_truthy(bat.states["alive-flee"], "alive-flee state must exist")
    h.assert_truthy(bat.states["alive-flying"], "alive-flying state must exist")
    h.assert_truthy(bat.states["dead"], "dead state must exist")
end)

test("15. alive-roosting state exists (aerial creature resting)", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.states and bat.states["alive-roosting"],
        "alive-roosting state must exist — bat roosts when idle")
end)

test("16. dead state sets animate = false and portable = true", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.states and bat.states["dead"], "dead state must exist")
    h.assert_eq(false, bat.states["dead"].animate, "dead.animate must be false")
    h.assert_eq(true, bat.states["dead"].portable, "dead.portable must be true")
end)

test("17. initial_state and _state fields exist", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.initial_state, "initial_state must exist")
    h.assert_truthy(bat._state, "_state must exist")
    h.assert_eq("string", type(bat.initial_state), "initial_state must be a string")
    h.assert_eq("string", type(bat._state), "_state must be a string")
end)

test("18. transitions table exists and is non-empty", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.transitions), "transitions must be a table")
    h.assert_truthy(#bat.transitions > 0, "transitions must not be empty")
end)

-- Behavior — light-reactive
test("19. behavior has aggression and flee_threshold", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.behavior), "behavior must be a table")
    h.assert_eq("number", type(bat.behavior.aggression), "aggression must be a number")
    h.assert_eq("number", type(bat.behavior.flee_threshold), "flee_threshold must be a number")
end)

test("20. light_reactive is true and roosting_position is 'ceiling'", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.behavior, "behavior must exist")
    h.assert_eq(true, bat.behavior.light_reactive, "bat must be light_reactive")
    h.assert_eq("ceiling", bat.behavior.roosting_position, "roosting_position must be 'ceiling'")
end)

-- Drives
test("21. drives exist with hunger", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.drives), "drives must be a table")
    h.assert_truthy(bat.drives.hunger, "hunger drive must exist")
    h.assert_eq("number", type(bat.drives.hunger.value), "hunger.value must be a number")
end)

-- Health
test("22. health and max_health exist and are > 0", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("number", type(bat.health), "health must be a number")
    h.assert_truthy(bat.health > 0, "health must be > 0")
    h.assert_eq("number", type(bat.max_health), "max_health must be a number")
    h.assert_truthy(bat.max_health > 0, "max_health must be > 0")
end)

-- Body tree — must include wings
test("23. body_tree exists with head, body, wings, legs zones", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.body_tree), "body_tree must be a table")
    h.assert_truthy(bat.body_tree.head, "body_tree must have head zone")
    h.assert_truthy(bat.body_tree.body, "body_tree must have body zone")
    h.assert_truthy(bat.body_tree.wings, "body_tree must have wings zone")
    h.assert_truthy(bat.body_tree.legs, "body_tree must have legs zone")
end)

test("24. body_tree zones have tissue layers with valid materials", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.body_tree, "body_tree must exist")
    for zone_name, zone in pairs(bat.body_tree) do
        if type(zone) == "table" and zone.tissue_layers then
            for _, layer in ipairs(zone.tissue_layers) do
                h.assert_truthy(layer.material,
                    zone_name .. " tissue layer must have material")
                h.assert_truthy(valid_materials[layer.material],
                    zone_name .. " tissue '" .. tostring(layer.material) .. "' not a valid material")
            end
        end
    end
end)

-- Combat
test("25. combat exists with natural_weapons", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_eq("table", type(bat.combat), "combat must be a table")
    h.assert_eq("table", type(bat.combat.natural_weapons), "combat.natural_weapons must be a table")
    h.assert_truthy(#bat.combat.natural_weapons > 0, "natural_weapons must not be empty")
end)

test("26. each weapon has type, material, force", function()
    h.assert_truthy(bat, "bat not loaded")
    h.assert_truthy(bat.combat and bat.combat.natural_weapons, "combat.natural_weapons must exist")
    for i, weapon in ipairs(bat.combat.natural_weapons) do
        h.assert_truthy(weapon.type, "weapon " .. i .. " must have type")
        h.assert_truthy(weapon.material, "weapon " .. i .. " must have material")
        h.assert_truthy(weapon.force, "weapon " .. i .. " must have force")
        h.assert_eq("number", type(weapon.force), "weapon " .. i .. " force must be a number")
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
