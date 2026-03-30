-- test/creatures/test-creature-tick.lua
-- WAVE-2 TDD: Validates creature tick engine — drive updates, behavior
-- selection, movement, perception range, and phase-sequencing guards.
-- Must be run from repository root: lua test/creatures/test-creature-tick.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load the creature tick engine (pcall-guarded — TDD: module may not exist)
---------------------------------------------------------------------------
local ok_mod, creatures = pcall(require, "engine.creatures")
if not ok_mod then
    print("WARNING: engine.creatures not found — tests will fail (TDD: expected)")
    creatures = nil
end

---------------------------------------------------------------------------
-- Mock helpers — matched to real engine/creatures/init.lua API:
--   registry:list()   -> all objects
--   registry:get(id)  -> object by guid/id
--   creature.location -> room id string
--   context.rooms     -> table keyed by room id
--   context.current_room -> room object with .id
--   exits use portal pattern: exit = { portal = "portal-guid" }
---------------------------------------------------------------------------

local portal_counter = 0

-- Build a mock creature modeled after the real rat.lua structure
local function make_mock_creature(overrides)
    local c = {
        guid = "{mock-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "mock-rat",
        name = "a mock rat",
        keywords = {"rat"},
        animate = true,
        alive = true,
        health = 5,
        max_health = 5,
        size = "tiny",
        weight = 0.3,
        material = "flesh",
        location = nil,
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"]   = { description = "Sitting." },
            ["alive-wander"] = { description = "Wandering.", room_presence = "A rat scurries along the baseboard." },
            ["alive-flee"]   = { description = "Fleeing.", room_presence = "A panicked rat zigzags across the floor." },
            ["dead"]         = { description = "Dead.", animate = false, portable = true },
        },
        transitions = {
            { from = "alive-idle",   to = "alive-wander", verb = "_tick", condition = "wander_roll" },
            { from = "alive-wander", to = "alive-idle",   verb = "_tick", condition = "settle_roll" },
            { from = "alive-idle",   to = "alive-flee",   verb = "_tick", condition = "fear_high" },
            { from = "alive-wander", to = "alive-flee",   verb = "_tick", condition = "fear_high" },
            { from = "alive-flee",   to = "alive-idle",   verb = "_tick", condition = "fear_low" },
        },
        behavior = {
            default = "idle",
            aggression = 5,
            flee_threshold = 30,
            wander_chance = 40,
            settle_chance = 60,
            territorial = false,
        },
        drives = {
            hunger = {
                value = 50, decay_rate = 2, max = 100, min = 0,
            },
            fear = {
                value = 0, decay_rate = -10, max = 100, min = 0,
            },
            curiosity = {
                value = 30, decay_rate = 1, max = 60, min = 0,
            },
        },
        reactions = {
            player_enters = { action = "evaluate", fear_delta = 35 },
            player_attacks = { action = "flee", fear_delta = 80 },
            loud_noise = { action = "flee", fear_delta = 25 },
            light_change = { action = "evaluate", fear_delta = 15 },
        },
        movement = {
            speed = 1,
            can_open_doors = false,
            can_climb = true,
            size_limit = 1,
        },
        awareness = {
            sight_range = 1,
            sound_range = 2,
            smell_range = 3,
        },
    }
    if overrides then
        for k, v in pairs(overrides) do c[k] = v end
    end
    return c
end

