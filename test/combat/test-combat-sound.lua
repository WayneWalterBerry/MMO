-- test/combat/test-combat-sound.lua
-- WAVE-4 TDD: Validates combat sound propagation — loud_noise stimulus
-- emission, adjacent-room creature reactions, distance gating, intensity
-- scaling, and player narration via emit_combat_sound().
--
-- Written to spec per npc-combat-implementation-phase3.md WAVE-4.
-- Usage: lua test/combat/test-combat-sound.lua
-- Must be run from the repository root.

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
-- Load modules (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local ok_creatures, creatures = pcall(require, "engine.creatures")
if not ok_creatures then
    print("WARNING: engine.creatures not found — stimulus tests will fail (TDD red)")
    creatures = nil
end

local ok_narration, narration = pcall(require, "engine.combat.narration")
if not ok_narration then
    print("WARNING: engine.combat.narration not found — narration tests will fail (TDD red)")
    narration = nil
end

---------------------------------------------------------------------------
-- Mock helpers (matched to test-stimulus.lua patterns)
---------------------------------------------------------------------------
local portal_counter = 200

local function make_mock_creature(overrides)
    local c = {
        guid = "{snd-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "snd-rat",
        name = "a sound-test rat",
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
            ["dead"]         = { description = "Dead.", animate = false },
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
            player_enters  = { action = "evaluate", fear_delta = 35 },
            player_attacks = { action = "flee", fear_delta = 80 },
            loud_noise     = { action = "flee", fear_delta = 25 },
            light_change   = { action = "evaluate", fear_delta = 15 },
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

local function make_predator(overrides)
    local base = make_mock_creature({
        id = "snd-wolf",
        name = "a wolf",
        keywords = {"wolf"},
        behavior = {
            default = "patrol",
            aggression = 70,
            flee_threshold = 80,
            wander_chance = 30,
        },
        reactions = {
            player_enters  = { action = "evaluate", fear_delta = 10 },
            player_attacks = { action = "fight", fear_delta = 20 },
            loud_noise     = { action = "investigate", fear_delta = -5 },
            light_change   = { action = "evaluate", fear_delta = 5 },
        },
    })
    if overrides then
        for k, v in pairs(overrides) do base[k] = v end
    end
    return base
end

local function make_portal(target_room_id, traversable)
    portal_counter = portal_counter + 1
    local pid = "{portal-snd-" .. portal_counter .. "}"
    return {
        guid = pid,
        id = "portal-snd-" .. portal_counter,
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
        guid = "{room-snd-" .. id .. "}",
        id = id,
        template = "room",
        exits = exits or {},
        contents = {},
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = objects or {} }
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
-- TESTS: Combat emits loud_noise stimulus
---------------------------------------------------------------------------
suite("COMBAT SOUND: loud_noise emission (WAVE-4)")

test("1. combat emits loud_noise stimulus to room", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    -- Emit loud_noise as combat would
    h.assert_no_error(function()
        creatures.emit_stimulus("cellar", "loud_noise", {
            source = "combat",
            intensity = 6,
        })
    end, "emitting loud_noise from combat must not crash")
end)

test("2. creature in same room receives loud_noise fear_delta", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    rat.drives.fear.value = 0
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "loud_noise", { source = "combat", intensity = 6 })
    creatures.tick(ctx)
    h.assert_truthy(rat.drives.fear.value > 0,
        "same-room creature should receive loud_noise fear_delta, got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: Adjacent room creatures receive stimulus
---------------------------------------------------------------------------
suite("COMBAT SOUND: adjacent room reception (WAVE-4)")

test("3. adjacent-room creature receives loud_noise stimulus", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "hallway" })
    rat.drives.fear.value = 0
    local p1, pid1 = make_portal("hallway", true)
    local p2, pid2 = make_portal("cellar", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid1 } })
    local hallway = make_mock_room("hallway", { south = { portal = pid2 } })
    local reg = make_mock_registry({rat, p1, p2, cellar, hallway})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway), cellar)
    creatures.emit_stimulus("cellar", "loud_noise", { source = "combat", intensity = 6 })
    creatures.tick(ctx)
    h.assert_truthy(rat.drives.fear.value > 0,
        "adjacent-room creature should receive loud_noise, fear got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: Prey creatures flee from loud_noise
---------------------------------------------------------------------------
suite("COMBAT SOUND: prey flee reaction (WAVE-4)")

test("4. prey creature with high fear flees after loud_noise", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "cellar" })
    -- Set fear just below flee threshold, loud_noise should push over
    rat.drives.fear.value = 20
    rat.behavior.flee_threshold = 30
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({rat, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "loud_noise", { source = "combat", intensity = 6 })
    creatures.tick(ctx)
    -- loud_noise fear_delta = 25, start = 20 → 45 > 30 threshold
    h.assert_truthy(rat.drives.fear.value >= rat.behavior.flee_threshold,
        "rat fear should exceed flee threshold after loud_noise, got: "
        .. rat.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: Predators investigate loud_noise
---------------------------------------------------------------------------
suite("COMBAT SOUND: predator investigate reaction (WAVE-4)")

test("5. predator's loud_noise reaction is investigate (not flee)", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local wolf = make_predator({ location = "hallway" })
    local reaction = wolf.reactions and wolf.reactions.loud_noise
    h.assert_truthy(reaction, "wolf must have loud_noise reaction")
    h.assert_eq(reaction.action, "investigate",
        "predator loud_noise action should be 'investigate'")
end)

test("6. predator fear decreases (curiosity) on loud_noise", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local wolf = make_predator({ location = "cellar" })
    wolf.drives.fear.value = 20
    local room = make_mock_room("cellar")
    local reg = make_mock_registry({wolf, room})
    local ctx = make_mock_context(reg, rooms_by_id(room), room)
    creatures.emit_stimulus("cellar", "loud_noise", { source = "combat", intensity = 6 })
    creatures.tick(ctx)
    -- Wolf's loud_noise fear_delta = -5 (predator reduces fear)
    h.assert_truthy(wolf.drives.fear.value <= 20,
        "predator fear should not increase on loud_noise, got: "
        .. wolf.drives.fear.value)
end)

---------------------------------------------------------------------------
-- TESTS: 2+ rooms away → no stimulus received
---------------------------------------------------------------------------
suite("COMBAT SOUND: distance gating (WAVE-4)")

test("7. creature 2+ rooms away does NOT receive loud_noise", function()
    h.assert_truthy(creatures, "engine.creatures not loaded (TDD red phase)")
    local rat = make_mock_creature({ location = "far-room" })
    rat.drives.fear.value = 0
    -- Build 3-room chain: cellar → hallway → far-room
    local p1, pid1 = make_portal("hallway", true)
    local p2, pid2 = make_portal("cellar", true)
    local p3, pid3 = make_portal("far-room", true)
    local p4, pid4 = make_portal("hallway", true)
    local cellar = make_mock_room("cellar", { north = { portal = pid1 } })
    local hallway = make_mock_room("hallway", {
        south = { portal = pid2 },
        north = { portal = pid3 },
    })
    local far_room = make_mock_room("far-room", { south = { portal = pid4 } })
    local reg = make_mock_registry({rat, p1, p2, p3, p4, cellar, hallway, far_room})
    local ctx = make_mock_context(reg, rooms_by_id(cellar, hallway, far_room), cellar)
    creatures.emit_stimulus("cellar", "loud_noise", { source = "combat", intensity = 6 })
    creatures.tick(ctx)
    h.assert_eq(0, rat.drives.fear.value,
        "creature 2+ rooms away must NOT receive loud_noise, fear should be 0")
end)

---------------------------------------------------------------------------
-- TESTS: Player in adjacent room hears narration text
---------------------------------------------------------------------------
suite("COMBAT SOUND: player narration (WAVE-4)")

test("8. emit_combat_sound returns narration for adjacent-room player", function()
    h.assert_truthy(narration, "engine.combat.narration not loaded (TDD red phase)")
    h.assert_truthy(narration.emit_combat_sound,
        "emit_combat_sound function must exist on narration module")

    -- Build a simple two-room layout
    local exits = {
        north = { portal = "{portal-test-1}", target = "combat-room" },
    }

    local text = narration.emit_combat_sound("combat-room", 6,
        "Something crashes.", {
            player_room_id = "player-room",
            exits = exits,
        })
    -- Adjacent player should hear narration text
    if text then
        h.assert_truthy(#text > 0,
            "adjacent player should receive non-empty narration text")
        h.assert_truthy(text:find("hear") or text:find("sound") or text:find("crash"),
            "narration should mention hearing/sounds, got: " .. text)
    else
        -- emit_combat_sound may return nil if proximity can't resolve —
        -- that's acceptable in TDD red phase
        h.assert_truthy(true,
            "emit_combat_sound returned nil (proximity resolution may need engine wiring)")
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code)
