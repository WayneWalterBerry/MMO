-- test/verbs/test-tutorial-hints.lua
-- Issue #113: Tutorial coverage gaps for EXTINGUISH, EAT, BURN verbs.
-- Tests: contextual one-shot hints, enhanced no-noun messages, hint dedup.
--
-- Usage: lua test/verbs/test-tutorial-hints.lua
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
        worn = opts.worn or {},
        injuries = {},
        bags = {},
        state = opts.state or {},
        max_health = 100,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

local function make_candle()
    return {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit   = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The candle wick catches and burns steadily." },
            { from = "lit", to = "extinguished", verb = "extinguish",
              message = "You blow out the candle. A wisp of smoke curls upward." },
        },
    }
end

local function make_match()
    return {
        id = "match",
        name = "a wooden match",
        keywords = {"match"},
        provides_tool = {"fire_source"},
        charges = 1,
    }
end

---------------------------------------------------------------------------
-- 1. EXTINGUISH hint — appears after lighting a candle
---------------------------------------------------------------------------
suite("extinguish hint — triggered by successful light")

test("lighting a candle shows extinguish hint", function()
    local candle = make_candle()
    local match_obj = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("put out") and output:find("Hint"),
        "Should show put-out hint after lighting candle")
end)

test("extinguish hint only shows once (one-shot)", function()
    local candle = make_candle()
    local match_obj = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    -- First light: triggers hint
    capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    -- Reset candle to unlit for second light
    candle._state = "unlit"
    match_obj.charges = 1
    -- Second light: hint should NOT appear again
    local output2 = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    local hint_count = 0
    for _ in output2:gmatch("%(Hint:.-extinguish.-%)") do hint_count = hint_count + 1 end
    eq(0, hint_count, "Extinguish hint should not repeat on second light")
end)

---------------------------------------------------------------------------
-- 2. BURN hint — appears after lighting a candle
---------------------------------------------------------------------------
suite("burn hint — triggered by successful light")

test("lighting a candle shows burn hint", function()
    local candle = make_candle()
    local match_obj = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(output:find("burn") and output:find("Hint"),
        "Should show burn hint after lighting candle")
end)

test("burn hint only shows once (one-shot)", function()
    local candle = make_candle()
    local match_obj = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    -- First light
    capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    candle._state = "unlit"
    match_obj.charges = 1
    -- Second light
    local output2 = capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    local hint_count = 0
    for _ in output2:gmatch("%(Hint:.-burn.-%)") do hint_count = hint_count + 1 end
    eq(0, hint_count, "Burn hint should not repeat on second light")
end)

---------------------------------------------------------------------------
-- 3. EAT hint — appears after eating something edible
---------------------------------------------------------------------------
suite("eat hint — triggered by eating edible item")

test("eating an edible object shows eat hint", function()
    local bread = {
        id = "bread",
        name = "a loaf of bread",
        keywords = {"bread", "loaf"},
        edible = true,
        portable = true,
    }
    local ctx = make_ctx({ verb = "eat" })
    ctx.registry:register("bread", bread)
    ctx.player.hands[1] = bread
    local output = capture_output(function()
        handlers["eat"](ctx, "bread")
    end)
    h.assert_truthy(output:find("Hint"),
        "Should show eat hint after eating edible object")
end)

test("eat hint only shows once (one-shot)", function()
    local bread = {
        id = "bread",
        name = "a loaf of bread",
        keywords = {"bread", "loaf"},
        edible = true,
        portable = true,
    }
    local apple = {
        id = "apple",
        name = "an apple",
        keywords = {"apple"},
        edible = true,
        portable = true,
    }
    local ctx = make_ctx({ verb = "eat" })
    ctx.registry:register("bread", bread)
    ctx.registry:register("apple", apple)
    ctx.player.hands[1] = bread
    ctx.player.hands[2] = apple
    -- First eat
    capture_output(function()
        handlers["eat"](ctx, "bread")
    end)
    -- Second eat: hint should not repeat
    local output2 = capture_output(function()
        handlers["eat"](ctx, "apple")
    end)
    local hint_count = 0
    for _ in output2:gmatch("%(Hint:.-%)") do hint_count = hint_count + 1 end
    eq(0, hint_count, "Eat hint should not repeat on second eat")
end)

---------------------------------------------------------------------------
-- 4. EAT hint via TASTE — tasting edible object teaches eat
---------------------------------------------------------------------------
suite("eat hint via taste — tasting edible item teaches eat verb")

test("tasting an edible object shows eat hint", function()
    local fruit = {
        id = "fruit",
        name = "a ripe fruit",
        keywords = {"fruit"},
        edible = true,
        on_taste = "Sweet and juicy.",
        portable = true,
    }
    local ctx = make_ctx({ verb = "taste" })
    ctx.registry:register("fruit", fruit)
    ctx.current_room.contents = { "fruit" }
    local output = capture_output(function()
        handlers["taste"](ctx, "fruit")
    end)
    h.assert_truthy(output:find("eat") and output:find("Hint"),
        "Tasting an edible object should hint about eat verb")
end)

test("tasting a non-edible object does NOT show eat hint", function()
    local rock = {
        id = "rock",
        name = "a smooth rock",
        keywords = {"rock"},
        on_taste = "Gritty and unpleasant.",
        portable = true,
    }
    local ctx = make_ctx({ verb = "taste" })
    ctx.registry:register("rock", rock)
    ctx.current_room.contents = { "rock" }
    local output = capture_output(function()
        handlers["taste"](ctx, "rock")
    end)
    local has_eat_hint = output:find("Hint") and output:find("eat")
    h.assert_truthy(not has_eat_hint,
        "Tasting a non-edible should NOT show eat hint")
end)

---------------------------------------------------------------------------
-- 5. Enhanced no-noun messages — all three verbs
---------------------------------------------------------------------------
suite("enhanced no-noun messages for tutorial verbs")

test("extinguish with no noun shows enhanced message", function()
    local output = capture_output(function()
        handlers["extinguish"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Extinguish what"),
        "Should still say 'Extinguish what?'")
    h.assert_truthy(output:find("extinguish %[item%]") or output:find("put out"),
        "Should include tutorial guidance")
end)

test("eat with no noun shows enhanced message", function()
    local output = capture_output(function()
        handlers["eat"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Eat what"),
        "Should still say 'Eat what?'")
    h.assert_truthy(output:find("eat %[item%]") or output:find("edible"),
        "Should include tutorial guidance about edible items")
end)

test("burn with no noun shows enhanced message", function()
    local output = capture_output(function()
        handlers["burn"](make_ctx(), "")
    end)
    h.assert_truthy(output:find("Burn what"),
        "Should still say 'Burn what?'")
    h.assert_truthy(output:find("burn %[item%]") or output:find("flammable"),
        "Should include tutorial guidance about flammable items")
end)

---------------------------------------------------------------------------
-- 6. Hint dedup across verbs
---------------------------------------------------------------------------
suite("hint deduplication — hints_shown state tracking")

test("hints_shown table is created on player.state", function()
    local candle = make_candle()
    local match_obj = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj
    capture_output(function()
        handlers["light"](ctx, "candle")
    end)
    h.assert_truthy(ctx.player.state.hints_shown,
        "hints_shown table should exist after hint is shown")
    h.assert_truthy(ctx.player.state.hints_shown["extinguish"],
        "extinguish hint should be tracked as shown")
    h.assert_truthy(ctx.player.state.hints_shown["burn"],
        "burn hint should be tracked as shown")
end)

h.summary()
