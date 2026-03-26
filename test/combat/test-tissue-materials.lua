-- test/combat/test-tissue-materials.lua
-- WAVE-4 TDD: Validates 7 tissue materials load and have required properties.
-- Tests: flesh (existing) + 6 new: skin, hide, bone, organ, tooth_enamel, keratin
-- Must be run from repository root: lua test/combat/test-tissue-materials.lua

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
-- Load materials registry
---------------------------------------------------------------------------
local ok_mat, materials = pcall(require, "engine.materials")
if not ok_mat then
    print("WARNING: engine.materials failed to load — " .. tostring(materials))
    materials = nil
end

-- All 7 tissue materials expected for combat system
local tissue_names = { "flesh", "skin", "hide", "bone", "organ", "tooth-enamel", "keratin" }

-- Required properties every tissue material must have
local required_props = { "density", "hardness", "flexibility", "fragility", "value" }

---------------------------------------------------------------------------
-- MATERIAL LOADING TESTS
---------------------------------------------------------------------------
suite("TISSUE MATERIALS: loading (WAVE-4)")

test("1. materials module loads", function()
    h.assert_truthy(ok_mat,
        "engine.materials must load: " .. tostring(materials))
    h.assert_truthy(materials, "materials module must not be nil")
end)

test("2. flesh material loads via materials.get('flesh')", function()
    h.assert_truthy(materials, "materials module not loaded")
    local flesh = materials.get("flesh")
    h.assert_truthy(flesh,
        "Material 'flesh' not found in registry — check src/meta/materials/flesh.lua "
        .. "exists and materials/init.lua auto-discovers it")
    h.assert_eq("table", type(flesh), "flesh must be a table")
end)

test("3. skin material loads via materials.get('skin')", function()
    h.assert_truthy(materials, "materials module not loaded")
    local skin = materials.get("skin")
    h.assert_truthy(skin,
        "Material 'skin' not found in registry — check src/meta/materials/skin.lua "
        .. "exists and materials/init.lua auto-discovers it")
    h.assert_eq("table", type(skin), "skin must be a table")
end)

test("4. hide material loads", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("hide")
    h.assert_truthy(mat,
        "Material 'hide' not found — src/meta/materials/hide.lua missing")
end)

test("5. bone material loads", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("bone")
    h.assert_truthy(mat,
        "Material 'bone' not found — src/meta/materials/bone.lua missing")
end)

test("6. organ material loads", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("organ")
    h.assert_truthy(mat,
        "Material 'organ' not found — src/meta/materials/organ.lua missing")
end)

test("7. tooth-enamel material loads", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("tooth-enamel")
    h.assert_truthy(mat,
        "Material 'tooth-enamel' not found — src/meta/materials/tooth-enamel.lua missing")
end)

test("8. keratin material loads", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("keratin")
    h.assert_truthy(mat,
        "Material 'keratin' not found — src/meta/materials/keratin.lua missing")
end)

---------------------------------------------------------------------------
-- REQUIRED PROPERTIES TESTS
---------------------------------------------------------------------------
suite("TISSUE MATERIALS: required properties (WAVE-4)")

-- Generate tests for each tissue material × each required property
local test_num = 9
for _, mat_name in ipairs(tissue_names) do
    for _, prop in ipairs(required_props) do
        local num = test_num
        test(num .. ". " .. mat_name .. " has " .. prop .. " (number)", function()
            h.assert_truthy(materials, "materials module not loaded")
            local mat = materials.get(mat_name)
            h.assert_truthy(mat, mat_name .. " not loaded")
            h.assert_truthy(mat[prop] ~= nil,
                mat_name .. " must have property: " .. prop)
            h.assert_eq("number", type(mat[prop]),
                mat_name .. "." .. prop .. " must be a number")
        end)
        test_num = test_num + 1
    end
end

---------------------------------------------------------------------------
-- VALUE RANGE TESTS
---------------------------------------------------------------------------
suite("TISSUE MATERIALS: value range [0, 100] (WAVE-4)")

for _, mat_name in ipairs(tissue_names) do
    local num = test_num
    test(num .. ". " .. mat_name .. " value in range [0, 100]", function()
        h.assert_truthy(materials, "materials module not loaded")
        local mat = materials.get(mat_name)
        h.assert_truthy(mat, mat_name .. " not loaded")
        local v = mat.value
        h.assert_truthy(v ~= nil, mat_name .. ".value must exist")
        h.assert_truthy(v >= 0 and v <= 100,
            mat_name .. ".value must be in [0, 100], got: " .. tostring(v))
    end)
    test_num = test_num + 1
end

---------------------------------------------------------------------------
-- SPECIAL PROPERTIES (max_edge on tooth_enamel and keratin)
---------------------------------------------------------------------------
suite("TISSUE MATERIALS: combat-specific properties (WAVE-4)")

test(test_num .. ". tooth-enamel has max_edge property", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("tooth-enamel")
    h.assert_truthy(mat, "tooth-enamel not loaded")
    h.assert_truthy(mat.max_edge ~= nil, "tooth-enamel must have max_edge")
    h.assert_eq("number", type(mat.max_edge), "tooth-enamel.max_edge must be a number")
end)
test_num = test_num + 1

test(test_num .. ". keratin has max_edge property", function()
    h.assert_truthy(materials, "materials module not loaded")
    local mat = materials.get("keratin")
    h.assert_truthy(mat, "keratin not loaded")
    h.assert_truthy(mat.max_edge ~= nil, "keratin must have max_edge")
    h.assert_eq("number", type(mat.max_edge), "keratin.max_edge must be a number")
end)
test_num = test_num + 1

---------------------------------------------------------------------------
-- TOTAL MATERIAL COUNT
---------------------------------------------------------------------------
suite("TISSUE MATERIALS: count verification (WAVE-4)")

test(test_num .. ". all 7 tissue materials are present in registry", function()
    h.assert_truthy(materials, "materials module not loaded")
    local missing = {}
    for _, name in ipairs(tissue_names) do
        if not materials.get(name) then
            missing[#missing + 1] = name
        end
    end
    h.assert_eq(0, #missing,
        "Missing tissue materials: " .. table.concat(missing, ", "))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
