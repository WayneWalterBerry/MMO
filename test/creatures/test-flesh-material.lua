-- test/creatures/test-flesh-material.lua
-- WAVE-1 TDD: Validates flesh.lua material loads correctly and integrates
-- with the material registry.
-- Must be run from repository root: lua test/creatures/test-flesh-material.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load flesh.lua directly via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local flesh_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "materials" .. SEP .. "flesh.lua"

local ok_direct, flesh = pcall(dofile, flesh_path)
if not ok_direct then
    print("WARNING: flesh.lua not found — tests will fail (TDD: expected)")
    flesh = nil
end

---------------------------------------------------------------------------
-- Load material registry to test integration
---------------------------------------------------------------------------
local ok_reg, materials = pcall(require, "engine.materials")
if not ok_reg then
    print("WARNING: material registry failed to load — registry tests will fail")
    materials = nil
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("FLESH MATERIAL: definition + registry validation (WAVE-1)")

-- Direct dofile loading
test("1. flesh.lua loads successfully via dofile", function()
    h.assert_truthy(ok_direct, "flesh.lua failed to load: " .. tostring(flesh))
    h.assert_truthy(type(flesh) == "table", "flesh.lua must return a table")
end)

test("2. name is 'flesh'", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("flesh", flesh.name, "material name must be 'flesh'")
end)

test("3. guid exists and is a string", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_truthy(flesh.guid, "flesh must have a guid")
    h.assert_eq("string", type(flesh.guid), "guid must be a string")
end)

-- Core material properties
test("4. density is a positive number", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.density), "density must be a number")
    h.assert_truthy(flesh.density > 0, "density must be positive")
end)

test("5. density is approximately 1050 (muscle/fat tissue)", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq(1050, flesh.density, "flesh density should be 1050 kg/m³")
end)

test("6. hardness is a number in [1, 10] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.hardness), "hardness must be a number")
    h.assert_eq(1, flesh.hardness, "flesh hardness should be 1 (very soft)")
end)

test("7. flexibility is a number in [0, 1] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.flexibility), "flexibility must be a number")
    h.assert_truthy(flesh.flexibility >= 0.0 and flesh.flexibility <= 1.0,
        "flexibility must be in [0, 1], got " .. tostring(flesh.flexibility))
    h.assert_eq(0.8, flesh.flexibility, "flesh flexibility should be 0.8")
end)

test("8. fragility is a number in [0, 1] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.fragility), "fragility must be a number")
    h.assert_truthy(flesh.fragility >= 0.0 and flesh.fragility <= 1.0,
        "fragility must be in [0, 1], got " .. tostring(flesh.fragility))
    h.assert_eq(0.7, flesh.fragility, "flesh fragility should be 0.7")
end)

test("9. absorbency is a number in [0, 1] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.absorbency), "absorbency must be a number")
    h.assert_truthy(flesh.absorbency >= 0.0 and flesh.absorbency <= 1.0,
        "absorbency must be in [0, 1]")
end)

test("10. opacity is a number in [0, 1] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.opacity), "opacity must be a number")
    h.assert_truthy(flesh.opacity >= 0.0 and flesh.opacity <= 1.0,
        "opacity must be in [0, 1]")
end)

test("11. flammability is a number in [0, 1] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.flammability), "flammability must be a number")
    h.assert_truthy(flesh.flammability >= 0.0 and flesh.flammability <= 1.0,
        "flammability must be in [0, 1]")
end)

test("12. conductivity is a number in [0, 1] range", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.conductivity), "conductivity must be a number")
    h.assert_truthy(flesh.conductivity >= 0.0 and flesh.conductivity <= 1.0,
        "conductivity must be in [0, 1]")
end)

test("13. value is a positive integer", function()
    h.assert_truthy(flesh, "flesh not loaded")
    h.assert_eq("number", type(flesh.value), "value must be a number")
    h.assert_truthy(flesh.value >= 1 and flesh.value <= 100,
        "value must be in [1, 100]")
    h.assert_eq(flesh.value, math.floor(flesh.value), "value must be an integer")
end)

-- Material registry integration
test("14. materials.get('flesh') returns a table", function()
    h.assert_truthy(materials, "material registry not loaded")
    local mat = materials.get("flesh")
    h.assert_truthy(mat, "materials.get('flesh') must return a table")
    h.assert_eq("table", type(mat), "materials.get('flesh') must be a table")
end)

test("15. registry flesh has correct density", function()
    h.assert_truthy(materials, "material registry not loaded")
    local mat = materials.get("flesh")
    h.assert_truthy(mat, "flesh must be in registry")
    h.assert_eq(1050, mat.density, "registry flesh density should be 1050")
end)

test("16. registry flesh has correct hardness", function()
    h.assert_truthy(materials, "material registry not loaded")
    local mat = materials.get("flesh")
    h.assert_truthy(mat, "flesh must be in registry")
    h.assert_eq(1, mat.hardness, "registry flesh hardness should be 1")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
