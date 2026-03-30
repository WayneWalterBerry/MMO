-- test/combat/test-weapon-combat.lua
-- WAVE-4 TDD: Validates weapon objects have combat metadata table.
-- Tests: silver-dagger.lua and knife.lua must have combat table with
-- type, force, message, and two_handed fields.
-- Must be run from repository root: lua test/combat/test-weapon-combat.lua

math.randomseed(42)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load weapon objects
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local objects_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP

local ok_dagger, dagger = pcall(dofile, objects_dir .. "silver-dagger.lua")
if not ok_dagger then
    print("WARNING: silver-dagger.lua failed to load — " .. tostring(dagger))
    dagger = nil
end

local ok_knife, knife = pcall(dofile, objects_dir .. "knife.lua")
if not ok_knife then
    print("WARNING: knife.lua failed to load — " .. tostring(knife))
    knife = nil
end

-- Valid combat types per combat system plan
local valid_combat_types = { edged = true, blunt = true, pierce = true }

---------------------------------------------------------------------------
-- SILVER DAGGER COMBAT TESTS
---------------------------------------------------------------------------
suite("WEAPON COMBAT: silver-dagger (WAVE-4)")

test("1. silver-dagger loads successfully", function()
    h.assert_truthy(ok_dagger, "silver-dagger.lua must load")
    h.assert_truthy(dagger, "silver-dagger must return a table")
end)

test("2. silver-dagger has combat table", function()
    h.assert_truthy(dagger, "dagger not loaded")
    h.assert_truthy(dagger.combat, "silver-dagger must have combat table (WAVE-4)")
    h.assert_eq("table", type(dagger.combat), "combat must be a table")
end)

test("3. silver-dagger combat.type is valid", function()
    h.assert_truthy(dagger and dagger.combat, "dagger.combat not loaded")
    local ct = dagger.combat.type
    h.assert_truthy(ct, "combat.type must exist")
    h.assert_eq("string", type(ct), "combat.type must be a string")
    h.assert_truthy(valid_combat_types[ct],
        "combat.type must be edged/blunt/pierce, got: " .. tostring(ct))
end)

test("4. silver-dagger combat.force is a positive number", function()
    h.assert_truthy(dagger and dagger.combat, "dagger.combat not loaded")
    local force = dagger.combat.force
    h.assert_truthy(force, "combat.force must exist")
    h.assert_eq("number", type(force), "combat.force must be a number")
    h.assert_truthy(force > 0, "combat.force must be positive, got: " .. tostring(force))
end)

test("5. silver-dagger combat.message is a string", function()
    h.assert_truthy(dagger and dagger.combat, "dagger.combat not loaded")
    h.assert_truthy(dagger.combat.message, "combat.message must exist")
    h.assert_eq("string", type(dagger.combat.message),
        "combat.message must be a string")
end)

test("6. silver-dagger combat.two_handed is boolean", function()
    h.assert_truthy(dagger and dagger.combat, "dagger.combat not loaded")
    h.assert_truthy(dagger.combat.two_handed ~= nil,
        "combat.two_handed must be defined (true or false)")
    h.assert_eq("boolean", type(dagger.combat.two_handed),
        "combat.two_handed must be a boolean")
end)

---------------------------------------------------------------------------
-- KNIFE COMBAT TESTS
---------------------------------------------------------------------------
suite("WEAPON COMBAT: knife (WAVE-4)")

test("7. knife loads successfully", function()
    h.assert_truthy(ok_knife, "knife.lua must load")
    h.assert_truthy(knife, "knife must return a table")
end)

test("8. knife has combat table", function()
    h.assert_truthy(knife, "knife not loaded")
    h.assert_truthy(knife.combat, "knife must have combat table (WAVE-4)")
    h.assert_eq("table", type(knife.combat), "combat must be a table")
end)

test("9. knife combat.type is valid", function()
    h.assert_truthy(knife and knife.combat, "knife.combat not loaded")
    local ct = knife.combat.type
    h.assert_truthy(ct, "combat.type must exist")
    h.assert_eq("string", type(ct), "combat.type must be a string")
    h.assert_truthy(valid_combat_types[ct],
        "combat.type must be edged/blunt/pierce, got: " .. tostring(ct))
end)

test("10. knife combat.force is a positive number", function()
    h.assert_truthy(knife and knife.combat, "knife.combat not loaded")
    local force = knife.combat.force
    h.assert_truthy(force, "combat.force must exist")
    h.assert_eq("number", type(force), "combat.force must be a number")
    h.assert_truthy(force > 0, "combat.force must be positive, got: " .. tostring(force))
end)

test("11. knife combat.message is a string", function()
    h.assert_truthy(knife and knife.combat, "knife.combat not loaded")
    h.assert_truthy(knife.combat.message, "combat.message must exist")
    h.assert_eq("string", type(knife.combat.message),
        "combat.message must be a string")
end)

test("12. knife combat.two_handed is boolean", function()
    h.assert_truthy(knife and knife.combat, "knife.combat not loaded")
    h.assert_truthy(knife.combat.two_handed ~= nil,
        "combat.two_handed must be defined (true or false)")
    h.assert_eq("boolean", type(knife.combat.two_handed),
        "combat.two_handed must be a boolean")
end)

---------------------------------------------------------------------------
-- CROSS-WEAPON VALIDATION
---------------------------------------------------------------------------
suite("WEAPON COMBAT: cross-validation (WAVE-4)")

test("13. both weapons have material field (for combat engine)", function()
    h.assert_truthy(dagger, "dagger not loaded")
    h.assert_truthy(knife, "knife not loaded")
    h.assert_truthy(dagger.material, "silver-dagger must have material field")
    h.assert_truthy(knife.material, "knife must have material field")
end)

test("14. weapon materials are strings", function()
    h.assert_truthy(dagger, "dagger not loaded")
    h.assert_truthy(knife, "knife not loaded")
    h.assert_eq("string", type(dagger.material), "dagger.material must be a string")
    h.assert_eq("string", type(knife.material), "knife.material must be a string")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
