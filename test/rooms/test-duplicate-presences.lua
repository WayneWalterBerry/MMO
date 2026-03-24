-- test/rooms/test-duplicate-presences.lua
-- BUG-050 regression: objects already described in room.description should NOT
-- also display their room_presence text. Objects declare their presence via
-- room_presence, but rooms that mention them in .description can list those
-- object IDs in .embedded_presences to suppress the double display.
--
-- Usage: lua test/rooms/test-duplicate-presences.lua
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
    }
end

local function make_ctx(objects, room_data)
    local reg = make_registry(objects)
    return {
        registry = reg,
        current_room = room_data,
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
    }
end

---------------------------------------------------------------------------
-- Test objects
---------------------------------------------------------------------------

local function make_torch()
    return {
        id = "torch-1", name = "a lit torch",
        keywords = {"torch"},
        room_presence = "Torches burn in iron brackets along the walls.",
        casts_light = true,
    }
end

local function make_table_obj()
    return {
        id = "side-table", name = "a polished side table",
        keywords = {"table", "side table"},
        room_presence = "A polished oak side table stands between the portraits.",
    }
end

local function make_portrait()
    return {
        id = "portrait-1", name = "a stern portrait",
        keywords = {"portrait"},
        room_presence = "Stern-faced portraits line the walls.",
    }
end

---------------------------------------------------------------------------
-- Suite 1: embedded_presences suppresses duplicate display
---------------------------------------------------------------------------
h.suite("BUG-050: embedded_presences suppresses duplicate display")

test("object in embedded_presences is NOT shown in room presences", function()
    local torch = make_torch()
    local tbl = make_table_obj()
    local objects = { ["torch-1"] = torch, ["side-table"] = tbl }

    local room = {
        id = "test-hallway", name = "Test Hallway",
        description = "A corridor lit by torches in iron brackets.",
        contents = {"torch-1", "side-table"},
        exits = {},
        embedded_presences = { "torch-1" },
    }
    local ctx = make_ctx(objects, room)

    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)

    -- Torch is in embedded_presences → its room_presence should NOT appear
    eq(nil, output:find("Torches burn in iron brackets along the walls"),
        "Torch room_presence should be suppressed. Output: " .. output)
end)

test("object NOT in embedded_presences still shows room_presence", function()
    local torch = make_torch()
    local tbl = make_table_obj()
    local objects = { ["torch-1"] = torch, ["side-table"] = tbl }

    local room = {
        id = "test-hallway", name = "Test Hallway",
        description = "A corridor lit by torches in iron brackets.",
        contents = {"torch-1", "side-table"},
        exits = {},
        embedded_presences = { "torch-1" },
    }
    local ctx = make_ctx(objects, room)

    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)

    -- Side table is NOT in embedded_presences → should still show
    truthy(output:find("polished oak side table"),
        "Side table room_presence should appear. Output: " .. output)
end)

test("room without embedded_presences shows all presences normally", function()
    local torch = make_torch()
    local tbl = make_table_obj()
    local objects = { ["torch-1"] = torch, ["side-table"] = tbl }

    local room = {
        id = "test-room", name = "Test Room",
        description = "A plain room.",
        contents = {"torch-1", "side-table"},
        exits = {},
    }
    local ctx = make_ctx(objects, room)

    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)

    truthy(output:find("Torches burn"),
        "Torch presence should appear when no embedded_presences. Output: " .. output)
    truthy(output:find("polished oak side table"),
        "Table presence should appear. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 2: multiple objects in embedded_presences
---------------------------------------------------------------------------
h.suite("BUG-050: multiple embedded_presences")

test("all embedded objects suppressed, non-embedded show", function()
    local torch = make_torch()
    local portrait = make_portrait()
    local tbl = make_table_obj()
    local objects = {
        ["torch-1"] = torch,
        ["portrait-1"] = portrait,
        ["side-table"] = tbl,
    }

    local room = {
        id = "hallway", name = "The Manor Hallway",
        description = "A corridor lit by torches. Portraits line the walls.",
        contents = {"torch-1", "portrait-1", "side-table"},
        exits = {},
        embedded_presences = { "torch-1", "portrait-1" },
    }
    local ctx = make_ctx(objects, room)

    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)

    eq(nil, output:find("Torches burn"),
        "Torch room_presence should be suppressed. Output: " .. output)
    eq(nil, output:find("Stern%-faced portraits"),
        "Portrait room_presence should be suppressed. Output: " .. output)
    truthy(output:find("polished oak side table"),
        "Table room_presence should appear. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 3: duplicate object IDs in room.contents
---------------------------------------------------------------------------
h.suite("BUG-050: duplicate IDs in room.contents")

test("same object ID twice in contents only shows presence once", function()
    local tbl = make_table_obj()
    -- Need a light source so the look handler doesn't show darkness message
    local candle = {
        id = "candle", name = "a candle",
        keywords = {"candle"},
        casts_light = true,
        hidden = true,
    }
    local objects = { ["side-table"] = tbl, ["candle"] = candle }

    local room = {
        id = "test-room", name = "Test Room",
        description = "A room.",
        contents = {"candle", "side-table", "side-table"},  -- duplicate!
        exits = {},
    }
    local ctx = make_ctx(objects, room)

    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)

    -- Count occurrences of the presence text
    local count = 0
    for _ in output:gmatch("polished oak side table") do count = count + 1 end
    eq(1, count, "Table presence should appear exactly once, not twice. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 4: room description still displays
---------------------------------------------------------------------------
h.suite("BUG-050: room description unaffected")

test("room description text always appears", function()
    local torch = make_torch()
    local objects = { ["torch-1"] = torch }

    local room = {
        id = "hallway", name = "Hallway",
        description = "A corridor lit by torches in iron brackets.",
        contents = {"torch-1"},
        exits = {},
        embedded_presences = { "torch-1" },
    }
    local ctx = make_ctx(objects, room)

    local output = capture_output(function()
        handlers["look"](ctx, "")
    end)

    truthy(output:find("A corridor lit by torches in iron brackets"),
        "Room description should still appear. Output: " .. output)
end)

os.exit(h.summary() > 0 and 1 or 0)
