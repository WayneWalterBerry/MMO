-- test/verbs/test-wash-verb.lua
-- Issue #112: Tests for the WASH verb handler.
-- Tests: wash soiled bandage, wash without water, wash non-washable,
--        wash hands, wash empty noun, wash with explicit target.
--
-- Usage: lua test/verbs/test-wash-verb.lua

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

local function make_soiled_bandage()
    return {
        id = "bandage",
        name = "a soiled bandage",
        keywords = {"bandage", "wrap", "dressing", "cloth wrap", "linen"},
        portable = true,
        material = "fabric",
        reusable = true,
        initial_state = "clean",
        _state = "soiled",
        states = {
            clean = { name = "a clean linen bandage" },
            applied = { name = "an applied bandage", in_use = true },
            soiled = { name = "a soiled bandage" },
        },
        transitions = {
            {
                from = "soiled", to = "clean",
                verb = "wash",
                aliases = {"clean", "rinse", "launder"},
                requires_tool = "water_source",
                message = "You rinse the bandage in the water. The blood washes out, leaving the cloth damp but clean.",
                fail_message = "You need water to wash this.",
            },
        },
    }
end

local function make_rain_barrel(state)
    return {
        id = "rain-barrel",
        name = "a rain barrel",
        keywords = {"barrel", "rain barrel", "water barrel"},
        portable = false,
        provides_tool = "water_source",
        _state = state or "full",
        states = {
            full = { name = "a rain barrel" },
            ["half-full"] = { name = "a half-full rain barrel" },
            empty = { name = "an empty rain barrel" },
        },
        transitions = {},
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
        current_verb = opts.verb or "wash",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
        wash_target = opts.wash_target or nil,
    }
end

---------------------------------------------------------------------------
suite("#112: wash — empty noun")
---------------------------------------------------------------------------

test("wash with no noun prints prompt", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["wash"](ctx, "")
    end)
    h.assert_truthy(output:find("Wash what"),
        "Should ask what to wash")
end)

---------------------------------------------------------------------------
suite("#112: wash — soiled bandage with water source nearby")
---------------------------------------------------------------------------

test("wash soiled bandage with rain barrel in room", function()
    local bandage = make_soiled_bandage()
    local barrel = make_rain_barrel("full")

    local ctx = make_ctx({
        hands = { bandage, nil },
        room_contents = { "rain-barrel" },
    })
    ctx.registry:register("bandage", bandage)
    ctx.registry:register("rain-barrel", barrel)

    local output = capture_output(function()
        handlers["wash"](ctx, "bandage")
    end)
    h.assert_truthy(output:find("rinse") or output:find("wash") or output:find("clean"),
        "Should print wash success message")
    eq("clean", bandage._state, "Bandage should transition to clean")
end)

test("wash soiled bandage with half-full barrel", function()
    local bandage = make_soiled_bandage()
    local barrel = make_rain_barrel("half-full")

    local ctx = make_ctx({
        hands = { bandage, nil },
        room_contents = { "rain-barrel" },
    })
    ctx.registry:register("bandage", bandage)
    ctx.registry:register("rain-barrel", barrel)

    local output = capture_output(function()
        handlers["wash"](ctx, "bandage")
    end)
    eq("clean", bandage._state, "Bandage should transition to clean with half-full barrel")
end)

---------------------------------------------------------------------------
suite("#112: wash — no water source")
---------------------------------------------------------------------------

test("wash bandage without water source prints fail message", function()
    local bandage = make_soiled_bandage()

    local ctx = make_ctx({
        hands = { bandage, nil },
    })
    ctx.registry:register("bandage", bandage)

    local output = capture_output(function()
        handlers["wash"](ctx, "bandage")
    end)
    h.assert_truthy(output:find("water") or output:find("wash"),
        "Should mention needing water")
    eq("soiled", bandage._state, "Bandage should remain soiled")
end)

