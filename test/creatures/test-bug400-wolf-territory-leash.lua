-- test/creatures/test-bug400-wolf-territory-leash.lua
-- TDD: #400 — Wolf wanders to deep-cellar and instant-kills unarmed player.
-- Creatures with behavior.territory should not wander outside their patrol area.
-- Must be run from repository root: lua test/creatures/test-bug400-wolf-territory-leash.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

local ok_actions, actions = pcall(require, "engine.creatures.actions")
if not ok_actions then
    print("WARNING: engine.creatures.actions not found — TDD red phase")
    actions = nil
end
local ok_creatures, creatures = pcall(require, "engine.creatures")
if not ok_creatures then
    print("WARNING: engine.creatures not found — TDD red phase")
    creatures = nil
end

---------------------------------------------------------------------------
-- Mocks
---------------------------------------------------------------------------
local portal_counter = 0

local function make_portal(target_room_id, traversable)
    portal_counter = portal_counter + 1
    local pid = "{portal-" .. portal_counter .. "}"
    return {
        guid = pid,
        id = "portal-" .. portal_counter,
        _state = traversable and "open" or "closed",
        states = {
            open = { traversable = true },
            closed = { traversable = false },
        },
        portal = { target = target_room_id },
    }, pid
end

local function make_mock_room(id, exits)
    return {
        guid = "{room-" .. id .. "}",
        id = id,
        template = "room",
        exits = exits or {},
        contents = {},
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = objects or {} }
    function reg:list() return self._objects end
    function reg:get(id)
        for _, obj in ipairs(self._objects) do
            if obj.guid == id or obj.id == id then return obj end
        end
        return nil
    end
    return reg
end

local function make_mock_context(registry, rooms_table, current_room_obj)
    return {
        registry = registry,
        rooms = rooms_table,
        current_room = current_room_obj,
        player = { location = current_room_obj and current_room_obj.id or nil },
    }
end

local function rooms_by_id(...)
    local t = {}
    for _, r in ipairs({...}) do t[r.id] = r end
    return t
end

local function make_wolf(overrides)
    local c = {
        guid = "{wolf-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "wolf",
        name = "a grey wolf",
        keywords = {"wolf"},
        animate = true,
        alive = true,
        health = 30,
        max_health = 30,
        size = "medium",
        weight = 40,
        material = "flesh",
        location = "hallway",
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"]   = { description = "Idle." },
            ["alive-wander"] = { description = "Wandering.", room_presence = "A wolf paces the room." },
            ["dead"]         = { description = "Dead.", animate = false },
        },
        transitions = {},
        behavior = {
            default = "idle",
            aggression = 70,
            flee_threshold = 20,
            wander_chance = 25,
            territorial = { marks_territory = true },
            territory = "hallway",
        },
        drives = {
            hunger = { value = 50, decay_rate = 2, max = 100, min = 0 },
            fear   = { value = 0, decay_rate = -5, max = 100, min = 0 },
            curiosity = { value = 30, decay_rate = 1, max = 60, min = 0 },
        },
        reactions = {},
        movement = { speed = 1, can_open_doors = false },
        awareness = { sight_range = 2, sound_range = 3, smell_range = 4 },
    }
    if overrides then
        for k, v in pairs(overrides) do c[k] = v end
    end
    return c
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #400: Wolf territory leash")

test("1. wolf in territory does NOT wander to non-territory room", function()
    h.assert_truthy(creatures, "engine.creatures must be loaded")

    -- Hallway connects to deep-cellar via open portal
    local p_dc, pid_dc = make_portal("deep-cellar", true)
    local hallway = make_mock_room("hallway", {
        down = { portal = pid_dc },
    })
    local deep_cellar = make_mock_room("deep-cellar")
    local wolf = make_wolf({ location = "hallway" })
    hallway.contents = { wolf.id }

    local reg = make_mock_registry({ wolf, hallway, deep_cellar, p_dc })
    local ctx = make_mock_context(reg, rooms_by_id(hallway, deep_cellar), deep_cellar)

    -- Run many ticks; wolf should never leave hallway
    for i = 1, 50 do
        creatures.tick(ctx)
    end

    h.assert_eq("hallway", wolf.location,
        "Wolf with territory=hallway must stay in hallway (not wander to deep-cellar)")
end)

