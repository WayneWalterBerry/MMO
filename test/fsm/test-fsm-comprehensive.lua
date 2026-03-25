-- test/fsm/test-fsm-comprehensive.lua
-- Comprehensive FSM state machine tests: transitions, timers, fire, consumables.
-- Covers: candle, match, door, trap door, wine bottle FSM lifecycles.
-- Also: invalid transitions, tool requirements, wind traverse effects.
--
-- Author: Nelson (QA)
-- Usage: lua test/fsm/test-fsm-comprehensive.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local registry_mod = require("engine.registry")
local fsm_mod = require("engine.fsm")
local verbs_mod = require("engine.verbs")
local traverse_effects = require("engine.traverse_effects")

local test   = h.test
local suite  = h.suite
local eq     = h.assert_eq
local truthy = h.assert_truthy
local is_nil = h.assert_nil

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Output capture helper
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
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

---------------------------------------------------------------------------
-- Timer helpers
---------------------------------------------------------------------------
local SECONDS_PER_TICK = 360

local function clear_timers()
    for k in pairs(fsm_mod.active_timers) do
        fsm_mod.active_timers[k] = nil
    end
    for k in pairs(fsm_mod.paused_timers) do
        fsm_mod.paused_timers[k] = nil
    end
end

local function simulate_tick(ctx, delta)
    delta = delta or SECONDS_PER_TICK
    local messages = fsm_mod.tick_timers(ctx.registry, delta)
    for _, entry in ipairs(messages) do
        local obj = ctx.registry:get(entry.obj_id)
        if obj and obj._state and ctx.player then
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
    return messages
end

---------------------------------------------------------------------------
-- Factory functions for test objects
---------------------------------------------------------------------------
local function make_candle(state)
    return {
        guid = "{992df7f3-1b8e-4164-939a-3415f8f6ffe3}",
        template = "small-item",
        id = "candle",
        material = "wax",
        keywords = {"candle", "tallow", "tallow candle"},
        size = 1, weight = 1,
        categories = {"light source", "small"},
        portable = true,
        name = "a tallow candle",
        description = "A stubby tallow candle. It is not lit.",
        on_feel = "A smooth wax cylinder, slightly greasy.",
        casts_light = false,
        location = "player",
        burn_duration = 7200,
        remaining_burn = 7200,
        initial_state = "unlit",
        _state = state or "unlit",
        states = {
            unlit = {
                name = "a tallow candle",
                description = "A stubby tallow candle. It is not lit.",
                on_feel = "A smooth wax cylinder.",
                casts_light = false,
            },
            lit = {
                name = "a lit tallow candle",
                description = "A tallow candle burns with a steady flame.",
                provides_tool = "fire_source",
                casts_light = true,
                light_radius = 2,
                timed_events = {
                    { event = "transition", delay = 7200, to_state = "spent" },
                },
            },
            extinguished = {
                name = "a half-burned candle",
                description = "A tallow candle, recently extinguished.",
                casts_light = false,
            },
            spent = {
                name = "a spent candle",
                description = "Nothing but a black nub of carbon.",
                casts_light = false,
                terminal = true,
                consumable = true,
            },
        },
        transitions = {
            {
                from = "unlit", to = "lit", verb = "light",
                aliases = {"ignite"},
                requires_tool = "fire_source",
                message = "The wick catches the flame.",
                fail_message = "You have nothing to light it with.",
            },
            {
                from = "lit", to = "extinguished", verb = "extinguish",
                aliases = {"blow", "put out", "snuff"},
                message = "You blow out the candle. Darkness closes in.",
                mutate = {
                    weight = function(w) return math.max(w * 0.7, 0.1) end,
                    keywords = { add = "half-burned" },
                },
            },
            {
                from = "extinguished", to = "lit", verb = "light",
                aliases = {"relight", "ignite"},
                requires_tool = "fire_source",
                message = "The wick catches again.",
                fail_message = "You have nothing to relight it with.",
            },
            {
                from = "lit", to = "spent", trigger = "auto",
                condition = "timer_expired",
                message = "The candle flame gutters, sputters, and dies.",
                mutate = {
                    weight = 0.05,
                    size = 0,
                    keywords = { add = "nub" },
                    categories = { remove = "light source" },
                },
            },
        },
        mutations = {},
    }
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
                on_feel = "A small wooden stick with a rough tip.",
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
                on_feel = "A cold, blackened stick.",
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
                mutate = {
                    weight = 0.005,
                    keywords = { add = "blackened" },
                    categories = { add = "useless" },
                },
            },
            {
                from = "lit", to = "spent", trigger = "auto",
                condition = "timer_expired",
                message = "The match flame reaches your fingers and dies.",
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
        name = "a small matchbox",
        keywords = {"matchbox", "box of matches"},
        has_striker = true,
        container = true,
        contents = {"match-1", "match-2", "match-3", "match-4", "match-5", "match-6", "match-7"},
        location = "player",
    }
