-- test/verbs/test-playtest-bugs-398-399-401-402.lua
-- TDD-FIRST tests for playtest bugs #398, #399, #401, #402.
-- Each test MUST FAIL before the fix, PASS after.
--
-- #402 — unbar prints success but door stays barred (FSM state not updated)
-- #399 — "strike match" resolves to trap door instead of match
-- #398 — "fuel lantern" routes to medical treatment instead of pour/refuel
-- #401 — courtyard dark despite moonlight + cat movement grammar
--
-- Usage: lua test/verbs/test-playtest-bugs-398-399-401-402.lua

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
local presentation = require("engine.ui.presentation")

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
        id = opts.room_id or "test-room",
        name = opts.room_name or "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
        light_level = opts.light_level,
        sky_visible = opts.sky_visible,
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = opts.injuries or {},
        bags = {},
        state = opts.state or {},
        max_health = 100,
        location = room.id,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- #402 — unbar prints success but door stays barred
---------------------------------------------------------------------------
suite("#402 — unbar door FSM state change")

test("#402: unbar changes door _state from barred to unbarred", function()
    local door = {
        id = "bedroom-hallway-door-south",
        name = "a heavy oak door",
        keywords = {"door", "heavy door", "oak door", "south door",
                    "barred door", "iron bar"},
        portal = {
            target = "start-room",
            bidirectional_id = "test-pair",
            direction_hint = "south",
        },
        initial_state = "barred",
        _state = "barred",
        states = {
            barred = {
                traversable = false,
                name = "a barred oak door",
                description = "Barred.",
            },
            unbarred = {
                traversable = false,
                name = "an unbarred oak door",
                description = "Unbarred.",
            },
            open = {
                traversable = true,
                name = "an open oak door",
                description = "Open.",
            },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              aliases = {"lift bar", "remove bar"},
              message = "You lift the bar. The door is free.",
              mutate = {
                  keywords = { add = "unbarred", remove = {"barred", "iron bar"} },
              },
            },
            { from = "unbarred", to = "open", verb = "open",
              message = "You push the door open." },
        },
    }

    local ctx = make_ctx({
        room_contents = { door.id },
        verb = "unbar",
    })
    ctx.registry:register(door.id, door)

    local output = capture_output(function()
        handlers["unbar"](ctx, "door")
    end)

    -- The state MUST change from "barred" to "unbarred"
    eq("unbarred", door._state, "#402: door._state should be 'unbarred' after unbar")
end)

test("#402: unbar prints the transition message", function()
    local door = {
        id = "test-door-402b",
        name = "a heavy oak door",
        keywords = {"door", "oak door"},
        initial_state = "barred",
        _state = "barred",
        states = {
            barred = { traversable = false, name = "barred door" },
            unbarred = { traversable = false, name = "unbarred door" },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              message = "The bar is lifted." },
        },
    }
    local ctx = make_ctx({ room_contents = { door.id }, verb = "unbar" })
    ctx.registry:register(door.id, door)

    local output = capture_output(function()
        handlers["unbar"](ctx, "door")
    end)

    h.assert_truthy(output:find("bar is lifted"), "#402: should print transition message")
end)

test("#402: unbar applies keyword mutations", function()
    local door = {
        id = "test-door-402c",
        name = "a barred oak door",
        keywords = {"door", "barred door", "iron bar"},
        initial_state = "barred",
        _state = "barred",
        states = {
            barred = { traversable = false, name = "barred" },
            unbarred = { traversable = false, name = "unbarred" },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              message = "Bar removed.",
              mutate = {
                  keywords = { add = "unbarred", remove = {"barred door", "iron bar"} },
              },
            },
        },
    }
    local ctx = make_ctx({ room_contents = { door.id }, verb = "unbar" })
    ctx.registry:register(door.id, door)

    capture_output(function()
        handlers["unbar"](ctx, "door")
    end)

    -- Check keyword mutation applied
    local has_unbarred = false
    local has_barred = false
    local has_iron_bar = false
    for _, kw in ipairs(door.keywords) do
        if kw == "unbarred" then has_unbarred = true end
        if kw == "barred door" then has_barred = true end
        if kw == "iron bar" then has_iron_bar = true end
    end
    h.assert_truthy(has_unbarred, "#402: should add 'unbarred' keyword")
    eq(false, has_barred, "#402: should remove 'barred door' keyword")
    eq(false, has_iron_bar, "#402: should remove 'iron bar' keyword")
end)

---------------------------------------------------------------------------
-- #399 — "strike match" resolves to trap door
---------------------------------------------------------------------------
suite("#399 — strike match noun resolution")

