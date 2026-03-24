-- test/verbs/test-engine-hooks-101.lua
-- Tests for on_enter_room, on_exit_room, on_pickup, on_drop hooks (#101).
--
-- Pattern follows on_wear / on_remove_worn / on_open / on_close hooks:
--   1. Callback fires after action succeeds: obj.on_X(obj, ctx)
--   2. event_output.on_X one-shot flavor text
--   3. Objects without hooks work normally (no error)
--
-- Usage: lua test/verbs/test-engine-hooks-101.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function capture_output(fn)
    local captured = {}
    local old_print = print
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

local function make_registry(objects)
    return {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
        remove = function(self, id) self._objects[id] = nil end,
        register = function(self, id, obj)
            self._objects[id] = obj
            if obj then obj.id = id end
        end,
    }
end

local function make_ctx(objects, room_contents, room_overrides)
    local reg = make_registry(objects)
    local room = {
        id = "test-room", name = "Test Room",
        description = "A plain room.",
        contents = room_contents or {},
        exits = {},
    }
    if room_overrides then
        for k, v in pairs(room_overrides) do room[k] = v end
    end
    objects["test-room"] = room
    return {
        registry = reg,
        current_room = room,
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- Suite 1: on_pickup callback
---------------------------------------------------------------------------
h.suite("on_pickup hook: callback fires on successful take")

test("on_pickup fires when item is taken", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
    }
    local hook_fired = false
    candle.on_pickup = function(obj, ctx)
        hook_fired = true
    end
    local ctx = make_ctx({ ["candle"] = candle }, {"candle"})

    capture_output(function()
        handlers["take"](ctx, "candle")
    end)

    truthy(hook_fired, "on_pickup callback should have fired")
end)

test("on_pickup receives correct object and context", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
    }
    local received_obj, received_ctx
    candle.on_pickup = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local ctx = make_ctx({ ["candle"] = candle }, {"candle"})

    capture_output(function()
        handlers["take"](ctx, "candle")
    end)

    eq("candle", received_obj.id, "on_pickup should receive the object")
    truthy(received_ctx.registry, "on_pickup should receive the context")
end)

test("take item WITHOUT on_pickup works without error", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
    }
    local ctx = make_ctx({ ["candle"] = candle }, {"candle"})

    local output = capture_output(function()
        handlers["take"](ctx, "candle")
    end)

    truthy(output:find("You take"), "Normal take message should appear. Output: " .. output)
end)

test("on_pickup fires with event_output.on_take together", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
        event_output = {
            on_take = "It's heavier than it looks.",
        },
    }
    local hook_fired = false
    candle.on_pickup = function(obj, ctx) hook_fired = true end
    local ctx = make_ctx({ ["candle"] = candle }, {"candle"})

    local output = capture_output(function()
        handlers["take"](ctx, "candle")
    end)

    truthy(hook_fired, "on_pickup should fire alongside event_output")
    truthy(output:find("heavier than it looks"), "event_output.on_take should also appear")
end)

test("event_output.on_take is one-shot (nil after first take)", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
        event_output = {
            on_take = "It's heavier than it looks.",
        },
    }
    local ctx = make_ctx({ ["candle"] = candle }, {"candle"})

    capture_output(function()
        handlers["take"](ctx, "candle")
    end)

    eq(nil, candle.event_output["on_take"],
        "on_take should be nil after first take")
end)

---------------------------------------------------------------------------
-- Suite 2: on_drop callback
---------------------------------------------------------------------------
h.suite("on_drop hook: callback fires on successful drop")

test("on_drop fires when item is dropped", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
    }
    local hook_fired = false
    candle.on_drop = function(obj, ctx)
        hook_fired = true
    end
    local objects = { ["candle"] = candle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = candle
    candle.location = "player"

    capture_output(function()
        handlers["drop"](ctx, "candle")
    end)

    truthy(hook_fired, "on_drop callback should have fired")
end)

test("on_drop receives correct object and context", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
    }
    local received_obj, received_ctx
    candle.on_drop = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local objects = { ["candle"] = candle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = candle
    candle.location = "player"

    capture_output(function()
        handlers["drop"](ctx, "candle")
    end)

    eq("candle", received_obj.id, "on_drop should receive the object")
    truthy(received_ctx.registry, "on_drop should receive the context")
end)

