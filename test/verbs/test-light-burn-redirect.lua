-- test/verbs/test-light-burn-redirect.lua
-- Bug #172: Light sack should burn it
-- TDD-FIRST: Tests for the light→burn redirect behavior.
--
-- The light handler must distinguish between:
--   1. Light-source objects (candle) → light them (FSM transition)
--   2. Flammable non-light-sources (sack) → redirect to burn
--   3. Non-flammable objects (stone) → refuse
--
-- Core redirect is FIXED (#172 code at fire.lua:209-214).
-- Remaining issue: when redirect fires with NO flame available,
-- the error message says "burn" instead of "light" because the burn
-- handler's error message leaks through. "light sack" should say
-- something about needing fire to light, not "burn anything with."
--
-- Usage: lua test/verbs/test-light-burn-redirect.lua
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
        max_health = 100,
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
-- #172 regression: "light sack" with flame burns it (FIXED)
---------------------------------------------------------------------------
suite("#172 — light flammable object: redirect to burn (regression)")

test("light sack (fabric, flammable) with flame burns it", function()
    local sack = {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "bag", "burlap sack"},
        material = "fabric",
        size = 1,
        weight = 0.3,
        portable = true,
        on_feel = "Rough burlap.",
        container = true,
    }

    local ctx = make_ctx({ verb = "light", state = { has_flame = 3 } })
    ctx.registry:register("sack", sack)
    ctx.player.hands[1] = sack

    local output = capture_output(function()
        handlers["light"](ctx, "sack")
    end)

    h.assert_truthy(
        output:find("catches fire") or output:find("burns") or output:find("flame") or output:find("ash"),
        "Flammable sack should burn when 'light' is used with flame; got: " .. output)
end)

test("light paper (flammable) with flame burns it", function()
    local paper = {
        id = "paper",
        name = "a sheet of paper",
        keywords = {"paper", "sheet"},
        material = "paper",
        size = 1,
        weight = 0.05,
        portable = true,
        on_feel = "Thin and smooth.",
    }

    local ctx = make_ctx({ verb = "light", state = { has_flame = 3 } })
    ctx.registry:register("paper", paper)
    ctx.player.hands[1] = paper

    local output = capture_output(function()
        handlers["light"](ctx, "paper")
    end)

    h.assert_truthy(
        output:find("catches fire") or output:find("burns") or output:find("flame") or output:find("ash"),
        "Flammable paper should burn when 'light' is used; got: " .. output)
end)

---------------------------------------------------------------------------
-- #172 remaining: "light sack" with no flame — error should not say "burn"
---------------------------------------------------------------------------
suite("#172 — light flammable, no flame: error message")

test("light sack with no flame says 'light' not 'burn' in error", function()
    -- Player says "light sack" but has no flame. The redirect sends to
    -- the burn handler, which says "You have no flame to burn anything with."
    -- BUG: the error message mentions "burn" but the player said "light".
    -- Should say something about needing fire to light it, not "burn".
    local sack = {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "bag"},
        material = "fabric",
        size = 1,
        weight = 0.3,
        portable = true,
        on_feel = "Rough burlap.",
        container = true,
    }

    local ctx = make_ctx({ verb = "light", state = {} })  -- no has_flame
    ctx.registry:register("sack", sack)
    ctx.player.hands[1] = sack

    local output = capture_output(function()
        handlers["light"](ctx, "sack")
    end)

    -- Error should reference "light", not "burn"
    h.assert_truthy(
        not output:find("burn"),
        "Error from 'light' command should not mention 'burn'; got: " .. output)
end)

---------------------------------------------------------------------------
-- #172 regression: non-flammable objects refuse
---------------------------------------------------------------------------
suite("#172 — light non-flammable object: refuse (regression)")

test("light stone (non-flammable) refuses", function()
    local stone = {
        id = "stone",
        name = "a smooth stone",
        keywords = {"stone", "rock"},
        material = "stone",
        size = 1,
        weight = 2,
        portable = true,
        on_feel = "Cool and smooth.",
    }

    local ctx = make_ctx({ verb = "light", state = { has_flame = 3 } })
    ctx.registry:register("stone", stone)
    ctx.player.hands[1] = stone

    local output = capture_output(function()
        handlers["light"](ctx, "stone")
    end)

    h.assert_truthy(
        output:find("can't") or output:find("won't") or output:find("not flammable"),
        "Non-flammable stone should refuse to light/burn; got: " .. output)
end)

---------------------------------------------------------------------------
-- #172 regression: light-source gets lit, not burned
---------------------------------------------------------------------------
suite("#172 — light candle: light-source gets lit, not burned (regression)")

test("light candle lights it (does not burn it)", function()
    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        material = "wax",
        size = 1,
        weight = 1,
        portable = true,
        on_feel = "Smooth wax cylinder.",
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The wick catches the flame." },
        },
    }

    local ctx = make_ctx({ verb = "light", state = { has_flame = 3 } })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle

    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)

    eq("lit", candle._state, "Candle should be lit, not burned")
    h.assert_truthy(ctx.registry:get("candle") ~= nil,
        "Candle should not be destroyed (it's a light source, not just flammable)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
os.exit(h.summary() > 0 and 1 or 0)
