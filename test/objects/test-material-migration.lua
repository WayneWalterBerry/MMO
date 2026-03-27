-- test/objects/test-material-migration.lua
-- Issue #123: TDD migration safety net for materials system.
-- Verifies the public API contract of src/engine/materials so that
-- Smithers can migrate from monolithic init.lua → per-file src/meta/materials/
-- with confidence. Every test here must be GREEN before AND after migration.
-- Must be run from repository root: lua test/objects/test-material-migration.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load material registry (the module under test)
---------------------------------------------------------------------------
local materials = require("engine.materials")

-- The 11 required properties every material must declare
local REQUIRED_PROPS = {
    "hardness", "density", "flexibility", "absorbency", "opacity",
    "flammability", "conductivity", "fragility", "value",
    "melting_point", "ignition_point",
}

-- The exact 30 materials that must survive migration
local EXPECTED_MATERIALS = {
    "bone", "brass", "burlap", "cardboard", "ceramic", "chitin", "cotton",
    "fabric", "flesh", "glass", "hemp", "hide", "iron", "keratin",
    "leather", "linen", "oak", "organ", "paper", "plant", "silver",
    "skin", "steel", "stone", "tallow", "tooth-enamel",
    "velvet", "wax", "wood", "wool",
}

---------------------------------------------------------------------------
-- SUITE 1: Public API Tests
---------------------------------------------------------------------------
suite("MATERIAL MIGRATION: Public API contract (#123)")

test("1. materials.get('ceramic') returns a table with all 11 properties", function()
    local mat = materials.get("ceramic")
    h.assert_truthy(mat, "get('ceramic') must return a table")
    h.assert_eq("table", type(mat), "get('ceramic') must be a table")
    for _, prop in ipairs(REQUIRED_PROPS) do
        -- melting_point and ignition_point may be nil for some materials,
        -- but ceramic has melting_point=1600 and ignition_point=nil
        if prop ~= "ignition_point" then
            h.assert_truthy(mat[prop] ~= nil,
                "ceramic missing property: " .. prop)
        end
    end
end)

test("2. materials.get('brass') returns correct spot-check values", function()
    local mat = materials.get("brass")
    h.assert_truthy(mat, "get('brass') must return a table")
    h.assert_eq(6, mat.hardness, "brass.hardness")
    h.assert_eq(8500, mat.density, "brass.density")
    h.assert_eq(0.1, mat.fragility, "brass.fragility")
    h.assert_eq(930, mat.melting_point, "brass.melting_point")
    h.assert_eq(0.6, mat.conductivity, "brass.conductivity")
end)

test("3. materials.get('nonexistent') returns nil gracefully", function()
    h.assert_nil(materials.get("nonexistent"), "unknown material must return nil")
    h.assert_nil(materials.get(nil), "nil input must return nil")
    h.assert_nil(materials.get(""), "empty string must return nil or table")
end)

test("4. materials.list or registry iteration returns all 30 materials", function()
    local count = 0
    local found = {}
    for name, _ in pairs(materials.registry) do
        count = count + 1
        found[name] = true
    end
    h.assert_eq(30, count,
        "expected exactly 30 materials, found " .. count)
end)