test("drop item WITHOUT on_drop works without error", function()
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true,
        on_feel = "Waxy cylinder.",
    }
    local objects = { ["candle"] = candle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = candle
    candle.location = "player"

    local output = capture_output(function()
        handlers["drop"](ctx, "candle")
    end)

    truthy(output:find("You drop"), "Normal drop message should appear. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 3: on_enter_room callback
---------------------------------------------------------------------------
h.suite("on_enter_room hook: callback fires on room entry")

test("on_enter_room fires when player enters room", function()
    local hook_fired = false
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
        on_enter_room = function(room, ctx)
            hook_fired = true
        end,
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    capture_output(function()
        handlers["go"](ctx, "north")
    end)

    truthy(hook_fired, "on_enter_room callback should have fired")
    eq("hallway", ctx.current_room.id, "Player should be in hallway")
end)

test("on_enter_room receives correct room and context", function()
    local received_room, received_ctx
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
        on_enter_room = function(room, ctx)
            received_room = room
            received_ctx = ctx
        end,
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    capture_output(function()
        handlers["go"](ctx, "north")
    end)

    eq("hallway", received_room.id, "on_enter_room should receive target room")
    truthy(received_ctx.registry, "on_enter_room should receive the context")
end)

test("room WITHOUT on_enter_room works without error", function()
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    local output = capture_output(function()
        handlers["go"](ctx, "north")
    end)

    truthy(output:find("arrive") or output:find("Hallway"),
        "Normal movement should work. Output: " .. output)
end)

test("event_output.on_enter_room fires one-shot", function()
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
        event_output = {
            on_enter_room = "A chill runs down your spine.",
        },
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    local output = capture_output(function()
        handlers["go"](ctx, "north")
    end)

    truthy(output:find("chill runs down"),
        "event_output.on_enter_room text should appear. Output: " .. output)
    eq(nil, target_room.event_output["on_enter_room"],
        "on_enter_room should be nil after first entry")
end)

---------------------------------------------------------------------------
-- Suite 4: on_exit_room callback
---------------------------------------------------------------------------
h.suite("on_exit_room hook: callback fires on room exit")

test("on_exit_room fires when player leaves room", function()
    local hook_fired = false
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
        on_exit_room = function(room, ctx)
            hook_fired = true
        end,
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    capture_output(function()
        handlers["go"](ctx, "north")
    end)

    truthy(hook_fired, "on_exit_room callback should have fired")
end)

test("on_exit_room receives correct room and context", function()
    local received_room, received_ctx
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
        on_exit_room = function(room, ctx)
            received_room = room
            received_ctx = ctx
        end,
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    capture_output(function()
        handlers["go"](ctx, "north")
    end)

    eq("bedroom", received_room.id, "on_exit_room should receive the old room")
    truthy(received_ctx.registry, "on_exit_room should receive the context")
end)

test("event_output.on_exit_room fires one-shot", function()
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
        event_output = {
            on_exit_room = "You feel a pang of regret leaving.",
        },
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    local output = capture_output(function()
        handlers["go"](ctx, "north")
    end)

    truthy(output:find("pang of regret"),
        "event_output.on_exit_room text should appear. Output: " .. output)
    eq(nil, start_room.event_output["on_exit_room"],
        "on_exit_room should be nil after first exit")
end)

---------------------------------------------------------------------------
-- Suite 5: hooks fire in correct order (exit → enter)
---------------------------------------------------------------------------
h.suite("Hook ordering: on_exit_room fires before on_enter_room")

test("on_exit_room fires before on_enter_room during movement", function()
    local order = {}
    local target_room = {
        id = "hallway", name = "Hallway",
        description = "A long hallway.",
        contents = {},
        exits = {},
        on_enter_room = function(room, ctx)
            order[#order + 1] = "enter"
        end,
    }
    local start_room = {
        id = "bedroom", name = "Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {
            north = { target = "hallway", open = true, name = "a doorway" },
        },
        on_exit_room = function(room, ctx)
            order[#order + 1] = "exit"
        end,
    }
    local objects = {
        ["bedroom"] = start_room,
        ["hallway"] = target_room,
    }
    local reg = make_registry(objects)
    local ctx = {
        registry = reg,
        current_room = start_room,
        rooms = { ["bedroom"] = start_room, ["hallway"] = target_room },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {}, location = "bedroom", visited_rooms = {} },
        injuries = {},
        object_sources = {},
        templates = {},
        verbs = handlers,
        
    }

    capture_output(function()
        handlers["go"](ctx, "north")
    end)

    eq(2, #order, "Both hooks should fire")
    eq("exit", order[1], "on_exit_room should fire first")
    eq("enter", order[2], "on_enter_room should fire second")
end)

os.exit(h.summary() > 0 and 1 or 0)