end

local function make_bedroom_door(state)
    return {
        guid = "{e4a7f3b2-91d6-4c8e-b5a0-3f2d1e8c6a49}",
        template = "furniture",
        id = "bedroom-door",
        material = "oak",
        keywords = {"door", "oak door", "bedroom door"},
        size = 6, weight = 120,
        categories = {"architecture", "wooden"},
        portable = false,
        name = "a heavy oak door",
        description = "A heavy oak door with iron bands.",
        on_feel = "Rough oak grain, cold iron bands.",
        location = nil,
        initial_state = "barred",
        _state = state or "barred",
        states = {
            barred = {
                name = "a heavy oak door",
                description = "A heavy oak door. It appears barred from the other side.",
                on_feel = "Rough oak grain. Solid — no give.",
            },
            unbarred = {
                name = "an unbarred oak door",
                description = "The heavy oak door stands unbarred.",
                on_feel = "The door shifts slightly. No longer held.",
            },
            open = {
                name = "an open oak door",
                description = "The heavy oak door stands open.",
                on_feel = "The open door edge, worn smooth.",
            },
            broken = {
                name = "a splintered doorframe",
                description = "Where the oak door once stood, only splintered wood remains.",
                on_feel = "Jagged splinters and bent iron.",
                terminal = true,
            },
        },
        transitions = {
            {
                from = "barred", to = "unbarred", verb = "unbar",
                trigger = "exit_unbarred",
                message = "The bar is lifted. The door is free.",
                mutate = {
                    keywords = { add = "unbarred", remove = "barred" },
                },
            },
            {
                from = "unbarred", to = "open", verb = "open",
                aliases = {"push"},
                message = "You push the door open.",
                mutate = {
                    keywords = { add = "open" },
                },
            },
            {
                from = "open", to = "unbarred", verb = "close",
                aliases = {"shut"},
                message = "You push the door shut.",
                mutate = {
                    keywords = { remove = "open" },
                },
            },
            {
                from = "barred", to = "broken", verb = "break",
                requires_strength = 3,
                message = "The door bursts inward!",
                mutate = {
                    keywords = { add = "broken", remove = "barred" },
                },
            },
        },
        mutations = {},
    }
end

local function make_trap_door(state)
    return {
        guid = "{a3f8c7d1-e592-4b6a-8d3e-f1c7a4b92e05}",
        template = "furniture",
        id = "trap-door",
        name = "a trap door",
        keywords = {"trap door", "trapdoor", "hatch"},
        hidden = true,
        size = 6, weight = 100,
        categories = {"architecture", "wooden"},
        portable = false,
        material = "wood",
        on_smell = "Damp earth and old wood.",
        location = nil,
        reveals_exit = "down",
        initial_state = "hidden",
        _state = state or "hidden",
        states = {
            hidden = {
                hidden = true,
                name = "a trap door",
                description = "",
                room_presence = "",
            },
            revealed = {
                hidden = false,
                name = "a trap door",
                description = "A heavy wooden trap door set flush with the flagstones.",
                room_presence = "A trap door is set into the stone floor.",
                on_feel = "Your fingers trace a heavy wooden door. An iron ring handle.",
            },
            open = {
                hidden = false,
                name = "a trap door",
                description = "The trap door yawns open, revealing a stairway.",
                room_presence = "A trap door stands open in the floor.",
                on_feel = "The trap door is propped open.",
            },
        },
        transitions = {
            {
                from = "hidden", to = "revealed", verb = "reveal", trigger = "reveal",
                message = "",
            },
            {
                from = "revealed", to = "open", verb = "open",
                message = "You grasp the iron ring and heave. The trap door swings open.",
                mutate = {
                    keywords = { add = "open" },
                },
            },
        },
        mutations = {},
    }
end

