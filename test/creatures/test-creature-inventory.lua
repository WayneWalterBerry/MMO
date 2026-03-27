-- test/creatures/test-creature-inventory.lua
-- WAVE-2 TDD: Validates creature inventory metadata structure, loading,
-- and validation rules (INV-01 through INV-04).
-- Must be run from repository root: lua test/creatures/test-creature-inventory.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load creature definitions via dofile (pcall-guarded — TDD)
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_wolf, wolf_def = pcall(dofile, creature_path("wolf"))
if not ok_wolf then print("WARNING: wolf.lua failed to load — " .. tostring(wolf_def)) end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

local ok_spider, spider_def = pcall(dofile, creature_path("spider"))
if not ok_spider then print("WARNING: spider.lua failed to load — " .. tostring(spider_def)) end

---------------------------------------------------------------------------
-- Load gnawed-bone object (for GUID resolution checks)
---------------------------------------------------------------------------
local obj_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP
local ok_bone, bone_def = pcall(dofile, obj_path .. "gnawed-bone.lua")
if not ok_bone then print("WARNING: gnawed-bone.lua failed to load — " .. tostring(bone_def)) end

---------------------------------------------------------------------------
-- Known GUIDs
---------------------------------------------------------------------------
local GNAWED_BONE_GUID = "{b8db1d83-9c05-401c-ae7b-67c31b98d6fc}"
local VALID_WORN_SLOTS = { head = true, torso = true, arms = true, legs = true, feet = true }

---------------------------------------------------------------------------
-- Validation functions (mirror the engine contract from WAVE-2 spec)
-- TDD: these define the expected behavior; engine must match.
---------------------------------------------------------------------------
local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects or {}) do
        if obj.guid then reg._objects[obj.guid] = obj end
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] or nil end
    return reg
end

