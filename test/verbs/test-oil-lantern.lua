-- test/verbs/test-oil-lantern.lua
-- Full lifecycle tests for the oil lantern: fuel, light, extinguish, relight,
-- spent/refuel cycle, wind resistance, broken state, casts_light, provides_tool.
--
-- Usage: lua test/verbs/test-oil-lantern.lua
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

local function make_lantern(state_override)
    local def = dofile("src/meta/worlds/manor/objects/oil-lantern.lua")
    if state_override then
        def._state = state_override
    end
    return def
end

local function make_oil_flask()
    return {
        id = "oil-flask",
        name = "a small ceramic oil flask",
        keywords = {"flask", "oil flask", "oil", "lamp oil"},
        provides_tool = "lamp-oil",
        categories = {"consumable", "fuel"},
    }
end

local function make_match()
    return {
        id = "match",
        name = "a lit match",
        keywords = {"match"},
        provides_tool = {"fire_source"},
        _state = "lit",
        states = {
            lit = { provides_tool = "fire_source", casts_light = true },
        },
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
        pour_target = opts.pour_target,
    }
end

---------------------------------------------------------------------------
-- 1. Object definition sanity checks
---------------------------------------------------------------------------
suite("oil-lantern — object definition")

test("lantern loads without error", function()
    local lantern = make_lantern()
    h.assert_truthy(lantern, "Lantern should load")
    eq("oil-lantern", lantern.id)
end)

test("material is brass", function()
    local lantern = make_lantern()
    eq("brass", lantern.material)
end)

test("initial state is empty", function()
    local lantern = make_lantern()
    eq("empty", lantern._state)
    eq("empty", lantern.initial_state)
end)

test("wind_resistant is true", function()
    local lantern = make_lantern()
    eq(true, lantern.wind_resistant)
end)

test("casts_light is false when empty", function()
    local lantern = make_lantern()
    eq(false, lantern.casts_light)
end)

test("has required keywords", function()
    local lantern = make_lantern()
    local found_lantern, found_brass = false, false
    for _, kw in ipairs(lantern.keywords) do
        if kw == "lantern" then found_lantern = true end
        if kw == "brass lantern" then found_brass = true end
    end
    h.assert_truthy(found_lantern, "Should have 'lantern' keyword")
    h.assert_truthy(found_brass, "Should have 'brass lantern' keyword")
end)

test("has on_feel for every state", function()
    local lantern = make_lantern()
    for state_name, state_data in pairs(lantern.states) do
        h.assert_truthy(state_data.on_feel,
            "State '" .. state_name .. "' must have on_feel")
    end
end)

test("has burn_duration and remaining_burn", function()
    local lantern = make_lantern()
    eq(14400, lantern.burn_duration)
    eq(14400, lantern.remaining_burn)
end)

---------------------------------------------------------------------------
-- 2. Fuel cycle: empty → fueled (pour)
---------------------------------------------------------------------------
suite("oil-lantern — fuel cycle")

