-- test/creatures/test-rat.lua
-- WAVE-1 TDD: Validates rat.lua object definition loads correctly, inherits
-- from creature template, and has all required NPC metadata.
-- Must be run from repository root: lua test/creatures/test-rat.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the rat object via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "rat.lua"

local ok, rat = pcall(dofile, rat_path)
if not ok then
    print("WARNING: rat.lua not found — tests will fail (TDD: expected)")
    rat = nil
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("RAT OBJECT: definition validation (WAVE-1)")

-- Basic loading
test("1. rat.lua loads successfully", function()
    h.assert_truthy(ok, "rat.lua failed to load: " .. tostring(rat))
    h.assert_truthy(type(rat) == "table", "rat.lua must return a table")
end)

test("2. id is 'rat'", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("rat", rat.id, "rat id")
end)

test("3. template is 'creature'", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("creature", rat.template, "rat template must be 'creature'")
end)

test("4. guid exists and is a string", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.guid, "rat must have a guid")
    h.assert_eq("string", type(rat.guid), "guid must be a string")
end)

-- Rat-specific fields
test("5. size is 'tiny'", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("tiny", rat.size, "rat size must be 'tiny'")
end)

test("6. weight is 0.3", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq(0.3, rat.weight, "rat weight must be 0.3")
end)

test("7. material is 'flesh'", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("flesh", rat.material, "rat material must be 'flesh'")
end)

-- Name and keywords
test("8. name is a non-empty string", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("string", type(rat.name), "name must be a string")
    h.assert_truthy(#rat.name > 0, "name must not be empty")
end)

test("9. keywords include 'rat'", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("table", type(rat.keywords), "keywords must be a table")
    local found = false
    for _, kw in ipairs(rat.keywords) do
        if kw == "rat" then found = true; break end
    end
    h.assert_truthy(found, "keywords must include 'rat'")
end)

-- Drives
test("10. drives table exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("table", type(rat.drives), "drives must be a table")
end)

test("11. hunger drive exists with required fields", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.drives, "drives must exist")
    h.assert_truthy(rat.drives.hunger, "hunger drive must exist")
    h.assert_eq("number", type(rat.drives.hunger.value), "hunger.value must be a number")
    h.assert_eq("number", type(rat.drives.hunger.decay_rate), "hunger.decay_rate must be a number")
end)

test("12. fear drive exists with required fields", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.drives, "drives must exist")
    h.assert_truthy(rat.drives.fear, "fear drive must exist")
    h.assert_eq("number", type(rat.drives.fear.value), "fear.value must be a number")
    h.assert_eq("number", type(rat.drives.fear.decay_rate), "fear.decay_rate must be a number")
end)

test("13. curiosity drive exists with required fields", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.drives, "drives must exist")
    h.assert_truthy(rat.drives.curiosity, "curiosity drive must exist")
    h.assert_eq("number", type(rat.drives.curiosity.value), "curiosity.value must be a number")
    h.assert_eq("number", type(rat.drives.curiosity.decay_rate), "curiosity.decay_rate must be a number")
end)

-- Reactions (4 stimulus types)
test("14. reactions table exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("table", type(rat.reactions), "reactions must be a table")
end)

test("15. player_enters reaction exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.reactions, "reactions must exist")
    h.assert_truthy(rat.reactions.player_enters, "player_enters reaction must exist")
end)

test("16. player_attacks reaction exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.reactions, "reactions must exist")
    h.assert_truthy(rat.reactions.player_attacks, "player_attacks reaction must exist")
end)

test("17. loud_noise reaction exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.reactions, "reactions must exist")
    h.assert_truthy(rat.reactions.loud_noise, "loud_noise reaction must exist")
end)

test("18. light_change reaction exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.reactions, "reactions must exist")
    h.assert_truthy(rat.reactions.light_change, "light_change reaction must exist")
end)

-- Sensory properties
test("19. on_feel exists (mandatory for all objects)", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.on_feel, "on_feel is mandatory — primary sense in darkness")
    h.assert_eq("string", type(rat.on_feel), "on_feel must be a string")
end)

test("20. description exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.description, "description must exist")
    h.assert_eq("string", type(rat.description), "description must be a string")
end)

test("21. on_smell exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.on_smell, "on_smell should exist for a creature")
    h.assert_eq("string", type(rat.on_smell), "on_smell must be a string")
end)

test("22. on_listen exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.on_listen, "on_listen should exist for a creature")
    h.assert_eq("string", type(rat.on_listen), "on_listen must be a string")
end)

-- FSM states
test("23. states table exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("table", type(rat.states), "states must be a table")
end)

test("24. alive-idle state exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.states and rat.states["alive-idle"], "alive-idle state must exist")
end)

test("25. alive-wander state exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.states and rat.states["alive-wander"], "alive-wander state must exist")
end)

test("26. alive-flee state exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.states and rat.states["alive-flee"], "alive-flee state must exist")
end)

test("27. dead state exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.states and rat.states["dead"], "dead state must exist")
end)

test("28. dead state sets animate = false and portable = true", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.states and rat.states["dead"], "dead state must exist")
    h.assert_eq(false, rat.states["dead"].animate, "dead.animate must be false")
    h.assert_eq(true, rat.states["dead"].portable, "dead.portable must be true")
end)

-- Behavior metadata
test("29. behavior table exists with defaults", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("table", type(rat.behavior), "behavior must be a table")
    h.assert_eq("idle", rat.behavior.default, "behavior.default must be 'idle'")
end)

test("30. behavior has aggression, flee_threshold, wander_chance", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.behavior, "behavior must exist")
    h.assert_eq("number", type(rat.behavior.aggression), "aggression must be a number")
    h.assert_eq("number", type(rat.behavior.flee_threshold), "flee_threshold must be a number")
    h.assert_eq("number", type(rat.behavior.wander_chance), "wander_chance must be a number")
end)

-- Movement
test("31. movement table exists", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_eq("table", type(rat.movement), "movement must be a table")
end)

test("32. movement.can_open_doors is false", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.movement, "movement must exist")
    h.assert_eq(false, rat.movement.can_open_doors, "rats cannot open doors")
end)

test("33. movement.can_climb is true", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.movement, "movement must exist")
    h.assert_eq(true, rat.movement.can_climb, "rats can climb")
end)

-- Phase sequencing guard — WAVE-4 delivered: body_tree and combat now present
test("34. body_tree field exists (WAVE-4)", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.body_tree,
        "body_tree must exist after WAVE-4 delivery")
end)

test("35. combat field exists (WAVE-4)", function()
    h.assert_truthy(rat, "rat not loaded")
    h.assert_truthy(rat.combat,
        "combat must exist after WAVE-4 delivery")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
