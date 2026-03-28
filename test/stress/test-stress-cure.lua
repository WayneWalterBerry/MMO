-- test/stress/test-stress-cure.lua
-- WAVE-3 TDD: Stress cure tests.
-- Tests: rest in safe room → stress cured, rest in unsafe room → stress persists.
-- Safe room = no hostile creatures in room (per Q2 resolution).
-- Implementation by Bart (cure logic) and Flanders (stress.lua) may not
-- exist yet — TDD: tests define the contract, failures are expected.
--
-- Must be run from repository root: lua test/stress/test-stress-cure.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load injury engine (pcall-guarded — TDD: stress support may not exist yet)
---------------------------------------------------------------------------
local injury_ok, injury_mod = pcall(require, "engine.injuries")
if not injury_ok then
    print("WARNING: engine.injuries not loadable — " .. tostring(injury_mod))
    injury_mod = nil
end

---------------------------------------------------------------------------
-- Stress definition (mirrors spec from npc-combat-implementation-phase4.md)
---------------------------------------------------------------------------
local stress_def = {
    id = "stress",
    name = "acute stress",
    category = "psychological",
    damage_type = "accumulator",
    initial_state = "active",
    on_inflict = {
        initial_damage = 0,
        message = "",
    },
    levels = {
        { name = "shaken",      threshold = 3,  description = "Your hands tremble slightly." },
        { name = "distressed",  threshold = 6,  description = "You're breathing hard, heart pounding." },
        { name = "overwhelmed", threshold = 10, description = "Panic grips you. Everything feels wrong." },
    },
    cure = {
        method = "rest",
        duration = "2 hours",
        requires = { safe_room = true },
        description = "With time and safety, the panic subsides.",
    },
    triggers = {
        witness_creature_death = 1,
        near_death_combat      = 2,
        witness_gore           = 1,
    },
    states = {
        active = {
            name = "stressed",
            symptom = "You feel the weight of what you've seen.",
            description = "Psychological stress from traumatic events.",
            damage_per_tick = 0,
        },
        healed = {
            name = "calm",
            description = "The stress has passed.",
            terminal = true,
        },
    },
    healing_interactions = {},
}

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        stress = 0,
        stress_level = nil,
        stress_effects = {},
        hands = { nil, nil },
        worn = {},
        state = {},
        room = "test-room",
    }
end

local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Error in capture: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function setup()
    if injury_mod and injury_mod.clear_cache then injury_mod.clear_cache() end
    if injury_mod and injury_mod.reset_id_counter then injury_mod.reset_id_counter() end
    if injury_mod and injury_mod.register_definition then
        injury_mod.register_definition("stress", stress_def)
    end
end

local function add_stress_n(player, trigger, count)
    for i = 1, count do
        if injury_mod.add_stress then
            capture_output(function()
                injury_mod.add_stress(player, trigger)
            end)
        else
            capture_output(function()
                injury_mod.inflict(player, "stress", trigger)
            end)
        end
    end
end

---------------------------------------------------------------------------
-- Mock room/context factories
---------------------------------------------------------------------------
local function make_safe_room()
    -- Safe room: no hostile creatures (per Q2: safe_room = no hostile creatures)
    return {
        guid = "{test-safe-room-001}",
        id = "safe-room",
        name = "a quiet chamber",
        description = "A peaceful stone chamber. No threats here.",
        instances = {},
        creatures = {},
    }
end

local function make_unsafe_room()
    -- Unsafe room: contains a hostile creature
    return {
        guid = "{test-unsafe-room-001}",
        id = "unsafe-room",
        name = "a wolf den",
        description = "A dark den. Growling echoes from the shadows.",
        instances = {},
        creatures = {
            {
                guid = "{test-wolf-001}",
                id = "wolf",
                name = "a grey wolf",
                alive = true,
                hostile = true,
            },
        },
    }
end