local function make_wine_bottle(state)
    return {
        guid = "{1143ab52-ba47-4610-bd1f-6c9aa6167287}",
        template = "small-item",
        id = "wine-bottle",
        material = "glass",
        keywords = {"bottle", "wine bottle", "wine"},
        size = 2, weight = 1.5,
        categories = {"small-item", "fragile", "glass", "bottle"},
        portable = true,
        name = "a dusty wine bottle",
        description = "A dark green glass bottle, sealed with a wax-dipped cork.",
        on_feel = "Cool glass, smooth and heavy.",
        on_smell = "Faintly vinegary through the seal.",
        location = "player",
        initial_state = "sealed",
        _state = state or "sealed",
        states = {
            sealed = {
                name = "a dusty wine bottle",
                description = "A dark green glass bottle, sealed.",
                on_feel = "Cool glass. Wax seal at the neck.",
                on_smell = "Faintly vinegary.",
            },
            open = {
                name = "an open wine bottle",
                description = "An open wine bottle, the cork removed.",
                on_feel = "Cool glass, open top.",
                on_smell = "Sharp vinegar and old grape.",
            },
            empty = {
                name = "an empty wine bottle",
                description = "An empty wine bottle, stained dark inside.",
                on_feel = "Light glass, hollow.",
                on_smell = "Stale wine residue.",
                terminal = true,
            },
            broken = {
                name = "a shattered wine bottle",
                description = "Shattered glass and spreading liquid.",
                on_feel = "Sharp glass fragments!",
                on_smell = "Wine and wet stone.",
                terminal = true,
            },
        },
        transitions = {
            {
                from = "sealed", to = "open", verb = "open",
                aliases = {"uncork"},
                message = "You pull the cork free with a soft pop.",
                mutate = {
                    weight = function(w) return w - 0.05 end,
                    keywords = { add = "open" },
                },
            },
            {
                from = "open", to = "empty", verb = "drink",
                aliases = {"quaff", "sip"},
                message = "You raise the bottle and take a swig. The wine is sour and old.",
                mutate = {
                    contains = nil,
                    weight = 0.5,
                    keywords = { add = "empty" },
                },
            },
            {
                from = "open", to = "empty", verb = "pour",
                message = "You upend the bottle. Dark wine splashes across the floor.",
                mutate = {
                    contains = nil,
                    weight = 0.4,
                    keywords = { add = "empty" },
                },
            },
            {
                from = "sealed", to = "broken", verb = "break",
                aliases = {"smash", "throw"},
                message = "The bottle shatters on the stone floor.",
            },
            {
                from = "open", to = "broken", verb = "break",
                aliases = {"smash", "throw"},
                message = "The open bottle shatters.",
            },
        },
        mutations = {},
    }
end

local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A room for testing.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
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
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = opts.verb or "look",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. CANDLE FSM: unlit → lit → extinguished → relit → spent (timer)
---------------------------------------------------------------------------
suite("candle FSM lifecycle")

test("candle starts in unlit state", function()
    local candle = make_candle()
    eq("unlit", candle._state)
    eq(false, candle.casts_light)
end)

test("candle unlit → lit via FSM transition (with fire_source)", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    ctx.registry:register("candle", candle)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    truthy(trans, "Transition should succeed")
    eq("lit", candle._state)
    eq(true, candle.casts_light, "Lit candle should cast light")
end)

test("candle lit state starts burn timer", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    truthy(fsm_mod.active_timers["candle"], "Timer must be started for lit candle")
    eq(7200, fsm_mod.active_timers["candle"].remaining, "Timer should use remaining_burn")
    eq("spent", fsm_mod.active_timers["candle"].to_state)
end)

test("candle lit → extinguished via FSM transition", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")

    local trans = fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")
    truthy(trans, "Extinguish transition should succeed")
    eq("extinguished", candle._state)
    eq(false, candle.casts_light, "Extinguished candle should not cast light")
end)

test("candle extinguish stops burn timer", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")
    truthy(fsm_mod.active_timers["candle"], "Timer should exist before extinguish")

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")
    is_nil(fsm_mod.active_timers["candle"], "Timer must be stopped on extinguish")
end)

test("candle extinguished → relit preserves partial burn", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.remaining_burn = 3600
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")
    eq("extinguished", candle._state)

    fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    eq("lit", candle._state)
    truthy(fsm_mod.active_timers["candle"], "Timer must restart on relight")
    eq(3600, fsm_mod.active_timers["candle"].remaining, "Timer should use remaining_burn (3600)")
end)

test("candle burns out after timer expires → spent (terminal)", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    candle.remaining_burn = 100
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    local msgs = simulate_tick(ctx, 200)

    eq("spent", candle._state, "Candle should be spent after timer expires")
    truthy(#msgs > 0, "Should produce a burn-out message")
end)

test("candle spent state is terminal — no further transitions", function()
    local ctx = make_ctx()
    local candle = make_candle("spent")
    ctx.registry:register("candle", candle)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    is_nil(trans, "Transition from terminal state should fail")
    eq("terminal", err, "Error should be 'terminal'")
end)

test("candle burn-out applies mutations (weight, keywords, categories)", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    candle.remaining_burn = 50
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    simulate_tick(ctx, 100)

    eq("spent", candle._state)
    eq(0.05, candle.weight, "Weight should be set to 0.05 after burn-out")
    eq(0, candle.size, "Size should be 0 after burn-out")
end)

test("candle timer ticks down remaining_burn on object", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    candle.remaining_burn = 7200
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    fsm_mod.tick_timers(ctx.registry, 1000)

    eq(6200, candle.remaining_burn, "remaining_burn should decrease by tick delta")
end)

test("candle extinguish applies weight mutation", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.weight = 1.0
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")
    eq(0.7, candle.weight, "Weight should be reduced by extinguish mutation")
end)

---------------------------------------------------------------------------
-- 2. MATCH FSM: unlit → lit → spent (auto-ignite + timer burn-out)
---------------------------------------------------------------------------
suite("match FSM lifecycle")

test("match starts in unlit state", function()
    local match = make_match()
    eq("unlit", match._state)
    eq(false, match.casts_light)
end)

test("match unlit → lit via strike (requires has_striker)", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    truthy(trans, "Strike transition should succeed with striker")
    eq("lit", match._state)
end)

test("match strike without striker fails (requires_property)", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local non_striker = { id = "rock", name = "a rock" }
    ctx.registry:register("match-1", match)
    ctx.registry:register("rock", non_striker)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "match-1", "lit", { target = non_striker }, "strike")
    is_nil(trans, "Strike should fail without striker")
    eq("requires_property", err, "Error should be requires_property")
    eq("unlit", match._state, "Match should remain unlit")
end)

