-- test/injuries/test-venom-survivability.lua
-- TDD tests for Issue #360: Spider venom kills before craft+apply sequence.
-- Venom should be urgent but survivable with quick action.
--
-- Tests that venom damage rates are tuned to give the player enough
-- turns in the curable window to craft and apply a remedy.
--
-- Usage: lua test/injuries/test-venom-survivability.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

local injury_mod = require("engine.injuries")

---------------------------------------------------------------------------
-- Test harness
---------------------------------------------------------------------------
local passed = 0
local failed = 0

local function assert_eq(actual, expected, label)
    if actual == expected then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected: " .. tostring(expected))
        print("    actual:   " .. tostring(actual))
    end
end

local function assert_true(val, label)
    assert_eq(not not val, true, label)
end

local function assert_lte(actual, max, label)
    if actual <= max then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected <= " .. tostring(max) .. ", got: " .. tostring(actual))
    end
end

local function assert_gte(actual, min, label)
    if actual >= min then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected >= " .. tostring(min) .. ", got: " .. tostring(actual))
    end
end

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then return table.concat(lines, "\n"), err end
    return table.concat(lines, "\n"), nil
end

---------------------------------------------------------------------------
-- Load spider-venom definition from disk
---------------------------------------------------------------------------
local venom_def = nil
do
    local ok, def = pcall(dofile, repo_root .. SEP .. "src" .. SEP .. "meta"
        .. SEP .. "injuries" .. SEP .. "spider-venom.lua")
    if ok and def then venom_def = def end
end

assert_true(venom_def ~= nil, "spider-venom definition loads from disk")

---------------------------------------------------------------------------
-- Helper: compute ticks from timed_events or duration
---------------------------------------------------------------------------
local SECONDS_PER_TICK = 360

local function get_ticks(state_def)
    if state_def.duration then return state_def.duration end
    if state_def.timed_events then
        for _, evt in ipairs(state_def.timed_events) do
            if evt.event == "transition" and evt.delay then
                return math.ceil(evt.delay / SECONDS_PER_TICK)
            end
        end
    end
    return nil
end

local function fresh_player()
    return {
        id = "player",
        is_player = true,
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        state = {},
    }
end

local function setup()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("spider-venom", venom_def)
end

---------------------------------------------------------------------------
-- 1. Reduced initial damage (was 2, now should be 1)
---------------------------------------------------------------------------
print("\n=== Issue #360: reduced initial damage ===")

do
    assert_lte(venom_def.on_inflict.initial_damage, 1,
        "initial_damage is at most 1 (was 2)")
end

---------------------------------------------------------------------------
-- 2. Reduced injected-state damage_per_tick (was 2, now should be 1)
---------------------------------------------------------------------------
print("\n=== Issue #360: reduced injected damage_per_tick ===")

do
    assert_lte(venom_def.states.injected.damage_per_tick, 1,
        "injected damage_per_tick is at most 1 (was 2)")
    assert_lte(venom_def.on_inflict.damage_per_tick, 1,
        "on_inflict damage_per_tick is at most 1 (was 2)")
end

---------------------------------------------------------------------------
-- 3. Longer injected window (was 3 ticks, now at least 5)
---------------------------------------------------------------------------
print("\n=== Issue #360: longer injected curable window ===")

do
    local ticks = get_ticks(venom_def.states.injected)
    assert_true(ticks ~= nil, "injected state has timed duration")
    assert_gte(ticks, 5, "injected window is at least 5 ticks (was 3)")
end

---------------------------------------------------------------------------
-- 4. Reduced spreading damage_per_tick (was 3, now should be 2)
---------------------------------------------------------------------------
print("\n=== Issue #360: reduced spreading damage_per_tick ===")

do
    assert_lte(venom_def.states.spreading.damage_per_tick, 2,
        "spreading damage_per_tick is at most 2 (was 3)")
end

---------------------------------------------------------------------------
-- 5. Longer spreading window (was 5 ticks, now at least 6)
---------------------------------------------------------------------------
print("\n=== Issue #360: longer spreading curable window ===")

do
    local ticks = get_ticks(venom_def.states.spreading)
    assert_true(ticks ~= nil, "spreading state has timed duration")
    assert_gte(ticks, 6, "spreading window is at least 6 ticks (was 5)")
end

---------------------------------------------------------------------------
-- 6. Survivability: player survives injected phase with 100 HP
---------------------------------------------------------------------------
print("\n=== Issue #360: survivability during craft+apply sequence ===")

do
    setup()
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite", "left arm")
    end)

    -- Simulate 5 turns of ticking (craft + apply window)
    for i = 1, 5 do
        capture_print(function() injury_mod.tick(player) end)
    end

    local health = injury_mod.compute_health(player)
    assert_gte(health, 80,
        "player retains >= 80 HP after 5 ticks of venom (craft+apply window)")
end

---------------------------------------------------------------------------
-- 7. Total venom damage across full lifecycle is non-lethal
---------------------------------------------------------------------------
print("\n=== Issue #360: total venom damage is survivable ===")

do
    setup()
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite", "leg")
    end)

    -- Tick through entire lifecycle (generous upper bound)
    for i = 1, 25 do
        capture_print(function() injury_mod.tick(player) end)
    end

    local health = injury_mod.compute_health(player)
    assert_gte(health, 50,
        "player survives full venom lifecycle with >= 50 HP (100 HP start)")
end

---------------------------------------------------------------------------
-- 8. Paralysis damage_per_tick unchanged at 1
---------------------------------------------------------------------------
print("\n=== Issue #360: paralysis damage unchanged ===")

do
    assert_eq(venom_def.states.paralysis.damage_per_tick, 1,
        "paralysis damage_per_tick stays at 1")
end

---------------------------------------------------------------------------
-- 9. Core identity preserved: still a disease, still over_time
---------------------------------------------------------------------------
print("\n=== Issue #360: core identity preserved ===")

do
    assert_eq(venom_def.category, "disease", "still categorized as disease")
    assert_eq(venom_def.damage_type, "over_time", "still over_time damage")
    assert_eq(venom_def.initial_state, "injected", "still starts in injected")
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    os.exit(1)
end