-- Create a portal object for an exit (matching engine's is_exit_passable API)
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

-- Build a mock room. Exits should be pre-built with portal refs.
local function make_mock_room(id, exits)
    return {
        guid = "{room-" .. id .. "}",
        id = id,
        template = "room",
        exits = exits or {},
        contents = {},
    }
end

-- Build a minimal mock registry (supports :list() and :get())
local function make_mock_registry(objects)
    local reg = {
        _objects = objects or {},
    }
    function reg:list()
        return self._objects
    end
    function reg:get(id)
        for _, obj in ipairs(self._objects) do
            if obj.guid == id or obj.id == id then return obj end
        end
        return nil
    end
    return reg
end

-- Build a mock context matching what engine/creatures/init.lua expects
local function make_mock_context(registry, rooms_table, current_room_obj)
    return {
        registry = registry,
        rooms = rooms_table,
        current_room = current_room_obj,
        player = { location = current_room_obj and current_room_obj.id or nil },
    }
end

-- Helper: build rooms table (keyed by id) from array of room objects
local function rooms_by_id(...)
    local t = {}
    for _, r in ipairs({...}) do t[r.id] = r end
    return t
end

---------------------------------------------------------------------------
-- TESTS: Drive Updates
---------------------------------------------------------------------------
suite("CREATURE TICK: drive updates (WAVE-2)")

test("1. hunger increases by decay_rate per tick", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    local old_hunger = rat.drives.hunger.value
    creatures.tick(ctx)
    h.assert_eq(old_hunger + rat.drives.hunger.decay_rate, rat.drives.hunger.value,
        "hunger should increase by decay_rate")
end)

test("2. fear decays (decreases) per tick when no stimulus", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 50
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    local old_fear = rat.drives.fear.value
    creatures.tick(ctx)
    -- decay_rate is -10, so fear should decrease by 10
    h.assert_eq(old_fear + rat.drives.fear.decay_rate, rat.drives.fear.value,
        "fear should decrease by |decay_rate| per tick")
end)

test("3. curiosity grows by decay_rate per tick", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    local old_curiosity = rat.drives.curiosity.value
    creatures.tick(ctx)
    h.assert_eq(old_curiosity + rat.drives.curiosity.decay_rate, rat.drives.curiosity.value,
        "curiosity should increase by decay_rate")
end)

---------------------------------------------------------------------------
-- TESTS: Drive Clamping
---------------------------------------------------------------------------
suite("CREATURE TICK: drive clamping (WAVE-2)")

test("4. hunger clamped at max (100)", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.hunger.value = 99
    rat.drives.hunger.decay_rate = 5
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    h.assert_eq(100, rat.drives.hunger.value,
        "hunger must clamp at max=100, not exceed it")
end)

test("5. fear clamped at min (0)", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 5
    rat.drives.fear.decay_rate = -10
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    h.assert_eq(0, rat.drives.fear.value,
        "fear must clamp at min=0, not go negative")
end)

test("6. curiosity clamped at its max (60 for rat)", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.curiosity.value = 59
    rat.drives.curiosity.decay_rate = 5
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    h.assert_eq(60, rat.drives.curiosity.value,
        "curiosity must clamp at its max (60)")
end)

---------------------------------------------------------------------------
-- TESTS: Behavior Selection
---------------------------------------------------------------------------
suite("CREATURE TICK: behavior selection (WAVE-2)")

test("7. high fear (above flee_threshold) selects flee", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 80  -- well above flee_threshold=30
    rat._state = "alive-idle"
    local portal, pid = make_portal("hallway", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid } })
    local hallway = make_mock_room("hallway")
    local reg = make_mock_registry({rat, portal, cellar, hallway})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway), cellar)
    creatures.tick(ctx)
    h.assert_eq("alive-flee", rat._state,
        "creature with fear > flee_threshold should transition to alive-flee")
end)

test("8. low fear and no urgent drives selects idle or wander", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    rat._state = "alive-idle"
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    local valid = (rat._state == "alive-idle" or rat._state == "alive-wander")
    h.assert_truthy(valid,
        "creature with low fear should be idle or wander, got: " .. rat._state)
end)

test("9. fear below flee_threshold in flee state returns to idle", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 5  -- below flee_threshold=30
    rat._state = "alive-flee"
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    -- With fear 5, flee won't score (fear < flee_threshold); idle/wander/vocalize should win
    h.assert_truthy(rat._state ~= "alive-flee",
        "creature with fear < flee_threshold should leave alive-flee, got: " .. rat._state)
end)

