-- test/objects/test-material-properties.lua
-- Issue #123: Validates material registry property completeness.
-- Every material must have the full 11-property bag with values in range.
-- Must be run from repository root: lua test/objects/test-material-properties.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load material registry
---------------------------------------------------------------------------
local materials = require("engine.materials")

-- The 11 core properties every material MUST have
local REQUIRED_PROPS = {
    "density",
    "melting_point",      -- nil allowed (materials that don't melt)
    "ignition_point",     -- nil allowed (non-flammable materials)
    "hardness",
    "flexibility",
    "absorbency",
    "opacity",
    "flammability",
    "conductivity",
    "fragility",
    "value",
}

-- Properties that must be numeric (nil is acceptable for melting/ignition)
local NUMERIC_REQUIRED = {
    "density", "hardness", "flexibility", "absorbency",
    "opacity", "flammability", "conductivity", "fragility", "value",
}

-- Properties that must be in [0.0, 1.0] range
local NORMALIZED_PROPS = {
    "flexibility", "absorbency", "opacity", "flammability",
    "conductivity", "fragility",
}

---------------------------------------------------------------------------
-- Collect materials
---------------------------------------------------------------------------
local mat_names = {}
for name, _ in pairs(materials.registry) do
    mat_names[#mat_names + 1] = name
end
table.sort(mat_names)

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("MATERIAL PROPERTIES: completeness validation (#123)")

test("1. Registry has 20+ materials", function()
    h.assert_truthy(#mat_names >= 20,
        "expected 20+ materials, found " .. #mat_names)
end)

test("2. Every material declares all 11 core property keys", function()
    local missing = {}
    for _, name in ipairs(mat_names) do
        local mat = materials.registry[name]
        for _, prop in ipairs(REQUIRED_PROPS) do
            if mat[prop] == nil and prop ~= "melting_point" and prop ~= "ignition_point" then
                missing[#missing + 1] = name .. "." .. prop
            end
        end
    end
    h.assert_eq(0, #missing,
        "missing required properties: " .. table.concat(missing, ", "))
end)

test("3. Numeric properties are actually numbers", function()
    local bad = {}
    for _, name in ipairs(mat_names) do
        local mat = materials.registry[name]
        for _, prop in ipairs(NUMERIC_REQUIRED) do
            if mat[prop] ~= nil and type(mat[prop]) ~= "number" then
                bad[#bad + 1] = name .. "." .. prop .. "=" .. type(mat[prop])
            end
        end
    end
    h.assert_eq(0, #bad,
        "non-numeric properties: " .. table.concat(bad, ", "))
end)

test("4. Normalized properties are in [0.0, 1.0] range", function()
    local out_of_range = {}
    for _, name in ipairs(mat_names) do
        local mat = materials.registry[name]
        for _, prop in ipairs(NORMALIZED_PROPS) do
            local v = mat[prop]
            if v ~= nil and (v < 0.0 or v > 1.0) then
                out_of_range[#out_of_range + 1] = name .. "." .. prop .. "=" .. v
            end
        end
    end
    h.assert_eq(0, #out_of_range,
        "out-of-range properties: " .. table.concat(out_of_range, ", "))
end)

test("5. Hardness is in [1, 10] Mohs-inspired range", function()
    local bad = {}
    for _, name in ipairs(mat_names) do
        local h_val = materials.registry[name].hardness
        if h_val and (h_val < 1 or h_val > 10) then
            bad[#bad + 1] = name .. ".hardness=" .. h_val
        end
    end
    h.assert_eq(0, #bad,
        "hardness out of range: " .. table.concat(bad, ", "))
end)

test("6. Density is positive", function()
    local bad = {}
    for _, name in ipairs(mat_names) do
        local d = materials.registry[name].density
        if d and d <= 0 then
            bad[#bad + 1] = name .. ".density=" .. d
        end
    end
    h.assert_eq(0, #bad,
        "non-positive density: " .. table.concat(bad, ", "))
end)

test("7. Value is a positive integer (1-100)", function()
    local bad = {}
    for _, name in ipairs(mat_names) do
        local v = materials.registry[name].value
        if v then
            if v < 1 or v > 100 or v ~= math.floor(v) then
                bad[#bad + 1] = name .. ".value=" .. v
            end
        end
    end
    h.assert_eq(0, #bad,
        "invalid value: " .. table.concat(bad, ", "))
end)

test("8. materials.get() returns correct tables", function()
    h.assert_truthy(materials.get("wax"), "get('wax') should return a table")
    h.assert_eq(nil, materials.get("nonexistent"), "get('nonexistent') should return nil")
    h.assert_eq(nil, materials.get(nil), "get(nil) should return nil")
end)

test("9. materials.get_property() returns correct values", function()
    h.assert_eq(900, materials.get_property("wax", "density"))
    h.assert_eq(nil, materials.get_property("nonexistent", "density"))
    h.assert_eq(nil, materials.get_property("wax", "nonexistent"))
end)

test("10. Melting/ignition points are nil or positive numbers", function()
    local bad = {}
    for _, name in ipairs(mat_names) do
        local mat = materials.registry[name]
        for _, prop in ipairs({"melting_point", "ignition_point"}) do
            local v = mat[prop]
            if v ~= nil then
                if type(v) ~= "number" or v <= 0 then
                    bad[#bad + 1] = name .. "." .. prop .. "=" .. tostring(v)
                end
            end
        end
    end
    h.assert_eq(0, #bad,
        "invalid temperature points: " .. table.concat(bad, ", "))
end)

test("11. No duplicate materials (registry keys are unique by definition)", function()
    -- Lua tables enforce unique keys, but verify count matches iteration
    local count = 0
    for _ in pairs(materials.registry) do count = count + 1 end
    h.assert_eq(#mat_names, count, "material count mismatch")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
print("Materials validated: " .. #mat_names)
print("Properties checked per material: " .. #REQUIRED_PROPS)
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
