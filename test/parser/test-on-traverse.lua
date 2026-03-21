-- test/parser/test-on-traverse.lua
-- Tests for the on_traverse exit-effect engine (traverse_effects.lua).
--
-- Verifies:
--   1. Normal exits (no on_traverse) still work unchanged
--   2. on_traverse fires wind_effect correctly
--   3. Wind effect only extinguishes items that are "lit"
--   4. Items not in the extinguishes list are unaffected
--   5. Wind-resistant items are spared
--   6. Custom effect types can be registered

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy
local is_nil = h.assert_nil

local traverse_effects = require("engine.traverse_effects")

---------------------------------------------------------------------------
-- Minimal mock registry
---------------------------------------------------------------------------
local function make_registry(objects)
    local store = {}
    for _, obj in ipairs(objects) do
        store[obj.id] = obj
    end
    return {
        get = function(self, id) return store[id] end,
        set = function(self, id, obj) store[id] = obj end,
        all = function(self)
            local out = {}
            for _, obj in pairs(store) do out[#out + 1] = obj end
            return out
        end,
    }
end

---------------------------------------------------------------------------
-- Capture print output
---------------------------------------------------------------------------
local captured = {}
local real_print = print
local function capture_print(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    captured[#captured + 1] = table.concat(parts, "\t")
end
local function start_capture() captured = {}; print = capture_print end
local function stop_capture() print = real_print; return captured end

---------------------------------------------------------------------------
-- Helper: build a minimal context with carried objects
---------------------------------------------------------------------------
local function make_ctx(objects, hand_ids)
    local registry = make_registry(objects)
    local hands = {}
    for i, id in ipairs(hand_ids or {}) do
        hands[i] = id
    end
    return {
        registry = registry,
        player = { hands = hands, worn = {} },
    }
end

---------------------------------------------------------------------------
-- Helper: make a candle object with lit/extinguished FSM
---------------------------------------------------------------------------
local function make_candle(state)
    return {
        id = "candle",
        name = "tallow candle",
        keywords = {"candle", "tallow candle"},
        _state = state or "lit",
        states = {
            unlit = { description = "An unlit candle." },
            lit = {
                description = "A lit candle.",
                casts_light = true,
            },
            extinguished = {
                description = "An extinguished candle.",
                casts_light = false,
            },
        },
        transitions = {
            {
                from = "lit", to = "extinguished", verb = "extinguish",
                aliases = {"blow", "snuff"},
                message = "You blow out the candle.",
            },
            {
                from = "extinguished", to = "lit", verb = "light",
                aliases = {"relight"},
                message = "The wick catches again.",
            },
        },
    }
end

---------------------------------------------------------------------------
-- Helper: make a wind-resistant lantern
---------------------------------------------------------------------------
local function make_lantern(state)
    return {
        id = "oil-lantern",
        name = "oil lantern",
        keywords = {"lantern", "oil lantern"},
        wind_resistant = true,
        _state = state or "lit",
        states = {
            lit = {
                description = "A lit lantern.",
                casts_light = true,
            },
            extinguished = {
                description = "An extinguished lantern.",
                casts_light = false,
            },
        },
        transitions = {
            {
                from = "lit", to = "extinguished", verb = "extinguish",
                message = "You extinguish the lantern.",
            },
        },
    }
end

---------------------------------------------------------------------------
h.suite("on_traverse — no effect (normal exits)")
---------------------------------------------------------------------------

test("string exit (no on_traverse) does nothing", function()
    local ctx = make_ctx({}, {})
    start_capture()
    traverse_effects.process("hallway", ctx)
    local output = stop_capture()
    eq(0, #output, "should produce no output for string exit")
end)

test("table exit without on_traverse does nothing", function()
    local exit = { target = "hallway", open = true }
    local ctx = make_ctx({}, {})
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq(0, #output, "should produce no output when no on_traverse")
end)

test("on_traverse with unknown type does nothing", function()
    local exit = {
        target = "hallway",
        on_traverse = { type = "unknown_future_type" },
    }
    local ctx = make_ctx({}, {})
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq(0, #output, "should produce no output for unknown type")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — wind_effect extinguishes lit candle")
---------------------------------------------------------------------------

test("wind_effect extinguishes a lit candle in hand", function()
    local candle = make_candle("lit")
    local ctx = make_ctx({candle}, {"candle"})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A cold draft rushes up the stairway...",
            extinguishes = { "candle" },
            message_extinguish = "The draft snuffs out your candle!",
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq("extinguished", candle._state, "candle should be extinguished")
    truthy(#output > 0, "should print effect messages")
    -- Check that description was printed
    local found_desc = false
    for _, line in ipairs(output) do
        if line:find("cold draft") then found_desc = true end
    end
    truthy(found_desc, "should print effect description")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — wind_effect ignores unlit candle")
---------------------------------------------------------------------------

test("wind_effect does NOT extinguish unlit candle", function()
    local candle = make_candle("unlit")
    local ctx = make_ctx({candle}, {"candle"})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A draft...",
            extinguishes = { "candle" },
            message_extinguish = "Snuffed!",
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq("unlit", candle._state, "unlit candle should remain unlit")
    eq(0, #output, "no messages when nothing to extinguish")
end)

test("wind_effect does NOT extinguish already-extinguished candle", function()
    local candle = make_candle("extinguished")
    local ctx = make_ctx({candle}, {"candle"})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            extinguishes = { "candle" },
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq("extinguished", candle._state, "already extinguished stays extinguished")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — wind_effect spares wind-resistant items")
---------------------------------------------------------------------------

test("wind_effect spares wind-resistant lantern", function()
    local lantern = make_lantern("lit")
    local ctx = make_ctx({lantern}, {"oil-lantern"})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A draft blows through...",
            extinguishes = { "lantern" },
            message_spared = "Your lantern holds steady.",
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq("lit", lantern._state, "wind-resistant lantern should stay lit")
    local found_spared = false
    for _, line in ipairs(output) do
        if line:find("holds steady") then found_spared = true end
    end
    truthy(found_spared, "should print spared message")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — items not in extinguishes list unaffected")
---------------------------------------------------------------------------

test("lit item NOT in extinguishes list is unaffected", function()
    local lantern = make_lantern("lit")
    lantern.wind_resistant = nil  -- remove wind resistance for this test
    local ctx = make_ctx({lantern}, {"oil-lantern"})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A draft...",
            extinguishes = { "candle" },  -- only candle, not lantern
            message_extinguish = "Snuffed!",
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq("lit", lantern._state, "lantern not in extinguishes list stays lit")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — mixed scenario (candle + lantern)")
---------------------------------------------------------------------------

test("wind extinguishes candle but spares wind-resistant lantern", function()
    local candle = make_candle("lit")
    local lantern = make_lantern("lit")
    local ctx = make_ctx({candle, lantern}, {"candle", "oil-lantern"})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A gust of warm air rushes down.",
            extinguishes = { "candle", "lantern" },
            message_extinguish = "Your candle goes out!",
            message_spared = "Your lantern holds steady.",
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq("extinguished", candle._state, "candle should be extinguished")
    eq("lit", lantern._state, "lantern should stay lit (wind_resistant)")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — extensibility (custom effect type)")
---------------------------------------------------------------------------

test("custom effect type can be registered and fires", function()
    local fired = false
    traverse_effects.register("water_effect", function(effect, ctx)
        fired = true
        print(effect.description or "Splash!")
    end)
    local exit = {
        target = "river-crossing",
        on_traverse = {
            type = "water_effect",
            description = "Water splashes everywhere!",
        },
    }
    local ctx = make_ctx({}, {})
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    truthy(fired, "custom handler should fire")
    eq(1, #output)
    truthy(output[1]:find("Water splashes"), "should print custom message")
end)

---------------------------------------------------------------------------
h.suite("on_traverse — on_traverse with missing fields is safe")
---------------------------------------------------------------------------

test("wind_effect with empty extinguishes list is safe", function()
    local ctx = make_ctx({}, {})
    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A draft...",
            extinguishes = {},
        },
    }
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq(0, #output, "no output when nothing to affect")
end)

test("on_traverse with no type field is safe", function()
    local exit = {
        target = "hallway",
        on_traverse = { description = "Something happens" },
    }
    local ctx = make_ctx({}, {})
    start_capture()
    traverse_effects.process(exit, ctx)
    local output = stop_capture()
    eq(0, #output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