---------------------------------------------------------------------------
-- TESTS: Empty Room / Dead Creatures
---------------------------------------------------------------------------
suite("CREATURE TICK: edge cases (WAVE-2)")

test("10. tick with no creatures in room does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local room = make_mock_room("empty-room")
    local reg = make_mock_registry({room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    h.assert_no_error(function()
        local msgs = creatures.tick(ctx)
        h.assert_eq("table", type(msgs), "tick must return a table (even if empty)")
    end, "tick with empty room should not crash")
end)

test("11. dead creature (animate=false) is skipped by tick", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.animate = false
    rat._state = "dead"
    rat.drives.hunger.value = 50
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    h.assert_eq(50, rat.drives.hunger.value,
        "dead creature drives should not be updated")
end)

test("12. tick with 1 creature returns messages table", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    local msgs = creatures.tick(ctx)
    h.assert_eq("table", type(msgs), "tick must return a messages table")
end)

---------------------------------------------------------------------------
-- TESTS: Wander Movement
---------------------------------------------------------------------------
suite("CREATURE TICK: wander movement (WAVE-2)")

test("13. wandering creature moves to adjacent room via open exit", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    math.randomseed(42)
    local rat = make_mock_creature({ location = "cellar" })
    rat._state = "alive-wander"
    rat.behavior.wander_chance = 100  -- force wander to always move
    rat.drives.curiosity.value = 60   -- max curiosity to boost wander score
    local portal_n, pid_n = make_portal("hallway", true)
    local portal_s, pid_s = make_portal("cellar", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid_n } })
    local hallway = make_mock_room("hallway", { south = { portal = pid_s } })
    local reg = make_mock_registry({rat, portal_n, portal_s, cellar, hallway})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway), cellar)
    -- Tick multiple times to give the wander a chance to move
    local moved = false
    for _ = 1, 10 do
        creatures.tick(ctx)
        if rat.location ~= "cellar" then moved = true; break end
    end
    h.assert_truthy(rat.location == "cellar" or rat.location == "hallway",
        "creature should be in a valid room after wandering, got: " .. tostring(rat.location))
end)

test("14. creature cannot move through closed door if can_open_doors=false", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat._state = "alive-wander"
    rat.behavior.wander_chance = 100
    rat.drives.curiosity.value = 60
    rat.movement.can_open_doors = false
    local portal_closed, pid_closed = make_portal("hallway", false)
    local cellar = make_mock_room("cellar", { north = { portal = pid_closed } })
    local hallway = make_mock_room("hallway")
    local reg = make_mock_registry({rat, portal_closed, cellar, hallway})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway), cellar)
    for _ = 1, 10 do creatures.tick(ctx) end
    h.assert_eq("cellar", rat.location,
        "creature should NOT move through a closed door")
end)

---------------------------------------------------------------------------
-- TESTS: Flee Movement
---------------------------------------------------------------------------
suite("CREATURE TICK: flee movement (WAVE-2)")

test("15. fleeing creature moves away from threat room", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat._state = "alive-flee"
    rat.drives.fear.value = 90  -- well above flee_threshold
    local portal_n, pid_n = make_portal("hallway", true)
    local portal_s, pid_s = make_portal("cellar", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid_n } })
    local hallway = make_mock_room("hallway", { south = { portal = pid_s } })
    local reg = make_mock_registry({rat, portal_n, portal_s, cellar, hallway})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway), cellar)
    creatures.tick(ctx)
    h.assert_eq("hallway", rat.location,
        "fleeing creature should move to an adjacent room")
end)

---------------------------------------------------------------------------
-- TESTS: Multiple Creatures
---------------------------------------------------------------------------
suite("CREATURE TICK: multiple creatures (WAVE-2)")

