-- test/verbs/test-bug-regressions.lua
-- Regression tests for BUG-069, BUG-071, BUG-104b, BUG-105b, BUG-106b.
-- Each bug gets at least one test to prevent regression.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")
local preprocess = require("engine.parser.preprocess")
local presentation = require("engine.ui.presentation")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

-- Create verb handlers
local handlers = verbs_mod.create()

-- Helper: capture print output
local function capture_output(fn)
    local captured = {}
    local old_print = print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "String not found") .. "\n  Expected: " .. needle .. "\n  In: " .. haystack)
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "String should NOT be found") .. "\n  Unexpected: " .. needle .. "\n  In: " .. haystack)
    end
end

-- Helper: create a mock candle object with FSM states (mirrors candle.lua)
local function make_candle(state)
    return {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow"},
        _state = state or "unlit",
        states = {
            unlit = { name = "a tallow candle", casts_light = false },
            lit = { name = "a lit tallow candle", casts_light = true },
            extinguished = { name = "a half-burned candle", casts_light = false },
            spent = { name = "a spent candle", casts_light = false, terminal = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light", aliases = {"ignite"} },
            {
                from = "lit", to = "extinguished", verb = "extinguish",
                aliases = {"blow", "put out", "snuff"},
                message = "You blow out the candle.",
            },
            { from = "extinguished", to = "lit", verb = "light", aliases = {"relight"} },
        },
    }
end

-- Helper: create basic test context with light
local function create_lit_context(extra_objects)
    local objects = {}
    local room_contents = {}
    -- Curtains for daylight
    objects["curtains"] = {
        id = "curtains", name = "curtains",
        allows_daylight = true, hidden = true,
    }
    room_contents[#room_contents + 1] = "curtains"
    for id, obj in pairs(extra_objects or {}) do
        objects[id] = obj
        room_contents[#room_contents + 1] = id
    end
    local room = {
        id = "test_room", name = "Test Room",
        description = "A test room.",
        contents = room_contents, exits = {},
    }
    local reg = {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
    }
    return {
        registry = reg,
        current_room = room,
        time_offset = 8,  -- 2AM + 8 = 10AM (daytime)
        game_start_time = os.time(),
        player = { hands = { nil, nil }, worn_items = {}, bags = {}, worn = {} },
        injuries = {},
    }
end

-------------------------------------------------------------------------------
h.suite("BUG-069: sleep until dawn — correct error when already past dawn")
-------------------------------------------------------------------------------

test("BUG-069: 'sleep until dawn' at 10AM → 'already past dawn' (not 12h limit)", function()
    local ctx = create_lit_context()
    -- time_offset = 8 → 2AM + 8 = 10AM, well past dawn (6AM)
    local output = capture_output(function()
        handlers["sleep"](ctx, "until dawn")
    end)
    assert_contains(output, "already past dawn",
        "Should say 'already past dawn' at 10AM")
    assert_not_contains(output, "can't sleep that long",
        "Should NOT hit 12-hour limit message")
end)

test("BUG-069: 'sleep until morning' at 10AM → 'already past dawn'", function()
    local ctx = create_lit_context()
    local output = capture_output(function()
        handlers["sleep"](ctx, "until morning")
    end)
    assert_contains(output, "already past dawn",
        "Should say 'already past dawn' at 10AM")
end)

test("BUG-069: 'sleep until dawn' at 11PM → wraps to next dawn (valid)", function()
    local ctx = create_lit_context()
    ctx.time_offset = 21  -- 2AM + 21 = 23:00 (11PM) → next dawn = 7 hours
    local output = capture_output(function()
        handlers["sleep"](ctx, "until dawn")
    end)
    -- Should actually sleep, not show error
    assert_contains(output, "close your eyes",
        "Should sleep from 11PM to dawn")
end)

test("BUG-069: 'sleep until night' at 10PM → 'already nighttime'", function()
    local ctx = create_lit_context()
    ctx.time_offset = 20  -- 2AM + 20 = 22:00 (10PM)
    local output = capture_output(function()
        handlers["sleep"](ctx, "until night")
    end)
    assert_contains(output, "already nighttime",
        "Should say 'already nighttime' at 10PM")
    assert_not_contains(output, "can't sleep that long",
        "Should NOT hit 12-hour limit message")
end)

test("BUG-069: 'sleep until dusk' at 8PM → 'already nighttime'", function()
    local ctx = create_lit_context()
    ctx.time_offset = 18  -- 2AM + 18 = 20:00 (8PM)
    local output = capture_output(function()
        handlers["sleep"](ctx, "until dusk")
    end)
    assert_contains(output, "already nighttime")
end)

-------------------------------------------------------------------------------
h.suite("BUG-071: Rapid 'look around' spam must not hang")
-------------------------------------------------------------------------------

test("BUG-071: 100x 'look around' pipeline calls complete without hang", function()
    for i = 1, 100 do
        local v, n = preprocess.natural_language("look around")
        eq("look", v, "Iteration " .. i .. ": look around should parse")
    end
end)

test("BUG-071: 100x 'look around' handler calls complete without hang", function()
    local ctx = create_lit_context()
    for i = 1, 100 do
        capture_output(function()
            handlers["look"](ctx, "")
        end)
    end
    -- If we get here, no hang occurred
    truthy(true, "100 look-around calls completed without hang")
end)

test("BUG-071: rapid mixed look commands complete without hang", function()
    local ctx = create_lit_context({
        chair = { id = "chair", name = "a chair", description = "A wooden chair." },
    })
    local commands = { "look around", "look", "look around", "look around" }
    for _, cmd in ipairs(commands) do
        local v, n = preprocess.natural_language(cmd)
        if v then
            capture_output(function() handlers[v](ctx, n) end)
        end
    end
    truthy(true, "Mixed look commands completed without hang")
end)

-------------------------------------------------------------------------------
h.suite("BUG-104b: Politeness + idiom combo — pipeline ordering")
-------------------------------------------------------------------------------

test("BUG-104b: 'please could you have a look around' → look", function()
    local v, n = preprocess.natural_language("please could you have a look around")
    eq("look", v, "politeness+idiom combo should resolve to 'look'")
    eq("", n)
end)

test("BUG-104b: 'could you have a look around' → look", function()
    local v, n = preprocess.natural_language("could you have a look around")
    eq("look", v)
    eq("", n)
end)

test("BUG-104b: 'please have a look around' → look", function()
    local v, n = preprocess.natural_language("please have a look around")
    eq("look", v)
    eq("", n)
end)

test("BUG-104b: 'please could you have a look' → look", function()
    local v, n = preprocess.natural_language("please could you have a look")
    eq("look", v)
    eq("", n)
end)

test("BUG-104b: 'please could you have a look at nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("please could you have a look at nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("BUG-104b: 'kindly have a look around' → look", function()
    local v, n = preprocess.natural_language("kindly have a look around")
    eq("look", v)
    eq("", n)
end)

test("BUG-104b: 'please blow out candle' → extinguish candle", function()
    local v, n = preprocess.natural_language("please blow out candle")
    eq("extinguish", v)
    eq("candle", n)
end)

-------------------------------------------------------------------------------
h.suite("BUG-105b: Bare 'examine' — should prompt, not 'can't find that'")
-------------------------------------------------------------------------------

test("BUG-105b: bare 'examine' handler says 'Examine what?'", function()
    local ctx = create_lit_context()
    local output = capture_output(function()
        handlers["examine"](ctx, "")
    end)
    assert_contains(output, "Examine what?",
        "Bare examine should prompt the player")
end)

test("BUG-105b: bare 'examine' does NOT say 'can't find'", function()
    local ctx = create_lit_context()
    local output = capture_output(function()
        handlers["examine"](ctx, "")
    end)
    assert_not_contains(output, "can't find",
        "Bare examine should NOT say 'can't find'")
end)

test("BUG-105b: 'examine candle' with candle in room still works", function()
    local candle = make_candle("unlit")
    local ctx = create_lit_context({ candle = candle })
    local output = capture_output(function()
        handlers["examine"](ctx, "candle")
    end)
    -- Should describe the candle, not say "Examine what?"
    assert_not_contains(output, "Examine what?",
        "Examine with valid noun should NOT prompt")
end)

-------------------------------------------------------------------------------
h.suite("BUG-106b: 'blow out candle' (unlit) — proper message")
-------------------------------------------------------------------------------

test("BUG-106b: extinguish unlit candle → 'isn't lit' (not 'can't extinguish')", function()
    local candle = make_candle("unlit")
    local ctx = create_lit_context({ candle = candle })
    local output = capture_output(function()
        handlers["extinguish"](ctx, "candle")
    end)
    assert_contains(output, "isn't lit",
        "Unlit candle should say 'isn't lit'")
    assert_not_contains(output, "can't extinguish",
        "Should NOT say 'can't extinguish' for an extinguishable object")
end)

test("BUG-106b: extinguish already-extinguished candle → 'isn't lit'", function()
    local candle = make_candle("extinguished")
    candle.name = "a half-burned candle"
    local ctx = create_lit_context({ candle = candle })
    local output = capture_output(function()
        handlers["extinguish"](ctx, "candle")
    end)
    assert_contains(output, "isn't lit",
        "Already-extinguished candle should say 'isn't lit'")
end)

test("BUG-106b: extinguish spent candle → 'isn't lit'", function()
    local candle = make_candle("spent")
    candle.name = "a spent candle"
    local ctx = create_lit_context({ candle = candle })
    local output = capture_output(function()
        handlers["extinguish"](ctx, "candle")
    end)
    assert_contains(output, "isn't lit",
        "Spent candle should say 'isn't lit'")
end)

test("BUG-106b: object without extinguish transition → 'can't extinguish'", function()
    -- A chair has no extinguish transition at all
    local chair = {
        id = "chair", name = "a wooden chair",
        keywords = {"chair"},
        _state = "normal",
        states = { normal = { name = "a wooden chair" } },
        transitions = {},
    }
    local ctx = create_lit_context({ chair = chair })
    local output = capture_output(function()
        handlers["extinguish"](ctx, "chair")
    end)
    assert_contains(output, "can't extinguish",
        "Non-extinguishable object should say 'can't extinguish'")
end)

test("BUG-106b: 'blow out candle' preprocessing → extinguish candle", function()
    local v, n = preprocess.natural_language("blow out the candle")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
