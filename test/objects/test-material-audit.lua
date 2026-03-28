-- test/objects/test-material-audit.lua
-- Fix #163: Structural test — every object in src/meta/objects/ must declare
-- a valid material that exists in the material registry.
-- Prevents regressions after the manual material audit.
-- Must be run from repository root: lua test/objects/test-material-audit.lua

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
local valid_materials = {}
for name, _ in pairs(materials.registry) do
    valid_materials[name] = true
end

---------------------------------------------------------------------------
-- Discover and load all object files
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

local objects_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP

local list_cmd
if is_windows then
    list_cmd = 'dir /b "' .. objects_dir .. '*.lua" 2>nul'
else
    list_cmd = 'ls "' .. objects_dir .. '"*.lua 2>/dev/null'
end

local object_files = {}
local handle = io.popen(list_cmd)
if handle then
    for line in handle:lines() do
        local fname = line:match("([^/\\]+)$") or line
        if fname:match("%.lua$") then
            object_files[#object_files + 1] = fname
        end
    end
    handle:close()
end

table.sort(object_files)

---------------------------------------------------------------------------
-- Classify objects
---------------------------------------------------------------------------
local loaded_objects = {}
local load_errors = {}
local missing_material = {}
local invalid_material = {}

for _, fname in ipairs(object_files) do
    local ok, obj = pcall(dofile, objects_dir .. fname)
    if ok and type(obj) == "table" then
        loaded_objects[#loaded_objects + 1] = { file = fname, obj = obj }
        if not obj.material and not obj.invisible then
            missing_material[#missing_material + 1] = fname
        elseif obj.material and not valid_materials[obj.material] then
            invalid_material[#invalid_material + 1] = fname .. " (material=\"" .. tostring(obj.material) .. "\")"
        end
    else
        load_errors[#load_errors + 1] = fname .. ": " .. tostring(obj)
    end
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("MATERIAL AUDIT: structural validation (#163)")

test("1. Found object files to test", function()
    h.assert_truthy(#object_files > 0, "must discover at least 1 object file")
    h.assert_truthy(#object_files >= 50,
        "expected 50+ objects, found " .. #object_files .. " — scan may be broken")
end)

test("2. All object files loaded successfully", function()
    h.assert_eq(0, #load_errors,
        "files that failed to load: " .. table.concat(load_errors, "; "))
end)

test("3. Every object declares a material field", function()
    h.assert_eq(0, #missing_material,
        "objects missing material: " .. table.concat(missing_material, ", "))
end)

test("4. Every material references a valid registry entry", function()
    h.assert_eq(0, #invalid_material,
        "objects with invalid material: " .. table.concat(invalid_material, ", "))
end)

test("5. Material field is always a string", function()
    local bad = {}
    for _, entry in ipairs(loaded_objects) do
        if entry.obj.material and type(entry.obj.material) ~= "string" then
            bad[#bad + 1] = entry.file
        end
    end
    h.assert_eq(0, #bad,
        "material must be a string in: " .. table.concat(bad, ", "))
end)

test("6. Material registry has entries", function()
    local count = 0
    for _ in pairs(valid_materials) do count = count + 1 end
    h.assert_truthy(count >= 10,
        "expected 10+ materials in registry, found " .. count)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
print("Objects scanned: " .. #loaded_objects .. "/" .. #object_files)
print("Materials in registry: " .. (function()
    local c = 0; for _ in pairs(valid_materials) do c = c + 1 end; return c
end)())
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
