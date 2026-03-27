-- test/creatures/test-spider.lua
-- WAVE-1 TDD: Validates spider.lua object definition loads correctly, inherits
-- from creature template, and has all required NPC metadata.
-- Must be run from repository root: lua test/creatures/test-spider.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the spider object via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local spider_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "spider.lua"

local ok, spider = pcall(dofile, spider_path)
if not ok then
    print("WARNING: spider.lua not found — tests will fail (TDD: expected)")
    spider = nil
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
suite("SPIDER OBJECT: definition validation (WAVE-1)")

-- Basic loading
test("1. spider.lua loads successfully", function()
    h.assert_truthy(ok, "spider.lua failed to load: " .. tostring(spider))
    h.assert_truthy(type(spider) == "table", "spider.lua must return a table")
end)

test("2. id is 'spider'", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("spider", spider.id, "spider id")
end)

test("3. template is 'creature'", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("creature", spider.template, "spider template must be 'creature'")
end)

test("4. guid exists and is a string", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.guid, "spider must have a guid")
    h.assert_eq("string", type(spider.guid), "guid must be a string")
end)

test("5. size is 'tiny'", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("tiny", spider.size, "spider size must be 'tiny'")
end)

test("6. weight is 0.05", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq(0.05, spider.weight, "spider weight must be 0.05")
end)

test("7. material is 'chitin'", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("chitin", spider.material, "spider material must be 'chitin'")
end)

-- Name and keywords
test("8. name is a non-empty string", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("string", type(spider.name), "name must be a string")
    h.assert_truthy(#spider.name > 0, "name must not be empty")
end)

test("9. keywords include 'spider'", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.keywords), "keywords must be a table")
    h.assert_truthy(contains(spider.keywords, "spider"), "keywords must include 'spider'")
end)

-- Animate / portable
test("10. animate is true and portable is false", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq(true, spider.animate, "spider must be animate")
    h.assert_eq(false, spider.portable, "spider must not be portable")
end)

-- Sensory properties
test("11. on_feel exists (mandatory for all objects)", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.on_feel, "on_feel is mandatory — primary sense in darkness")
    h.assert_eq("string", type(spider.on_feel), "on_feel must be a string")
end)

test("12. description exists", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.description, "description must exist")
    h.assert_eq("string", type(spider.description), "description must be a string")
end)

test("13. on_smell, on_listen, on_taste exist", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.on_smell, "on_smell should exist for a creature")
    h.assert_eq("string", type(spider.on_smell), "on_smell must be a string")
    h.assert_truthy(spider.on_listen, "on_listen should exist for a creature")
    h.assert_eq("string", type(spider.on_listen), "on_listen must be a string")
    h.assert_truthy(spider.on_taste, "on_taste should exist for a creature")
    h.assert_eq("string", type(spider.on_taste), "on_taste must be a string")
end)

-- FSM states
test("14. states table exists with alive-idle, alive-flee, dead", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.states), "states must be a table")
    h.assert_truthy(spider.states["alive-idle"], "alive-idle state must exist")
    h.assert_truthy(spider.states["alive-flee"], "alive-flee state must exist")
    h.assert_truthy(spider.states["dead"], "dead state must exist")
end)

test("15. alive-web-building state exists (web-builder behavior)", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.states and spider.states["alive-web-building"],
        "alive-web-building state must exist — spider is a web-builder")
end)

test("16. dead state sets animate = false and portable = true", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.states and spider.states["dead"], "dead state must exist")
    h.assert_eq(false, spider.states["dead"].animate, "dead.animate must be false")
    h.assert_eq(true, spider.states["dead"].portable, "dead.portable must be true")
end)

test("17. initial_state and _state fields exist", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.initial_state, "initial_state must exist")
    h.assert_truthy(spider._state, "_state must exist")
    h.assert_eq("string", type(spider.initial_state), "initial_state must be a string")
    h.assert_eq("string", type(spider._state), "_state must be a string")
end)

test("18. transitions table exists and is non-empty", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.transitions), "transitions must be a table")
    h.assert_truthy(#spider.transitions > 0, "transitions must not be empty")
end)

-- Behavior — web-builder
test("19. behavior has aggression and flee_threshold", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.behavior), "behavior must be a table")
    h.assert_eq("number", type(spider.behavior.aggression), "aggression must be a number")
    h.assert_eq("number", type(spider.behavior.flee_threshold), "flee_threshold must be a number")
end)

test("20. behavior.web_builder is true", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.behavior, "behavior must exist")
    h.assert_eq(true, spider.behavior.web_builder, "spider must be a web_builder")
end)

-- Drives
test("21. drives exist with hunger", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.drives), "drives must be a table")
    h.assert_truthy(spider.drives.hunger, "hunger drive must exist")
    h.assert_eq("number", type(spider.drives.hunger.value), "hunger.value must be a number")
end)

-- Health
test("22. health and max_health exist and are > 0", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("number", type(spider.health), "health must be a number")
    h.assert_truthy(spider.health > 0, "health must be > 0")
    h.assert_eq("number", type(spider.max_health), "max_health must be a number")
    h.assert_truthy(spider.max_health > 0, "max_health must be > 0")
end)

-- Body tree
test("23. body_tree exists with cephalothorax, abdomen, legs zones", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.body_tree), "body_tree must be a table")
    h.assert_truthy(spider.body_tree.cephalothorax, "body_tree must have cephalothorax zone")
    h.assert_truthy(spider.body_tree.abdomen, "body_tree must have abdomen zone")
    h.assert_truthy(spider.body_tree.legs, "body_tree must have legs zone")
end)

test("24. body_tree zones have tissue layers with valid materials", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.body_tree, "body_tree must exist")
    for zone_name, zone in pairs(spider.body_tree) do
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

-- Combat — venom
test("25. combat exists with natural_weapons", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_eq("table", type(spider.combat), "combat must be a table")
    h.assert_eq("table", type(spider.combat.natural_weapons), "combat.natural_weapons must be a table")
    h.assert_truthy(#spider.combat.natural_weapons > 0, "natural_weapons must not be empty")
end)

test("26. each weapon has type, material, force", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.combat and spider.combat.natural_weapons, "combat.natural_weapons must exist")
    for i, weapon in ipairs(spider.combat.natural_weapons) do
        h.assert_truthy(weapon.type, "weapon " .. i .. " must have type")
        h.assert_truthy(weapon.material, "weapon " .. i .. " must have material")
        h.assert_truthy(weapon.force, "weapon " .. i .. " must have force")
        h.assert_eq("number", type(weapon.force), "weapon " .. i .. " force must be a number")
    end
end)

test("27. bite weapon has on_hit venom effect", function()
    h.assert_truthy(spider, "spider not loaded")
    h.assert_truthy(spider.combat and spider.combat.natural_weapons, "combat.natural_weapons must exist")
    local bite = nil
    for _, weapon in ipairs(spider.combat.natural_weapons) do
        if weapon.id == "bite" or weapon.name == "bite" then
            bite = weapon
            break
        end
    end
    h.assert_truthy(bite, "bite weapon must exist in natural_weapons")
    h.assert_truthy(bite.on_hit, "bite must have on_hit")
    h.assert_eq("spider-venom", bite.on_hit.inflict,
        "bite on_hit must inflict 'spider-venom'")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