test("match lit state starts 30s burn timer", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    clear_timers()

    fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    truthy(fsm_mod.active_timers["match-1"], "Timer must exist after strike")
    eq(30, fsm_mod.active_timers["match-1"].remaining, "Match burn timer should be 30s")
    eq("spent", fsm_mod.active_timers["match-1"].to_state)
end)

test("match burns out after timer expires → spent", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    clear_timers()

    fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    local msgs = simulate_tick(ctx, SECONDS_PER_TICK)

    eq("spent", match._state, "Match should be spent after timer expires (360 > 30)")
    truthy(#msgs > 0, "Should produce a burn-out message")
end)

test("match burn-out frees hand slot", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    clear_timers()

    fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    simulate_tick(ctx, SECONDS_PER_TICK)

    is_nil(ctx.player.hands[1], "Hand should be freed after match burns out")
end)

test("match burn-out applies mutations (weight, keywords, categories)", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    clear_timers()

    fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    simulate_tick(ctx, SECONDS_PER_TICK)

    eq(0.005, match.weight, "Weight should be 0.005 after burn-out")
end)

test("spent match is terminal — cannot be relit", function()
    local ctx = make_ctx()
    local match = make_match("spent")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    is_nil(trans, "Transition from terminal state should fail")
    eq("terminal", err, "Error should be 'terminal'")
end)

test("match manual extinguish → spent (single-use)", function()
    local ctx = make_ctx()
    local match = make_match("lit")
    ctx.registry:register("match-1", match)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "match-1", "spent", {}, "extinguish")
    truthy(trans, "Extinguish should succeed")
    eq("spent", match._state, "Match goes to spent, NOT extinguished (single-use)")
end)

---------------------------------------------------------------------------
-- 3. AUTO-IGNITE: "light candle" with unlit match
---------------------------------------------------------------------------
suite("auto-ignite fire mechanics")

test("'light candle' with unlit match → both auto-ignite and light", function()
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

    eq("lit", candle._state, "Candle should be lit")
    eq("lit", match._state, "Match should be auto-ignited to lit")
end)

test("auto-ignited match has burn timer started", function()
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

    truthy(fsm_mod.active_timers["match-1"],
        "Auto-ignited match MUST have burn timer (Bug #178 fix)")
end)

test("auto-ignited match burns out after tick", function()
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
    simulate_tick(ctx, SECONDS_PER_TICK)

    eq("spent", match._state, "Auto-ignited match should burn out after tick")
    eq("lit", candle._state, "Candle should remain lit after match burns out")
end)

test("auto-ignite: match with explicit tool_noun", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    ctx.tool_noun = "match"
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)

    eq("lit", candle._state, "Candle should be lit")
    eq("lit", match._state, "Match should be auto-ignited via tool_noun")
end)

---------------------------------------------------------------------------
-- 4. DOOR FSM: barred → unbarred → open → close → broken
---------------------------------------------------------------------------
suite("bedroom door FSM lifecycle")

test("door starts in barred state", function()
    local door = make_bedroom_door()
    eq("barred", door._state)
end)

test("door barred → unbarred via FSM", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("barred")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "bedroom-door", "unbarred", {}, "unbar")
    truthy(trans, "Unbar transition should succeed")
    eq("unbarred", door._state)
end)

test("door unbarred → open via FSM", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("unbarred")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "bedroom-door", "open", {}, "open")
    truthy(trans, "Open transition should succeed")
    eq("open", door._state)
end)

test("door open → close (back to unbarred)", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("open")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "bedroom-door", "unbarred", {}, "close")
    truthy(trans, "Close transition should succeed")
    eq("unbarred", door._state)
end)

test("door barred → broken via FSM", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("barred")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "bedroom-door", "broken", {}, "break")
    truthy(trans, "Break transition should succeed")
    eq("broken", door._state)
end)

test("broken door is terminal — no further transitions", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("broken")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "bedroom-door", "open", {}, "open")
    is_nil(trans, "Transition from broken should fail")
    eq("terminal", err)
