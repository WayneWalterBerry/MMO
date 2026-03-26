-- test/objects/test-object-templates.lua
-- Fix #124: Structural test — every object in src/meta/objects/ must declare a template.
-- Valid templates: small-item, container, furniture, sheet
-- Must be run from repository root: lua test/objects/test-object-templates.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Discover and load all object files
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local is_windows = SEP == "\\"

-- Use repo root (cwd) for reliable path resolution
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

local VALID_TEMPLATES = {
    ["small-item"] = true,
    ["container"]  = true,
    ["creature"]   = true,
    ["furniture"]  = true,
    ["sheet"]      = true,
    ["portal"]     = true,
}

---------------------------------------------------------------------------
-- TEST: All objects discovered
---------------------------------------------------------------------------
suite("OBJECT TEMPLATES: structural validation (#124)")

test("1. Found object files to test", function()
    h.assert_truthy(#object_files > 0, "must discover at least 1 object file")
    -- We know there are 83 objects; fail if fewer than 50 found (catch scan bugs)
    h.assert_truthy(#object_files >= 50,
        "expected 50+ objects, found " .. #object_files .. " — scan may be broken")
end)

---------------------------------------------------------------------------
-- TEST: Every object has a template field
---------------------------------------------------------------------------
local missing_template = {}
local invalid_template = {}
local loaded_objects = {}

for _, fname in ipairs(object_files) do
    local ok, obj = pcall(dofile, objects_dir .. fname)
    if ok and type(obj) == "table" then
        loaded_objects[#loaded_objects + 1] = { file = fname, obj = obj }
        if not obj.template then
            missing_template[#missing_template + 1] = fname
        elseif not VALID_TEMPLATES[obj.template] then
            invalid_template[#invalid_template + 1] = fname .. " (" .. tostring(obj.template) .. ")"
        end
    end
end

test("2. Every object declares a template field", function()
    h.assert_eq(0, #missing_template,
        "objects missing template: " .. table.concat(missing_template, ", "))
end)

test("3. Every template value is a recognized type", function()
    h.assert_eq(0, #invalid_template,
        "objects with invalid template: " .. table.concat(invalid_template, ", "))
end)

test("4. Template is always a string", function()
    local bad = {}
    for _, entry in ipairs(loaded_objects) do
        if entry.obj.template and type(entry.obj.template) ~= "string" then
            bad[#bad + 1] = entry.file
        end
    end
    h.assert_eq(0, #bad,
        "template must be a string in: " .. table.concat(bad, ", "))
end)

---------------------------------------------------------------------------
-- TEST: Required fields alongside template
---------------------------------------------------------------------------
test("5. Every object has an id field", function()
    local bad = {}
    for _, entry in ipairs(loaded_objects) do
        if not entry.obj.id then
            bad[#bad + 1] = entry.file
        end
    end
    h.assert_eq(0, #bad,
        "objects missing id: " .. table.concat(bad, ", "))
end)

test("6. Every object has a keywords table", function()
    local bad = {}
    for _, entry in ipairs(loaded_objects) do
        if type(entry.obj.keywords) ~= "table" or #entry.obj.keywords == 0 then
            bad[#bad + 1] = entry.file
        end
    end
    h.assert_eq(0, #bad,
        "objects missing or empty keywords: " .. table.concat(bad, ", "))
end)

test("7. Every object has a name", function()
    local bad = {}
    for _, entry in ipairs(loaded_objects) do
        if not entry.obj.name or #entry.obj.name == 0 then
            bad[#bad + 1] = entry.file
        end
    end
    h.assert_eq(0, #bad,
        "objects missing name: " .. table.concat(bad, ", "))
end)

test("8. Every object has a guid", function()
    local bad = {}
    for _, entry in ipairs(loaded_objects) do
        if not entry.obj.guid then
            bad[#bad + 1] = entry.file
        end
    end
    h.assert_eq(0, #bad,
        "objects missing guid: " .. table.concat(bad, ", "))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
print("Objects scanned: " .. #loaded_objects .. "/" .. #object_files)
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
