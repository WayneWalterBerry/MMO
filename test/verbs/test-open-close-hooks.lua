-- test/verbs/test-open-close-hooks.lua
-- Tests for on_open / on_close hooks and event_output support (#103).
--
-- Pattern follows on_wear / on_remove_worn hooks:
--   1. on_open callback fires after successful FSM open transition
--   2. on_close callback fires after successful FSM close transition
--   3. event_output.on_open one-shot flavor text
--   4. event_output.on_close one-shot flavor text
--   5. Failed open/close do NOT fire hooks
--
-- Usage: lua test/verbs/test-open-close-hooks.lua
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

local function make_openable_chest()
    return {
        id = "chest", name = "a wooden chest",
        keywords = {"chest", "wooden chest"},
        _state = "closed",
        states = {
            closed = { description = "A heavy wooden chest, firmly shut." },
            open   = { description = "The chest lies open, revealing its interior." },
        },
        transitions = {
            { from = "closed", to = "open",   verb = "open",  message = "You heave open the heavy lid." },
            { from = "open",   to = "closed", verb = "close", message = "You lower the lid back into place." },
        },
    }
end

local function make_ctx(objects, room_contents)
    local reg = make_registry(objects)
    return {
        registry = reg,
        current_room = {
            id = "test-room", name = "Test Room",
            description = "A plain room.",
            contents = room_contents or {},
            exits = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
        object_sources = {},
        templates = {},
    }
end

---------------------------------------------------------------------------
-- Suite 1: on_open callback
---------------------------------------------------------------------------
h.suite("on_open hook: callback fires on successful open")

test("on_open fires when chest is opened", function()
    local chest = make_openable_chest()
    local hook_fired = false
    chest.on_open = function(obj, ctx)
        hook_fired = true
    end
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    truthy(hook_fired, "on_open callback should have fired")
    eq("open", chest._state, "Chest should be in 'open' state")
end)

test("on_open receives correct object and context", function()
    local chest = make_openable_chest()
    local received_obj, received_ctx
    chest.on_open = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    eq("chest", received_obj.id, "on_open should receive the object")
    truthy(received_ctx.registry, "on_open should receive the context")
end)

test("on_open does NOT fire when object is already open", function()
    local chest = make_openable_chest()
    chest._state = "open"  -- already open
    local hook_fired = false
    chest.on_open = function() hook_fired = true end
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    eq(false, hook_fired, "on_open should NOT fire when already open")
end)

---------------------------------------------------------------------------
-- Suite 2: on_close callback
---------------------------------------------------------------------------
h.suite("on_close hook: callback fires on successful close")

test("on_close fires when chest is closed", function()
    local chest = make_openable_chest()
    chest._state = "open"
    local hook_fired = false
    chest.on_close = function(obj, ctx)
        hook_fired = true
    end
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    truthy(hook_fired, "on_close callback should have fired")
    eq("closed", chest._state, "Chest should be in 'closed' state")
end)

test("on_close receives correct object and context", function()
    local chest = make_openable_chest()
    chest._state = "open"
    local received_obj, received_ctx
    chest.on_close = function(obj, ctx)
        received_obj = obj
        received_ctx = ctx
    end
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    eq("chest", received_obj.id, "on_close should receive the object")
    truthy(received_ctx.registry, "on_close should receive the context")
end)

test("on_close does NOT fire when object is already closed", function()
    local chest = make_openable_chest()
    chest._state = "closed"
    local hook_fired = false
    chest.on_close = function() hook_fired = true end
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    eq(false, hook_fired, "on_close should NOT fire when already closed")
end)

---------------------------------------------------------------------------
-- Suite 3: event_output.on_open one-shot
---------------------------------------------------------------------------
h.suite("event_output: on_open fires once")

test("open chest prints event_output.on_open flavor text", function()
    local chest = make_openable_chest()
    chest.event_output = {
        on_open = "A musty waft of stale air escapes the chest.",
    }
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    truthy(output:find("musty waft"),
        "event_output.on_open text should appear. Output: " .. output)
end)

test("event_output.on_open is nil'd after first open", function()
    local chest = make_openable_chest()
    chest.event_output = {
        on_open = "A musty waft of stale air escapes the chest.",
    }
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    eq(nil, chest.event_output["on_open"],
        "on_open should be nil after first open")
end)

test("open chest AGAIN produces no event_output text", function()
    local chest = make_openable_chest()
    chest.event_output = {
        on_open = "A musty waft of stale air escapes the chest.",
    }
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    -- First open: consume the event
    capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    -- Close it again
    capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    -- Second open: no event_output
    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    eq(nil, output:find("musty waft"),
        "event_output.on_open should NOT fire again. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 4: event_output.on_close one-shot
---------------------------------------------------------------------------
h.suite("event_output: on_close fires once")

test("close chest prints event_output.on_close flavor text", function()
    local chest = make_openable_chest()
    chest._state = "open"
    chest.event_output = {
        on_close = "The lid slams shut with a hollow boom.",
    }
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    local output = capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    truthy(output:find("hollow boom"),
        "event_output.on_close text should appear. Output: " .. output)
end)

test("event_output.on_close is nil'd after first close", function()
    local chest = make_openable_chest()
    chest._state = "open"
    chest.event_output = {
        on_close = "The lid slams shut with a hollow boom.",
    }
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    eq(nil, chest.event_output["on_close"],
        "on_close should be nil after first close")
end)

---------------------------------------------------------------------------
-- Suite 5: both hooks + event_output fire independently
---------------------------------------------------------------------------
h.suite("on_open + on_close: independent firing")

test("on_open and on_close fire independently on same object", function()
    local chest = make_openable_chest()
    local open_count = 0
    local close_count = 0
    chest.on_open = function() open_count = open_count + 1 end
    chest.on_close = function() close_count = close_count + 1 end
    chest.event_output = {
        on_open = "Stale air.",
        on_close = "Thud.",
    }
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    -- Open
    local out1 = capture_output(function()
        handlers["open"](ctx, "chest")
    end)
    eq(1, open_count, "on_open should fire once")
    eq(0, close_count, "on_close should not fire on open")
    truthy(out1:find("Stale air"), "on_open event_output should appear")

    -- Close
    local out2 = capture_output(function()
        handlers["close"](ctx, "chest")
    end)
    eq(1, open_count, "on_open count unchanged after close")
    eq(1, close_count, "on_close should fire once")
    truthy(out2:find("Thud"), "on_close event_output should appear")
end)

---------------------------------------------------------------------------
-- Suite 6: object without hooks works normally
---------------------------------------------------------------------------
h.suite("on_open/on_close: objects without hooks")

test("open object without on_open works without error", function()
    local chest = make_openable_chest()
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    local output = capture_output(function()
        handlers["open"](ctx, "chest")
    end)

    truthy(output:find("heave open"),
        "Normal open message should appear. Output: " .. output)
end)

test("close object without on_close works without error", function()
    local chest = make_openable_chest()
    chest._state = "open"
    local ctx = make_ctx({ ["chest"] = chest }, {"chest"})

    local output = capture_output(function()
        handlers["close"](ctx, "chest")
    end)

    truthy(output:find("lower the lid"),
        "Normal close message should appear. Output: " .. output)
end)

os.exit(h.summary() > 0 and 1 or 0)
