-- test/creatures/test-bug312-territory-never-created.lua
-- Bug #312: Territory markers never instantiated by wolf.
-- Root cause: mark_territory() registers all markers under shared id "territory-marker",
-- causing overwrites. Also _last_marked_room set even when marking fails.
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/creatures/test-bug312-territory-never-created.lua

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

local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-312-" .. guid_counter .. "}"
end

-- Use REAL registry to expose id-vs-guid mismatch bugs
local registry_mod = require("engine.registry")

local function make_mock_registry(objects)
    local reg = registry_mod.new()
    for _, obj in ipairs(objects) do
        reg:register(obj.id or obj.guid, obj)
    end
    return reg
end

local function make_room(id, contents, exits)
    return {
        guid = "{room-" .. id .. "}", id = id, template = "room",
        name = id, description = "Test room.", contents = contents or {}, exits = exits or {},
    }
end

local function make_wolf(location)
    return {
        guid = next_guid(), template = "creature", id = "wolf",
        name = "a grey wolf", animate = true, alive = true,
        health = 22, max_health = 22, _state = "alive-idle",
        location = location,
        behavior = {
            default = "idle", aggression = 70, flee_threshold = 20,
            territorial = { marks_territory = true, mark_object = "territory-marker", mark_radius = 2 },
            territory = "hallway",
        },
        drives = {
            hunger = { value = 30, decay_rate = 1, max = 100, min = 0 },
            fear = { value = 0, decay_rate = -5, max = 100, min = 0 },
        },
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #312: Wolf territory markers must be created and findable")

test("1. mark_territory creates a marker retrievable via room.contents", function()
    h.assert_truthy(territorial, "territorial module must load")

    local wolf = make_wolf("hallway")
    local room = make_room("hallway", { wolf.guid })
    local reg = make_mock_registry({ wolf, room })
    local ctx = { registry = reg, rooms = { hallway = room }, game_time = 100 }

    territorial.mark_territory(wolf, ctx)

    -- Marker must be findable via room.contents using reg:get
    local found = false
    for _, ref in ipairs(room.contents) do
        local obj = reg:get(ref)
        if obj and (obj.id == "territory-marker" or (obj.id and obj.id:find("territory%-marker"))) then
            found = true
            break
        end
    end
    h.assert_truthy(found,
        "marker must be retrievable from room.contents via reg:get — room.contents refs must match registration ids")
end)

test("2. multiple markers in different rooms don't overwrite each other", function()
    h.assert_truthy(territorial, "territorial module must load")

    local wolf = make_wolf("hallway")
    local room_a = make_room("hallway", { wolf.guid })
    local room_b = make_room("cellar", {})
    local reg = make_mock_registry({ wolf, room_a, room_b })
    local ctx = { registry = reg, rooms = { hallway = room_a, cellar = room_b }, game_time = 100 }

    -- Mark room A
    wolf.location = "hallway"
    territorial.mark_territory(wolf, ctx)

    -- Mark room B
    wolf.location = "cellar"
    territorial.mark_territory(wolf, ctx)

    -- Both rooms should have markers
    local markers_a = territorial.find_markers_in_room(reg, "hallway")
    local markers_b = territorial.find_markers_in_room(reg, "cellar")

    h.assert_truthy(#markers_a >= 1, "room A must have at least 1 marker, got " .. #markers_a)
    h.assert_truthy(#markers_b >= 1, "room B must have at least 1 marker, got " .. #markers_b)
end)

test("3. creature_tick marks room when wolf enters with location set", function()
    h.assert_truthy(creatures, "engine.creatures must load")

    local wolf = make_wolf("hallway")
    local room = make_room("hallway", { wolf.guid },
        { north = { target = "cellar" } })
    local cellar = make_room("cellar", {}, { south = { target = "hallway" } })
    local reg = make_mock_registry({ wolf, room, cellar })
    local ctx = {
        registry = reg,
        rooms = { hallway = room, cellar = cellar },
        current_room = { id = "bedroom" },  -- player not in hallway
        player = { location = "bedroom", health = 50, max_health = 50, hands = { nil, nil } },
        game_time = 100,
    }

    creatures.creature_tick(ctx, wolf)

    local markers = territorial.find_markers_in_room(reg, "hallway")
    h.assert_truthy(#markers >= 1,
        "wolf creature_tick must create territory marker in current room, found " .. #markers)
end)

test("4. smell scan can detect territory marker in room via on_smell", function()
    h.assert_truthy(territorial, "territorial module must load")

    local wolf = make_wolf("hallway")
    local room = make_room("hallway", { wolf.guid })
    local reg = make_mock_registry({ wolf, room })
    local ctx = { registry = reg, rooms = { hallway = room }, game_time = 100 }

    territorial.mark_territory(wolf, ctx)

    -- The marker should be findable and have on_smell
    local markers = territorial.find_markers_in_room(reg, "hallway")
    h.assert_truthy(#markers >= 1, "must find marker in room")

    local marker = markers[1]
    h.assert_truthy(marker.on_smell, "territory marker must have on_smell for detection")
    h.assert_truthy(marker.on_smell:lower():find("musky") or marker.on_smell:lower():find("scent")
        or marker.on_smell:lower():find("animal"),
        "marker on_smell should describe territorial scent, got: " .. tostring(marker.on_smell))
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
