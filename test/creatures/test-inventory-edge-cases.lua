-- test/creatures/test-inventory-edge-cases.lua
-- WAVE-2 TDD: Edge cases for creature inventory validation — boundary
-- conditions, malformed data, nil handling.
-- Must be run from repository root: lua test/creatures/test-inventory-edge-cases.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Validation (same contract as test-creature-inventory.lua)
---------------------------------------------------------------------------
local VALID_WORN_SLOTS = { head = true, torso = true, arms = true, legs = true, feet = true }

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects or {}) do
        if obj.guid then reg._objects[obj.guid] = obj end
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] or nil end
    return reg
end

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
-- TESTS: Inventory edge cases (WAVE-2)
---------------------------------------------------------------------------
suite("INVENTORY EDGE CASES: boundary and malformed data (WAVE-2)")

-- 1. Over-hand-limit: 3 items → INV-01 violation
test("1. INV-01: 3 items in hands → validation error", function()
    local creature = {
        id = "over-hands",
        inventory = { hands = { "{g1}", "{g2}", "{g3}" }, worn = {}, carried = {} },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_eq(false, ok, "3 items in hands must fail")
    local found = false
    for _, e in ipairs(errs) do if e:find("INV%-01") then found = true end end
    h.assert_truthy(found, "must report INV-01")
end)

-- 2. Exactly 2 items in hands → valid
test("2. exactly 2 items in hands — valid", function()
    local g1, g2 = "{hand-a}", "{hand-b}"
    local creature = {
        id = "two-hands",
        inventory = { hands = { g1, g2 }, worn = {}, carried = {} },
    }
    local reg = make_mock_registry({
        { guid = g1, id = "a" }, { guid = g2, id = "b" },
    })
    local ok, errs = validate_inventory(creature, reg)
    h.assert_truthy(ok, "2 items in hands is valid — errors: " .. table.concat(errs or {}, "; "))
end)

-- 3. Invalid worn slot → INV-02 violation
test("3. INV-02: invalid worn slot 'shoulder' → validation error", function()
    local creature = {
        id = "bad-slot",
        inventory = { hands = {}, worn = { shoulder = "{helm}" }, carried = {} },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_eq(false, ok, "invalid worn slot must fail")
    local found = false
    for _, e in ipairs(errs) do if e:find("INV%-02") then found = true end end
    h.assert_truthy(found, "must report INV-02 for 'shoulder'")
end)

-- 4. All valid worn slots pass
test("4. all valid worn slots pass validation", function()
    local creature = {
        id = "full-armor",
        inventory = {
            hands = {},
            worn = {
                head = "{helm}", torso = "{plate}",
                arms = "{bracers}", legs = "{greaves}", feet = "{boots}",
            },
            carried = {},
        },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_truthy(ok, "valid worn slots must pass — errors: " .. table.concat(errs or {}, "; "))
end)

-- 5. Non-existent GUID in carried → INV-03 violation
test("5. INV-03: non-existent GUID in carried → validation error", function()
    local creature = {
        id = "bad-guid",
        inventory = { hands = {}, worn = {}, carried = { "{does-not-exist}" } },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_eq(false, ok, "unresolvable GUID must fail")
    local found = false
    for _, e in ipairs(errs) do if e:find("INV%-03") then found = true end end
    h.assert_truthy(found, "must report INV-03")
end)

-- 6. Empty arrays in all slots → clean pass
test("6. empty arrays in all slots — clean pass", function()
    local creature = {
        id = "empty-inv",
        inventory = { hands = {}, worn = {}, carried = {} },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_truthy(ok, "empty inventory must pass — errors: " .. table.concat(errs or {}, "; "))
    h.assert_eq(0, #errs, "no errors for empty inventory")
end)

-- 7. nil inventory → no crash
test("7. nil inventory — no crash", function()
    local creature = { id = "no-inv" }
    h.assert_no_error(function()
        local ok, errs = validate_inventory(creature, make_mock_registry({}))
        h.assert_truthy(ok, "nil inventory must pass")
        h.assert_eq(0, #errs, "no errors for nil inventory")
    end, "nil inventory must not crash")
end)

-- 8. nil creature → graceful failure
test("8. nil creature — graceful failure", function()
    local ok, errs = validate_inventory(nil, make_mock_registry({}))
    h.assert_eq(false, ok, "nil creature must fail validation")
    h.assert_truthy(#errs > 0, "must have error message for nil creature")
end)

-- 9. Multiple INV violations reported together
test("9. multiple violations reported together", function()
    local creature = {
        id = "multi-bad",
        inventory = {
            hands = { "{g1}", "{g2}", "{g3}" },
            worn = { back = "{bad}" },
            carried = { "{phantom}" },
        },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_eq(false, ok, "multiple violations must fail")
    -- Should have at least INV-01 + INV-02 + INV-03
    local inv01, inv02, inv03 = false, false, false
    for _, e in ipairs(errs) do
        if e:find("INV%-01") then inv01 = true end
        if e:find("INV%-02") then inv02 = true end
        if e:find("INV%-03") then inv03 = true end
    end
    h.assert_truthy(inv01, "must report INV-01")
    h.assert_truthy(inv02, "must report INV-02")
    h.assert_truthy(inv03, "must report INV-03")
end)

-- 10. Inventory with only hands slot → valid
test("10. inventory with only hands slot — valid", function()
    local creature = {
        id = "hands-only",
        inventory = { hands = {} },
    }
    local ok, errs = validate_inventory(creature, make_mock_registry({}))
    h.assert_truthy(ok, "hands-only inventory must pass — errors: " .. table.concat(errs or {}, "; "))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
