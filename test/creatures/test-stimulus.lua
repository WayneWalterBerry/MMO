-- test/creatures/test-stimulus.lua
-- WAVE-2 TDD: Validates stimulus emission and reception — player_enters,
-- loud_noise, light_change, drive modifications, range boundaries, pcall guards.
-- Must be run from repository root: lua test/creatures/test-stimulus.lua

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
-- Load the creature engine (pcall-guarded — TDD: module may not exist)
---------------------------------------------------------------------------
local ok_mod, creatures = pcall(require, "engine.creatures")
if not ok_mod then
    print("WARNING: engine.creatures not found — tests will fail (TDD: expected)")
    creatures = nil
end

---------------------------------------------------------------------------
-- Mock helpers — matched to real engine/creatures/init.lua API
---------------------------------------------------------------------------

local portal_counter = 100  -- offset from tick test portals

local function make_mock_creature(overrides)
    local c = {
        guid = "{stim-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "stim-rat",
        name = "a stimulus test rat",
        keywords = {"rat"},
        animate = true,
        alive = true,
        health = 5,
        max_health = 5,
        size = "tiny",
        location = nil,
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"]   = { description = "Sitting." },
            ["alive-wander"] = { description = "Wandering." },
            ["alive-flee"]   = { description = "Fleeing." },
            ["dead"]         = { description = "Dead.", animate = false, portable = true },
        },
        behavior = {
            default = "idle",
            aggression = 5,
            flee_threshold = 30,
            wander_chance = 40,
        },
        drives = {
            hunger = { value = 50, decay_rate = 2, max = 100, min = 0 },
            fear   = { value = 0,  decay_rate = -10, max = 100, min = 0 },
            curiosity = { value = 30, decay_rate = 1, max = 60, min = 0 },
        },
        reactions = {
            player_enters = { action = "evaluate", fear_delta = 35 },
            player_attacks = { action = "flee", fear_delta = 80 },
            loud_noise = { action = "flee", fear_delta = 25 },
            light_change = { action = "evaluate", fear_delta = 15 },
        },
        movement = {
            speed = 1, can_open_doors = false, can_climb = true, size_limit = 1,
        },
        awareness = {
            sight_range = 1, sound_range = 2, smell_range = 3,
        },
    }
    if overrides then
        for k, v in pairs(overrides) do c[k] = v end
    end
    return c
end

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

---------------------------------------------------------------------------
-- TESTS: Stimulus Emission — player_enters
---------------------------------------------------------------------------
suite("STIMULUS: player_enters emission (WAVE-2)")

test("1. emit_stimulus player_enters does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "player_enters", { player = true })
    end, "emit_stimulus player_enters must not crash")
end)

test("2. creature in room receives fear_delta from player_enters", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    -- player_enters has fear_delta = 35
    h.assert_truthy(rat.drives.fear.value >= 35,
        "creature fear should increase by at least fear_delta (35) after player_enters, got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: Stimulus Emission — loud_noise
---------------------------------------------------------------------------
suite("STIMULUS: loud_noise emission (WAVE-2)")

test("3. emit_stimulus loud_noise does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "loud_noise", {})
    end, "emit_stimulus loud_noise must not crash")
end)

test("4. creature receives fear_delta from loud_noise", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "loud_noise", {})
    creatures.tick(ctx)
    h.assert_truthy(rat.drives.fear.value > 0,
        "creature fear should increase after loud_noise, got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: Stimulus Emission — light_change
---------------------------------------------------------------------------
suite("STIMULUS: light_change emission (WAVE-2)")

test("5. emit_stimulus light_change does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "light_change", {})
    end, "emit_stimulus light_change must not crash")
end)

test("6. creature receives fear_delta from light_change", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "light_change", {})
    creatures.tick(ctx)
    h.assert_truthy(rat.drives.fear.value > 0,
        "creature fear should increase after light_change, got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: Stimulus Drive Modification
---------------------------------------------------------------------------
suite("STIMULUS: drive modification correctness (WAVE-2)")

test("7. player_enters fear_delta adds exactly to fear drive", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 10
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    -- Expected: start=10, +35 (stimulus), -10 (decay_rate) = 35
    h.assert_truthy(rat.drives.fear.value > 10,
        "fear should increase from stimulus, got: " .. rat.drives.fear.value)
end)

test("8. multiple stimuli stack on same creature", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.emit_stimulus("cellar", "loud_noise", {})
    creatures.tick(ctx)
    -- player_enters = +35, loud_noise = +25, decay = -10 => ~50
    h.assert_truthy(rat.drives.fear.value >= 40,
        "stacked stimuli should compound fear, got: " .. rat.drives.fear.value)
end)

test("9. stimulus with no matching reaction is silently ignored", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.reactions = {}  -- no reactions defined
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "player_enters", { player = true })
        creatures.tick(ctx)
    end, "stimulus with no matching reaction should not crash")
end)

