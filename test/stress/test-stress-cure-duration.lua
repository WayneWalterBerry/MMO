-- test/stress/test-stress-cure-duration.lua
-- Issue #311 TDD: cure_stress must enforce 2-hour rest duration.
-- Stress cure requires accumulated safe-room rest >= cure.duration.
-- Must be run from repository root: lua test/stress/test-stress-cure-duration.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local injury_ok, injury_mod = pcall(require, "engine.injuries")
if not injury_ok then
    print("WARNING: engine.injuries not loadable — " .. tostring(injury_mod))
    injury_mod = nil
end

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
        stress_rest_accumulated = 0,
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
end

local function add_stress_n(player, trigger, count)
    for i = 1, count do
        if injury_mod.add_stress then
            capture_output(function() injury_mod.add_stress(player, trigger) end)
        end
    end
end

local function make_safe_ctx(player)
    return {
        player = player,
        room = {
            guid = "{test-safe-room}",
            id = "safe-room",
            name = "a quiet chamber",
            creatures = {},
        },
        registry = { _objects = {}, list = function(self) return {} end },
    }
end

local function make_unsafe_ctx(player)
    return {
        player = player,
        room = {
            guid = "{test-unsafe-room}",
            id = "unsafe-room",
            name = "a wolf den",
            creatures = {
                { guid = "{wolf-1}", id = "wolf", alive = true, hostile = true },
            },
        },
        registry = { _objects = {}, list = function(self) return {} end },
    }
end

---------------------------------------------------------------------------
-- TESTS: Stress Cure Duration Enforcement (Issue #311)
---------------------------------------------------------------------------
suite("STRESS CURE DURATION: 2-hour rest requirement (Issue #311 TDD)")

test("1. resting 1 hour in safe room does NOT cure stress (duration not met)", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre: stress must be 3")

    local ctx = make_safe_ctx(player)
    local result
    capture_output(function()
        result = injury_mod.cure_stress(player, ctx, 1.0)
    end)

    h.assert_truthy(player.stress > 0,
        "1 hour rest must NOT cure stress (requires 2 hours), stress=" .. tostring(player.stress))
end)

test("2. resting 2 hours in safe room DOES cure stress", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre: stress must be 3")

    local ctx = make_safe_ctx(player)
    local result
    capture_output(function()
        result = injury_mod.cure_stress(player, ctx, 2.0)
    end)

    h.assert_eq(0, player.stress,
        "2 hours rest in safe room must cure stress")
    h.assert_eq(true, result, "cure_stress must return true when cured")
end)

test("3. accumulated rest: 1 hour + 1 hour = cured", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre: stress must be 3")

    local ctx = make_safe_ctx(player)

    -- First rest: 1 hour — not enough
    capture_output(function()
        injury_mod.cure_stress(player, ctx, 1.0)
    end)
    h.assert_truthy(player.stress > 0,
        "After 1h rest, stress should persist")

    -- Second rest: 1 more hour — total = 2 hours, should cure
    local result
    capture_output(function()
        result = injury_mod.cure_stress(player, ctx, 1.0)
    end)
    h.assert_eq(0, player.stress,
        "After 1h + 1h = 2h accumulated rest, stress must be cured")
end)

test("4. resting in unsafe room does NOT accumulate rest time", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    add_stress_n(player, "witness_creature_death", 3)

    local unsafe_ctx = make_unsafe_ctx(player)
    local safe_ctx = make_safe_ctx(player)

    -- Try resting 2h in unsafe room — should not work
    capture_output(function()
        injury_mod.cure_stress(player, unsafe_ctx, 2.0)
    end)
    h.assert_eq(3, player.stress,
        "Resting in unsafe room must not cure stress")

    -- Accumulated rest should still be 0 — need full 2h in safe room
    capture_output(function()
        injury_mod.cure_stress(player, safe_ctx, 1.0)
    end)
    h.assert_truthy(player.stress > 0,
        "After 0h safe + 1h safe = 1h, still need more rest")
end)

test("5. backward compat: cure_stress without duration cures instantly (legacy)", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    add_stress_n(player, "witness_creature_death", 3)
    h.assert_eq(3, player.stress, "Pre: stress must be 3")

    local ctx = make_safe_ctx(player)
    -- Call without rest_hours — legacy behavior should still work
    local result
    capture_output(function()
        result = injury_mod.cure_stress(player, ctx)
    end)
    h.assert_eq(0, player.stress,
        "Legacy call without duration should still cure (backward compat)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