end)

test("door cannot open from barred (no direct barred→open transition)", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("barred")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "bedroom-door", "open", {}, "open")
    is_nil(trans, "Cannot open a barred door directly")
    eq("no_transition", err, "Error should be no_transition")
end)

test("door transitions apply keyword mutations", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("barred")
    door.keywords = {"door", "oak door", "barred"}
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    fsm_mod.transition(ctx.registry, "bedroom-door", "unbarred", {}, "unbar")

    -- Check keyword list mutation was applied
    local has_unbarred = false
    local has_barred = false
    for _, kw in ipairs(door.keywords) do
        if kw == "unbarred" then has_unbarred = true end
        if kw == "barred" then has_barred = true end
    end
    truthy(has_unbarred, "Should add 'unbarred' keyword")
    truthy(not has_barred, "Should remove 'barred' keyword")
end)

---------------------------------------------------------------------------
-- 5. TRAP DOOR FSM: hidden → revealed → open
---------------------------------------------------------------------------
suite("trap door FSM lifecycle")

test("trap door starts hidden", function()
    local td = make_trap_door()
    eq("hidden", td._state)
    eq(true, td.hidden)
end)

test("trap door hidden → revealed via FSM", function()
    local ctx = make_ctx()
    local td = make_trap_door("hidden")
    ctx.registry:register("trap-door", td)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "trap-door", "revealed", {}, "reveal")
    truthy(trans, "Reveal transition should succeed")
    eq("revealed", td._state)
    eq(false, td.hidden, "Trap door should no longer be hidden")
end)

test("trap door revealed → open via FSM", function()
    local ctx = make_ctx()
    local td = make_trap_door("revealed")
    ctx.registry:register("trap-door", td)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "trap-door", "open", {}, "open")
    truthy(trans, "Open transition should succeed")
    eq("open", td._state)
end)

test("trap door open applies 'open' keyword mutation", function()
    local ctx = make_ctx()
    local td = make_trap_door("revealed")
    td.keywords = {"trap door", "hatch"}
    ctx.registry:register("trap-door", td)
    clear_timers()

    fsm_mod.transition(ctx.registry, "trap-door", "open", {}, "open")

    local has_open = false
    for _, kw in ipairs(td.keywords) do
        if kw == "open" then has_open = true end
    end
    truthy(has_open, "Should add 'open' keyword")
end)

test("trap door cannot go directly from hidden → open", function()
    local ctx = make_ctx()
    local td = make_trap_door("hidden")
    ctx.registry:register("trap-door", td)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "trap-door", "open", {}, "open")
    is_nil(trans, "Cannot open a hidden trap door directly")
    eq("no_transition", err)
end)

---------------------------------------------------------------------------
-- 6. WINE BOTTLE FSM: sealed → open → empty/broken
---------------------------------------------------------------------------
suite("wine bottle FSM lifecycle")

test("wine bottle starts sealed", function()
    local wb = make_wine_bottle()
    eq("sealed", wb._state)
end)

test("wine bottle sealed → open", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("sealed")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "wine-bottle", "open", {}, "open")
    truthy(trans, "Open transition should succeed")
    eq("open", wb._state)
end)

test("wine bottle open → empty (drink)", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("open")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "wine-bottle", "empty", {}, "drink")
    truthy(trans, "Drink transition should succeed")
    eq("empty", wb._state)
end)

test("wine bottle open → empty (pour)", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("open")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "wine-bottle", "empty", {}, "pour")
    truthy(trans, "Pour transition should succeed")
    eq("empty", wb._state)
end)

test("wine bottle sealed → broken (break)", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("sealed")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "wine-bottle", "broken", {}, "break")
    truthy(trans, "Break transition should succeed")
    eq("broken", wb._state)
end)

test("wine bottle open → broken (break)", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("open")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans = fsm_mod.transition(ctx.registry, "wine-bottle", "broken", {}, "break")
    truthy(trans, "Break open bottle should succeed")
    eq("broken", wb._state)
end)

test("wine bottle empty is terminal — no further transitions", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("empty")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "wine-bottle", "open", {})
    is_nil(trans, "Cannot transition from empty")
    eq("terminal", err)
end)

test("wine bottle broken is terminal — no further transitions", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("broken")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "wine-bottle", "sealed", {})
    is_nil(trans, "Cannot transition from broken")
    eq("terminal", err)
end)

test("wine bottle cannot drink from sealed (no transition)", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("sealed")
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "wine-bottle", "empty", {}, "drink")
    is_nil(trans, "Cannot drink from sealed bottle")
    eq("no_transition", err)
end)