test("2. displaced wolf returns to territory", function()
    h.assert_truthy(creatures, "engine.creatures must be loaded")

    -- Wolf starts in deep-cellar (displaced), hallway is reachable via "up"
    local p_hw, pid_hw = make_portal("hallway", true)
    local deep_cellar = make_mock_room("deep-cellar", {
        up = { portal = pid_hw },
    })
    local hallway = make_mock_room("hallway")
    local wolf = make_wolf({ location = "deep-cellar" })
    deep_cellar.contents = { wolf.id }

    local reg = make_mock_registry({ wolf, hallway, deep_cellar, p_hw })
    local ctx = make_mock_context(reg, rooms_by_id(hallway, deep_cellar), hallway)

    -- Run ticks; wolf should eventually wander back to hallway
    for i = 1, 50 do
        creatures.tick(ctx)
    end

    h.assert_eq("hallway", wolf.location,
        "Displaced wolf should wander back to territory=hallway")
end)

test("3. creature without territory can wander freely", function()
    h.assert_truthy(creatures, "engine.creatures must be loaded")

    -- Rat with no territory; should be able to move between rooms
    local p_b, pid_b = make_portal("room-b", true)
    local room_a = make_mock_room("room-a", {
        north = { portal = pid_b },
    })
    local p_a, pid_a = make_portal("room-a", true)
    local room_b = make_mock_room("room-b", {
        south = { portal_a },
    })

    local rat = {
        guid = "{rat-test}",
        template = "creature",
        id = "rat",
        name = "a rat",
        keywords = {"rat"},
        animate = true,
        alive = true,
        health = 5,
        max_health = 5,
        size = "tiny",
        weight = 0.3,
        material = "flesh",
        location = "room-a",
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"]   = { description = "Idle." },
            ["alive-wander"] = { description = "Wandering." },
            ["dead"]         = { description = "Dead." },
        },
        transitions = {},
        behavior = {
            default = "idle",
            aggression = 5,
            flee_threshold = 30,
            wander_chance = 80,
            settle_chance = 10,
            territorial = false,
        },
        drives = {
            hunger = { value = 50, decay_rate = 2, max = 100, min = 0 },
            fear   = { value = 0, decay_rate = -10, max = 100, min = 0 },
            curiosity = { value = 50, decay_rate = 1, max = 60, min = 0 },
        },
        reactions = {},
        movement = { speed = 1, can_open_doors = false },
        awareness = { sight_range = 1, sound_range = 2, smell_range = 3 },
    }
    room_a.contents = { rat.id }

    local reg = make_mock_registry({ rat, room_a, room_b, p_b, p_a })
    local ctx = make_mock_context(reg, rooms_by_id(room_a, room_b), room_b)

    -- High wander chance — should move at some point
    local moved = false
    for i = 1, 50 do
        creatures.tick(ctx)
        if rat.location ~= "room-a" then moved = true; break end
    end

    h.assert_truthy(moved, "Rat without territory should be able to wander freely")
end)

test("4. wolf with patrol_rooms can move within allowed rooms", function()
    h.assert_truthy(creatures, "engine.creatures must be loaded")

    local p_cellar, pid_cellar = make_portal("cellar", true)
    local p_hallway, pid_hallway = make_portal("hallway", true)
    local hallway = make_mock_room("hallway", {
        down = { portal = pid_cellar },
    })
    local cellar = make_mock_room("cellar", {
        up = { portal = pid_hallway },
    })
    local wolf = make_wolf({ location = "hallway" })
    wolf.behavior.patrol_rooms = { "hallway", "cellar" }
    hallway.contents = { wolf.id }

    local reg = make_mock_registry({ wolf, hallway, cellar, p_cellar, p_hallway })
    local ctx = make_mock_context(reg, rooms_by_id(hallway, cellar), cellar)

    local visited_cellar = false
    for i = 1, 50 do
        creatures.tick(ctx)
        if wolf.location == "cellar" then visited_cellar = true; break end
    end

    h.assert_truthy(visited_cellar,
        "Wolf with patrol_rooms={hallway,cellar} should be able to visit cellar")
end)

h.summary()