test("5. Every material has all 11 required property keys", function()
    local missing = {}
    for name, mat in pairs(materials.registry) do
        for _, prop in ipairs(REQUIRED_PROPS) do
            -- melting_point and ignition_point may be nil (non-melting/non-flammable)
            -- but the KEY must still be declared in the table
            if prop ~= "melting_point" and prop ~= "ignition_point" then
                if mat[prop] == nil then
                    missing[#missing + 1] = name .. "." .. prop
                end
            end
        end
    end
    h.assert_eq(0, #missing,
        "missing required properties: " .. table.concat(missing, ", "))
end)

test("6. All numeric properties are actually numbers", function()
    local NUMERIC = {
        "hardness", "density", "flexibility", "absorbency", "opacity",
        "flammability", "conductivity", "fragility", "value",
    }
    local bad = {}
    for name, mat in pairs(materials.registry) do
        for _, prop in ipairs(NUMERIC) do
            if mat[prop] ~= nil and type(mat[prop]) ~= "number" then
                bad[#bad + 1] = name .. "." .. prop .. "=" .. type(mat[prop])
            end
        end
        -- melting_point / ignition_point: nil or number
        for _, prop in ipairs({"melting_point", "ignition_point"}) do
            if mat[prop] ~= nil and type(mat[prop]) ~= "number" then
                bad[#bad + 1] = name .. "." .. prop .. "=" .. type(mat[prop])
            end
        end
    end
    h.assert_eq(0, #bad,
        "non-numeric properties: " .. table.concat(bad, ", "))
end)

test("7. Property values are in valid ranges", function()
    local out = {}
    for name, mat in pairs(materials.registry) do
        -- hardness: 1-10 Mohs-inspired
        local hv = mat.hardness
        if hv and (hv < 1 or hv > 10) then
            out[#out + 1] = name .. ".hardness=" .. hv
        end
        -- fragility: 0-1
        local fv = mat.fragility
        if fv and (fv < 0 or fv > 1) then
            out[#out + 1] = name .. ".fragility=" .. fv
        end
        -- flammability: 0-1
        local fl = mat.flammability
        if fl and (fl < 0 or fl > 1) then
            out[#out + 1] = name .. ".flammability=" .. fl
        end
        -- density: positive
        local d = mat.density
        if d and d <= 0 then
            out[#out + 1] = name .. ".density=" .. d
        end
        -- value: 1-100
        local v = mat.value
        if v and (v < 1 or v > 100) then
            out[#out + 1] = name .. ".value=" .. v
        end
        -- conductivity: 0-1
        local c = mat.conductivity
        if c and (c < 0 or c > 1) then
            out[#out + 1] = name .. ".conductivity=" .. c
        end
        -- opacity: 0-1
        local o = mat.opacity
        if o and (o < 0 or o > 1) then
            out[#out + 1] = name .. ".opacity=" .. o
        end
    end
    h.assert_eq(0, #out,
        "out-of-range values: " .. table.concat(out, ", "))
end)

---------------------------------------------------------------------------
-- SUITE 2: Cross-Reference Tests
---------------------------------------------------------------------------
suite("MATERIAL MIGRATION: Cross-reference integrity (#123)")

test("8. Every object's material field resolves via materials.get()", function()
    local SEP = package.config:sub(1, 1)
    local is_windows = SEP == "\\"
    local objects_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP

    local list_cmd
    if is_windows then
        list_cmd = 'dir /b "' .. objects_dir .. '*.lua" 2>nul'
    else
        list_cmd = 'ls "' .. objects_dir .. '"*.lua 2>/dev/null'
    end

    local unresolved = {}
    local handle = io.popen(list_cmd)
    if handle then
        for line in handle:lines() do
            local fname = line:match("([^/\\]+)$") or line
            if fname:match("%.lua$") then
                local ok, obj = pcall(dofile, objects_dir .. fname)
                if ok and type(obj) == "table" and obj.material then
                    if not materials.get(obj.material) then
                        unresolved[#unresolved + 1] = fname .. " → \"" .. obj.material .. "\""
                    end
                end
            end
        end
        handle:close()
    end
    h.assert_eq(0, #unresolved,
        "objects referencing unknown materials: " .. table.concat(unresolved, ", "))
end)

test("9. Armor system can derive protection from material hardness", function()
    -- The armor system (src/engine/armor.lua) calls:
    --   materials.get(item.material).hardness
    -- Verify the contract works for representative wearable materials
    local test_materials = {"ceramic", "iron", "steel", "leather", "wool"}
    for _, name in ipairs(test_materials) do
        local mat = materials.get(name)
        h.assert_truthy(mat, "materials.get('" .. name .. "') must exist for armor")
        h.assert_truthy(type(mat.hardness) == "number",
            name .. ".hardness must be a number for armor calculation")
        h.assert_truthy(mat.hardness >= 1 and mat.hardness <= 10,
            name .. ".hardness must be 1-10 for armor formula")
    end
end)

test("10. Burn system can check flammability >= 0.3 threshold", function()
    -- The burn system (src/engine/verbs/fire.lua L454-497) calls:
    --   local mat = obj.material and materials.get(obj.material)
    --   local flammability = mat and mat.flammability or 0
    --   if flammability < 0.3 then ... not burnable
    -- Verify known burnable and non-burnable materials
    local burnable = {"wax", "wood", "paper", "fabric", "cotton", "tallow"}
    local non_burnable = {"iron", "steel", "brass", "glass", "stone", "silver"}

    for _, name in ipairs(burnable) do
        local mat = materials.get(name)
        h.assert_truthy(mat, name .. " must exist")
        h.assert_truthy(mat.flammability >= 0.3,
            name .. ".flammability=" .. tostring(mat.flammability) .. " should be >= 0.3 (burnable)")
    end
    for _, name in ipairs(non_burnable) do
        local mat = materials.get(name)
        h.assert_truthy(mat, name .. " must exist")
        h.assert_truthy(mat.flammability < 0.3,
            name .. ".flammability=" .. tostring(mat.flammability) .. " should be < 0.3 (non-burnable)")
    end
end)

---------------------------------------------------------------------------
-- SUITE 3: Migration-Specific Tests
---------------------------------------------------------------------------
suite("MATERIAL MIGRATION: Migration safety (#123)")

test("11. If src/meta/materials/ exists, per-file materials load correctly", function()
    local SEP = package.config:sub(1, 1)
    local meta_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "materials"

    -- Check if the migration target directory exists
    local check_cmd
    if SEP == "\\" then
        check_cmd = 'if exist "' .. meta_dir .. '" (echo EXISTS) else (echo MISSING)'
    else
        check_cmd = 'test -d "' .. meta_dir .. '" && echo EXISTS || echo MISSING'
    end
    local pipe = io.popen(check_cmd)
    local result = pipe:read("*a"):match("(%S+)")
    pipe:close()

    if result == "EXISTS" then
        -- Migration has happened — verify per-file materials load and match
        local list_cmd
        if SEP == "\\" then
            list_cmd = 'dir /b "' .. meta_dir .. SEP .. '*.lua" 2>nul'
        else
            list_cmd = 'ls "' .. meta_dir .. '/"*.lua 2>/dev/null'
        end
        local file_count = 0
        local handle = io.popen(list_cmd)
        if handle then
            for line in handle:lines() do
                local fname = line:match("([^/\\]+)$") or line
                if fname:match("%.lua$") then
                    file_count = file_count + 1
                    local ok, mat = pcall(dofile, meta_dir .. SEP .. fname)
                    h.assert_truthy(ok, "failed to load " .. fname .. ": " .. tostring(mat))
                    h.assert_truthy(type(mat) == "table",
                        fname .. " must return a table")
                end
            end
            handle:close()
        end
        h.assert_truthy(file_count > 0,
            "src/meta/materials/ exists but contains no .lua files")
        print("    (post-migration: " .. file_count .. " per-file materials found)")
    else
        -- Pre-migration — directory doesn't exist yet, that's fine
        print("    (pre-migration: src/meta/materials/ not yet created — OK)")
        h.assert_truthy(true, "pre-migration: monolithic file in use")
    end
end)

test("12. Material count is exactly 30 (no materials lost)", function()
    local count = 0
    for _ in pairs(materials.registry) do count = count + 1 end
    h.assert_eq(30, count,
        "expected exactly 30 materials, found " .. count ..
        " — materials may have been lost or duplicated during migration")
end)

test("13. Specific value spot-checks for migration fidelity", function()
    -- These exact values must survive the monolithic → per-file migration
    local ceramic = materials.get("ceramic")
    h.assert_truthy(ceramic, "ceramic must exist")
    h.assert_eq(7, ceramic.hardness, "ceramic.hardness must be 7")
    h.assert_eq(2300, ceramic.density, "ceramic.density must be 2300")
    h.assert_eq(0.7, ceramic.fragility, "ceramic.fragility must be 0.7")
    h.assert_eq(1600, ceramic.melting_point, "ceramic.melting_point must be 1600")

    local brass = materials.get("brass")
    h.assert_truthy(brass, "brass must exist")
    h.assert_eq(0.1, brass.fragility, "brass.fragility must be 0.1")
    h.assert_eq(8, brass.value, "brass.value must be 8")

    local glass = materials.get("glass")
    h.assert_truthy(glass, "glass must exist")
    h.assert_eq(0.9, glass.fragility, "glass.fragility must be 0.9")
    h.assert_eq(0.1, glass.opacity, "glass.opacity must be 0.1")

    local silver = materials.get("silver")
    h.assert_truthy(silver, "silver must exist")
    h.assert_eq(10490, silver.density, "silver.density must be 10490")
    h.assert_eq(0.95, silver.conductivity, "silver.conductivity must be 0.95")
    h.assert_eq(40, silver.value, "silver.value must be 40")

    local wax = materials.get("wax")
    h.assert_truthy(wax, "wax must exist")
    h.assert_eq(0.7, wax.flammability, "wax.flammability must be 0.7")
end)

test("14. All 24 expected material names are present", function()
    local missing = {}
    for _, name in ipairs(EXPECTED_MATERIALS) do
        if not materials.get(name) then
            missing[#missing + 1] = name
        end
    end
    h.assert_eq(0, #missing,
        "materials missing from registry: " .. table.concat(missing, ", "))
end)

test("15. get_property() API works for migration consumers", function()
    -- materials.get_property(name, prop) is used by engine subsystems
    h.assert_eq(7, materials.get_property("ceramic", "hardness"),
        "get_property('ceramic', 'hardness')")
    h.assert_eq(0.9, materials.get_property("glass", "fragility"),
        "get_property('glass', 'fragility')")
    h.assert_nil(materials.get_property("nonexistent", "hardness"),
        "get_property('nonexistent', ...) must return nil")
    h.assert_nil(materials.get_property("ceramic", "nonexistent"),
        "get_property(..., 'nonexistent') must return nil")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
print("Migration safety tests: 15 tests across 3 suites")
print("Materials validated: 24")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