test("wine open→empty drink applies weight mutation", function()
    local ctx = make_ctx()
    local wb = make_wine_bottle("open")
    wb.weight = 1.5
    ctx.registry:register("wine-bottle", wb)
    clear_timers()

    fsm_mod.transition(ctx.registry, "wine-bottle", "empty", {}, "drink")
    eq(0.5, wb.weight, "Weight should be 0.5 after drinking")
end)

---------------------------------------------------------------------------
-- 7. FIRE MECHANICS: verb-level light/extinguish tests
---------------------------------------------------------------------------
suite("fire verb mechanics")

test("light candle with lit match in hand", function()
    local ctx = make_ctx()
    local match = make_match("lit")
    match.provides_tool = "fire_source"
    local candle = make_candle("unlit")
    ctx.registry:register("match-1", match)
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = candle
    clear_timers()

    capture_output(function() handlers["light"](ctx, "candle") end)

    eq("lit", candle._state, "Candle should be lit")
end)

test("light candle without any fire source → fail message", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    local output = capture_output(function() handlers["light"](ctx, "candle") end)

    eq("unlit", candle._state, "Candle should remain unlit")
    truthy(output:find("nothing to light") or output:find("have nothing"),
        "Should say you have nothing to light it with, got: " .. output)
end)

test("light already-lit candle → describes current state", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    local output = capture_output(function() handlers["light"](ctx, "candle") end)

    eq("lit", candle._state, "Should remain lit")
    truthy(output:len() > 0, "Should output something describing the lit state")
end)

test("extinguish lit candle via verb handler", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    capture_output(function() handlers["extinguish"](ctx, "candle") end)

    eq("extinguished", candle._state)
end)

test("extinguish unlit candle → tells player it isn't lit", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    local output = capture_output(function() handlers["extinguish"](ctx, "candle") end)

    eq("unlit", candle._state, "Should remain unlit")
    truthy(output:find("isn't lit") or output:find("not lit") or output:find("can't extinguish"),
        "Should say it's not lit, got: " .. output)
end)

test("strike match on matchbox via verb handler", function()
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
    truthy(fsm_mod.active_timers["match-1"], "Timer must exist after strike")
end)

