-- test/verbs/test-linked-exit-sync.lua
-- Tests that FSM transitions on objects with linked_exit sync the exit state.
-- When bedroom-door (object) is broken, the north exit should become open+unlocked.
-- When window (object) is opened, the window exit should become open+unlocked.
--
-- Usage: lua test/verbs/test-linked-exit-sync.lua
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
        exits = opts.exits or {},
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
        current_verb = opts.verb or "break",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- Break door → linked exit sync
---------------------------------------------------------------------------
suite("linked_exit sync: break door updates north exit")

test("break door with linked_exit syncs exit to open+unlocked", function()
    local door_obj = {
        id = "bedroom-door",
        name = "a heavy oak door",
        keywords = {"door", "oak door"},
        material = "oak",
        _state = "barred",
        initial_state = "barred",
        linked_exit = "north",
        linked_passage_id = "bedroom-hallway-door",
        states = {
            barred = { name = "a heavy oak door", description = "Barred." },
            broken = { name = "a splintered doorframe", description = "Broken." },
        },
        transitions = {
            { from = "barred", to = "broken", verb = "break",
              message = "The door bursts inward!" },
        },
    }

    local exit = {
        target = "hallway",
        type = "door",
        passage_id = "bedroom-hallway-door",
        name = "a heavy oak door",
        keywords = {"door"},
        open = false,
        locked = true,
        breakable = true,
        mutations = {
            ["break"] = {
                becomes_exit = {
                    open = true,
                    locked = false,
                    broken = true,
                    name = "a splintered doorframe",
                },
                message = "The door bursts inward!",
            },
        },
    }

    local ctx = make_ctx({
        exits = { north = exit },
        room_contents = { "bedroom-door" },
    })
    ctx.registry:register("bedroom-door", door_obj)

    local output = capture_output(function()
        handlers["break"](ctx, "door")
    end)

    eq(true, ctx.current_room.exits.north.open,
        "Exit should be open after break with linked_exit")
    eq(false, ctx.current_room.exits.north.locked,
        "Exit should be unlocked after break with linked_exit")
    eq(true, ctx.current_room.exits.north.broken,
        "Exit should be broken after break with linked_exit")
end)

---------------------------------------------------------------------------
-- Open window → linked exit sync
---------------------------------------------------------------------------
suite("linked_exit sync: open window updates window exit")

test("open window with linked_exit syncs exit to open", function()
    local window_obj = {
        id = "window",
        name = "a leaded glass window",
        keywords = {"window", "glass"},
        material = "glass",
        _state = "closed",
        initial_state = "closed",
        linked_exit = "window",
        linked_passage_id = "bedroom-courtyard-window",
        states = {
            closed = { name = "a leaded glass window", description = "Latched shut." },
            open = { name = "an open window", description = "Open to the courtyard." },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open",
              message = "You unlatch and push the window open." },
        },
    }

    local exit = {
        target = "courtyard",
        type = "window",
        passage_id = "bedroom-courtyard-window",
        name = "the leaded glass window",
        keywords = {"window"},
        open = false,
        locked = true,
        mutations = {
            open = {
                becomes_exit = {
                    open = true,
                    locked = false,
                },
                message = "The window opens.",
            },
        },
    }

    local ctx = make_ctx({
        exits = { window = exit },
        room_contents = { "window" },
        verb = "open",
    })
    ctx.registry:register("window", window_obj)

    local output = capture_output(function()
        handlers["open"](ctx, "window")
    end)

    eq(true, ctx.current_room.exits.window.open,
        "Window exit should be open after opening window object")
    eq(false, ctx.current_room.exits.window.locked,
        "Window exit should be unlocked after opening window object")
end)

---------------------------------------------------------------------------
-- No linked_exit → no sync (safety)
---------------------------------------------------------------------------
suite("linked_exit sync: no linked_exit field → exit unchanged")

test("break object without linked_exit does not touch exits", function()
    local obj = {
        id = "vase",
        name = "a vase",
        keywords = {"vase"},
        _state = "intact",
        initial_state = "intact",
        states = {
            intact = { name = "a vase", description = "A vase." },
            broken = { name = "a broken vase", description = "Smashed." },
        },
        transitions = {
            { from = "intact", to = "broken", verb = "break",
              message = "The vase shatters!" },
        },
    }

    local exit = {
        target = "other-room",
        type = "door",
        name = "a door",
        keywords = {"door"},
        open = false,
        locked = true,
        breakable = true,
        mutations = {
            ["break"] = {
                becomes_exit = { open = true, locked = false },
            },
        },
    }

    local ctx = make_ctx({
        exits = { north = exit },
        room_contents = { "vase" },
    })
    ctx.registry:register("vase", obj)

    capture_output(function()
        handlers["break"](ctx, "vase")
    end)

    eq(false, ctx.current_room.exits.north.open,
        "Exit should remain closed when object has no linked_exit")
    eq(true, ctx.current_room.exits.north.locked,
        "Exit should remain locked when object has no linked_exit")
end)

h.summary()
