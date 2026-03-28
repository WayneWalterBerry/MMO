-- test/creatures/test-territory-marker-expiry.lua
-- Issue #323 TDD: Territory markers must expire after mark_duration.
-- Wolf scent marks should linger for 1 game day, then be removed.
-- Must be run from repository root: lua test/creatures/test-territory-marker-expiry.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------
local terr_ok, territorial = pcall(require, "engine.creatures.territorial")
if not terr_ok then
    print("WARNING: engine.creatures.territorial not loadable — " .. tostring(territorial))
    territorial = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-expiry-" .. guid_counter .. "}"
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:list()
        local seen, result = {}, {}
        for _, obj in pairs(self._objects) do
            if not seen[obj.guid] then
                seen[obj.guid] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    function reg:get(id) return self._objects[id] end
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:remove(guid)
        local obj = self._objects[guid]
        if obj then
            self._objects[guid] = nil
            if obj.id then self._objects[obj.id] = nil end
        end
        return obj
    end
    return reg
end

local function make_room(id, contents)
    return {
        guid = "{room-" .. id .. "}",
        id = id,
        template = "room",
        name = id,
        description = "A test room.",
        contents = contents or {},
    }
end

local function make_marker(owner_guid, room_id, timestamp)
    local guid = next_guid()
    return {
        guid = guid,
        id = "territory-marker",
        name = "a territorial scent mark",
        template = "small-item",
        location = room_id,
        owner = owner_guid,
        creator = owner_guid,
        timestamp = timestamp,
        territory = {
            owner = owner_guid,
            radius = 2,
            timestamp = timestamp,
        },
        on_smell = "A musky, animal scent lingers here.",
        on_feel = "You feel nothing unusual.",
        visible = false,
    }
end

---------------------------------------------------------------------------
-- TESTS: Territory Marker Expiry (Issue #323)
---------------------------------------------------------------------------
suite("TERRITORY MARKER EXPIRY: scent lingers for mark_duration (Issue #323 TDD)")

test("1. expire_markers function exists on territorial module", function()
    h.assert_truthy(territorial, "territorial module must load")
    h.assert_truthy(territorial.expire_markers,
        "territorial.expire_markers() function must exist")
end)

test("2. fresh marker is NOT expired (within duration)", function()
    h.assert_truthy(territorial, "territorial module must load")

    local current_time = 1000
    local marker = make_marker("{wolf-1}", "hallway", current_time - 10)
    local room = make_room("hallway", { marker.guid })
    local reg = make_mock_registry({ marker, room })
    local ctx = {
        registry = reg,
        rooms = { hallway = room },
        game_time = current_time,
    }

    -- mark_duration = 24 hours (1 day). Marker is 10 hours old. Should survive.
    territorial.expire_markers(ctx, 24)

    -- Marker should still exist
    local markers = territorial.find_markers_in_room(reg, "hallway")
    h.assert_eq(1, #markers,
        "Fresh marker (10h old, 24h duration) must NOT be expired")
end)

test("3. old marker IS expired (past duration)", function()
    h.assert_truthy(territorial, "territorial module must load")

    local current_time = 1000
    -- Marker placed 25 hours ago — past the 24-hour duration
    local marker = make_marker("{wolf-1}", "hallway", current_time - 25)
    local room = make_room("hallway", { marker.guid })
    local reg = make_mock_registry({ marker, room })
    local ctx = {
        registry = reg,
        rooms = { hallway = room },
        game_time = current_time,
    }

    territorial.expire_markers(ctx, 24)

    -- Marker should be removed
    local markers = territorial.find_markers_in_room(reg, "hallway")
    h.assert_eq(0, #markers,
        "Expired marker (25h old, 24h duration) must be removed")
end)

test("4. only expired markers removed — fresh markers kept", function()
    h.assert_truthy(territorial, "territorial module must load")

    local current_time = 1000
    local old_marker = make_marker("{wolf-1}", "hallway", current_time - 30)
    local fresh_marker = make_marker("{wolf-2}", "hallway", current_time - 5)
    local room = make_room("hallway", { old_marker.guid, fresh_marker.guid })
    local reg = make_mock_registry({ old_marker, fresh_marker, room })
    local ctx = {
        registry = reg,
        rooms = { hallway = room },
        game_time = current_time,
    }

    territorial.expire_markers(ctx, 24)

    local markers = territorial.find_markers_in_room(reg, "hallway")
    h.assert_eq(1, #markers,
        "Only the old marker should be removed; fresh marker should survive")
    h.assert_eq(fresh_marker.guid, markers[1].guid,
        "Surviving marker must be the fresh one")
end)

test("5. expired marker is removed from room contents list", function()
    h.assert_truthy(territorial, "territorial module must load")

    local current_time = 1000
    local marker = make_marker("{wolf-1}", "hallway", current_time - 30)
    local room = make_room("hallway", { marker.guid })
    local reg = make_mock_registry({ marker, room })
    local ctx = {
        registry = reg,
        rooms = { hallway = room },
        game_time = current_time,
    }

    territorial.expire_markers(ctx, 24)

    -- Room contents should not reference the expired marker
    local found = false
    for _, ref in ipairs(room.contents) do
        if ref == marker.guid then found = true end
    end
    h.assert_truthy(not found,
        "Expired marker GUID must be removed from room.contents")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
