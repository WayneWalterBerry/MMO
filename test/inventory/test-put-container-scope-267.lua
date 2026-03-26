-- test/inventory/test-put-container-scope-267.lua
-- Regression tests for #267: put X in Y should only require holding the item,
-- not the container. The container just needs to be in scope.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local registry_mod = require("engine.registry")
local containment_mod = require("engine.containment")
local verbs_mod = require("engine.verbs")

local test = h.test
local eq   = h.assert_eq

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    fn()
    _G.print = old_print
    return table.concat(lines, "\n")
end

local function make_ctx()
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A featureless room for testing.",
        contents = {},
        exits = {},
    }
    local player = {
        hands = { nil, nil },
        worn = {},
        state = {},
    }
    local handlers = verbs_mod.create()
    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        verbs = handlers,
        containment = containment_mod,
        known_objects = {},
        last_noun = nil,
        last_object = nil,
    }
    return ctx, reg, room, handlers
end

local function hand_id(h_slot)
    if type(h_slot) == "table" then return h_slot.id end
    return h_slot
end

local function list_contains(list, id)
    for _, v in ipairs(list or {}) do
        if v == id then return true end
    end
    return false
end

-------------------------------------------------------------------------------
h.suite("#267 — put item in container on floor (container not held)")
-------------------------------------------------------------------------------

test("#267: put item in sack on floor succeeds", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Sack on the floor
    local sack = {
        id = "sack", name = "a burlap sack",
        keywords = {"sack", "burlap sack"},
        container = true, capacity = 10, contents = {},
        location = "test-room",
    }
    reg:register("sack", sack)
    room.contents[#room.contents + 1] = "sack"

    -- Matchbox in hand
    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox", "small matchbox"},
        portable = true, size = 1, location = "player",
    }
    reg:register("matchbox", matchbox)
    ctx.player.hands[1] = matchbox

    local output = capture_print(function()
        handlers["put"](ctx, "matchbox in sack")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected 'You put' message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(sack.contents, "matchbox"))
end)

test("#267: put item on furniture surface (not held) succeeds", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Nightstand in room with top surface
    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        surfaces = {
            top = { capacity = 5, max_item_size = 3, accessible = true, contents = {} },
        },
    }
    reg:register("nightstand", nightstand)
    room.contents[#room.contents + 1] = "nightstand"

    -- Candle in hand
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle", "tallow candle"},
        portable = true, size = 1, location = "player",
    }
    reg:register("candle", candle)
    ctx.player.hands[1] = candle

    local output = capture_print(function()
        handlers["put"](ctx, "candle on nightstand")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected 'You put' message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(nightstand.surfaces.top.contents, "candle"))
end)

test("#267: put item in drawer (nested in furniture, not held) succeeds", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Nightstand in room
    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        surfaces = {
            top = { capacity = 5, max_item_size = 3, accessible = true, contents = {} },
        },
        contents = { "drawer" },
        parts = {
            drawer = {
                id = "nightstand-drawer",
                keywords = {"drawer", "small drawer"},
                name = "a small drawer",
            },
        },
    }
    reg:register("nightstand", nightstand)
    room.contents[#room.contents + 1] = "nightstand"

    -- Drawer (open, accessible)
    local drawer = {
        id = "drawer", name = "a small drawer",
        keywords = {"drawer", "small drawer"},
        container = true, capacity = 3, max_item_size = 2,
        contents = {},
        accessible = true,
        location = "nightstand",
    }
    reg:register("drawer", drawer)

    -- Candle in hand
    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true, size = 1, location = "player",
    }
    reg:register("candle", candle)
    ctx.player.hands[1] = candle

    local output = capture_print(function()
        handlers["put"](ctx, "candle in drawer")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected 'You put' message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(drawer.contents, "candle"))
end)

-------------------------------------------------------------------------------
h.suite("#267 — error messages name the specific item")
-------------------------------------------------------------------------------

test("#267: error names the item when not in hand", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Sack on floor
    local sack = {
        id = "sack", name = "a burlap sack",
        keywords = {"sack"},
        container = true, capacity = 10, contents = {},
        location = "test-room",
    }
    reg:register("sack", sack)
    room.contents[#room.contents + 1] = "sack"

    -- Matchbox on floor (not in hand)
    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox"},
        portable = true, size = 1, location = "test-room",
    }
    reg:register("matchbox", matchbox)
    room.contents[#room.contents + 1] = "matchbox"

    local output = capture_print(function()
        handlers["put"](ctx, "matchbox in sack")
    end)
    eq(true, output:find("holding") ~= nil,
       "Expected 'holding' in error, got: " .. output)
    eq(true, output:find("matchbox") ~= nil,
       "Expected item name 'matchbox' in error, got: " .. output)
end)

test("#267: item already inside target gives helpful message", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Matchbox inside sack, sack on floor
    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox"},
        portable = true, size = 1, location = "sack",
    }
    reg:register("matchbox", matchbox)

    local sack = {
        id = "sack", name = "a burlap sack",
        keywords = {"sack"},
        container = true, capacity = 10,
        contents = { "matchbox" },
        location = "test-room",
    }
    reg:register("sack", sack)
    room.contents[#room.contents + 1] = "sack"

    local output = capture_print(function()
        handlers["put"](ctx, "matchbox in sack")
    end)
    eq(true, output:find("already") ~= nil,
       "Expected 'already' message, got: " .. output)
end)

test("#267: place alias works same as put", function()
    local ctx, reg, room, handlers = make_ctx()

    local sack = {
        id = "sack", name = "a burlap sack",
        keywords = {"sack"},
        container = true, capacity = 10, contents = {},
        location = "test-room",
    }
    reg:register("sack", sack)
    room.contents[#room.contents + 1] = "sack"

    local candle = {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"},
        portable = true, size = 1, location = "player",
    }
    reg:register("candle", candle)
    ctx.player.hands[1] = candle

    local output = capture_print(function()
        handlers["place"](ctx, "candle in sack")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected 'You put' message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(sack.contents, "candle"))
end)

-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