-- INV-01: hands max 2
-- INV-02: worn slots valid (head, torso, arms, legs, feet)
-- INV-03: carried GUIDs resolve
-- Returns: ok (boolean), errors (table of strings)
local function validate_inventory(creature, registry)
    local errs = {}
    if not creature then
        return false, { "creature is nil" }
    end

    local inv = creature.inventory
    if inv == nil then
        return true, {}
    end

    if type(inv) ~= "table" then
        return false, { "inventory must be a table" }
    end

    -- INV-01: hands max 2
    if inv.hands then
        if type(inv.hands) ~= "table" then
            errs[#errs + 1] = "inventory.hands must be a table"
        elseif #inv.hands > 2 then
            errs[#errs + 1] = "INV-01: inventory.hands exceeds max 2 (has " .. #inv.hands .. ")"
        end
    end

    -- INV-02: worn slots must be valid
    if inv.worn then
        if type(inv.worn) ~= "table" then
            errs[#errs + 1] = "inventory.worn must be a table"
        else
            for slot, _ in pairs(inv.worn) do
                if not VALID_WORN_SLOTS[slot] then
                    errs[#errs + 1] = "INV-02: invalid worn slot '" .. tostring(slot) .. "'"
                end
            end
        end
    end

    -- INV-03: carried GUIDs must resolve
    if inv.carried then
        if type(inv.carried) ~= "table" then
            errs[#errs + 1] = "inventory.carried must be a table"
        else
            for i, guid in ipairs(inv.carried) do
                if type(guid) ~= "string" then
                    errs[#errs + 1] = "INV-03: carried[" .. i .. "] must be a string GUID"
                elseif registry and not registry:get(guid) then
                    errs[#errs + 1] = "INV-03: carried GUID '" .. guid .. "' does not resolve"
                end
            end
        end
    end

    return #errs == 0, errs
end

---------------------------------------------------------------------------
-- TESTS: Creature inventory metadata (WAVE-2)
---------------------------------------------------------------------------
suite("CREATURE INVENTORY: metadata structure (WAVE-2)")

-- 1. Wolf has inventory field
test("1. wolf has inventory field", function()
    h.assert_truthy(ok_wolf, "wolf.lua must load")
    h.assert_truthy(wolf_def.inventory, "wolf must have inventory field")
    h.assert_eq("table", type(wolf_def.inventory), "inventory must be a table")
end)

-- 2. Wolf inventory has hands, worn, carried slots
test("2. wolf inventory has hands, worn, carried slots", function()
    h.assert_truthy(ok_wolf and wolf_def.inventory, "wolf inventory required")
    local inv = wolf_def.inventory
    h.assert_eq("table", type(inv.hands), "inventory.hands must be a table")
    h.assert_eq("table", type(inv.worn), "inventory.worn must be a table")
    h.assert_eq("table", type(inv.carried), "inventory.carried must be a table")
end)

-- 3. Wolf carried contains gnawed-bone GUID
test("3. wolf carried contains gnawed-bone GUID", function()
    h.assert_truthy(ok_wolf and wolf_def.inventory, "wolf inventory required")
    local carried = wolf_def.inventory.carried
    h.assert_truthy(#carried >= 1, "wolf must carry at least one item")
    local found = false
    for _, guid in ipairs(carried) do
        if guid == GNAWED_BONE_GUID then found = true; break end
    end
    h.assert_truthy(found, "wolf must carry gnawed-bone GUID " .. GNAWED_BONE_GUID)
end)

-- 4. Wolf hands is empty (wolves don't hold items in paws)
test("4. wolf hands is empty", function()
    h.assert_truthy(ok_wolf and wolf_def.inventory, "wolf inventory required")
    h.assert_eq(0, #wolf_def.inventory.hands, "wolf hands should be empty")
end)

-- 5. Wolf carried GUIDs are strings
test("5. wolf carried GUIDs are strings", function()
    h.assert_truthy(ok_wolf and wolf_def.inventory, "wolf inventory required")
    for i, guid in ipairs(wolf_def.inventory.carried) do
        h.assert_eq("string", type(guid), "carried[" .. i .. "] must be a string")
    end
end)

-- 6. Gnawed-bone GUID matches actual object
test("6. gnawed-bone GUID matches wolf carried GUID", function()
    h.assert_truthy(ok_bone, "gnawed-bone.lua must load")
    h.assert_eq(GNAWED_BONE_GUID, bone_def.guid,
        "gnawed-bone GUID must match wolf's carried reference")
end)

-- 7. Validate wolf inventory passes with registry containing bone
test("7. wolf inventory validates with registry containing gnawed-bone", function()
    h.assert_truthy(ok_wolf, "wolf.lua must load")
    local registry = make_mock_registry({ bone_def or { guid = GNAWED_BONE_GUID, id = "gnawed-bone" } })
    local ok, errs = validate_inventory(wolf_def, registry)
    h.assert_truthy(ok, "wolf inventory should validate — errors: " .. table.concat(errs or {}, "; "))
end)

-- 8. Hands max 2 enforced (INV-01)
test("8. INV-01: hands max 2 enforced", function()
    local fake = {
        inventory = {
            hands = { "{g1}", "{g2}", "{g3}" },
            worn = {},
            carried = {},
        }
    }
    local ok, errs = validate_inventory(fake, make_mock_registry({}))
    h.assert_eq(false, ok, "3 items in hands must fail validation")
    local found_inv01 = false
    for _, e in ipairs(errs) do
        if e:find("INV%-01") then found_inv01 = true end
    end
    h.assert_truthy(found_inv01, "must report INV-01 violation")
end)

-- 9. Worn slots must be valid (INV-02)
test("9. INV-02: worn slots must be valid", function()
    local fake = {
        inventory = {
            hands = {},
            worn = { head = "{helm-guid}", shoulder = "{bad-guid}" },
            carried = {},
        }
    }
    local ok, errs = validate_inventory(fake, make_mock_registry({}))
    h.assert_eq(false, ok, "invalid worn slot 'shoulder' must fail")
    local found_inv02 = false
    for _, e in ipairs(errs) do
        if e:find("INV%-02") then found_inv02 = true end
    end
    h.assert_truthy(found_inv02, "must report INV-02 violation")
end)

-- 10. Carried GUIDs must resolve (INV-03)
test("10. INV-03: unresolvable carried GUID fails validation", function()
    local fake = {
        inventory = {
            hands = {},
            worn = {},
            carried = { "{nonexistent-guid}" },
        }
    }
    local ok, errs = validate_inventory(fake, make_mock_registry({}))
    h.assert_eq(false, ok, "unresolvable GUID must fail validation")
    local found_inv03 = false
    for _, e in ipairs(errs) do
        if e:find("INV%-03") then found_inv03 = true end
    end
    h.assert_truthy(found_inv03, "must report INV-03 violation")
end)

-- 11. Empty inventory loads without error
test("11. empty inventory loads without error", function()
    local creature = {
        id = "test-creature",
        inventory = { hands = {}, worn = {}, carried = {} },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_truthy(ok, "empty inventory must validate — errors: " .. table.concat(errs or {}, "; "))
end)

-- 12. Creature without inventory field → no crash
test("12. creature without inventory field — no crash", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local ok, errs = validate_inventory(rat_def, make_mock_registry({}))
    h.assert_truthy(ok, "no inventory field should validate cleanly")
    h.assert_eq(0, #errs, "no errors expected")
end)

-- 13. Rat has no inventory
test("13. rat has no inventory field", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    h.assert_nil(rat_def.inventory, "rat should not have inventory")
end)

-- 14. Cat has no inventory
test("14. cat has no inventory field", function()
    h.assert_truthy(ok_cat, "cat.lua must load")
    h.assert_nil(cat_def.inventory, "cat should not have inventory")
end)

-- 15. Spider has no inventory (silk is byproduct, not inventory)
test("15. spider has no inventory — silk is death_state byproduct", function()
    h.assert_truthy(ok_spider, "spider.lua must load")
    h.assert_nil(spider_def.inventory, "spider should not have inventory (silk is byproduct)")
    h.assert_truthy(spider_def.death_state and spider_def.death_state.byproducts,
        "spider silk should come from death_state.byproducts, not inventory")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