test("pour oil transitions empty → fueled", function()
    local lantern = make_lantern("empty")
    local oil = make_oil_flask()
    local ctx = make_ctx({ verb = "pour", pour_target = "lantern" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.registry:register("oil-flask", oil)
    ctx.player.hands[1] = oil
    ctx.player.hands[2] = lantern

    local output = capture_output(function()
        handlers["pour"](ctx, "oil")
    end)
    eq("fueled", lantern._state, "Lantern should be fueled after pouring oil")
    h.assert_truthy(output:find("oil") or output:find("reservoir") or output:find("fuel"),
        "Should print fueling message")
end)

test("spent lantern can be refueled (spent → fueled)", function()
    local lantern = make_lantern("spent")
    local oil = make_oil_flask()
    local ctx = make_ctx({ verb = "pour", pour_target = "lantern" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.registry:register("oil-flask", oil)
    ctx.player.hands[1] = oil
    ctx.player.hands[2] = lantern

    local output = capture_output(function()
        handlers["pour"](ctx, "oil")
    end)
    eq("fueled", lantern._state, "Spent lantern should be refueled to 'fueled'")
    h.assert_truthy(output:find("oil") or output:find("burn again") or output:find("fresh"),
        "Should print refuel message")
end)

---------------------------------------------------------------------------
-- 3. Light cycle: fueled → lit → extinguished → relit
---------------------------------------------------------------------------
suite("oil-lantern — light/extinguish cycle")

test("light fueled lantern with fire_source → lit", function()
    local lantern = make_lantern("fueled")
    local match = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.registry:register("match", match)
    ctx.player.hands[1] = lantern
    ctx.player.hands[2] = match

    local output = capture_output(function()
        handlers["light"](ctx, "lantern")
    end)
    eq("lit", lantern._state, "Lantern should be lit")
    h.assert_truthy(output:find("flame") or output:find("light") or output:find("wick"),
        "Should print lighting message")
end)

test("lit state provides fire_source and casts_light", function()
    local lantern = make_lantern()
    local lit_state = lantern.states.lit
    eq(true, lit_state.casts_light, "Lit state should cast light")
    eq("fire_source", lit_state.provides_tool, "Lit state should provide fire_source")
    eq(3, lit_state.light_radius, "Lit state should have light_radius 3")
end)

test("lit state on_feel matches issue spec", function()
    local lantern = make_lantern()
    local lit_state = lantern.states.lit
    h.assert_truthy(lit_state.on_feel:find("brass") and lit_state.on_feel:find("glass chimney") and lit_state.on_feel:find("warm"),
        "Lit on_feel should mention brass, glass chimney, and warm")
end)

test("extinguish lit lantern → extinguished", function()
    local lantern = make_lantern("lit")
    local ctx = make_ctx({ verb = "extinguish" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.player.hands[1] = lantern

    local output = capture_output(function()
        handlers["extinguish"](ctx, "lantern")
    end)
    eq("extinguished", lantern._state, "Lantern should be extinguished")
    h.assert_truthy(output:find("blow") or output:find("smolder") or output:find("dies") or output:find("Darkness"),
        "Should print extinguish message")
end)

test("relight extinguished lantern with fire_source → lit", function()
    local lantern = make_lantern("extinguished")
    local match = make_match()
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.registry:register("match", match)
    ctx.player.hands[1] = lantern
    ctx.player.hands[2] = match

    local output = capture_output(function()
        handlers["light"](ctx, "lantern")
    end)
    eq("lit", lantern._state, "Lantern should be relit")
    h.assert_truthy(output:find("oily") or output:find("catches") or output:find("Light") or output:find("warm"),
        "Should print relight message")
end)

test("light fueled lantern without fire_source fails", function()
    local lantern = make_lantern("fueled")
    local ctx = make_ctx({ verb = "light" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.player.hands[1] = lantern

    local output = capture_output(function()
        handlers["light"](ctx, "lantern")
    end)
    eq("fueled", lantern._state, "Lantern should stay fueled")
    h.assert_truthy(output:find("nothing to light") or output:find("have no"),
        "Should print fail message")
end)

---------------------------------------------------------------------------
-- 4. Broken state (glass chimney shatters)
---------------------------------------------------------------------------
suite("oil-lantern — broken state")

test("break empty lantern → broken", function()
    local lantern = make_lantern("empty")
    local ctx = make_ctx({ verb = "break" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.player.hands[1] = lantern

    local output = capture_output(function()
        handlers["break"](ctx, "lantern")
    end)
    eq("broken", lantern._state, "Empty lantern should break")
    h.assert_truthy(output:find("shatter") or output:find("glass") or output:find("chimney"),
        "Should mention glass shattering")
end)

test("break lit lantern → broken", function()
    local lantern = make_lantern("lit")
    local ctx = make_ctx({ verb = "break" })
    ctx.registry:register("oil-lantern", lantern)
    ctx.player.hands[1] = lantern

    local output = capture_output(function()
        handlers["break"](ctx, "lantern")
    end)
    eq("broken", lantern._state, "Lit lantern should break")
end)

test("broken state is terminal", function()
    local lantern = make_lantern()
    h.assert_truthy(lantern.states.broken.terminal,
        "Broken state should be terminal")
end)

test("broken state has on_feel", function()
    local lantern = make_lantern()
    h.assert_truthy(lantern.states.broken.on_feel,
        "Broken state should have on_feel")
    h.assert_truthy(lantern.states.broken.on_feel:find("jagged") or lantern.states.broken.on_feel:find("glass"),
        "Broken on_feel should mention glass damage")
end)

test("broken state casts_light is false", function()
    local lantern = make_lantern()
    eq(false, lantern.states.broken.casts_light, "Broken should not cast light")
end)

---------------------------------------------------------------------------
-- 5. Wind resistance
---------------------------------------------------------------------------
suite("oil-lantern — wind resistance")

test("lantern has wind_resistant property", function()
    local lantern = make_lantern()
    eq(true, lantern.wind_resistant,
        "Lantern should be wind resistant (glass chimney protects flame)")
end)

test("candle is NOT wind resistant (comparison)", function()
    local candle = dofile("src/meta/worlds/manor/objects/candle.lua")
    h.assert_truthy(not candle.wind_resistant,
        "Candle should NOT be wind resistant")
end)

---------------------------------------------------------------------------
-- 6. State data integrity
---------------------------------------------------------------------------
suite("oil-lantern — state data integrity")

test("all states have casts_light defined", function()
    local lantern = make_lantern()
    for state_name, state_data in pairs(lantern.states) do
        h.assert_truthy(state_data.casts_light ~= nil,
            "State '" .. state_name .. "' must define casts_light")
    end
end)

test("only lit state has casts_light = true", function()
    local lantern = make_lantern()
    for state_name, state_data in pairs(lantern.states) do
        if state_name == "lit" then
            eq(true, state_data.casts_light, "Lit should cast light")
        else
            eq(false, state_data.casts_light,
                "State '" .. state_name .. "' should NOT cast light")
        end
    end
end)

test("only lit state provides fire_source tool", function()
    local lantern = make_lantern()
    eq("fire_source", lantern.states.lit.provides_tool)
    for state_name, state_data in pairs(lantern.states) do
        if state_name ~= "lit" then
            h.assert_truthy(not state_data.provides_tool,
                "State '" .. state_name .. "' should NOT provide tools")
        end
    end
end)

test("spent state is NOT terminal (refuelable)", function()
    local lantern = make_lantern()
    h.assert_truthy(not lantern.states.spent.terminal,
        "Spent should not be terminal — lantern can be refueled")
end)

test("broken is the only terminal state", function()
    local lantern = make_lantern()
    for state_name, state_data in pairs(lantern.states) do
        if state_name == "broken" then
            eq(true, state_data.terminal, "Broken should be terminal")
        else
            h.assert_truthy(not state_data.terminal,
                "State '" .. state_name .. "' should NOT be terminal")
        end
    end
end)

test("lit state has timed_events for fuel exhaustion", function()
    local lantern = make_lantern()
    local lit = lantern.states.lit
    h.assert_truthy(lit.timed_events, "Lit state should have timed_events")
    h.assert_truthy(#lit.timed_events > 0, "Should have at least one timed event")
    eq("transition", lit.timed_events[1].event)
    eq("spent", lit.timed_events[1].to_state)
    eq(14400, lit.timed_events[1].delay, "Should match burn_duration")
end)

---------------------------------------------------------------------------
-- 7. FSM transition coverage
---------------------------------------------------------------------------
suite("oil-lantern — transition coverage")

test("all transitions reference valid from/to states", function()
    local lantern = make_lantern()
    local state_names = {}
    for k, _ in pairs(lantern.states) do state_names[k] = true end

    for i, t in ipairs(lantern.transitions) do
        h.assert_truthy(state_names[t.from],
            "Transition " .. i .. " 'from' state '" .. t.from .. "' not found in states")
        h.assert_truthy(state_names[t.to],
            "Transition " .. i .. " 'to' state '" .. t.to .. "' not found in states")
    end
end)

test("every non-broken state has a break transition", function()
    local lantern = make_lantern()
    local break_froms = {}
    for _, t in ipairs(lantern.transitions) do
        if t.verb == "break" then
            break_froms[t.from] = true
        end
    end
    for state_name, _ in pairs(lantern.states) do
        if state_name ~= "broken" then
            h.assert_truthy(break_froms[state_name],
                "State '" .. state_name .. "' should have a break transition")
        end
    end
end)

test("prerequisites declare fire_source and lamp-oil", function()
    local lantern = make_lantern()
    h.assert_truthy(lantern.prerequisites.light, "Should have light prerequisite")
    eq("fire_source", lantern.prerequisites.light.requires[1])
    h.assert_truthy(lantern.prerequisites.fuel, "Should have fuel prerequisite")
    eq("lamp-oil", lantern.prerequisites.fuel.requires[1])
end)

print("\nExit code: " .. h.summary())
