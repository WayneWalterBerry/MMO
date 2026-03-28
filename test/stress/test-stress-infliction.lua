-- test/stress/test-stress-infliction.lua
-- WAVE-3 TDD: Stress infliction tests.
-- Tests: witness creature death → +1, near-death combat → +2, witness gore → +1.
-- Implementation by Bart (trauma hooks) and Flanders (stress.lua) may not
-- exist yet — TDD: tests define the contract, failures are expected.
--
-- Must be run from repository root: lua test/stress/test-stress-infliction.lua

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

---------------------------------------------------------------------------
-- TESTS: Stress Infliction Triggers
---------------------------------------------------------------------------
suite("STRESS INFLICTION: trauma triggers (WAVE-3 TDD)")

test("1. witness creature death → +1 stress", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    h.assert_truthy(injury_mod.add_stress or injury_mod.inflict,
        "injuries module must have add_stress or inflict")
    setup()

    local player = fresh_player()

    -- Simulate: creature dies in player's room → trauma hook fires
    -- The engine calls add_stress(player, "witness_creature_death")
    -- which should add +1 stress (per spec: triggers.witness_creature_death = 1)
    if injury_mod.add_stress then
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    else
        -- Fallback: if add_stress doesn't exist yet, inflict stress directly
        capture_output(function()
            injury_mod.inflict(player, "stress", "witness_creature_death")
        end)
    end

    h.assert_eq(1, player.stress, "Stress must be 1 after witnessing one creature death")
end)

test("2. near-death combat → +2 stress", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    -- Player health is below 10% after combat → near_death_combat trigger fires
    -- Simulate: combat ends, player at 8/100 health → engine fires add_stress
    player.max_health = 100
    -- Mark the player as near-death (health computed from injuries)
    -- The engine checks: health < max_health * 0.1 → triggers near_death_combat
    if injury_mod.add_stress then
        capture_output(function()
            injury_mod.add_stress(player, "near_death_combat")
        end)
    else
        capture_output(function()
            injury_mod.inflict(player, "stress", "near_death_combat")
        end)
    end

    h.assert_eq(2, player.stress, "Stress must be 2 after near-death combat (+2 per spec)")
end)

test("3. witness gore (butchery) → +1 stress", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()

    -- Simulate: player witnesses butchery in their room → witness_gore trigger
    if injury_mod.add_stress then
        capture_output(function()
            injury_mod.add_stress(player, "witness_gore")
        end)
    else
        capture_output(function()
            injury_mod.inflict(player, "stress", "witness_gore")
        end)
    end

    h.assert_eq(1, player.stress, "Stress must be 1 after witnessing gore (+1 per spec)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
