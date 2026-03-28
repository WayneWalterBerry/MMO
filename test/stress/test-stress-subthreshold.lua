-- test/stress/test-stress-subthreshold.lua
-- Issue #317 TDD: Sub-threshold stress must show feedback in injuries list.
-- When stress > 0 but below "shaken" threshold (3), injuries.list() should
-- print a subtle message like "You feel a growing unease."
--
-- Must be run from repository root: lua test/stress/test-stress-subthreshold.lua

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
-- Load modules
---------------------------------------------------------------------------
local injury_ok, injury_mod = pcall(require, "engine.injuries")
if not injury_ok then
    print("WARNING: engine.injuries not loadable — " .. tostring(injury_mod))
    injury_mod = nil
end

---------------------------------------------------------------------------
-- Stress definition (mirrors spec)
---------------------------------------------------------------------------
local stress_def = {
    id = "stress",
    name = "acute stress",
    category = "psychological",
    damage_type = "accumulator",
    initial_state = "active",
    on_inflict = { initial_damage = 0, message = "" },
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
        active = { name = "stressed", description = "Psychological stress.", damage_per_tick = 0 },
        healed = { name = "calm", description = "The stress has passed.", terminal = true },
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

---------------------------------------------------------------------------
-- TESTS: Sub-threshold stress feedback (Issue #317 TDD)
---------------------------------------------------------------------------
suite("STRESS SUB-THRESHOLD: injuries list shows feedback below shaken (Issue #317)")

test("1. stress=1 shows sub-threshold message in injuries list", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    -- Add 1 stress (below shaken threshold of 3)
    capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_eq(1, player.stress, "Stress must be 1")
    h.assert_eq(nil, injury_mod.get_stress_level(player),
        "Stress level must be nil (below threshold)")

    -- injuries.list() should still mention stress
    local output = capture_output(function()
        injury_mod.list(player)
    end)
    h.assert_truthy(output:find("uneas") or output:find("growing"),
        "injuries list must show sub-threshold stress message, got: " .. output)
end)

test("2. stress=2 shows sub-threshold message in injuries list", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_eq(2, player.stress, "Stress must be 2")

    local output = capture_output(function()
        injury_mod.list(player)
    end)
    h.assert_truthy(output:find("uneas") or output:find("growing"),
        "injuries list must show sub-threshold stress message at stress=2, got: " .. output)
end)

test("3. stress=0 does NOT show any stress message", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    h.assert_eq(0, player.stress, "Stress must be 0")

    local output = capture_output(function()
        injury_mod.list(player)
    end)
    h.assert_truthy(not (output:find("uneas") or output:find("growing")),
        "injuries list must NOT show sub-threshold message at stress=0, got: " .. output)
end)

test("4. stress=3 (at threshold) shows level description, not sub-threshold", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
        injury_mod.add_stress(player, "witness_creature_death")
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_eq(3, player.stress, "Stress must be 3")
    h.assert_eq("shaken", injury_mod.get_stress_level(player),
        "Stress level must be shaken at 3")

    local output = capture_output(function()
        injury_mod.list(player)
    end)
    -- Should show threshold-level description, not sub-threshold
    h.assert_truthy(output:find("hands tremble"),
        "injuries list must show shaken description at threshold, got: " .. output)
end)

test("5. sub-threshold stress with no physical injuries still shows examine header", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)

    local output = capture_output(function()
        injury_mod.list(player)
    end)
    -- Should NOT say "You feel fine" — there IS stress
    h.assert_truthy(not output:find("feel fine"),
        "injuries list must NOT say 'feel fine' when stress > 0, got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
