-- test/creatures/test-bug323-wolf-scent-linger.lua
-- Bug #323: Wolf scent vanishes instantly when wolf leaves room.
-- Fix: wolf leaves a lingering scent (territory marker) when it departs.
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/creatures/test-bug323-wolf-scent-linger.lua

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
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

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
    return "{test-323-" .. guid_counter .. "}"
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
    function reg:register(id, object)
        object.id = id
        self._objects[id] = object
        if object.guid then self._objects[object.guid] = object end
    end
    function reg:list()
        local seen, result = {}, {}
        for _, obj in pairs(self._objects) do
            if type(obj) == "table" and obj.guid and not seen[obj.guid] then
                seen[obj.guid] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
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
            wander_chance = 100, settle_chance = 0,
            territorial = { marks_territory = true, mark_object = "territory-marker", mark_radius = 2 },
            territory = "hallway",
            lingering_scent = {
                on_smell = "A faint predator's musk lingers in the air — a wolf was here recently.",
                duration = 5,
            },
        },
        drives = {
            hunger = { value = 30, decay_rate = 1, max = 100, min = 0 },
            fear = { value = 0, decay_rate = -5, max = 100, min = 0 },
            curiosity = { value = 50, decay_rate = 1, max = 60 },
        },
        movement = { speed = 3, can_open_doors = false, can_climb = false, size_limit = 3 },
        on_smell = "Wet dog and old meat. A predator's musk, sharp and territorial.",
        combat = { behavior = { flee_threshold = 0.2 } },
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #323: Wolf scent must linger after wolf leaves room")

test("1. wolf definition has lingering_scent metadata", function()
    local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "wolf.lua"
    local ok, wolf_def = pcall(dofile, wolf_path)
    h.assert_truthy(ok, "wolf.lua must load")
    h.assert_truthy(wolf_def.behavior, "wolf must have behavior")
    h.assert_truthy(wolf_def.behavior.lingering_scent, "wolf must have lingering_scent in behavior")
    h.assert_truthy(wolf_def.behavior.lingering_scent.on_smell,
        "lingering_scent must have on_smell text")
    h.assert_truthy(wolf_def.behavior.lingering_scent.duration,
        "lingering_scent must have duration (turns)")
end)

test("2. territorial wolf leaves scent marker when departing a room", function()
    h.assert_truthy(creatures, "engine.creatures must load")
    h.assert_truthy(territorial, "territorial module must load")

    local wolf = make_wolf("hallway")
    local room_a = make_room("hallway", { wolf.guid },
        { north = { target = "cellar" } })
    local room_b = make_room("cellar", {},
        { south = { target = "hallway" } })
    local reg = make_mock_registry({ wolf, room_a, room_b })
    local ctx = {
        registry = reg,
        rooms = { hallway = room_a, cellar = room_b },
        current_room = { id = "bedroom" },
        player = { location = "bedroom", health = 50, max_health = 50, hands = { nil, nil } },
        game_time = 100,
    }

    -- Run multiple ticks — wolf should eventually mark territory
    for _ = 1, 10 do
        creatures.creature_tick(ctx, wolf)
    end

    -- Check that a scent marker exists in at least one room
    local markers_a = territorial.find_markers_in_room(reg, "hallway")
    local markers_b = territorial.find_markers_in_room(reg, "cellar")
    local total = #markers_a + #markers_b

    h.assert_truthy(total >= 1,
        "wolf must leave at least one territory/scent marker after movement, found " .. total)
end)

test("3. lingering scent marker has on_smell for ambient detection", function()
    h.assert_truthy(territorial, "territorial module must load")

    local wolf = make_wolf("hallway")
    local room = make_room("hallway", { wolf.guid })
    local reg = make_mock_registry({ wolf, room })
    local ctx = { registry = reg, rooms = { hallway = room }, game_time = 100 }

    territorial.mark_territory(wolf, ctx)

    local markers = territorial.find_markers_in_room(reg, "hallway")
    h.assert_truthy(#markers >= 1, "marker must exist")
    h.assert_truthy(markers[1].on_smell, "marker must have on_smell for scent detection")
end)

---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
