-- test/verbs/test-match-burnout.lua
-- Bug #178: Lit match never burns out.
--
-- Wayne's playtest: Player lit candle with match many turns ago, match still
-- shows as "a lit match" in inventory. Matches should auto-transition from
-- lit → spent after their burn_duration expires via the timed_events system.
--
-- ROOT CAUSE: The `auto_ignite()` path in fire.lua sets `_state = "lit"`
-- directly WITHOUT calling `fsm.start_timer()`. When a player types
-- "light candle" with an UNLIT match, the match gets auto-ignited through
-- this bypass path and the burn timer never starts.
--
-- TDD RED PHASE — these tests document the bug and MUST fail until fixed.
--
-- Usage: lua test/verbs/test-match-burnout.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local fsm_mod = require("engine.fsm")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
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

local function make_match(state)
    return {
        guid = "{009b0347-2ba3-45d1-a733-7a587ad1f5c9}",
        template = "small-item",
        id = "match-1",
        material = "wood",
        keywords = {"match", "stick", "matchstick"},
        size = 1, weight = 0.01,
        categories = {"small", "consumable"},
        portable = true,
        name = "a wooden match",
        on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
        on_smell = "Faintly sulfurous.",
        casts_light = false,
        location = "player",
        burn_duration = 30,
        initial_state = "unlit",
        _state = state or "unlit",
        states = {
            unlit = {
                name = "a wooden match",
                description = "A small wooden match. Unlit.",
                on_feel = "A small wooden stick with a bulbous, slightly rough tip.",
                on_smell = "Faintly sulfurous.",
                casts_light = false,
            },
            lit = {
                name = "a lit match",
                description = "A burning match. The fire creeps down the stick.",
                on_feel = "HOT! You burn your fingers.",
                on_smell = "Burning sulfur and wood.",
                provides_tool = "fire_source",
                casts_light = true,
                light_radius = 1,
                timed_events = {
                    { event = "transition", delay = 30, to_state = "spent" },
                },
            },
            spent = {
                name = "a spent match",
                description = "A blackened match stub, cold and inert.",
                on_feel = "A cold, blackened stick. Fragile. Dead.",
                casts_light = false,
                terminal = true,
                consumable = true,
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
                message = "You blow out the match. The blackened head crumbles.",
            },
            {
                from = "lit", to = "spent", trigger = "auto",
                condition = "timer_expired",
                message = "The match flame reaches your fingers and dies. You drop the blackened stub.",
                mutate = {
                    weight = 0.005,
                    keywords = { add = "blackened" },
                    categories = { add = "useless" },
                },
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
        location = "player",
    }
end

local function make_candle(state)
    return {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        portable = true, size = 1, weight = 0.3,
        wearable = false,
        on_feel = "Waxy cylinder, cool to the touch.",
        casts_light = false,
        location = "player",
        initial_state = state or "unlit",
        _state = state or "unlit",
        states = {
            unlit = {
                name = "a tallow candle",
                description = "A stubby tallow candle. Unlit.",
                casts_light = false,
            },
            lit = {
                name = "a lit tallow candle",
                description = "A tallow candle burning with a steady flame.",
                casts_light = true,
                light_radius = 2,
                provides_tool = "fire_source",
            },
        },
        transitions = {
            {
                from = "unlit", to = "lit", verb = "light",
                aliases = {"ignite"},
                requires_tool = "fire_source",
                message = "You touch the match flame to the wick. The candle catches.",
            },
        },
    }
end

local function make_ctx()
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A room for testing.",
        contents = {},
        exits = {},
    }
    local player = {
        hands = { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 8,
        game_start_time = os.time(),
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

local function hand_id(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end

-- Simulate post-command tick processing (same as game loop lines 592-618)
local SECONDS_PER_TICK = 360
local function simulate_tick(ctx)
    local reg = ctx.registry
    local messages = fsm_mod.tick_timers(reg, SECONDS_PER_TICK)
    local output_lines = {}
    for _, entry in ipairs(messages) do
        output_lines[#output_lines + 1] = entry.message
        if ctx.player then
            local obj = reg:get(entry.obj_id)
            if obj and obj._state then
                local st = obj.states and obj.states[obj._state]
                if st and st.terminal and st.consumable then
                    for i = 1, 2 do
                        local hand = ctx.player.hands[i]
                        local hid = hand and (type(hand) == "table" and hand.id or hand)
                        if hid == entry.obj_id then
                            ctx.player.hands[i] = nil
                        end
                    end
                end
            end
        end
    end
    return output_lines
end

local function clear_timers()
    if fsm_mod.active_timers then
        for k in pairs(fsm_mod.active_timers) do
            fsm_mod.active_timers[k] = nil
        end
    end
end

---------------------------------------------------------------------------
-- Bug #178: Match object has timer properties for burn-out
---------------------------------------------------------------------------

h.suite("Bug #178 — match burn-out: object metadata")

test("match lit state has timed_events with delay", function()
    local match = make_match("lit")
    local lit_state = match.states.lit
    truthy(lit_state.timed_events,
        "Lit state must declare timed_events for auto burn-out")
    truthy(lit_state.timed_events[1],
        "timed_events must have at least one entry")
    eq("transition", lit_state.timed_events[1].event,
        "timed event should be a transition")
    eq("spent", lit_state.timed_events[1].to_state,
        "timed event should transition to spent")
    truthy(lit_state.timed_events[1].delay and lit_state.timed_events[1].delay > 0,
        "timed event must have a positive delay")
end)

test("match has an auto-transition for timer_expired", function()
    local match = make_match("lit")
    local found = false
    for _, t in ipairs(match.transitions) do
        if t.from == "lit" and t.trigger == "auto"
           and t.condition == "timer_expired" then
            found = true
        end
    end
    truthy(found,
        "Match must have a lit→spent auto-transition with timer_expired condition")
end)

---------------------------------------------------------------------------
-- Bug #178 CORE: "light candle" with UNLIT match — auto_ignite bypass
--
-- This is the ACTUAL gameplay scenario. The player has an unlit match and
-- types "light candle". The light handler auto-ignites the match via
-- auto_ignite() which sets _state directly WITHOUT calling start_timer().
-- The match enters "lit" state but no burn timer is registered.
---------------------------------------------------------------------------

h.suite("Bug #178 — auto-ignite bypass: timer never starts")

test("'light candle' with unlit match → match auto-ignited to lit", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    -- Player types "light candle" — the light handler should auto-ignite
    -- the unlit match to use as fire_source, then light the candle.
    capture_output(function() handlers["light"](ctx, "candle") end)

    eq("lit", candle._state, "Candle should be lit")
    eq("lit", match._state,
        "Match should be auto-ignited to lit as fire source")
end)

test("auto-ignited match MUST have FSM timer started (BUG: it does not)", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)

    -- THIS IS THE BUG: auto_ignite() sets _state directly without start_timer()
    truthy(fsm_mod.active_timers and fsm_mod.active_timers["match-1"],
        "Auto-ignited match MUST have a burn timer — auto_ignite() bypasses FSM")
end)

test("auto-ignited match burns out after tick (BUG: timer never started)", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)

    -- Simulate game loop post-command tick
    local tick_output = simulate_tick(ctx)

    eq("spent", match._state,
        "Auto-ignited match should burn out after one tick (360 > 30s delay)")
end)

test("auto-ignited match burn-out frees hand slot", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)
    simulate_tick(ctx)

    eq(nil, ctx.player.hands[1],
        "Hand should be freed after auto-ignited match burns out")
end)

test("burn-out message displayed for auto-ignited match", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)
    local tick_output = simulate_tick(ctx)

    truthy(#tick_output > 0,
        "Burn-out must produce a message for the player")
    local found_msg = false
    for _, msg in ipairs(tick_output) do
        if msg:find("match") then found_msg = true end
    end
    truthy(found_msg,
        "Burn-out message should mention the match")
end)

test("candle stays lit after auto-ignited match burns out", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)
    simulate_tick(ctx)

    eq("lit", candle._state,
        "Candle must remain lit after match burns out")
end)

---------------------------------------------------------------------------
-- Bug #178: Explicit strike path (control group — should work)
---------------------------------------------------------------------------

h.suite("Bug #178 — explicit strike path (control tests)")

test("explicit strike → timer starts → burn-out works", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    clear_timers()

    capture_output(function() handlers["strike"](ctx, "match on matchbox") end)
    eq("lit", match._state, "Match should be lit after striking")
    truthy(fsm_mod.active_timers and fsm_mod.active_timers["match-1"],
        "Timer must exist after explicit strike")

    simulate_tick(ctx)
    eq("spent", match._state, "Match should burn out after tick")
end)

test("spent match cannot be relit (ignite fails)", function()
    local ctx = make_ctx()
    local match = make_match("spent")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox

    local output = capture_output(function()
        handlers["light"](ctx, "match")
    end)

    eq("spent", match._state,
        "Spent match must remain spent")
    truthy(output:find("spent") or output:find("relight") or output:find("relit")
           or output:find("dead") or output:find("useless"),
        "Should indicate the match cannot be relit, got: " .. output)
end)

local failed = h.summary()
if failed > 0 then os.exit(1) end
