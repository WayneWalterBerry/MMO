-- test/rooms/test-butcher-knife-placement.lua
-- Issue #351: butcher-knife not placed in any room
-- TDD: Tests that the butcher-knife is placed in a Level 1 room
-- and is discoverable by the player before reaching the wolf.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

-- Load the butcher-knife object
local knife = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/butcher-knife.lua")

-- Load all Level 1 rooms
local rooms_dir = script_dir .. "/../../src/meta/worlds/manor/rooms/"
local rooms = {
    ["start-room"]     = dofile(rooms_dir .. "start-room.lua"),
    ["cellar"]         = dofile(rooms_dir .. "cellar.lua"),
    ["storage-cellar"] = dofile(rooms_dir .. "storage-cellar.lua"),
    ["deep-cellar"]    = dofile(rooms_dir .. "deep-cellar.lua"),
    ["crypt"]          = dofile(rooms_dir .. "crypt.lua"),
    ["hallway"]        = dofile(rooms_dir .. "hallway.lua"),
    ["courtyard"]      = dofile(rooms_dir .. "courtyard.lua"),
}

-- Helper: recursively search instances tree for a given type_id (GUID)
local function find_instance_by_type_id(instances, target_guid)
    if not instances then return nil end
    local normalized = target_guid:gsub("[{}]", ""):lower()
    for _, inst in ipairs(instances) do
        local inst_guid = (inst.type_id or ""):gsub("[{}]", ""):lower()
        if inst_guid == normalized then return inst end
        -- Check nested containers
        for _, key in ipairs({"on_top", "contents", "nested", "underneath"}) do
            if type(inst[key]) == "table" then
                local found = find_instance_by_type_id(inst[key], target_guid)
                if found then return found end
            end
        end
    end
    return nil
end

-- Helper: find instance by id
local function find_instance_by_id(instances, target_id)
    if not instances then return nil end
    for _, inst in ipairs(instances) do
        if inst.id == target_id then return inst end
        for _, key in ipairs({"on_top", "contents", "nested", "underneath"}) do
            if type(inst[key]) == "table" then
                local found = find_instance_by_id(inst[key], target_id)
                if found then return found end
            end
        end
    end
    return nil
end

-- =========================================================================
suite("ISSUE #351 — Butcher-knife object validity")
-- =========================================================================

test("butcher-knife.lua exists and loads", function()
    h.assert_truthy(knife, "butcher-knife.lua must load")
    h.assert_eq("table", type(knife), "must return a table")
end)

test("butcher-knife has valid GUID", function()
    h.assert_truthy(knife.guid, "must have a guid")
    h.assert_eq("{9e8ab074-0888-42ab-b871-af7e39e59598}", knife.guid)
end)

test("butcher-knife has required sensory property on_feel", function()
    h.assert_truthy(knife.on_feel, "every object MUST have on_feel")
end)

test("butcher-knife is portable", function()
    h.assert_eq(true, knife.portable, "knife must be portable")
end)

-- =========================================================================
suite("ISSUE #351 — Butcher-knife placed in a Level 1 room")
-- =========================================================================

test("butcher-knife is referenced in at least one Level 1 room", function()
    local found_in = nil
    for room_id, room in pairs(rooms) do
        local inst = find_instance_by_type_id(room.instances, knife.guid)
        if not inst then
            inst = find_instance_by_id(room.instances, "butcher-knife")
        end
        if inst then
            found_in = room_id
            break
        end
    end
    h.assert_truthy(found_in,
        "butcher-knife must be placed in a Level 1 room (found in none)")
end)

test("butcher-knife is placed BEFORE the hallway (where wolf is)", function()
    -- Critical path order: start-room → cellar → storage-cellar → deep-cellar → hallway
    -- The knife must be in a room the player visits BEFORE reaching the wolf
    local pre_hallway_rooms = {
        "start-room", "cellar", "storage-cellar", "deep-cellar", "crypt", "courtyard"
    }
    local found_in = nil
    for _, room_id in ipairs(pre_hallway_rooms) do
        local room = rooms[room_id]
        if room then
            local inst = find_instance_by_type_id(room.instances, knife.guid)
            if not inst then
                inst = find_instance_by_id(room.instances, "butcher-knife")
            end
            if inst then
                found_in = room_id
                break
            end
        end
    end
    h.assert_truthy(found_in,
        "butcher-knife must be in a pre-hallway room so player can find it before the wolf")
end)

test("butcher-knife instance has correct type_id matching the object GUID", function()
    local found = nil
    local found_room = nil
    for room_id, room in pairs(rooms) do
        local inst = find_instance_by_type_id(room.instances, knife.guid)
        if inst then
            found = inst
            found_room = room_id
            break
        end
    end
    h.assert_truthy(found,
        "must find an instance with type_id matching butcher-knife GUID")
    local inst_guid = (found.type_id or ""):gsub("[{}]", ""):lower()
    local knife_guid = knife.guid:gsub("[{}]", ""):lower()
    h.assert_eq(knife_guid, inst_guid,
        "instance type_id must match butcher-knife GUID")
end)

-- =========================================================================
print("")
local exit_code = h.summary()
os.exit(exit_code)