test("strike already-lit match → tells player it's already lit", function()
    local ctx = make_ctx()
    local match = make_match("lit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    clear_timers()

    local output = capture_output(function() handlers["strike"](ctx, "match on matchbox") end)

    eq("lit", match._state, "Should remain lit")
    truthy(output:find("already lit"),
        "Should say match is already lit, got: " .. output)
end)

test("strike spent match → tells player it's spent", function()
    local ctx = make_ctx()
    local match = make_match("spent")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    ctx.player.hands[2] = matchbox
    clear_timers()

    local output = capture_output(function() handlers["strike"](ctx, "match on matchbox") end)

    eq("spent", match._state, "Should remain spent")
    truthy(output:find("spent") or output:find("relit"),
        "Should say match is spent, got: " .. output)
end)

---------------------------------------------------------------------------
-- 8. FSM TIMER ENGINE: pause, resume, scan
---------------------------------------------------------------------------
suite("FSM timer engine mechanics")

test("pause_timer preserves remaining time", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")

    -- Tick a bit to reduce time
    fsm_mod.tick_timers(ctx.registry, 1000)
    local remaining_before = fsm_mod.active_timers["candle"].remaining

    fsm_mod.pause_timer("candle")
    is_nil(fsm_mod.active_timers["candle"], "Active timer should be nil after pause")
    truthy(fsm_mod.paused_timers["candle"], "Paused timer should exist")
    eq(remaining_before, fsm_mod.paused_timers["candle"].remaining,
        "Paused timer should preserve remaining time")
end)

test("resume_timer restores from paused", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")
    fsm_mod.tick_timers(ctx.registry, 1000)

    fsm_mod.pause_timer("candle")
    local paused_remaining = fsm_mod.paused_timers["candle"].remaining

    fsm_mod.resume_timer("candle")
    truthy(fsm_mod.active_timers["candle"], "Timer should be active again")
    is_nil(fsm_mod.paused_timers["candle"], "Paused timer should be cleared")
    eq(paused_remaining, fsm_mod.active_timers["candle"].remaining,
        "Resumed timer should have same remaining time")
end)

test("tick_timers does not fire expired timer if state changed", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")

    -- Manually change state before timer fires
    candle._state = "extinguished"
    local msgs = fsm_mod.tick_timers(ctx.registry, 99999)

    eq("extinguished", candle._state, "State should not change if manually altered")
    eq(0, #msgs, "No messages when state doesn't match timer's expected state")
end)

test("stop_timer removes timer completely", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")
    truthy(fsm_mod.active_timers["candle"])

    fsm_mod.stop_timer("candle")
    is_nil(fsm_mod.active_timers["candle"], "Timer should be removed after stop")
end)

test("start_timer uses remaining_burn when available", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.remaining_burn = 2000
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.start_timer(ctx.registry, "candle")
    eq(2000, fsm_mod.active_timers["candle"].remaining,
        "Timer should use remaining_burn (2000) instead of delay (7200)")
end)

test("start_timer uses delay when no remaining_burn", function()
    local ctx = make_ctx()
    local match = make_match("lit")
    ctx.registry:register("match-1", match)
    clear_timers()

    fsm_mod.start_timer(ctx.registry, "match-1")
    eq(30, fsm_mod.active_timers["match-1"].remaining,
        "Timer should use timed_events delay (30) when no remaining_burn")
end)

test("start_timer does nothing for state without timed_events", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("barred")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    fsm_mod.start_timer(ctx.registry, "bedroom-door")
    is_nil(fsm_mod.active_timers["bedroom-door"],
        "No timer for state without timed_events")
end)

test("scan_room_timers starts timers for lit objects in room", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    ctx.current_room.contents = {"candle"}
    clear_timers()

    fsm_mod.scan_room_timers(ctx.registry, ctx.current_room)
    truthy(fsm_mod.active_timers["candle"],
        "scan_room_timers should start timer for lit candle in room")
end)

test("pause_room_timers pauses all room timers", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    ctx.registry:register("candle", candle)
    ctx.current_room.contents = {"candle"}
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")

    fsm_mod.pause_room_timers(ctx.current_room)
    is_nil(fsm_mod.active_timers["candle"], "Active timer should be paused")
    truthy(fsm_mod.paused_timers["candle"], "Timer should be in paused state")
end)

---------------------------------------------------------------------------
-- 9. FSM MUTATION ENGINE: direct, function, list add/remove
---------------------------------------------------------------------------
suite("FSM mutation mechanics")

test("direct value mutation applied on transition", function()
    local ctx = make_ctx()
    local match = make_match("unlit")
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", match)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = match
    clear_timers()

    -- Strike → lit, then extinguish → spent (has weight mutation)
    fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    fsm_mod.transition(ctx.registry, "match-1", "spent", {}, "extinguish")

    eq(0.005, match.weight, "Direct value mutation (0.005) should be applied")
end)

test("function mutation applied on transition (candle weight)", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.weight = 1.0
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")
    eq(0.7, candle.weight, "Function mutation should reduce weight to max(1.0*0.7, 0.1) = 0.7")
end)

test("list add mutation adds keyword", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    candle.keywords = {"candle", "tallow"}
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")

    local found = false
    for _, kw in ipairs(candle.keywords) do
        if kw == "half-burned" then found = true end
    end
    truthy(found, "Should add 'half-burned' keyword via list mutation")
end)

test("list remove mutation removes keyword", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("barred")
    door.keywords = {"door", "oak door", "barred"}
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    fsm_mod.transition(ctx.registry, "bedroom-door", "unbarred", {}, "unbar")

    local found_barred = false
    for _, kw in ipairs(door.keywords) do
        if kw == "barred" then found_barred = true end
    end
    truthy(not found_barred, "Should remove 'barred' keyword via list mutation")
end)

test("list add does not duplicate existing keyword", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    candle.keywords = {"candle", "tallow", "half-burned"}
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")

    local count = 0
    for _, kw in ipairs(candle.keywords) do
        if kw == "half-burned" then count = count + 1 end
    end
    eq(1, count, "Should not duplicate existing keyword")
end)

---------------------------------------------------------------------------
-- 10. INVALID TRANSITIONS / EDGE CASES
---------------------------------------------------------------------------
suite("invalid transitions and edge cases")

test("transition on non-FSM object returns not_fsm", function()
    local ctx = make_ctx()
    local rock = { id = "rock", name = "a rock" }
    ctx.registry:register("rock", rock)
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "rock", "broken", {})
    is_nil(trans)
    eq("not_fsm", err)
end)

test("transition on non-existent object returns not_fsm", function()
    local ctx = make_ctx()
    clear_timers()

    local trans, err = fsm_mod.transition(ctx.registry, "nonexistent", "open", {})
    is_nil(trans)
    eq("not_fsm", err)
end)

test("transition with wrong verb_hint falls back", function()
    local ctx = make_ctx()
    local door = make_bedroom_door("unbarred")
    ctx.registry:register("bedroom-door", door)
    clear_timers()

    -- "push" is an alias for "open"
    local trans = fsm_mod.transition(ctx.registry, "bedroom-door", "open", {}, "push")
    truthy(trans, "Should fall back to matching transition via aliases")
    eq("open", door._state)
end)

test("get_transitions only returns non-auto transitions", function()
    local candle = make_candle("lit")
    local transitions = fsm_mod.get_transitions(candle)

    local has_auto = false
    for _, t in ipairs(transitions) do
        if t.trigger == "auto" then has_auto = true end
    end
    truthy(not has_auto, "get_transitions should exclude auto-transitions")
    truthy(#transitions > 0, "Should return at least the extinguish transition")
end)

test("fsm.load returns object for FSM objects, nil for non-FSM", function()
    local candle = make_candle()
    local rock = { id = "rock" }

    truthy(fsm_mod.load(candle), "FSM object should return itself")
    is_nil(fsm_mod.load(rock), "Non-FSM object should return nil")
    is_nil(fsm_mod.load(nil), "nil should return nil")
    is_nil(fsm_mod.load("string"), "string should return nil")
end)

test("state properties applied correctly on transition", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    ctx.registry:register("candle", candle)
    clear_timers()

    eq(false, candle.casts_light, "Should not cast light when unlit")
    eq("a tallow candle", candle.name, "Name should be unlit name")

    fsm_mod.transition(ctx.registry, "candle", "lit", {}, "light")
    eq(true, candle.casts_light, "Should cast light when lit")
    eq("a lit tallow candle", candle.name, "Name should change to lit name")
end)

test("old state properties cleaned up on transition", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    candle.light_radius = 2
    candle.provides_tool = "fire_source"
    ctx.registry:register("candle", candle)
    clear_timers()

    fsm_mod.transition(ctx.registry, "candle", "extinguished", {}, "extinguish")
    eq(false, candle.casts_light, "casts_light should be false after extinguish")
    is_nil(candle.light_radius, "light_radius should be cleaned from lit state")
    is_nil(candle.provides_tool, "provides_tool should be cleaned from lit state")
end)

---------------------------------------------------------------------------
-- 11. WIND TRAVERSE EFFECT: extinguishes non-wind-resistant carried flames
---------------------------------------------------------------------------
suite("wind traverse effect")

test("wind effect extinguishes carried lit candle", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "candle")

    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            description = "A cold draft rushes up the stairway...",
            extinguishes = { "candle" },
            message_extinguish = "The draft snuffs out your candle!",
        },
    }

    capture_output(function() traverse_effects.process(exit, ctx) end)

    eq("extinguished", candle._state, "Candle should be extinguished by wind")
