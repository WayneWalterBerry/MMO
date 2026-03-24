-- test/inventory/test-put-regression.lua
-- Regression tests for put verb bugs #79 and #80.
--
-- #79: put items in closed drawer bypasses accessibility check
-- #80: 'put X in Y' silently misroutes when Y has no inside surface

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

local function place_in_room(ctx, obj_def)
    ctx.registry:register(obj_def.id, obj_def)
    ctx.current_room.contents[#ctx.current_room.contents + 1] = obj_def.id
    obj_def.location = ctx.current_room.id
    return obj_def
end

local function place_in_hand(ctx, obj_def, hand_slot)
    ctx.registry:register(obj_def.id, obj_def)
    hand_slot = hand_slot or 1
    if ctx.player.hands[1] == nil and hand_slot == 1 then
        ctx.player.hands[1] = obj_def
    elseif ctx.player.hands[2] == nil then
        ctx.player.hands[2] = obj_def
    end
    obj_def.location = "player"
    return obj_def
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
h.suite("#79 — put in closed drawer must fail (accessibility)")
-------------------------------------------------------------------------------

test("#79: can_contain rejects root-level container with accessible=false", function()
    local item = { id = "knife", name = "a knife", size = 1 }
    local drawer = {
        id = "drawer", name = "a small drawer",
        container = true, capacity = 5, contents = {},
        accessible = false,
    }
    local ok, err = containment_mod.can_contain(item, drawer, nil, nil)
    eq(false, ok)
    eq(true, err ~= nil and err:find("not accessible") ~= nil)
end)

test("#79: can_contain allows root-level container with accessible=true", function()
    local item = { id = "knife", name = "a knife", size = 1 }
    local drawer = {
        id = "drawer", name = "a small drawer",
        container = true, capacity = 5, contents = {},
        accessible = true,
    }
    local ok, err = containment_mod.can_contain(item, drawer, nil, nil)
    eq(true, ok)
end)

test("#79: can_contain allows root-level container with no accessible field", function()
    local item = { id = "knife", name = "a knife", size = 1 }
    local bag = {
        id = "bag", name = "a bag",
        container = true, capacity = 5, contents = {},
    }
    local ok, err = containment_mod.can_contain(item, bag, nil, nil)
    eq(true, ok)
end)

test("#79: put in closed drawer fails via verb handler", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Nightstand with drawer as a composite part
    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        _state = "closed_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {} },
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
    place_in_room(ctx, nightstand)

    -- Drawer in closed state (accessible = false)
    local drawer = {
        id = "drawer", name = "a small drawer",
        keywords = {"drawer", "small drawer"},
        container = true, capacity = 2, max_item_size = 1,
        contents = {},
        accessible = false,
        location = "nightstand",
    }
    reg:register("drawer", drawer)

    place_in_hand(ctx, {
        id = "knife", name = "a knife",
        keywords = {"knife"}, portable = true, size = 1,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "knife in drawer")
    end)
    eq(true, output:find("not accessible") ~= nil,
       "Expected 'not accessible' error, got: " .. output)
    -- Knife should still be in hand
    eq("knife", hand_id(ctx.player.hands[1]))
end)

test("#79: put in open drawer succeeds", function()
    local ctx, reg, room, handlers = make_ctx()

    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        _state = "open_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {} },
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
    place_in_room(ctx, nightstand)

    local drawer = {
        id = "drawer", name = "a small drawer",
        keywords = {"drawer", "small drawer"},
        container = true, capacity = 2, max_item_size = 1,
        contents = {},
        accessible = true,
        location = "nightstand",
    }
    reg:register("drawer", drawer)

    place_in_hand(ctx, {
        id = "knife", name = "a knife",
        keywords = {"knife"}, portable = true, size = 1,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "knife in drawer")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected success message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(drawer.contents, "knife"))
end)

-------------------------------------------------------------------------------
h.suite("#80 — put in furniture with no inside rejects gracefully")
-------------------------------------------------------------------------------

test("#80: put in nightstand fails when no inside surface", function()
    local ctx, reg, room, handlers = make_ctx()

    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        surfaces = {
            top = { capacity = 3, max_item_size = 2, accessible = true, contents = {} },
        },
    }
    place_in_room(ctx, nightstand)

    place_in_hand(ctx, {
        id = "knife", name = "a knife",
        keywords = {"knife"}, portable = true, size = 1,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "knife in nightstand")
    end)
    eq(true, output:find("can't put anything inside") ~= nil,
       "Expected 'can't put anything inside' error, got: " .. output)
    -- Item stays in hand
    eq("knife", hand_id(ctx.player.hands[1]))
    -- Item NOT placed on top
    eq(0, #nightstand.surfaces.top.contents)
end)

test("#80: put on nightstand still works (top surface)", function()
    local ctx, reg, room, handlers = make_ctx()

    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        surfaces = {
            top = { capacity = 3, max_item_size = 2, accessible = true, contents = {} },
        },
    }
    place_in_room(ctx, nightstand)

    place_in_hand(ctx, {
        id = "knife", name = "a knife",
        keywords = {"knife"}, portable = true, size = 1,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "knife on nightstand")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected success message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(nightstand.surfaces.top.contents, "knife"))
end)

test("#80: put in wardrobe works when open (has inside surface)", function()
    local ctx, reg, room, handlers = make_ctx()

    local wardrobe = {
        id = "wardrobe", name = "a heavy wardrobe",
        keywords = {"wardrobe"},
        surfaces = {
            inside = { capacity = 8, max_item_size = 4, accessible = true, contents = {} },
        },
    }
    place_in_room(ctx, wardrobe)

    place_in_hand(ctx, {
        id = "cloak", name = "a wool cloak",
        keywords = {"cloak"}, portable = true, size = 2,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "cloak in wardrobe")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected success message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(wardrobe.surfaces.inside.contents, "cloak"))
end)

test("#80: put in simple container still works (bag with no surfaces)", function()
    local ctx, reg, room, handlers = make_ctx()

    local sack = {
        id = "sack", name = "a burlap sack",
        keywords = {"sack"},
        container = true, capacity = 10, contents = {},
    }
    place_in_room(ctx, sack)

    place_in_hand(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"}, portable = true, size = 1,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "coin in sack")
    end)
    eq(true, output:find("You put") ~= nil,
       "Expected success message, got: " .. output)
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(sack.contents, "coin"))
end)

-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