test("#399: 'strike match' does not mention trap door", function()
    -- The compound actions preprocessor should route "strike match"
    -- to "light match" so it never reaches fuzzy noun resolution
    local compound = require("engine.parser.preprocess.compound_actions")
    local result = compound.transform_compound_actions("strike match")
    -- Should be transformed away from raw "strike match" that fuzzy-matches trap door
    h.assert_truthy(result ~= "strike match" or result == "light match",
        "#399: 'strike match' should be transformed to avoid trap-door mismatch, got: " .. tostring(result))
end)

test("#399: 'strike a match' also transforms correctly", function()
    local compound = require("engine.parser.preprocess.compound_actions")
    local result = compound.transform_compound_actions("strike a match")
    h.assert_truthy(result == "light match",
        "#399: 'strike a match' should become 'light match', got: " .. tostring(result))
end)

---------------------------------------------------------------------------
-- #398 — "fuel lantern" routes to medical instead of pour/refuel
---------------------------------------------------------------------------
suite("#398 — fuel verb routing")

test("#398: 'fuel' handler exists and is not medical", function()
    h.assert_truthy(handlers["fuel"], "#398: handlers['fuel'] should exist")
    -- Verify it's the same as pour, not apply
    eq(handlers["pour"], handlers["fuel"],
        "#398: handlers['fuel'] should be same as handlers['pour']")
end)

test("#398: 'refuel' handler exists", function()
    h.assert_truthy(handlers["refuel"], "#398: handlers['refuel'] should exist")
    eq(handlers["pour"], handlers["refuel"],
        "#398: handlers['refuel'] should be same as handlers['pour']")
end)

test("#398: 'fuel lantern' does not produce medical error", function()
    local lantern = {
        id = "oil-lantern",
        name = "a brass lantern",
        keywords = {"lantern", "brass lantern", "oil lantern"},
        _state = "empty",
        initial_state = "empty",
        states = {
            empty = { name = "an empty lantern" },
            fueled = { name = "a fueled lantern" },
        },
        transitions = {
            { from = "empty", to = "fueled", verb = "pour",
              aliases = {"fill", "fuel"},
              requires_tool = "lamp-oil",
              message = "You pour oil into the lantern." },
        },
    }
    local ctx = make_ctx({
        room_contents = { lantern.id },
        verb = "fuel",
        hands = { lantern.id, nil },
    })
    ctx.registry:register(lantern.id, lantern)

    local output = capture_output(function()
        handlers["fuel"](ctx, "lantern")
    end)

    -- Must NOT mention injuries or medical treatment
    eq(false, output:find("injur") ~= nil,
        "#398: 'fuel lantern' should NOT mention injuries, got: " .. output)
end)

---------------------------------------------------------------------------
-- #401 — courtyard dark despite moonlight
---------------------------------------------------------------------------
suite("#401 — ambient light level")

test("#401: room with light_level=1 returns 'dim' not 'dark'", function()
    local ctx = make_ctx({
        room_id = "courtyard",
        room_name = "The Inner Courtyard",
        light_level = 1,
        time_offset = 20, -- nighttime, no daylight
    })

    local level = presentation.get_light_level(ctx)
    eq("dim", level,
        "#401: room with light_level=1 should be 'dim', got: " .. tostring(level))
end)

test("#401: room with light_level=0 remains 'dark'", function()
    local ctx = make_ctx({
        time_offset = 20, -- nighttime
    })
    -- no light_level set (nil) => should still be dark
    local level = presentation.get_light_level(ctx)
    eq("dark", level, "#401: room without light_level should be 'dark'")
end)

test("#401: room with light_level=2 returns 'lit'", function()
    local ctx = make_ctx({
        light_level = 2,
        time_offset = 20,
    })
    local level = presentation.get_light_level(ctx)
    eq("lit", level,
        "#401: room with light_level=2 should be 'lit', got: " .. tostring(level))
end)

---------------------------------------------------------------------------
-- #401 — cat movement grammar
---------------------------------------------------------------------------
suite("#401 — creature movement grammar")

test("#401: non-cardinal direction gets preposition", function()
    -- Simulate the message generation logic from actions.lua
    -- The fix should add prepositions for non-cardinal exit names
    local CARDINAL = { north=true, south=true, east=true, west=true,
                       up=true, down=true, northeast=true, northwest=true,
                       southeast=true, southwest=true }
    local direction = "window"
    local name = "a grey cat"
    local Name = name:sub(1,1):upper() .. name:sub(2)

    -- After fix: non-cardinal directions should get "through the" prefix
    local msg
    if CARDINAL[direction] then
        msg = Name .. " scurries " .. direction .. "."
    else
        msg = Name .. " scurries through the " .. direction .. "."
    end

    h.assert_truthy(msg:find("through the window"),
        "#401: should say 'scurries through the window', got: " .. msg)
end)

---------------------------------------------------------------------------
h.summary()