test("wash bandage with empty barrel prints fail message", function()
    local bandage = make_soiled_bandage()
    local barrel = make_rain_barrel("empty")

    local ctx = make_ctx({
        hands = { bandage, nil },
        room_contents = { "rain-barrel" },
    })
    ctx.registry:register("bandage", bandage)
    ctx.registry:register("rain-barrel", barrel)

    local output = capture_output(function()
        handlers["wash"](ctx, "bandage")
    end)
    h.assert_truthy(output:find("water"),
        "Should mention needing water even with empty barrel")
    eq("soiled", bandage._state, "Bandage should remain soiled with empty barrel")
end)

---------------------------------------------------------------------------
suite("#112: wash — non-washable object")
---------------------------------------------------------------------------

test("wash object without FSM wash transition", function()
    local rock = {
        id = "rock",
        name = "a rock",
        keywords = {"rock", "stone"},
        portable = true,
    }

    local ctx = make_ctx({
        hands = { rock, nil },
    })
    ctx.registry:register("rock", rock)

    local output = capture_output(function()
        handlers["wash"](ctx, "rock")
    end)
    h.assert_truthy(output:find("can't wash"),
        "Should say can't wash non-washable object")
end)

---------------------------------------------------------------------------
suite("#112: wash — object not found")
---------------------------------------------------------------------------

test("wash non-existent object prints not-found", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["wash"](ctx, "unicorn")
    end)
    h.assert_truthy(output ~= "",
        "Should print some error message for non-existent object")
end)

---------------------------------------------------------------------------
suite("#112: wash hands")
---------------------------------------------------------------------------

test("wash hands with water source cleans player", function()
    local barrel = make_rain_barrel("full")
    local ctx = make_ctx({
        room_contents = { "rain-barrel" },
        state = { bloody = true, dirty = true },
    })
    ctx.registry:register("rain-barrel", barrel)

    local output = capture_output(function()
        handlers["wash"](ctx, "hands")
    end)
    h.assert_truthy(output:find("hands") or output:find("clean") or output:find("scrub"),
        "Should print hand-washing message")
    h.assert_nil(ctx.player.state.bloody, "Bloody flag should be cleared")
    h.assert_nil(ctx.player.state.dirty, "Dirty flag should be cleared")
end)

test("wash hands without water source fails", function()
    local ctx = make_ctx({
        state = { bloody = true },
    })

    local output = capture_output(function()
        handlers["wash"](ctx, "hands")
    end)
    h.assert_truthy(output:find("water"),
        "Should mention needing water for hand washing")
end)

test("wash my hands works (possessive stripping)", function()
    local barrel = make_rain_barrel("full")
    local ctx = make_ctx({
        room_contents = { "rain-barrel" },
    })
    ctx.registry:register("rain-barrel", barrel)

    local output = capture_output(function()
        handlers["wash"](ctx, "my hands")
    end)
    h.assert_truthy(output:find("hands") or output:find("clean"),
        "Should handle 'my hands' possessive")
end)

---------------------------------------------------------------------------
suite("#112: wash — explicit 'wash X in Y' target")
---------------------------------------------------------------------------

test("wash bandage in barrel with wash_target resolves water source", function()
    local bandage = make_soiled_bandage()
    local barrel = make_rain_barrel("full")

    local ctx = make_ctx({
        hands = { bandage, nil },
        room_contents = { "rain-barrel" },
        wash_target = "barrel",
    })
    ctx.registry:register("bandage", bandage)
    ctx.registry:register("rain-barrel", barrel)

    local output = capture_output(function()
        handlers["wash"](ctx, "bandage")
    end)
    eq("clean", bandage._state, "Bandage should be clean after washing in barrel")
end)

test("wash bandage in non-water-source rejects", function()
    local bandage = make_soiled_bandage()
    local crate = {
        id = "crate",
        name = "a wooden crate",
        keywords = {"crate"},
        portable = false,
    }

    local ctx = make_ctx({
        hands = { bandage, nil },
        room_contents = { "crate" },
        wash_target = "crate",
    })
    ctx.registry:register("bandage", bandage)
    ctx.registry:register("crate", crate)

    local output = capture_output(function()
        handlers["wash"](ctx, "bandage")
    end)
    h.assert_truthy(output:find("water source") or output:find("water"),
        "Should reject non-water target")
    eq("soiled", bandage._state, "Bandage should remain soiled")
end)

h.summary()
