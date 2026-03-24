-- test/verbs/test-fire-verbs.lua
-- Pre-refactoring coverage for light, extinguish verb handlers.
-- Tests: light FSM transitions, light with tool requirement, light already-lit,
--        extinguish FSM, extinguish not-lit, light empty noun, fire aliases.
--
-- Usage: lua test/verbs/test-fire-verbs.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local fsm_mod = require("engine.fsm")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
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
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = opts.state or {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "light",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. LIGHT — FSM transitions
---------------------------------------------------------------------------
suite("light — basic FSM transitions")

test("light with empty noun prints 'Light what?'", function()
    local output = capture_output(function()
        handlers["light"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Light what"),
        "Empty noun should prompt 'Light what?'")
end)

test("light nonexistent object prints 'don't have anything'", function()
    local output = capture_output(function()
        handlers["light"](make_ctx(), "xyzzy")
    end)
    h.assert_truthy(output:find("don't have") or output:find("don't notice"),
        "Nonexistent should say don't have it")
end)

test("light FSM object with fire_source tool succeeds", function()
    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The candle wick catches and burns steadily." },
        },
    }
    local match_obj = {
        id = "match",
        name = "a wooden match",
        keywords = {"match"},
        provides_tool = {"fire_source"},
        charges = 1,
    }
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("candle") or output:find("wick") or output:find("burn") or output:find("light"),
        "Should print candle lighting message")
    eq("lit", candle._state, "Candle should be lit after lighting")
end)

test("light FSM object with player flame (has_flame) succeeds", function()
    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle"},
        _state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The candle catches fire." },
        },
    }
    local ctx = make_ctx({ verb = "light", state = { has_flame = 1 } })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("candle") or output:find("flame") or output:find("light"),
        "Should light candle with player flame")
    eq("lit", candle._state, "Candle should be lit")
    eq(0, ctx.player.state.has_flame, "Flame should be consumed")
end)

test("light already-lit object reports current state", function()
    local candle = {
        id = "candle",
        name = "a lit candle",
        keywords = {"candle"},
        _state = "lit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true,
                    description = "A candle burns with a warm flame." },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source" },
        },
    }
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("already") or output:find("burn") or output:find("flame") or output:find("warm"),
        "Already-lit object should report current lit state")
end)

test("light without required tool prints fail message", function()
    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle"},
        _state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              fail_message = "You have nothing to light it with." },
        },
    }
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("nothing to light") or output:find("have no"),
        "Missing fire_source should print fail message")
end)

test("light non-lightable object prints can't-light", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    }
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["light"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't light"),
        "Non-lightable should say can't light")
end)

test("light FSM object without tool requirement succeeds", function()
    local torch = {
        id = "torch",
        name = "a torch",
        keywords = {"torch"},
        _state = "unlit",
        states = {
            unlit = { name = "an unlit torch", casts_light = false },
            lit = { name = "a lit torch", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              message = "The torch flares to life." },
        },
    }
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("torch", torch)
    ctx.player.hands[1] = torch
    local output = capture_output(function()
        handlers["light"](ctx, "torch")
    end)
    h.assert_truthy(output:find("flare") or output:find("torch") or output:find("light"),
        "Should light torch without tool")
    eq("lit", torch._state, "Torch should be lit")
end)

---------------------------------------------------------------------------
-- 2. EXTINGUISH — put out flames
---------------------------------------------------------------------------
suite("extinguish — flame management")

test("extinguish with empty noun prints 'Extinguish what?'", function()
    local output = capture_output(function()
        handlers["extinguish"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Extinguish what"),
        "Empty noun should prompt")
end)

test("extinguish lit candle transitions to unlit", function()
    local candle = {
        id = "candle",
        name = "a lit candle",
        keywords = {"candle"},
        _state = "lit",
        states = {
            unlit = { name = "unlit candle", casts_light = false },
            lit = { name = "lit candle", casts_light = true },
        },
        transitions = {
            { from = "lit", to = "unlit", verb = "extinguish",
              message = "The candle flame gutters and dies." },
        },
    }
    local ctx = make_ctx({ verb = "extinguish" })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    local output = capture_output(function()
        handlers["extinguish"](ctx, "candle")
    end)
    h.assert_truthy(output:find("gutter") or output:find("dies") or output:find("extinguish"),
        "Should print extinguish message")
    eq("unlit", candle._state, "Candle should be unlit")
end)

test("extinguish already-unlit candle says 'isn't lit'", function()
    local candle = {
        id = "candle",
        name = "a candle",
        keywords = {"candle"},
        _state = "unlit",
        states = {
            unlit = { name = "unlit candle", casts_light = false },
            lit = { name = "lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light" },
            { from = "lit", to = "unlit", verb = "extinguish" },
        },
    }
    local ctx = make_ctx({ verb = "extinguish" })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    local output = capture_output(function()
        handlers["extinguish"](ctx, "candle")
    end)
    h.assert_truthy(output:find("isn't lit") or output:find("not lit") or output:find("can't extinguish"),
        "Already-unlit should say isn't lit")
end)

test("extinguish non-extinguishable object prints can't-extinguish", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock"},
    }
    local ctx = make_ctx({ verb = "extinguish" })
    ctx.registry:register("rock", rock)
    ctx.player.hands[1] = rock
    local output = capture_output(function()
        handlers["extinguish"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't extinguish"),
        "Non-extinguishable should say can't extinguish")
end)

test("snuff alias works for extinguish", function()
    h.assert_truthy(handlers["snuff"] == handlers["extinguish"],
        "snuff should be alias for extinguish")
end)

---------------------------------------------------------------------------
-- 3. ALIASES
---------------------------------------------------------------------------
suite("fire verb aliases")

test("ignite is alias for light", function()
    h.assert_truthy(handlers["ignite"] == handlers["light"],
        "ignite should be alias for light")
end)

test("relight is alias for light", function()
    h.assert_truthy(handlers["relight"] == handlers["light"],
        "relight should be alias for light")
end)

print("\nExit code: " .. h.summary())
