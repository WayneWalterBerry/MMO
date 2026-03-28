-- test/stress/test-stress-debuffs.lua
-- WAVE-3 TDD: Stress debuff application tests.
-- Tests: shaken → -1 attack, distressed → -2 attack + 20% flee_bias,
--        overwhelmed → -2 attack + 30% flee_bias + 20% movement_penalty.
-- Implementation by Bart (debuff system) and Flanders (stress.lua) may not
-- exist yet — TDD: tests define the contract, failures are expected.
--
-- Must be run from repository root: lua test/stress/test-stress-debuffs.lua

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
    effects = {
        shaken      = { attack_penalty = -1 },
        distressed  = { attack_penalty = -2, flee_bias = 0.2 },
        overwhelmed = { attack_penalty = -2, flee_bias = 0.3, movement_penalty = 0.2 },
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
-- Helper: get current stress effects from player
---------------------------------------------------------------------------
local function get_stress_effects(player)
    -- Try engine convenience function first
    if injury_mod.get_stress_effects then
        return injury_mod.get_stress_effects(player)
    end
    -- Fall back to player.stress_effects populated by engine
    return player.stress_effects or {}
end

local function get_stress_level(player)
    if injury_mod.get_stress_level then
        return injury_mod.get_stress_level(player)
    end
    return player.stress_level
end

---------------------------------------------------------------------------
-- TESTS: Stress Debuffs by Level
---------------------------------------------------------------------------
suite("STRESS DEBUFFS: level-based effects (WAVE-3 TDD)")

test("1. shaken level (3 stress) → -1 attack penalty", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()

    -- Accumulate 3 stress to reach "shaken" threshold
    -- 3x witness_creature_death = +3 stress
    add_stress_n(player, "witness_creature_death", 3)

    h.assert_eq(3, player.stress, "Stress must be 3 after 3 witnessed deaths")

    local level = get_stress_level(player)
    h.assert_eq("shaken", level, "Stress level must be 'shaken' at threshold 3")

    local effects = get_stress_effects(player)
    h.assert_eq(-1, effects.attack_penalty,
        "Shaken level must apply -1 attack penalty")
end)

test("2. distressed level (6 stress) → -2 attack, +20% flee_bias", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()

    -- Accumulate 6 stress to reach "distressed" threshold
    -- 3x near_death_combat = +6 stress
    add_stress_n(player, "near_death_combat", 3)

    h.assert_eq(6, player.stress, "Stress must be 6 after 3 near-death events")

    local level = get_stress_level(player)
    h.assert_eq("distressed", level, "Stress level must be 'distressed' at threshold 6")

    local effects = get_stress_effects(player)
    h.assert_eq(-2, effects.attack_penalty,
        "Distressed level must apply -2 attack penalty")
    h.assert_eq(0.2, effects.flee_bias,
        "Distressed level must apply 0.2 (20%) flee bias")
end)

test("3. overwhelmed level (10 stress) → full debuff suite", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()

    -- Accumulate 10 stress to reach "overwhelmed" threshold
    -- 5x near_death_combat = +10 stress
    add_stress_n(player, "near_death_combat", 5)

    h.assert_eq(10, player.stress, "Stress must be 10 after 5 near-death events")

    local level = get_stress_level(player)
    h.assert_eq("overwhelmed", level,
        "Stress level must be 'overwhelmed' at threshold 10")

    local effects = get_stress_effects(player)
    h.assert_eq(-2, effects.attack_penalty,
        "Overwhelmed level must apply -2 attack penalty")
    h.assert_eq(0.3, effects.flee_bias,
        "Overwhelmed level must apply 0.3 (30%) flee bias")
    h.assert_eq(0.2, effects.movement_penalty,
        "Overwhelmed level must apply 0.2 (20%) movement penalty")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