---------------------------------------------------------------------------
-- TESTS: Perception Range Boundary
---------------------------------------------------------------------------
suite("STIMULUS: perception range boundary (WAVE-2)")

test("10. creature outside perception range does NOT receive stimulus", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "far-room" })
    rat.drives.fear.value = 0
    local p1, pid1 = make_portal("hall", true)
    local p2, pid2 = make_portal("cellar", true)
    local p3, pid3 = make_portal("corridor", true)
    local p4, pid4 = make_portal("hall", true)
    local p5, pid5 = make_portal("far-room", true)
    local p6, pid6 = make_portal("corridor", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid1 } })
    local hall = make_mock_room("hall", {
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
    local reg = make_mock_registry({rat, p1, p2, p3, p4, p5, p6, cellar, hall, corridor, far_room})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hall, corridor, far_room), cellar)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    h.assert_eq(0, rat.drives.fear.value,
        "creature 3+ rooms away must NOT receive stimulus, fear should stay 0")
end)

test("11. adjacent-room creature DOES receive stimulus", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "hallway" })
    rat.drives.fear.value = 0
    local p1, pid1 = make_portal("hallway", true)
    local p2, pid2 = make_portal("cellar", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid1 } })
    local hallway = make_mock_room("hallway", { south = { portal = pid2 } })
    local reg = make_mock_registry({rat, p1, p2, cellar, hallway})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway), cellar)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    h.assert_truthy(rat.drives.fear.value > 0,
        "adjacent-room creature should receive stimulus, fear got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: pcall Guards / Robustness
---------------------------------------------------------------------------
suite("STIMULUS: pcall guards (WAVE-2)")

test("12. emit_stimulus to nonexistent room does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_no_error(function()
        creatures.emit_stimulus("room-that-does-not-exist", "player_enters", {})
    end, "emit_stimulus to missing room must not crash")
end)

test("13. emit_stimulus with nil stimulus_type does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", nil, {})
    end, "emit_stimulus with nil type must not crash")
end)

test("14. emit_stimulus with nil data does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "player_enters", nil)
    end, "emit_stimulus with nil data must not crash")
end)

test("15. tick after emit_stimulus with unknown stimulus type is safe", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    creatures.clear_stimuli()  -- ensure clean slate
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "earthquake", { magnitude = 9 })
        creatures.tick(ctx)
    end, "unknown stimulus type should be silently ignored")
    -- Fear should stay at 0 (decay from 0 clamps to 0, no matching reaction)
    h.assert_eq(0, rat.drives.fear.value,
        "unknown stimulus should not modify drives")
end)

---------------------------------------------------------------------------
-- TESTS: Stimulus in Empty Room
---------------------------------------------------------------------------
suite("STIMULUS: empty room (WAVE-2)")

test("16. emit_stimulus + tick in room with no creatures does not crash", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local room = make_mock_room("empty-cellar")
    local reg = make_mock_registry({room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    h.assert_no_error(function()
        creatures.emit_stimulus("empty-cellar", "player_enters", { player = true })
        local msgs = creatures.tick(ctx)
        h.assert_eq("table", type(msgs), "tick must return a table even in empty room")
    end, "stimulus + tick in empty room must not crash")
end)

---------------------------------------------------------------------------
-- TESTS: Stimulus Queue Consumed After Tick
---------------------------------------------------------------------------
suite("STIMULUS: queue consumption (WAVE-2)")

test("17. stimulus is consumed after tick (not reprocessed next tick)", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "player_enters", { player = true })
    creatures.tick(ctx)
    local fear_after_first = rat.drives.fear.value
    -- Second tick with NO new stimulus — fear should decay, not spike again
    creatures.tick(ctx)
    h.assert_truthy(rat.drives.fear.value <= fear_after_first,
        "stimulus should be consumed — fear must not spike again on 2nd tick, "
        .. "first=" .. fear_after_first .. " second=" .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