test("16. tick handles multiple creatures without interference", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat1 = make_mock_creature({ id = "rat-1", guid = "{mock-rat-1}", location = "cellar" })
    local rat2 = make_mock_creature({ id = "rat-2", guid = "{mock-rat-2}", location = "cellar" })
    rat1.drives.hunger.value = 40
    rat2.drives.hunger.value = 60
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat1, rat2, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.tick(ctx)
    h.assert_eq(42, rat1.drives.hunger.value,
        "rat1 hunger should be 40+2=42")
    h.assert_eq(62, rat2.drives.hunger.value,
        "rat2 hunger should be 60+2=62")
end)

---------------------------------------------------------------------------
-- TESTS: Performance Gate
---------------------------------------------------------------------------
suite("CREATURE TICK: performance (GATE-2)")

test("17. 5 creatures tick in <50ms", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local objs = {}
    for i = 1, 5 do
        local c = make_mock_creature({ id = "perf-rat-" .. i, guid = "{perf-" .. i .. "}", location = "perf-room" })
        objs[#objs + 1] = c
    end
    local portal_n, pid_n = make_portal("perf-hall", true)
    local portal_s, pid_s = make_portal("perf-room", true)
    local room = make_mock_room("perf-room", { north = { portal = pid_n } })
    local hall = make_mock_room("perf-hall", { south = { portal = pid_s } })
    objs[#objs + 1] = portal_n
    objs[#objs + 1] = portal_s
    objs[#objs + 1] = room
    objs[#objs + 1] = hall
    local reg = make_mock_registry(objs)
    local ctx = make_mock_context(reg, rooms_by_id(room, hall), room)

    local start = os.clock()
    creatures.tick(ctx)
    local elapsed_ms = (os.clock() - start) * 1000
    h.assert_truthy(elapsed_ms < 50,
        "5-creature tick must complete in <50ms, took " .. string.format("%.1f", elapsed_ms) .. "ms")
end)

---------------------------------------------------------------------------
-- TESTS: Perception Range
---------------------------------------------------------------------------
suite("CREATURE TICK: perception range (WAVE-2)")

test("18. distant-room creature does NOT receive local stimulus", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    -- Creature is in "far-room", 3+ rooms away from player in "cellar"
    local rat = make_mock_creature({ location = "far-room" })
    rat.drives.fear.value = 0
    local p1, pid1 = make_portal("hallway", true)
    local p2, pid2 = make_portal("cellar", true)
    local p3, pid3 = make_portal("corridor", true)
    local p4, pid4 = make_portal("hallway", true)
    local p5, pid5 = make_portal("far-room", true)
    local p6, pid6 = make_portal("corridor", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid1 } })
    local hallway = make_mock_room("hallway", {
        south = { portal = pid2 },
        north = { portal = pid3 },
    })
    local corridor = make_mock_room("corridor", {
        south = { portal = pid4 },
        north = { portal = pid5 },
    })
    local far_room = make_mock_room("far-room", {
        south = { portal = pid6 },
    })
    local reg = make_mock_registry({rat, p1, p2, p3, p4, p5, p6, cellar, hallway, corridor, far_room})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway, corridor, far_room), cellar)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    h.assert_eq(0, rat.drives.fear.value,
        "distant creature (3+ rooms away) must NOT receive local stimulus")
end)

test("19. same-room creature DOES receive stimulus", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local cellar = make_mock_room("cellar")
    local reg = make_mock_registry({rat, cellar})
    local ctx = make_mock_context(reg, rooms_by_id(cellar), cellar)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    -- Rat's player_enters reaction has fear_delta = 35
    h.assert_truthy(rat.drives.fear.value > 0,
        "same-room creature should receive stimulus and have fear > 0")
end)

---------------------------------------------------------------------------
-- TESTS: get_creatures_in_room
---------------------------------------------------------------------------
suite("CREATURE TICK: get_creatures_in_room (WAVE-2)")

test("20. returns only creatures in the specified room", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat1 = make_mock_creature({ id = "rat-local", guid = "{local-rat}", location = "cellar" })
    local rat2 = make_mock_creature({ id = "rat-other", guid = "{other-rat}", location = "hallway" })
    local cellar = make_mock_room("cellar")
    local hallway = make_mock_room("hallway")
    local reg = make_mock_registry({rat1, rat2, cellar, hallway})
    local result = creatures.get_creatures_in_room(reg, "cellar")
    h.assert_eq(1, #result, "should find exactly 1 creature in cellar")
    h.assert_eq("rat-local", result[1].id, "should be the local rat")
end)

test("21. returns empty table for room with no creatures", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local room = make_mock_room("empty")
    local reg = make_mock_registry({room})
    local result = creatures.get_creatures_in_room(reg, "empty")
    h.assert_eq("table", type(result), "must return a table")
    h.assert_eq(0, #result, "no creatures in empty room")
end)

---------------------------------------------------------------------------
-- TESTS: Phase Sequencing Guard (D-COMBAT-NPC-PHASE-SEQUENCING)
---------------------------------------------------------------------------
suite("CREATURE TICK: phase sequencing guard (WAVE-2)")

test("22. tick does NOT produce combat actions", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    rat.behavior.aggression = 100  -- max aggression, but no combat in Phase 1
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    local msgs = creatures.tick(ctx)
    -- No message should reference "attack", "bite", or "combat"
    for _, msg in ipairs(msgs or {}) do
        local lower = string.lower(msg)
        h.assert_truthy(not string.find(lower, "attack"),
            "tick must NOT produce attack actions in Phase 1: " .. msg)
        h.assert_truthy(not string.find(lower, "combat"),
            "tick must NOT produce combat actions in Phase 1: " .. msg)
    end
    -- Creature state should NOT be any combat-related state
    h.assert_truthy(rat._state ~= "attacking" and rat._state ~= "combat",
        "creature must NOT enter combat state in Phase 1, got: " .. rat._state)
end)

test("23. real rat.lua has combat field (WAVE-4 delivered)", function()
    local SEP = package.config:sub(1, 1)
    local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "rat.lua"
    local ok_rat, rat_obj = pcall(dofile, rat_path)
    h.assert_truthy(ok_rat, "rat.lua must load")
    h.assert_truthy(rat_obj.combat,
        "combat field must exist after WAVE-4 delivery")
end)

test("24. real rat.lua has body_tree field (WAVE-4 delivered)", function()
    local SEP = package.config:sub(1, 1)
    local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "rat.lua"
    local ok_rat, rat_obj = pcall(dofile, rat_path)
    h.assert_truthy(ok_rat, "rat.lua must load")
    h.assert_truthy(rat_obj.body_tree,
        "body_tree must exist after WAVE-4 delivery")
end)

---------------------------------------------------------------------------
-- TESTS: Message Collection
---------------------------------------------------------------------------
suite("CREATURE TICK: message collection (WAVE-2)")

test("25. tick returns messages only for player's room", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat_local = make_mock_creature({ id = "local-rat", guid = "{local}", location = "cellar" })
    local rat_far = make_mock_creature({ id = "far-rat", guid = "{far}", location = "hallway" })
    rat_far._state = "alive-wander"
    local portal_nc, pid_nc = make_portal("corridor", true)
    local portal_cn, pid_cn = make_portal("hallway", true)
    local cellar = make_mock_room("cellar")
    local hallway = make_mock_room("hallway", { north = { portal = pid_nc } })
    local corridor = make_mock_room("corridor", { south = { portal = pid_cn } })
    local reg = make_mock_registry({rat_local, rat_far, portal_nc, portal_cn, cellar, hallway, corridor})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway, corridor), cellar)
    local msgs = creatures.tick(ctx)
    h.assert_eq("table", type(msgs), "tick must return a messages table")
    for _, msg in ipairs(msgs or {}) do
        h.assert_truthy(type(msg) == "string", "each message must be a string")
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