end)

test("wind effect spares wind-resistant items", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    candle.wind_resistant = true
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            extinguishes = { "candle" },
        },
    }

    capture_output(function() traverse_effects.process(exit, ctx) end)

    eq("lit", candle._state, "Wind-resistant candle should remain lit")
end)

test("wind effect does nothing to unlit candle", function()
    local ctx = make_ctx()
    local candle = make_candle("unlit")
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            extinguishes = { "candle" },
        },
    }

    capture_output(function() traverse_effects.process(exit, ctx) end)

    eq("unlit", candle._state, "Unlit candle should be unaffected by wind")
end)

test("wind effect only targets items in extinguishes list", function()
    local ctx = make_ctx()
    local candle = make_candle("lit")
    candle.casts_light = true
    ctx.registry:register("candle", candle)
    ctx.player.hands[1] = candle
    clear_timers()

    local exit = {
        target = "hallway",
        on_traverse = {
            type = "wind_effect",
            extinguishes = { "torch" },
        },
    }

    capture_output(function() traverse_effects.process(exit, ctx) end)

    eq("lit", candle._state, "Candle not in extinguish list should remain lit")
end)

---------------------------------------------------------------------------
-- 12. CONSUMABLE MECHANICS: matchbox supply
---------------------------------------------------------------------------
suite("consumable mechanics")

test("matchbox starts with 7 matches", function()
    local mb = make_matchbox()
    eq(7, #mb.contents, "Matchbox should start with 7 matches")
end)

test("multiple matches can be created and tracked independently", function()
    local ctx = make_ctx()
    local m1 = make_match("unlit"); m1.id = "match-1"
    local m2 = make_match("unlit"); m2.id = "match-2"
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", m1)
    ctx.registry:register("match-2", m2)
    ctx.registry:register("matchbox", matchbox)
    clear_timers()

    -- Strike first match
    fsm_mod.transition(ctx.registry, "match-1", "lit", { target = matchbox }, "strike")
    eq("lit", m1._state)
    eq("unlit", m2._state, "Second match should remain unlit")
end)

test("match FSM transitions are independent per instance", function()
    local ctx = make_ctx()
    local m1 = make_match("lit"); m1.id = "match-1"
    local m2 = make_match("lit"); m2.id = "match-2"
    local matchbox = make_matchbox()
    ctx.registry:register("match-1", m1)
    ctx.registry:register("match-2", m2)
    ctx.registry:register("matchbox", matchbox)
    ctx.player.hands[1] = m1
    clear_timers()
    fsm_mod.start_timer(ctx.registry, "match-1")
    fsm_mod.start_timer(ctx.registry, "match-2")

    simulate_tick(ctx, SECONDS_PER_TICK)

    eq("spent", m1._state, "Match 1 should burn out")
    eq("spent", m2._state, "Match 2 should also burn out")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failed = h.summary()
if failed > 0 then os.exit(1) end
