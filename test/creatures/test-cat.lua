-- test/creatures/test-cat.lua
-- WAVE-1 TDD: Validates cat.lua object definition loads correctly, inherits
-- from creature template, and has all required NPC metadata.
-- Must be run from repository root: lua test/creatures/test-cat.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the cat object via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local cat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "cat.lua"

local ok, cat = pcall(dofile, cat_path)
if not ok then
    print("WARNING: cat.lua not found — tests will fail (TDD: expected)")
    cat = nil
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
suite("CAT OBJECT: definition validation (WAVE-1)")

-- Basic loading
test("1. cat.lua loads successfully", function()
    h.assert_truthy(ok, "cat.lua failed to load: " .. tostring(cat))
    h.assert_truthy(type(cat) == "table", "cat.lua must return a table")
end)

test("2. id is 'cat'", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("cat", cat.id, "cat id")
end)

test("3. template is 'creature'", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("creature", cat.template, "cat template must be 'creature'")
end)

test("4. guid exists and is a string", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.guid, "cat must have a guid")
    h.assert_eq("string", type(cat.guid), "guid must be a string")
end)

test("5. size is 'small'", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("small", cat.size, "cat size must be 'small'")
end)

test("6. weight is 4.0", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq(4.0, cat.weight, "cat weight must be 4.0")
end)

test("7. material is 'flesh'", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("flesh", cat.material, "cat material must be 'flesh'")
end)

-- Name and keywords
test("8. name is a non-empty string", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("string", type(cat.name), "name must be a string")
    h.assert_truthy(#cat.name > 0, "name must not be empty")
end)

test("9. keywords include 'cat'", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.keywords), "keywords must be a table")
    h.assert_truthy(contains(cat.keywords, "cat"), "keywords must include 'cat'")
end)

-- Animate / portable
test("10. animate is true and portable is false", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq(true, cat.animate, "cat must be animate")
    h.assert_eq(false, cat.portable, "cat must not be portable")
end)

-- Sensory properties
test("11. on_feel exists (mandatory for all objects)", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.on_feel, "on_feel is mandatory — primary sense in darkness")
    h.assert_eq("string", type(cat.on_feel), "on_feel must be a string")
end)

test("12. description exists", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.description, "description must exist")
    h.assert_eq("string", type(cat.description), "description must be a string")
end)

test("13. on_smell, on_listen, on_taste exist", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.on_smell, "on_smell should exist for a creature")
    h.assert_eq("string", type(cat.on_smell), "on_smell must be a string")
    h.assert_truthy(cat.on_listen, "on_listen should exist for a creature")
    h.assert_eq("string", type(cat.on_listen), "on_listen must be a string")
    h.assert_truthy(cat.on_taste, "on_taste should exist for a creature")
    h.assert_eq("string", type(cat.on_taste), "on_taste must be a string")
end)

-- FSM states
test("14. states table exists with alive-idle, alive-wander, alive-flee, dead", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.states), "states must be a table")
    h.assert_truthy(cat.states["alive-idle"], "alive-idle state must exist")
    h.assert_truthy(cat.states["alive-wander"], "alive-wander state must exist")
    h.assert_truthy(cat.states["alive-flee"], "alive-flee state must exist")
    h.assert_truthy(cat.states["dead"], "dead state must exist")
end)

test("15. alive-hunt state exists (predator behavior)", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.states and cat.states["alive-hunt"],
        "alive-hunt state must exist — cat is a predator")
end)

test("16. dead state sets animate = false and portable = true", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.states and cat.states["dead"], "dead state must exist")
    h.assert_eq(false, cat.states["dead"].animate, "dead.animate must be false")
    h.assert_eq(true, cat.states["dead"].portable, "dead.portable must be true")
end)

test("17. initial_state and _state fields exist", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.initial_state, "initial_state must exist")
    h.assert_truthy(cat._state, "_state must exist")
    h.assert_eq("string", type(cat.initial_state), "initial_state must be a string")
    h.assert_eq("string", type(cat._state), "_state must be a string")
end)

test("18. transitions table exists and is non-empty", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.transitions), "transitions must be a table")
    h.assert_truthy(#cat.transitions > 0, "transitions must not be empty")
end)

-- Behavior
test("19. behavior has aggression and flee_threshold", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.behavior), "behavior must be a table")
    h.assert_eq("number", type(cat.behavior.aggression), "aggression must be a number")
    h.assert_eq("number", type(cat.behavior.flee_threshold), "flee_threshold must be a number")
end)

test("20. behavior.prey includes 'rat'", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.behavior, "behavior must exist")
    h.assert_eq("table", type(cat.behavior.prey), "behavior.prey must be a table")
    h.assert_truthy(contains(cat.behavior.prey, "rat"), "prey must include 'rat'")
end)

-- Drives
test("21. drives exist with hunger", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.drives), "drives must be a table")
    h.assert_truthy(cat.drives.hunger, "hunger drive must exist")
    h.assert_eq("number", type(cat.drives.hunger.value), "hunger.value must be a number")
end)

-- Health
test("22. health and max_health exist and are > 0", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("number", type(cat.health), "health must be a number")
    h.assert_truthy(cat.health > 0, "health must be > 0")
    h.assert_eq("number", type(cat.max_health), "max_health must be a number")
    h.assert_truthy(cat.max_health > 0, "max_health must be > 0")
end)

-- Body tree
test("23. body_tree exists with head, body, legs, tail zones", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.body_tree), "body_tree must be a table")
    h.assert_truthy(cat.body_tree.head, "body_tree must have head zone")
    h.assert_truthy(cat.body_tree.body, "body_tree must have body zone")
    h.assert_truthy(cat.body_tree.legs, "body_tree must have legs zone")
    h.assert_truthy(cat.body_tree.tail, "body_tree must have tail zone")
end)

test("24. body_tree zones have tissue layers with valid materials", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.body_tree, "body_tree must exist")
    for zone_name, zone in pairs(cat.body_tree) do
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
    h.assert_truthy(cat, "cat not loaded")
    h.assert_eq("table", type(cat.combat), "combat must be a table")
    h.assert_eq("table", type(cat.combat.natural_weapons), "combat.natural_weapons must be a table")
    h.assert_truthy(#cat.combat.natural_weapons > 0, "natural_weapons must not be empty")
end)

test("26. each weapon has type, material, force", function()
    h.assert_truthy(cat, "cat not loaded")
    h.assert_truthy(cat.combat and cat.combat.natural_weapons, "combat.natural_weapons must exist")
    for i, weapon in ipairs(cat.combat.natural_weapons) do
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
