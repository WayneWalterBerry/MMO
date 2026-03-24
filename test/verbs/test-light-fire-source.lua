-- test/verbs/test-light-fire-source.lua
-- Bug #169: Light candle fails when holding match
-- TDD-FIRST: These tests MUST FAIL on current code to prove the bug exists.
--
-- The real match object only has provides_tool = "fire_source" in its lit state,
-- not at root level. find_tool_in_inventory checks root-level provides_tool,
-- so an unlit match in the player's hand is NOT detected as a fire_source.
-- The light handler should auto-detect an unlit match as a potential fire source.
--
-- Usage: lua test/verbs/test-light-fire-source.lua
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

-- Realistic candle: FSM-managed light source (matches src/meta/objects/candle.lua)
local function make_candle()
    return {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle", "tallow"},
        material = "wax",
        size = 1,
        weight = 1,
        portable = true,
        on_feel = "A smooth wax cylinder.",
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { name = "an unlit candle", casts_light = false },
            lit = { name = "a lit candle", casts_light = true,
                    provides_tool = "fire_source" },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              requires_tool = "fire_source",
              message = "The wick catches the flame and curls to life.",
              fail_message = "You have nothing to light it with." },
        },
    }
end

-- Realistic unlit match: NO provides_tool at root (matches src/meta/objects/match.lua)
-- The real match only has provides_tool in states.lit, not at root level.
local function make_unlit_match()
    return {
        id = "match",
        name = "a wooden match",
        keywords = {"match", "matchstick", "wooden match"},
        material = "wood",
        size = 1,
        weight = 0.01,
        portable = true,
        on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
        _state = "unlit",
        initial_state = "unlit",
        states = {
            unlit = { name = "a wooden match", casts_light = false },
            lit = { name = "a lit match", casts_light = true,
                    provides_tool = "fire_source" },
            spent = { name = "a spent match", casts_light = false, terminal = true },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "strike",
              aliases = {"light", "ignite"},
              requires_property = "has_striker",
              message = "The match sputters and catches." },
            { from = "lit", to = "spent", verb = "extinguish" },
        },
    }
end

---------------------------------------------------------------------------
-- Bug #169: Implicit fire_source — match in other hand auto-detected
---------------------------------------------------------------------------
suite("#169 — light candle: implicit fire_source from held match")

test("light candle with unlit match in other hand succeeds", function()
    -- Player holds candle + unlit match. "light candle" should auto-detect
    -- the match as a fire_source and strike+use it. Currently FAILS because
    -- find_tool_in_inventory only checks root-level provides_tool.
    local candle = make_candle()
    local match_obj = make_unlit_match()

    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj

    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)

    -- Should succeed — match should be auto-detected and used as fire_source
    eq("lit", candle._state,
        "Candle should be lit when holding an unlit match; got output: " .. output)
end)

test("light candle with match — match is consumed or transitioned", function()
    local candle = make_candle()
    local match_obj = make_unlit_match()

    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj

    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)

    -- After lighting candle, the match should be spent or lit (not still unlit)
    h.assert_truthy(match_obj._state ~= "unlit",
        "Match should not remain unlit after being used as fire_source; state: " .. tostring(match_obj._state))
end)

---------------------------------------------------------------------------
-- Bug #169: Explicit "with match" — named tool
---------------------------------------------------------------------------
suite("#169 — light candle with match: explicit tool naming")

test("light candle with match — explicit tool succeeds", function()
    -- "light candle with match" names the tool directly. The game loop strips
    -- "with X" for light/burn verbs, so the handler gets noun="candle".
    -- But the handler still needs to find the match as a fire_source.
    local candle = make_candle()
    local match_obj = make_unlit_match()

    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.registry:register("match", match_obj)
    ctx.player.hands[1] = candle
    ctx.player.hands[2] = match_obj

    -- The game loop strips "with match", so handler receives just "candle"
    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)

    eq("lit", candle._state,
        "Candle should be lit with explicit 'with match'; got output: " .. output)
end)

---------------------------------------------------------------------------
-- Bug #169: No fire source — should fail with helpful message
---------------------------------------------------------------------------
suite("#169 — light candle: no fire source available")

test("light candle with empty hands gives helpful failure message", function()
    local candle = make_candle()

    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle

    local output = capture_output(function()
        handlers["light"](ctx, "candle")
    end)

    eq("unlit", candle._state, "Candle should remain unlit without fire source")
    h.assert_truthy(
        output:find("nothing to light") or output:find("need") or output:find("fire") or output:find("match"),
        "Should give helpful message about needing fire source; got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
os.exit(h.summary() > 0 and 1 or 0)
