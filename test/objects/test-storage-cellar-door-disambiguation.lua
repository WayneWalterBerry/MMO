-- test/objects/test-storage-cellar-door-disambiguation.lua
-- Fix #309: Storage Cellar has two doors with overlapping names/keywords.
-- The south door (to cellar) = "the iron-bound door"
-- The north door (to deep cellar) = "the black iron door"
-- Players must be able to distinguish them in disambiguation prompts.
-- Run from repo root: lua test/objects/test-storage-cellar-door-disambiguation.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load both door objects (storage-cellar side)
---------------------------------------------------------------------------
local objects_dir = script_dir .. "/../../src/meta/objects/"
local south_door = dofile(objects_dir .. "storage-cellar-door-south.lua")
local north_door = dofile(objects_dir .. "storage-deep-cellar-door-north.lua")

---------------------------------------------------------------------------
-- Helper: exact keyword match (mirrors engine matches_keyword logic)
---------------------------------------------------------------------------
local function matches_keyword(obj, kw)
    if not obj then return false end
    kw = kw:lower()
    if obj.id and obj.id:lower() == kw then return true end
    if type(obj.keywords) == "table" then
        for _, k in ipairs(obj.keywords) do
            if k:lower() == kw then return true end
        end
    end
    if obj.name then
        local padded = " " .. obj.name:lower() .. " "
        if padded:find(" " .. kw .. " ", 1, true) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- TESTS: Distinct names
---------------------------------------------------------------------------
suite("STORAGE CELLAR DOOR DISAMBIGUATION (#309)")

test("1. South door name contains 'iron-bound'", function()
    h.assert_truthy(south_door.name:lower():find("iron%-bound"),
        "south door name should contain 'iron-bound', got: " .. south_door.name)
end)

test("2. North door name contains 'black iron'", function()
    h.assert_truthy(north_door.name:lower():find("black iron"),
        "north door name should contain 'black iron', got: " .. north_door.name)
end)

test("3. Door names are visually distinct", function()
    h.assert_truthy(south_door.name ~= north_door.name,
        "door names must differ for disambiguation prompt")
end)

---------------------------------------------------------------------------
-- TESTS: Unique keyword resolution
---------------------------------------------------------------------------

test("4. 'iron-bound door' matches south door only", function()
    h.assert_truthy(matches_keyword(south_door, "iron-bound door"),
        "'iron-bound door' must match south door")
    h.assert_truthy(not matches_keyword(north_door, "iron-bound door"),
        "'iron-bound door' must NOT match north door")
end)

test("5. 'black iron door' matches north door only", function()
    h.assert_truthy(matches_keyword(north_door, "black iron door"),
        "'black iron door' must match north door")
    h.assert_truthy(not matches_keyword(south_door, "black iron door"),
        "'black iron door' must NOT match south door")
end)

test("6. 'south door' matches south door only", function()
    h.assert_truthy(matches_keyword(south_door, "south door"),
        "'south door' must match south door")
    h.assert_truthy(not matches_keyword(north_door, "south door"),
        "'south door' must NOT match north door")
end)

test("7. 'north door' matches north door only", function()
    h.assert_truthy(matches_keyword(north_door, "north door"),
        "'north door' must match north door")
    h.assert_truthy(not matches_keyword(south_door, "north door"),
        "'north door' must NOT match south door")
end)

---------------------------------------------------------------------------
-- TESTS: No dangerous keyword overlap
-- "door" alone is expected to match both (generic noun) — that's fine.
-- But multi-word descriptive keywords must NOT overlap.
---------------------------------------------------------------------------

test("8. No multi-word keyword overlap between the two doors", function()
    local overlap = {}
    for _, sk in ipairs(south_door.keywords) do
        if sk:find(" ") then  -- multi-word only
            for _, nk in ipairs(north_door.keywords) do
                if sk:lower() == nk:lower() then
                    overlap[#overlap + 1] = sk
                end
            end
        end
    end
    h.assert_eq(0, #overlap,
        "multi-word keywords must not overlap, but found: " .. table.concat(overlap, ", "))
end)

---------------------------------------------------------------------------
-- TESTS: State names are also distinct
---------------------------------------------------------------------------

test("9. Locked-state names are distinct", function()
    local s_name = south_door.states.locked.name
    local n_name = north_door.states.locked.name
    h.assert_truthy(s_name ~= n_name,
        "locked state names must differ: south=" .. s_name .. " north=" .. n_name)
end)

test("10. Open-state names are distinct", function()
    local s_name = south_door.states.open.name
    local n_name = north_door.states.open.name
    h.assert_truthy(s_name ~= n_name,
        "open state names must differ: south=" .. s_name .. " north=" .. n_name)
end)

test("11. Closed-state names are distinct", function()
    local s_name = south_door.states.closed.name
    local n_name = north_door.states.closed.name
    h.assert_truthy(s_name ~= n_name,
        "closed state names must differ: south=" .. s_name .. " north=" .. n_name)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
