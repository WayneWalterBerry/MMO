-- test/verbs/test-engine-hooks-102.lua
-- Tests for on_eat, on_drink, on_use hooks (#102).
--
-- Pattern follows on_pickup / on_drop / on_wear hooks:
--   1. Callback fires after action succeeds: obj.on_X(obj, ctx)
--   2. event_output.on_X one-shot flavor text
--   3. Objects without hooks work normally (no error)
--
-- on_wear / on_remove_worn already shipped in Phase A6 (equipment.lua).
--
-- Usage: lua test/verbs/test-engine-hooks-102.lua
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
-- Suite 1: on_eat callback
---------------------------------------------------------------------------
h.suite("on_eat hook: callback fires on successful eat")

test("on_eat fires when edible item is eaten", function()
    local bread = {
        id = "bread", name = "a piece of bread",
        keywords = {"bread"},
        edible = true,
        on_feel = "Crusty surface.",
    }
    local hook_fired = false
    bread.on_eat = function(obj, ctx)
        hook_fired = true
    end
    local ctx = make_ctx({ ["bread"] = bread }, {"bread"})

    capture_output(function()
        handlers["eat"](ctx, "bread")
    end)

    truthy(hook_fired, "on_eat callback should have fired")
end)

test("on_eat receives correct object and context", function()
    local bread = {
        id = "bread", name = "a piece of bread",
        keywords = {"bread"},
        edible = true,
        on_feel = "Crusty surface.",
    }
    local received_obj, received_ctx
    bread.on_eat = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local ctx = make_ctx({ ["bread"] = bread }, {"bread"})

    capture_output(function()
        handlers["eat"](ctx, "bread")
    end)

    eq("bread", received_obj.id, "on_eat should receive the object")
    truthy(received_ctx.registry, "on_eat should receive the context")
end)

test("eat edible item WITHOUT on_eat works without error", function()
    local bread = {
        id = "bread", name = "a piece of bread",
        keywords = {"bread"},
        edible = true,
        on_feel = "Crusty surface.",
    }
    local ctx = make_ctx({ ["bread"] = bread }, {"bread"})

    local output = capture_output(function()
        handlers["eat"](ctx, "bread")
    end)

    truthy(output:find("You eat"), "Normal eat message should appear. Output: " .. output)
end)

test("on_eat fires with event_output.on_eat together", function()
    local bread = {
        id = "bread", name = "a piece of bread",
        keywords = {"bread"},
        edible = true,
        on_feel = "Crusty surface.",
        event_output = {
            on_eat = "It tastes stale but filling.",
        },
    }
    local hook_fired = false
    bread.on_eat = function(obj, ctx) hook_fired = true end
    local ctx = make_ctx({ ["bread"] = bread }, {"bread"})

    local output = capture_output(function()
        handlers["eat"](ctx, "bread")
    end)

    truthy(hook_fired, "on_eat should fire alongside event_output")
    truthy(output:find("stale but filling"), "event_output.on_eat should also appear")
end)

test("event_output.on_eat is one-shot (nil after first eat)", function()
    local bread = {
        id = "bread", name = "a piece of bread",
        keywords = {"bread"},
        edible = true,
        on_feel = "Crusty surface.",
        event_output = {
            on_eat = "It tastes stale but filling.",
        },
    }
    local ctx = make_ctx({ ["bread"] = bread }, {"bread"})

    capture_output(function()
        handlers["eat"](ctx, "bread")
    end)

    eq(nil, bread.event_output["on_eat"],
        "on_eat should be nil after first eat")
end)

test("eat from inventory fires on_eat", function()
    local bread = {
        id = "bread", name = "a piece of bread",
        keywords = {"bread"},
        edible = true,
        on_feel = "Crusty surface.",
    }
    local hook_fired = false
    bread.on_eat = function(obj, ctx) hook_fired = true end
    local objects = { ["bread"] = bread }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = bread
    bread.location = "player"

    capture_output(function()
        handlers["eat"](ctx, "bread")
    end)

    truthy(hook_fired, "on_eat callback should fire for inventory item")
end)

---------------------------------------------------------------------------
-- Suite 2: on_drink callback
---------------------------------------------------------------------------
h.suite("on_drink hook: callback fires on successful drink (FSM path)")

test("on_drink fires when FSM drink transition succeeds", function()
    local bottle = {
        id = "bottle", name = "a water bottle",
        keywords = {"bottle"},
        on_feel = "Smooth glass.",
        initial_state = "full",
        _state = "full",
        states = {
            full = { description = "A bottle full of water." },
            empty = { description = "An empty bottle." },
        },
        transitions = {
            { from = "full", to = "empty", verb = "drink",
              message = "You drink the water." },
        },
    }
    local hook_fired = false
    bottle.on_drink = function(obj, ctx)
        hook_fired = true
    end
    local objects = { ["bottle"] = bottle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = bottle
    bottle.location = "player"

    capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)

    truthy(hook_fired, "on_drink callback should have fired")
end)

test("on_drink receives correct object and context", function()
    local bottle = {
        id = "bottle", name = "a water bottle",
        keywords = {"bottle"},
        on_feel = "Smooth glass.",
        initial_state = "full",
        _state = "full",
        states = {
            full = { description = "A bottle full of water." },
            empty = { description = "An empty bottle." },
        },
        transitions = {
            { from = "full", to = "empty", verb = "drink",
              message = "You drink the water." },
        },
    }
    local received_obj, received_ctx
    bottle.on_drink = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local objects = { ["bottle"] = bottle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = bottle
    bottle.location = "player"

    capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)

    eq("bottle", received_obj.id, "on_drink should receive the object")
    truthy(received_ctx.registry, "on_drink should receive the context")
end)

test("drink WITHOUT on_drink works without error", function()
    local bottle = {
        id = "bottle", name = "a water bottle",
        keywords = {"bottle"},
        on_feel = "Smooth glass.",
        initial_state = "full",
        _state = "full",
        states = {
            full = { description = "A bottle full of water." },
            empty = { description = "An empty bottle." },
        },
        transitions = {
            { from = "full", to = "empty", verb = "drink",
              message = "You drink the water." },
        },
    }
    local objects = { ["bottle"] = bottle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = bottle
    bottle.location = "player"

    local output = capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)

    truthy(output:find("You drink"), "Normal drink message should appear. Output: " .. output)
end)

test("on_drink fires with event_output.on_drink together", function()
    local bottle = {
        id = "bottle", name = "a water bottle",
        keywords = {"bottle"},
        on_feel = "Smooth glass.",
        initial_state = "full",
        _state = "full",
        states = {
            full = { description = "A bottle full of water." },
            empty = { description = "An empty bottle." },
        },
        transitions = {
            { from = "full", to = "empty", verb = "drink",
              message = "You drink the water." },
        },
        event_output = {
            on_drink = "Refreshing!",
        },
    }
    local hook_fired = false
    bottle.on_drink = function(obj, ctx) hook_fired = true end
    local objects = { ["bottle"] = bottle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = bottle
    bottle.location = "player"

    local output = capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)

    truthy(hook_fired, "on_drink should fire alongside event_output")
    truthy(output:find("Refreshing"), "event_output.on_drink should also appear")
end)

test("event_output.on_drink is one-shot (nil after first drink)", function()
    local bottle = {
        id = "bottle", name = "a water bottle",
        keywords = {"bottle"},
        on_feel = "Smooth glass.",
        initial_state = "full",
        _state = "full",
        states = {
            full = { description = "A bottle full of water." },
            empty = { description = "An empty bottle." },
        },
        transitions = {
            { from = "full", to = "empty", verb = "drink",
              message = "You drink the water." },
        },
        event_output = {
            on_drink = "Refreshing!",
        },
    }
    local objects = { ["bottle"] = bottle }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = bottle
    bottle.location = "player"

    capture_output(function()
        handlers["drink"](ctx, "bottle")
    end)

    eq(nil, bottle.event_output["on_drink"],
        "on_drink should be nil after first drink")
end)

---------------------------------------------------------------------------
-- Suite 3: on_use callback
---------------------------------------------------------------------------
h.suite("on_use hook: callback fires on generic 'use X'")

test("on_use fires when object has callback", function()
    local widget = {
        id = "widget", name = "a strange widget",
        keywords = {"widget"},
        on_feel = "Cold metal with bumps.",
    }
    local hook_fired = false
    widget.on_use = function(obj, ctx)
        hook_fired = true
    end
    local ctx = make_ctx({ ["widget"] = widget }, {"widget"})

    capture_output(function()
        handlers["use"](ctx, "widget")
    end)

    truthy(hook_fired, "on_use callback should have fired")
end)

test("on_use receives correct object and context", function()
    local widget = {
        id = "widget", name = "a strange widget",
        keywords = {"widget"},
        on_feel = "Cold metal with bumps.",
    }
    local received_obj, received_ctx
    widget.on_use = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local ctx = make_ctx({ ["widget"] = widget }, {"widget"})

    capture_output(function()
        handlers["use"](ctx, "widget")
    end)

    eq("widget", received_obj.id, "on_use should receive the object")
    truthy(received_ctx.registry, "on_use should receive the context")
end)

test("use object WITHOUT on_use prints fallback message", function()
    local rock = {
        id = "rock", name = "a plain rock",
        keywords = {"rock"},
        on_feel = "Rough and heavy.",
    }
    local ctx = make_ctx({ ["rock"] = rock }, {"rock"})

    local output = capture_output(function()
        handlers["use"](ctx, "rock")
    end)

    truthy(output:find("don't know how to use"), "Fallback message should appear. Output: " .. output)
end)

test("on_use fires with event_output.on_use together", function()
    local widget = {
        id = "widget", name = "a strange widget",
        keywords = {"widget"},
        on_feel = "Cold metal with bumps.",
        event_output = {
            on_use = "It clicks and whirrs.",
        },
    }
    local hook_fired = false
    widget.on_use = function(obj, ctx) hook_fired = true end
    local ctx = make_ctx({ ["widget"] = widget }, {"widget"})

    local output = capture_output(function()
        handlers["use"](ctx, "widget")
    end)

    truthy(hook_fired, "on_use should fire alongside event_output")
    truthy(output:find("clicks and whirrs"), "event_output.on_use should also appear")
end)

test("event_output.on_use is one-shot (nil after first use)", function()
    local widget = {
        id = "widget", name = "a strange widget",
        keywords = {"widget"},
        on_feel = "Cold metal with bumps.",
        event_output = {
            on_use = "It clicks and whirrs.",
        },
    }
    local ctx = make_ctx({ ["widget"] = widget }, {"widget"})

    capture_output(function()
        handlers["use"](ctx, "widget")
    end)

    eq(nil, widget.event_output["on_use"],
        "on_use should be nil after first use")
end)

test("event_output.on_use alone (no callback) fires correctly", function()
    local widget = {
        id = "widget", name = "a strange widget",
        keywords = {"widget"},
        on_feel = "Cold metal with bumps.",
        event_output = {
            on_use = "A puff of smoke appears.",
        },
    }
    local ctx = make_ctx({ ["widget"] = widget }, {"widget"})

    local output = capture_output(function()
        handlers["use"](ctx, "widget")
    end)

    truthy(output:find("puff of smoke"), "event_output.on_use should print. Output: " .. output)
end)

test("use from inventory fires on_use", function()
    local widget = {
        id = "widget", name = "a strange widget",
        keywords = {"widget"},
        on_feel = "Cold metal with bumps.",
    }
    local hook_fired = false
    widget.on_use = function(obj, ctx) hook_fired = true end
    local objects = { ["widget"] = widget }
    local ctx = make_ctx(objects, {})
    ctx.player.hands[1] = widget
    widget.location = "player"

    capture_output(function()
        handlers["use"](ctx, "widget")
    end)

    truthy(hook_fired, "on_use callback should fire for inventory item")
end)

test("use with empty noun prints prompt", function()
    local ctx = make_ctx({}, {})

    local output = capture_output(function()
        handlers["use"](ctx, "")
    end)

    truthy(output:find("Use what"), "Should prompt for noun. Output: " .. output)
end)

test("use nonexistent object prints not found", function()
    local ctx = make_ctx({}, {})

    local output = capture_output(function()
        handlers["use"](ctx, "nonexistent")
    end)

    truthy(output:find("don't see") or output:find("[Nn]othing") or output:find("[Cc]an't find") or output:find("don't notice"),
        "Should print not-found message. Output: " .. output)
end)

os.exit(h.summary() > 0 and 1 or 0)
