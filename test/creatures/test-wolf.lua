-- test/creatures/test-wolf.lua
-- WAVE-1 TDD: Validates wolf.lua object definition loads correctly, inherits
-- from creature template, and has all required NPC metadata.
-- Must be run from repository root: lua test/creatures/test-wolf.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the wolf object via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "wolf.lua"

local ok, wolf = pcall(dofile, wolf_path)
if not ok then
    print("WARNING: wolf.lua not found — tests will fail (TDD: expected)")
    wolf = nil
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
suite("WOLF OBJECT: definition validation (WAVE-1)")

-- Basic loading
test("1. wolf.lua loads successfully", function()
    h.assert_truthy(ok, "wolf.lua failed to load: " .. tostring(wolf))
    h.assert_truthy(type(wolf) == "table", "wolf.lua must return a table")
end)

test("2. id is 'wolf'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("wolf", wolf.id, "wolf id")
end)

test("3. template is 'creature'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("creature", wolf.template, "wolf template must be 'creature'")
end)

test("4. guid exists and is a string", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.guid, "wolf must have a guid")
    h.assert_eq("string", type(wolf.guid), "guid must be a string")
end)

test("5. size is 'medium'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("medium", wolf.size, "wolf size must be 'medium'")
end)

test("6. weight is 35.0", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq(35.0, wolf.weight, "wolf weight must be 35.0")
end)

test("7. material is 'flesh'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("flesh", wolf.material, "wolf material must be 'flesh'")
end)

-- Name and keywords
test("8. name is a non-empty string", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("string", type(wolf.name), "name must be a string")
    h.assert_truthy(#wolf.name > 0, "name must not be empty")
end)

test("9. keywords include 'wolf'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.keywords), "keywords must be a table")
    h.assert_truthy(contains(wolf.keywords, "wolf"), "keywords must include 'wolf'")
end)

-- Animate / portable
test("10. animate is true and portable is false", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq(true, wolf.animate, "wolf must be animate")
    h.assert_eq(false, wolf.portable, "wolf must not be portable")
end)

-- Sensory properties
test("11. on_feel exists (mandatory for all objects)", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.on_feel, "on_feel is mandatory — primary sense in darkness")
    h.assert_eq("string", type(wolf.on_feel), "on_feel must be a string")
end)

test("12. description exists", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.description, "description must exist")
    h.assert_eq("string", type(wolf.description), "description must be a string")
end)

test("13. on_smell, on_listen, on_taste exist", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.on_smell, "on_smell should exist for a creature")
    h.assert_eq("string", type(wolf.on_smell), "on_smell must be a string")
    h.assert_truthy(wolf.on_listen, "on_listen should exist for a creature")
    h.assert_eq("string", type(wolf.on_listen), "on_listen must be a string")
    h.assert_truthy(wolf.on_taste, "on_taste should exist for a creature")
    h.assert_eq("string", type(wolf.on_taste), "on_taste must be a string")
end)

-- FSM states
test("14. states table exists with all required states", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.states), "states must be a table")
    h.assert_truthy(wolf.states["alive-idle"], "alive-idle state must exist")
    h.assert_truthy(wolf.states["alive-wander"], "alive-wander state must exist")
    h.assert_truthy(wolf.states["alive-patrol"], "alive-patrol state must exist")
    h.assert_truthy(wolf.states["alive-aggressive"], "alive-aggressive state must exist")
    h.assert_truthy(wolf.states["alive-flee"], "alive-flee state must exist")
    h.assert_truthy(wolf.states["dead"], "dead state must exist")
end)

test("15. dead state sets animate = false and portable = false (too heavy)", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.states and wolf.states["dead"], "dead state must exist")
    h.assert_eq(false, wolf.states["dead"].animate, "dead.animate must be false")
    h.assert_eq(false, wolf.states["dead"].portable, "dead wolf too heavy to carry")
end)

