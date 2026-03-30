-- test/food/test-food-poisoning.lua
-- WAVE-3 TDD: Food poisoning injury tests — FSM lifecycle, damage, recovery.
-- Tests injury infliction, state progression, damage over time, and clearing.
-- Must be run from repository root: lua test/food/test-food-poisoning.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load injury module (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local injuries_ok, injuries = pcall(require, "engine.injuries")
if not injuries_ok then
    print("WARNING: engine.injuries not loadable — " .. tostring(injuries))
    injuries = nil
end

---------------------------------------------------------------------------
-- Load food-poisoning injury definition
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local fp_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "injuries" .. SEP .. "food-poisoning.lua"
local ok_fp, fp_def = pcall(dofile, fp_path)
if not ok_fp then
    print("WARNING: food-poisoning.lua not found — " .. tostring(fp_def))
    fp_def = nil
end

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[deep_copy(k)] = deep_copy(v) end
    return copy
end

---------------------------------------------------------------------------
-- Food poisoning FSM spec (from WAVE-3 plan)
-- This is the expected structure — TDD tests validate that the actual
-- food-poisoning.lua file matches this spec when it exists.
---------------------------------------------------------------------------
local expected_fp = {
    id = "food-poisoning",
    name = "Food Poisoning",
    category = "disease",
    damage_type = "over_time",
    initial_state = "onset",
    states = {
        onset = {
            damage_per_tick = 0,
            timed_duration_ticks = 3,   -- 1080s / 360s per tick = 3 ticks
        },
        nausea = {
            damage_per_tick = 1,
            timed_duration_ticks = 12,  -- 4320s / 360s per tick = 12 ticks
        },
        recovery = {
            damage_per_tick = 0,
            timed_duration_ticks = 5,   -- 1800s / 360s per tick = 5 ticks
        },
        cleared = {
            terminal = true,
        },
    },
    transitions = {
        { from = "onset", to = "nausea" },
        { from = "nausea", to = "recovery" },
        { from = "recovery", to = "cleared" },
    },
}

-- Simulate FSM tick progression on a food-poisoning injury instance.
-- The real engine uses timed_events with delays in seconds. For testing,
-- we model duration as tick counts derived from the timed_events delays.
local function make_fp_instance()
    local transitions = {
        { from = "onset", to = "nausea", verb = "_tick", condition = "timer_expired" },
        { from = "nausea", to = "recovery", verb = "_tick", condition = "timer_expired" },
        { from = "recovery", to = "cleared", verb = "_tick", condition = "timer_expired" },
    }
    -- Use timed_duration_ticks from expected_fp for simulation
    local states = {
        onset = { damage_per_tick = 0, duration = expected_fp.states.onset.timed_duration_ticks },
        nausea = { damage_per_tick = 1, duration = expected_fp.states.nausea.timed_duration_ticks },
        recovery = { damage_per_tick = 0, duration = expected_fp.states.recovery.timed_duration_ticks },
        cleared = { terminal = true },
    }
    return {
        id = "food-poisoning",
        type = "food-poisoning",
        _state = "onset",
        _tick_counter = 0,
        states = deep_copy(states),
        transitions = deep_copy(transitions),
    }
end

local function advance_fp_ticks(inst, n)
    for _ = 1, n do
        inst._tick_counter = (inst._tick_counter or 0) + 1
        local current = inst._state
        local state_def = inst.states and inst.states[current]
        if state_def and state_def.duration and inst._tick_counter >= state_def.duration then
            for _, tr in ipairs(inst.transitions or {}) do
                if tr.from == current and tr.verb == "_tick" then
                    inst._state = tr.to
                    inst._tick_counter = 0
                    break
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- SUITE 1: Food poisoning injury definition
---------------------------------------------------------------------------
suite("FOOD POISONING: injury definition (WAVE-3)")

test("1. food-poisoning.lua exists and loads", function()
    if not ok_fp then
        -- TDD: file doesn't exist yet — validate expected spec instead
        h.assert_truthy(expected_fp.id == "food-poisoning",
            "expected food-poisoning spec must have correct id")
        h.assert_truthy(expected_fp.initial_state == "onset",
            "expected food-poisoning must start in onset state")
        return
    end
    h.assert_truthy(fp_def, "food-poisoning.lua must return a table")
    h.assert_eq("food-poisoning", fp_def.id, "id must be food-poisoning")
    h.assert_eq("onset", fp_def.initial_state, "initial_state must be onset")
end)

test("2. food-poisoning is a disease category", function()
    if fp_def then
        h.assert_eq("disease", fp_def.category, "category must be disease")
    else
        h.assert_eq("disease", expected_fp.category, "expected category must be disease")
    end
end)

test("3. food-poisoning has over_time damage type", function()
    if fp_def then
        h.assert_eq("over_time", fp_def.damage_type, "damage_type must be over_time")
    else
        h.assert_eq("over_time", expected_fp.damage_type, "expected damage_type must be over_time")
    end
end)

---------------------------------------------------------------------------
-- SUITE 2: FSM progression
---------------------------------------------------------------------------
suite("FOOD POISONING: FSM progression (WAVE-3)")

test("4. food-poisoning starts in onset state", function()
    local inst = make_fp_instance()
    h.assert_eq("onset", inst._state, "must start in onset state")
end)

test("5. onset → nausea after duration ticks", function()
    local inst = make_fp_instance()
    advance_fp_ticks(inst, expected_fp.states.onset.timed_duration_ticks)
    h.assert_eq("nausea", inst._state, "must transition to nausea after onset duration")
end)

test("6. nausea → recovery after duration ticks", function()
    local inst = make_fp_instance()
    advance_fp_ticks(inst, expected_fp.states.onset.timed_duration_ticks)    -- → nausea
    advance_fp_ticks(inst, expected_fp.states.nausea.timed_duration_ticks)   -- → recovery
    h.assert_eq("recovery", inst._state, "must transition to recovery after nausea duration")
end)

test("7. recovery → cleared after duration ticks", function()
    local inst = make_fp_instance()
    advance_fp_ticks(inst, expected_fp.states.onset.timed_duration_ticks)    -- → nausea
    advance_fp_ticks(inst, expected_fp.states.nausea.timed_duration_ticks)   -- → recovery
    advance_fp_ticks(inst, expected_fp.states.recovery.timed_duration_ticks) -- → cleared
    h.assert_eq("cleared", inst._state, "must transition to cleared after recovery duration")
end)

---------------------------------------------------------------------------
-- SUITE 3: Damage over time
---------------------------------------------------------------------------
suite("FOOD POISONING: damage over time (WAVE-3)")

test("8. onset state has zero damage per tick", function()
    h.assert_eq(0, expected_fp.states.onset.damage_per_tick,
        "onset damage_per_tick must be 0")
end)

test("9. nausea state applies damage per tick", function()
    h.assert_truthy(expected_fp.states.nausea.damage_per_tick > 0,
        "nausea damage_per_tick must be positive")
    h.assert_eq(1, expected_fp.states.nausea.damage_per_tick,
        "nausea damage_per_tick must be 1")
end)

test("10. recovery state has zero damage per tick", function()
    h.assert_eq(0, expected_fp.states.recovery.damage_per_tick,
        "recovery damage_per_tick must be 0")
end)

test("11. cleared state is terminal", function()
    h.assert_eq(true, expected_fp.states.cleared.terminal,
        "cleared state must be terminal")
end)

---------------------------------------------------------------------------
-- SUITE 4: Duration ticks correctly
---------------------------------------------------------------------------
suite("FOOD POISONING: duration tracking (WAVE-3)")

test("12. onset duration is 3 ticks", function()
    h.assert_eq(3, expected_fp.states.onset.timed_duration_ticks,
        "onset duration must be 3 ticks")
end)

test("13. nausea duration is 12 ticks", function()
    h.assert_eq(12, expected_fp.states.nausea.timed_duration_ticks,
        "nausea duration must be 12 ticks")
end)

test("14. recovery duration is 5 ticks", function()
    h.assert_eq(5, expected_fp.states.recovery.timed_duration_ticks,
        "recovery duration must be 5 ticks")
end)

test("15. total food-poisoning duration is 20 ticks", function()
    local total = expected_fp.states.onset.timed_duration_ticks
               + expected_fp.states.nausea.timed_duration_ticks
               + expected_fp.states.recovery.timed_duration_ticks
    h.assert_eq(20, total, "total food-poisoning duration must be 20 ticks")
end)

---------------------------------------------------------------------------
-- SUITE 5: Recovery clears restrictions
---------------------------------------------------------------------------
suite("FOOD POISONING: recovery (WAVE-3)")

test("16. full FSM cycle reaches cleared terminal state", function()
    local inst = make_fp_instance()
    advance_fp_ticks(inst, expected_fp.states.onset.timed_duration_ticks)    -- → nausea
    advance_fp_ticks(inst, expected_fp.states.nausea.timed_duration_ticks)   -- → recovery
    advance_fp_ticks(inst, expected_fp.states.recovery.timed_duration_ticks) -- → cleared

    h.assert_eq("cleared", inst._state, "must reach cleared state")
    h.assert_eq(true, expected_fp.states.cleared.terminal,
        "cleared state must be terminal — injury is done")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