local function make_context(player, room, registry_objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(registry_objects or {}) do
        reg._objects[obj.guid or obj.id] = obj
    end
    function reg:list()
        local result, seen = {}, {}
        for _, obj in pairs(self._objects) do
            local key = obj.guid or obj.id
            if not seen[key] then
                seen[key] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    function reg:get(id) return self._objects[id] end

    return {
        player = player,
        room = room,
        registry = reg,
    }
end

---------------------------------------------------------------------------
-- TESTS: Stress Cure via Rest
---------------------------------------------------------------------------
suite("STRESS CURE: rest-based healing (WAVE-3 TDD)")

test("1. rest in safe room cures stress", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    local safe_room = make_safe_room()

    -- Accumulate stress to "shaken" level (3 stress)
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre-condition: stress must be 3")

    -- Rest in a safe room (no hostile creatures) for cure duration
    -- The engine should check: room has no hostile creatures → safe_room = true
    -- Then apply cure: stress → 0
    local ctx = make_context(player, safe_room)

    if injury_mod.cure_stress then
        capture_output(function()
            injury_mod.cure_stress(player, ctx)
        end)
    elseif injury_mod.rest_cure then
        capture_output(function()
            injury_mod.rest_cure(player, ctx)
        end)
    else
        -- Fallback: simulate the expected rest verb behavior
        -- The rest verb handler should call the cure path
        error("No cure_stress or rest_cure function found on injury module")
    end

    h.assert_eq(0, player.stress,
        "Stress must be 0 after resting in a safe room")
end)

test("2. rest in unsafe room does NOT cure stress", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    local unsafe_room = make_unsafe_room()

    -- Accumulate stress to "shaken" level (3 stress)
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre-condition: stress must be 3")

    -- Attempt rest in unsafe room (hostile creature present)
    -- The engine should check: room has hostile creatures → safe_room = false
    -- Cure should NOT apply — stress persists
    local ctx = make_context(player, unsafe_room, unsafe_room.creatures)

    if injury_mod.cure_stress then
        capture_output(function()
            injury_mod.cure_stress(player, ctx)
        end)
    elseif injury_mod.rest_cure then
        capture_output(function()
            injury_mod.rest_cure(player, ctx)
        end)
    else
        error("No cure_stress or rest_cure function found on injury module")
    end

    h.assert_eq(3, player.stress,
        "Stress must remain 3 — cannot rest with hostile creature present")
end)

---------------------------------------------------------------------------
-- TESTS: #308 — Rest verb MUST call cure_stress
---------------------------------------------------------------------------
suite("#308: rest verb handler calls cure_stress")

test("3. #308: rest verb reduces stress when resting in safe room", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
    h.assert_truthy(verbs_ok, "engine.verbs must load: " .. tostring(verbs_mod))
    local handlers = verbs_mod.create()
    local rest_fn = handlers["rest"]
    h.assert_truthy(rest_fn, "rest handler must exist")

    local player = fresh_player()
    player.hands = { nil, nil }
    player.worn = {}
    player.bags = {}
    player.consciousness = { state = "conscious" }

    -- Accumulate stress to "shaken" level (3 stress)
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre-condition: stress must be 3")

    local safe_room = make_safe_room()
    safe_room.contents = {}
    safe_room.sky_visible = false

    local reg = {
        _objects = {},
        get = function(self, id) return self._objects[id] end,
        list = function(self) return {} end,
    }

    local ctx = {
        player = player,
        current_room = safe_room,
        room = safe_room,
        registry = reg,
        time_offset = 2,
        game_start_time = os.time(),
        headless = true,
        current_verb = "rest",
        known_objects = {},
    }

    capture_output(function()
        rest_fn(ctx, "for 2 hours")
    end)

    h.assert_eq(0, player.stress,
        "#308: Stress must be 0 after resting 2 hours in a safe room (got " .. tostring(player.stress) .. ")")
end)

test("4. #308: rest verb does NOT reduce stress in unsafe room", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
    h.assert_truthy(verbs_ok, "engine.verbs must load")
    local handlers = verbs_mod.create()
    local rest_fn = handlers["rest"]

    local player = fresh_player()
    player.hands = { nil, nil }
    player.worn = {}
    player.bags = {}
    player.consciousness = { state = "conscious" }

    -- Accumulate stress
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre-condition: stress must be 3")

    local unsafe_room = make_unsafe_room()
    unsafe_room.contents = {}
    unsafe_room.sky_visible = false

    local reg = {
        _objects = {},
        get = function(self, id) return self._objects[id] end,
        list = function(self) return {} end,
    }

    local ctx = {
        player = player,
        current_room = unsafe_room,
        room = unsafe_room,
        registry = reg,
        time_offset = 2,
        game_start_time = os.time(),
        headless = true,
        current_verb = "rest",
        known_objects = {},
    }

    capture_output(function()
        rest_fn(ctx, "for 2 hours")
    end)

    h.assert_eq(3, player.stress,
        "#308: Stress must remain 3 when resting in unsafe room (hostile creatures)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
