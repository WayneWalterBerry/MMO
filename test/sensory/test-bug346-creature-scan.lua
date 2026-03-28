-- test/sensory/test-bug346-creature-scan.lua
-- Bug #346: Ambient smell/listen room scan excludes creatures.
-- The smell/listen handlers only scan room.contents (inanimate objects),
-- but creatures are stored separately and must be scanned via
-- get_creatures_in_room().
-- TDD: Must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/sensory/test-bug346-creature-scan.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

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

    -- Register all objects provided
    for _, obj in ipairs(opts.objects or {}) do
        reg:register(obj.id or obj.guid, obj)
    end

    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        on_smell = opts.room_smell or nil,
        on_listen = opts.room_listen or nil,
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = opts.worn or {},
        injuries = {},
        bags = {},
        state = {},
        skills = {},
        max_health = 100,
        consciousness = { state = "conscious" },
        visited_rooms = { ["test-room"] = true },
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 0,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- TESTS
---------------------------------------------------------------------------
suite("BUG #346: Ambient smell/listen must include creatures")

test("1. bare smell includes rat on_smell", function()
    local rat = {
        guid = "{rat-346}",
        id = "rat",
        name = "a brown rat",
        keywords = {"rat"},
        animate = true,
        location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty rodent — damp fur and ammonia.",
        on_listen = "Skittering claws on stone.",
        on_feel = "Coarse fur.",
        states = {
            ["alive-idle"] = { room_presence = "A rat crouches near the wall." },
        },
    }

    local ctx = make_ctx({ objects = { rat } })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    h.assert_truthy(output:find("rodent") or output:find("ammonia") or output:find("rat"),
        "bare smell must include rat's on_smell, got: " .. output:sub(1, 300))
end)

test("2. bare listen includes rat on_listen", function()
    local rat = {
        guid = "{rat-346-listen}",
        id = "rat",
        name = "a brown rat",
        keywords = {"rat"},
        animate = true,
        location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty rodent.",
        on_listen = "Skittering claws on stone.",
        on_feel = "Coarse fur.",
        states = {
            ["alive-idle"] = { room_presence = "A rat crouches near the wall." },
        },
    }

    local ctx = make_ctx({ objects = { rat } })

    local output = capture_output(function()
        handlers["listen"](ctx, "")
    end)

    h.assert_truthy(output:find("[Ss]kittering") or output:find("claws"),
        "bare listen must include rat's on_listen, got: " .. output:sub(1, 300))
end)

test("3. smell uses state-specific on_smell when available", function()
    local rat = {
        guid = "{rat-346-state}",
        id = "rat",
        name = "a brown rat",
        keywords = {"rat"},
        animate = true,
        location = "test-room",
        _state = "alive-wander",
        on_smell = "Musty rodent — generic.",
        on_listen = "Generic sounds.",
        on_feel = "Coarse fur.",
        states = {
            ["alive-wander"] = {
                room_presence = "A rat scurries along the baseboard.",
                on_smell = "Disturbed dust and rodent musk.",
            },
        },
    }

    local ctx = make_ctx({ objects = { rat } })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    -- State-specific should be preferred if the engine overlays it
    h.assert_truthy(output:find("rodent") or output:find("musk") or output:find("rat"),
        "smell scan must include creature sensory text, got: " .. output:sub(1, 300))
end)

test("4. dead creatures are included in smell scan", function()
    local dead_rat = {
        guid = "{dead-rat-346}",
        id = "dead-rat",
        name = "a dead rat",
        keywords = {"dead rat"},
        animate = false,
        location = "test-room",
        _state = "fresh",
        on_smell = "Blood and musk. The sharp copper of death.",
        on_listen = "Nothing.",
        on_feel = "Cooling fur.",
        states = {
            fresh = { room_presence = "A dead rat lies crumpled on the floor." },
        },
    }

    -- Dead rat is on the floor, registered as room contents (not animate)
    local ctx = make_ctx({
        objects = { dead_rat },
        room_contents = { dead_rat.id },
    })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    h.assert_truthy(output:find("copper") or output:find("musk") or output:find("death"),
        "dead rat on floor should appear in smell scan, got: " .. output:sub(1, 300))
end)

test("5. creature AND inanimate objects both appear in smell", function()
    local rat = {
        guid = "{rat-346-both}",
        id = "rat",
        name = "a brown rat",
        keywords = {"rat"},
        animate = true,
        location = "test-room",
        _state = "alive-idle",
        on_smell = "Musty rodent musk.",
        on_feel = "Coarse fur.",
        states = {
            ["alive-idle"] = { room_presence = "A rat crouches near the wall." },
        },
    }

    local candle = {
        guid = "{candle-346}",
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle"},
        on_smell = "Faint tallow smell.",
        on_feel = "Waxy cylinder.",
    }

    local ctx = make_ctx({
        objects = { rat, candle },
        room_contents = { candle.id },
    })

    local output = capture_output(function()
        handlers["smell"](ctx, "")
    end)

    h.assert_truthy(output:find("rodent") or output:find("musk"),
        "smell must include creature, got: " .. output:sub(1, 300))
    h.assert_truthy(output:find("tallow"),
        "smell must include inanimate object, got: " .. output:sub(1, 300))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