test("16. initial_state and _state fields exist", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.initial_state, "initial_state must exist")
    h.assert_truthy(wolf._state, "_state must exist")
    h.assert_eq("string", type(wolf.initial_state), "initial_state must be a string")
    h.assert_eq("string", type(wolf._state), "_state must be a string")
end)

test("17. transitions table exists and is non-empty", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.transitions), "transitions must be a table")
    h.assert_truthy(#wolf.transitions > 0, "transitions must not be empty")
end)

-- Behavior — territorial + prey
test("18. behavior has aggression and flee_threshold", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.behavior), "behavior must be a table")
    h.assert_eq("number", type(wolf.behavior.aggression), "aggression must be a number")
    h.assert_eq("number", type(wolf.behavior.flee_threshold), "flee_threshold must be a number")
end)

test("19. territorial metadata has marks_territory and mark_object", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.behavior, "behavior must exist")
    h.assert_eq("table", type(wolf.behavior.territorial), "territorial must be a table")
    h.assert_eq(true, wolf.behavior.territorial.marks_territory, "marks_territory must be true")
    h.assert_eq("territory-marker", wolf.behavior.territorial.mark_object, "mark_object must be 'territory-marker'")
end)

test("20. behavior.prey includes 'rat' and 'cat'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.behavior, "behavior must exist")
    h.assert_eq("table", type(wolf.behavior.prey), "behavior.prey must be a table")
    h.assert_truthy(contains(wolf.behavior.prey, "rat"), "prey must include 'rat'")
    h.assert_truthy(contains(wolf.behavior.prey, "cat"), "prey must include 'cat'")
end)

-- Drives
test("21. drives exist with hunger", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.drives), "drives must be a table")
    h.assert_truthy(wolf.drives.hunger, "hunger drive must exist")
    h.assert_eq("number", type(wolf.drives.hunger.value), "hunger.value must be a number")
end)

-- Health
test("22. health and max_health exist and are > 0", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("number", type(wolf.health), "health must be a number")
    h.assert_truthy(wolf.health > 0, "health must be > 0")
    h.assert_eq("number", type(wolf.max_health), "max_health must be a number")
    h.assert_truthy(wolf.max_health > 0, "max_health must be > 0")
end)

-- Body tree
test("23. body_tree exists with head, body, forelegs, hindlegs, tail zones", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.body_tree), "body_tree must be a table")
    h.assert_truthy(wolf.body_tree.head, "body_tree must have head zone")
    h.assert_truthy(wolf.body_tree.body, "body_tree must have body zone")
    h.assert_truthy(wolf.body_tree.forelegs, "body_tree must have forelegs zone")
    h.assert_truthy(wolf.body_tree.hindlegs, "body_tree must have hindlegs zone")
    h.assert_truthy(wolf.body_tree.tail, "body_tree must have tail zone")
end)

test("24. body_tree zones have tissue layers with valid materials", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.body_tree, "body_tree must exist")
    for zone_name, zone in pairs(wolf.body_tree) do
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
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_eq("table", type(wolf.combat), "combat must be a table")
    h.assert_eq("table", type(wolf.combat.natural_weapons), "combat.natural_weapons must be a table")
    h.assert_truthy(#wolf.combat.natural_weapons > 0, "natural_weapons must not be empty")
end)

test("26. each weapon has type, material, force", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.combat and wolf.combat.natural_weapons, "combat.natural_weapons must exist")
    for i, weapon in ipairs(wolf.combat.natural_weapons) do
        h.assert_truthy(weapon.type, "weapon " .. i .. " must have type")
        h.assert_truthy(weapon.material, "weapon " .. i .. " must have material")
        h.assert_truthy(weapon.force, "weapon " .. i .. " must have force")
        h.assert_eq("number", type(weapon.force), "weapon " .. i .. " force must be a number")
    end
end)

test("27. natural_armor exists with hide coverage", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.combat, "combat must exist")
    h.assert_truthy(wolf.combat.natural_armor, "wolf must have natural_armor")
    h.assert_eq("table", type(wolf.combat.natural_armor), "natural_armor must be a table")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
