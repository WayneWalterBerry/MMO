-- test/verbs/test-match-no-relight.lua
-- Issue #119: Matches are single-use — once extinguished, they can't be relit.
-- Tests the full lifecycle: unlit → lit → spent (terminal, no relight).
--
-- Usage: lua test/verbs/test-match-no-relight.lua

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

local function make_match(state)
    return {
        guid = "{009b0347-2ba3-45d1-a733-7a587ad1f5c9}",
        template = "small-item",
        id = "match",
        material = "wood",
        keywords = {"match", "stick", "matchstick"},
        size = 1,
        weight = 0.01,
        portable = true,
        name = "a wooden match",
        on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
        casts_light = false,
        initial_state = "unlit",
        _state = state or "unlit",
        states = {
            unlit = {
                name = "a wooden match",
                description = "A small wooden match. Unlit.",
                on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
                casts_light = false,
            },
            lit = {
                name = "a lit match",
                description = "A burning match. The fire creeps down the stick.",
                on_feel = "HOT! You burn your fingers.",
                provides_tool = "fire_source",
                casts_light = true,
                light_radius = 1,
            },
            spent = {
                name = "a spent match",
                description = "A blackened match stub, cold and inert.",
                on_feel = "A cold, blackened stick. Fragile. Dead.",
                casts_light = false,
                terminal = true,
            },
        },
        transitions = {
            {
                from = "unlit", to = "lit", verb = "strike",
                aliases = {"light", "ignite"},
                requires_property = "has_striker",
                message = "You strike the match. It catches with a hiss of sulphur.",
                fail_message = "You need a rough surface to strike it on.",
            },
            {
                from = "lit", to = "spent", verb = "extinguish",
                aliases = {"blow", "put out"},
                message = "You blow out the match. The blackened head crumbles. It's useless now.",
            },
        },
        mutations = {},
    }
end

local function make_matchbox()
    return {
        id = "matchbox",
        name = "a matchbox",
        keywords = {"matchbox", "box"},
        has_striker = true,
    }
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
-- Issue #119: Match no-relight on extinguish
---------------------------------------------------------------------------
suite("match lifecycle — strike, extinguish, no-relight")

test("fresh match can be struck (unlit → lit)", function()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local ctx = make_ctx({ verb = "strike" })
    ctx.registry:register("match", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    local output = capture_output(function()
        handlers["strike"](ctx, "match on matchbox")
    end)
    eq("lit", match._state, "Match should transition to lit")
    h.assert_truthy(output:find("strike") or output:find("catches") or output:find("sulphur"),
        "Should print strike success message")
end)

test("extinguish lit match → spent", function()
    local match = make_match("lit")
    local ctx = make_ctx({ verb = "extinguish" })
    ctx.registry:register("match", match)
    ctx.player.hands[1] = match
    local output = capture_output(function()
        handlers["extinguish"](ctx, "match")
    end)
    eq("spent", match._state, "Match should transition to spent")
    h.assert_truthy(output:find("blow") or output:find("useless") or output:find("crumble"),
        "Should print extinguish message")
end)

test("light spent match → error 'match is spent'", function()
    local match = make_match("spent")
    local matchbox = make_matchbox()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("match", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    local output = capture_output(function()
        handlers["light"](ctx, "match")
    end)
    eq("spent", match._state, "Match should remain spent")
    h.assert_truthy(output:find("spent") and output:find("relight"),
        "Should say match is spent and can't be relit, got: " .. output)
end)

test("strike spent match → error 'match is spent'", function()
    local match = make_match("spent")
    local matchbox = make_matchbox()
    local ctx = make_ctx({ verb = "strike" })
    ctx.registry:register("match", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    local output = capture_output(function()
        handlers["strike"](ctx, "match on matchbox")
    end)
    eq("spent", match._state, "Match should remain spent")
    h.assert_truthy(output:find("spent") and output:find("relit"),
        "Should say match is spent and cannot be relit, got: " .. output)
end)

test("full lifecycle: strike → extinguish → relight blocked", function()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local ctx = make_ctx({ verb = "strike" })
    ctx.registry:register("match", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox

    -- Step 1: Strike it
    capture_output(function()
        handlers["strike"](ctx, "match on matchbox")
    end)
    eq("lit", match._state, "Step 1: match should be lit")

    -- Step 2: Extinguish it
    capture_output(function()
        handlers["extinguish"](ctx, "match")
    end)
    eq("spent", match._state, "Step 2: match should be spent")

    -- Step 3: Try to relight it
    local output = capture_output(function()
        handlers["light"](ctx, "match")
    end)
    eq("spent", match._state, "Step 3: match should remain spent")
    h.assert_truthy(output:find("spent"),
        "Step 3: should mention match is spent, got: " .. output)
end)

print("\nExit code: " .. h.summary())
