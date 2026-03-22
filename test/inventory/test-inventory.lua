-- test/inventory/test-inventory.lua
-- Regression tests for the inventory system: take, drop, put, inventory,
-- container interactions, and surface/containment logic.
--
-- Tests the CURRENT behavior so we can safely refactor later.
-- Uses the same test-helpers framework as the parser tests.

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

-- Capture printed output from verb handlers
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

-- Build a minimal game context for testing
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

-- Register an object and place it in the room
local function place_in_room(ctx, obj_def)
    ctx.registry:register(obj_def.id, obj_def)
    ctx.current_room.contents[#ctx.current_room.contents + 1] = obj_def.id
    obj_def.location = ctx.current_room.id
    return obj_def
end

-- Register an object and put it in the player's hand (stores object instance)
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

-- Extract object ID from a hand slot (supports instances and legacy strings)
local function hand_id(h)
    if type(h) == "table" then return h.id end
    return h
end

-- Check if an ID is in a list
local function list_contains(list, id)
    for _, v in ipairs(list or {}) do
        if v == id then return true end
    end
    return false
end

-------------------------------------------------------------------------------
h.suite("take — basic pickup from room")
-------------------------------------------------------------------------------

test("take portable object from room moves it to hand", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "apple", name = "a red apple",
        keywords = {"apple"}, portable = true,
    })

    handlers["take"](ctx, "apple")

    eq("apple", hand_id(ctx.player.hands[1]))
    eq(false, list_contains(room.contents, "apple"))
    eq("player", reg:get("apple").location)
end)

test("take uses first empty hand (left first)", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "key", name = "a brass key",
        keywords = {"key"}, portable = true,
    })
    place_in_room(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"}, portable = true,
    })

    handlers["take"](ctx, "key")
    handlers["take"](ctx, "coin")

    eq("key", hand_id(ctx.player.hands[1]))
    eq("coin", hand_id(ctx.player.hands[2]))
end)

test("take with empty noun prints prompt", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["take"](ctx, "")
    end)
    eq(true, output:find("Take what") ~= nil)
end)

test("take nonexistent object prints error", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["take"](ctx, "unicorn")
    end)
    eq(true, output:find("don't notice") ~= nil)
end)

test("take non-portable object prints error", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_room(ctx, {
        id = "boulder", name = "a huge boulder",
        keywords = {"boulder"}, portable = false,
    })
    local output = capture_print(function()
        handlers["take"](ctx, "boulder")
    end)
    eq(true, output:find("can't carry") ~= nil)
end)

test("take when hands are full prints error", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "sword", name = "a sword",
        keywords = {"sword"}, portable = true,
    }, 1)
    place_in_hand(ctx, {
        id = "shield", name = "a shield",
        keywords = {"shield"}, portable = true,
    }, 2)
    place_in_room(ctx, {
        id = "gem", name = "a gem",
        keywords = {"gem"}, portable = true,
    })

    local output = capture_print(function()
        handlers["take"](ctx, "gem")
    end)
    eq(true, output:find("[Hh]ands.* full") ~= nil)
    eq(true, list_contains(ctx.current_room.contents, "gem"))
end)

test("take something already held prints already-have message", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "ring", name = "a silver ring",
        keywords = {"ring"}, portable = true,
    })

    local output = capture_print(function()
        handlers["take"](ctx, "ring")
    end)
    eq(true, output:find("already have") ~= nil)
end)

test("'get' is an alias for take", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "book", name = "a dusty book",
        keywords = {"book"}, portable = true,
    })

    handlers["get"](ctx, "book")

    eq("book", hand_id(ctx.player.hands[1]))
    eq("player", reg:get("book").location)
end)

test("'grab' is an alias for take", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "rope", name = "a coil of rope",
        keywords = {"rope"}, portable = true,
    })

    handlers["grab"](ctx, "rope")

    eq("rope", hand_id(ctx.player.hands[1]))
end)

-------------------------------------------------------------------------------
h.suite("take — two-handed objects")
-------------------------------------------------------------------------------

test("take two-handed object occupies both hands", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "crate", name = "a large crate",
        keywords = {"crate"}, portable = true, hands_required = 2,
    })

    handlers["take"](ctx, "crate")

    eq("crate", hand_id(ctx.player.hands[1]))
    eq("crate", hand_id(ctx.player.hands[2]))
    eq("player", reg:get("crate").location)
end)

test("take two-handed object fails if one hand occupied", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "candle", name = "a candle",
        keywords = {"candle"}, portable = true,
    })
    place_in_room(ctx, {
        id = "barrel", name = "a barrel",
        keywords = {"barrel"}, portable = true, hands_required = 2,
    })

    local output = capture_print(function()
        handlers["take"](ctx, "barrel")
    end)
    eq(true, output:find("both hands") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("drop — basic drop to room")
-------------------------------------------------------------------------------

test("drop held object places it in room", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "stone", name = "a smooth stone",
        keywords = {"stone"}, portable = true,
    })

    handlers["drop"](ctx, "stone")

    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(room.contents, "stone"))
    eq(room.id, reg:get("stone").location)
end)

test("drop with empty noun prints prompt", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["drop"](ctx, "")
    end)
    eq(true, output:find("Drop what") ~= nil)
end)

test("drop something not held prints error", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["drop"](ctx, "phantom")
    end)
    eq(true, output:find("aren't holding") ~= nil)
end)

test("drop two-handed object frees both hands", function()
    local ctx, reg, room, handlers = make_ctx()
    local crate = {
        id = "big-box", name = "a big box",
        keywords = {"box"}, portable = true, hands_required = 2,
    }
    reg:register("big-box", crate)
    ctx.player.hands[1] = crate
    ctx.player.hands[2] = crate
    crate.location = "player"

    handlers["drop"](ctx, "box")

    eq(nil, ctx.player.hands[1])
    eq(nil, ctx.player.hands[2])
    eq(true, list_contains(room.contents, "big-box"))
end)

test("drop item in bag gives helpful message", function()
    local ctx, reg, _, handlers = make_ctx()
    local bag = {
        id = "sack", name = "a sack",
        keywords = {"sack"}, portable = true, container = true,
        contents = { "pebble" },
    }
    reg:register("sack", bag)
    ctx.player.hands[1] = bag
    bag.location = "player"
    reg:register("pebble", {
        id = "pebble", name = "a pebble",
        keywords = {"pebble"}, portable = true,
        location = "sack",
    })

    local output = capture_print(function()
        handlers["drop"](ctx, "pebble")
    end)
    eq(true, output:find("bag") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("take from container — 'take X from Y'")
-------------------------------------------------------------------------------

test("take item from carried container", function()
    local ctx, reg, _, handlers = make_ctx()
    local box = {
        id = "matchbox", name = "a matchbox",
        keywords = {"matchbox"}, portable = true, container = true,
        contents = { "match-1" },
    }
    reg:register("matchbox", box)
    ctx.player.hands[1] = box
    box.location = "player"
    reg:register("match-1", {
        id = "match-1", name = "a wooden match",
        keywords = {"match"}, portable = true,
        location = "matchbox",
    })

    handlers["take"](ctx, "match from matchbox")

    eq("match-1", hand_id(ctx.player.hands[2]))
    eq(0, #box.contents)
    eq("player", reg:get("match-1").location)
end)

test("take from visible room container (not held)", function()
    local ctx, reg, room, handlers = make_ctx()
    local rack = {
        id = "wine-rack", name = "a wine rack",
        keywords = {"rack", "wine rack"}, container = true,
        contents = { "wine-bottle" },
    }
    place_in_room(ctx, rack)
    reg:register("wine-bottle", {
        id = "wine-bottle", name = "a bottle of wine",
        keywords = {"bottle", "wine"}, portable = true,
        location = "wine-rack",
    })

    handlers["take"](ctx, "bottle from rack")

    eq("wine-bottle", hand_id(ctx.player.hands[1]))
    eq(0, #rack.contents)
end)

test("take from container with nothing matching prints error", function()
    local ctx, reg, _, handlers = make_ctx()
    local box = {
        id = "chest", name = "a wooden chest",
        keywords = {"chest"}, container = true, contents = {},
    }
    place_in_room(ctx, box)

    local output = capture_print(function()
        handlers["take"](ctx, "jewel from chest")
    end)
    eq(true, output:find("no ") ~= nil or output:find("There is no") ~= nil)
end)

test("take from nonexistent container prints error", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["take"](ctx, "sword from wardrobe")
    end)
    eq(true, output:find("don't see") ~= nil)
end)

test("take from non-container visible object prints error", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_room(ctx, {
        id = "chair", name = "a wooden chair",
        keywords = {"chair"}, portable = false,
    })

    local output = capture_print(function()
        handlers["take"](ctx, "cushion from chair")
    end)
    eq(true, output:find("not a container") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("take from surface-based container")
-------------------------------------------------------------------------------

test("take from surface container (accessible)", function()
    local ctx, reg, room, handlers = make_ctx()
    local nightstand = {
        id = "nightstand", name = "the nightstand",
        keywords = {"nightstand"},
        surfaces = {
            inside = {
                accessible = true,
                contents = { "diary" },
                capacity = 5,
            },
        },
    }
    place_in_room(ctx, nightstand)
    reg:register("diary", {
        id = "diary", name = "a leather diary",
        keywords = {"diary"}, portable = true,
        location = "nightstand.inside",
    })

    handlers["take"](ctx, "diary from nightstand")

    eq("diary", hand_id(ctx.player.hands[1]))
    eq(0, #nightstand.surfaces.inside.contents)
end)

test("take from inaccessible surface fails gracefully", function()
    local ctx, reg, _, handlers = make_ctx()
    local safe = {
        id = "safe", name = "a wall safe",
        keywords = {"safe"},
        surfaces = {
            inside = {
                accessible = false,
                contents = { "gold-bar" },
                capacity = 5,
            },
        },
    }
    place_in_room(ctx, safe)
    reg:register("gold-bar", {
        id = "gold-bar", name = "a gold bar",
        keywords = {"gold"}, portable = true,
        location = "safe.inside",
    })

    -- Inaccessible surfaces are skipped during search — item shouldn't be found
    local output = capture_print(function()
        handlers["take"](ctx, "gold from safe")
    end)
    -- Should indicate nothing found in the container
    eq(true, output:find("no ") ~= nil or output:find("There is no") ~= nil
        or output:find("not a container") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("put — put item in/on container")
-------------------------------------------------------------------------------

test("put item in simple container", function()
    local ctx, reg, room, handlers = make_ctx()
    local pouch = {
        id = "pouch", name = "a leather pouch",
        keywords = {"pouch"}, container = true, portable = true,
        contents = {}, capacity = 10,
    }
    place_in_room(ctx, pouch)
    place_in_hand(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"}, portable = true, size = 1,
    })

    handlers["put"](ctx, "coin in pouch")

    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(pouch.contents, "coin"))
    eq(pouch.id, reg:get("coin").location)
end)

test("put item on surface-based furniture", function()
    local ctx, reg, room, handlers = make_ctx()
    local table_obj = {
        id = "table", name = "a wooden table",
        keywords = {"table"},
        surfaces = {
            top = {
                accessible = true,
                contents = {},
                capacity = 20,
            },
        },
    }
    place_in_room(ctx, table_obj)
    place_in_hand(ctx, {
        id = "mug", name = "a ceramic mug",
        keywords = {"mug"}, portable = true, size = 2,
    })

    handlers["put"](ctx, "mug on table")

    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(table_obj.surfaces.top.contents, "mug"))
end)

test("put item in surface-based inside", function()
    local ctx, reg, room, handlers = make_ctx()
    local drawer = {
        id = "dresser", name = "a dresser",
        keywords = {"dresser"},
        surfaces = {
            inside = {
                accessible = true,
                contents = {},
                capacity = 10,
            },
        },
    }
    place_in_room(ctx, drawer)
    place_in_hand(ctx, {
        id = "socks", name = "a pair of socks",
        keywords = {"socks"}, portable = true, size = 1,
    })

    handlers["put"](ctx, "socks in dresser")

    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(drawer.surfaces.inside.contents, "socks"))
end)

test("put without holding item gives error", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_room(ctx, {
        id = "bucket", name = "a bucket",
        keywords = {"bucket"}, container = true, contents = {}, capacity = 10,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "fish in bucket")
    end)
    eq(true, output:find("don't have") ~= nil)
end)

test("put with incomplete syntax gives help", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["put"](ctx, "")
    end)
    eq(true, output:find("Put what") ~= nil)

    output = capture_print(function()
        handlers["put"](ctx, "sword")
    end)
    eq(true, output:find("Put what") ~= nil or output:find("where") ~= nil)
end)

test("put into nonexistent target gives error", function()
    local ctx, _, _, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "dagger", name = "a dagger",
        keywords = {"dagger"}, portable = true,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "dagger in wardrobe")
    end)
    eq(true, output:find("don't see") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("put — containment validation")
-------------------------------------------------------------------------------

test("put rejects item that is too large", function()
    local ctx, _, _, handlers = make_ctx()
    local box = {
        id = "smallbox", name = "a small box",
        keywords = {"box"},
        surfaces = {
            inside = {
                accessible = true,
                contents = {},
                capacity = 10,
                max_item_size = 2,
            },
        },
    }
    place_in_room(ctx, box)
    place_in_hand(ctx, {
        id = "boulder", name = "a boulder",
        keywords = {"boulder"}, portable = true, size = 5,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "boulder in box")
    end)
    eq(true, output:find("too large") ~= nil)
end)

test("put rejects when container is full (capacity)", function()
    local ctx, reg, _, handlers = make_ctx()
    local jar = {
        id = "jar", name = "a glass jar",
        keywords = {"jar"},
        surfaces = {
            inside = {
                accessible = true,
                contents = { "marble-1", "marble-2" },
                capacity = 2,
            },
        },
    }
    place_in_room(ctx, jar)
    reg:register("marble-1", {
        id = "marble-1", name = "a marble", keywords = {"marble"}, size = 1,
    })
    reg:register("marble-2", {
        id = "marble-2", name = "a marble", keywords = {"marble"}, size = 1,
    })
    place_in_hand(ctx, {
        id = "marble-3", name = "another marble",
        keywords = {"marble"}, portable = true, size = 1,
    })

    local output = capture_print(function()
        handlers["put"](ctx, "marble in jar")
    end)
    eq(true, output:find("not enough room") ~= nil or output:find("too large") ~= nil)
end)

test("can't put object inside itself (same reference)", function()
    -- BUG-036b: containment uses identity check (==), not id comparison
    local box = { id = "box", name = "box", container = true, capacity = 10, contents = {} }
    local ok, reason = containment_mod.can_contain(box, box, nil, nil)
    eq(false, ok)
    eq(true, reason:find("itself") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("inventory — listing what you carry")
-------------------------------------------------------------------------------

test("inventory shows empty hands when nothing carried", function()
    local ctx, _, _, handlers = make_ctx()
    local output = capture_print(function()
        handlers["inventory"](ctx, "")
    end)
    eq(true, output:find("Left hand:.*empty") ~= nil)
    eq(true, output:find("Right hand:.*empty") ~= nil)
end)

test("inventory shows item in left hand", function()
    local ctx, reg, _, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "torch", name = "a lit torch",
        keywords = {"torch"}, portable = true,
    })

    local output = capture_print(function()
        handlers["inventory"](ctx, "")
    end)
    eq(true, output:find("Left hand:.*lit torch") ~= nil)
    eq(true, output:find("Right hand:.*empty") ~= nil)
end)

test("inventory shows items in both hands", function()
    local ctx, reg, _, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "bread", name = "a loaf of bread",
        keywords = {"bread"}, portable = true,
    }, 1)
    place_in_hand(ctx, {
        id = "cheese", name = "a wedge of cheese",
        keywords = {"cheese"}, portable = true,
    }, 2)

    local output = capture_print(function()
        handlers["inventory"](ctx, "")
    end)
    eq(true, output:find("Left hand:.*bread") ~= nil)
    eq(true, output:find("Right hand:.*cheese") ~= nil)
end)

test("inventory shows bag contents", function()
    local ctx, reg, _, handlers = make_ctx()
    local bag = {
        id = "satchel", name = "a leather satchel",
        keywords = {"satchel"}, portable = true, container = true,
        contents = { "quill" },
    }
    reg:register("satchel", bag)
    ctx.player.hands[1] = bag
    bag.location = "player"
    reg:register("quill", {
        id = "quill", name = "a feather quill",
        keywords = {"quill"}, portable = true,
        location = "satchel",
    })

    local output = capture_print(function()
        handlers["inventory"](ctx, "")
    end)
    eq(true, output:find("satchel") ~= nil)
    eq(true, output:find("contains") ~= nil)
    eq(true, output:find("quill") ~= nil)
end)

test("'i' is alias for inventory", function()
    local ctx, _, _, handlers = make_ctx()
    eq(handlers["i"], handlers["inventory"])
end)

-------------------------------------------------------------------------------
h.suite("containment module — direct unit tests")
-------------------------------------------------------------------------------

test("can_contain allows valid item in container", function()
    local item = { id = "coin", name = "coin", size = 1, weight = 1 }
    local container = { id = "box", name = "box", container = true, capacity = 5, contents = {} }
    local ok, err = containment_mod.can_contain(item, container, nil, nil)
    eq(true, ok)
end)

test("can_contain rejects non-container", function()
    local item = { id = "coin", name = "coin" }
    local target = { id = "rock", name = "rock" }
    local ok, err = containment_mod.can_contain(item, target, nil, nil)
    eq(false, ok)
    eq(true, err:find("not a container") ~= nil)
end)

test("can_contain checks max_item_size", function()
    local item = { id = "sword", name = "sword", size = 5 }
    local container = { id = "box", name = "box", container = true,
        capacity = 100, max_item_size = 3, contents = {} }
    local ok, err = containment_mod.can_contain(item, container, nil, nil)
    eq(false, ok)
    eq(true, err:find("too large") ~= nil)
end)

test("can_contain checks weight capacity", function()
    local reg = registry_mod.new()
    local item = { id = "anvil", name = "anvil", size = 1, weight = 50 }
    reg:register("anvil", item)
    local container = { id = "shelf", name = "shelf", container = true,
        capacity = 100, weight_capacity = 10, contents = {} }
    reg:register("shelf", container)
    local ok, err = containment_mod.can_contain(item, container, nil, reg)
    eq(false, ok)
    eq(true, err:find("too heavy") ~= nil)
end)

test("can_contain validates category accept list", function()
    local item = { id = "sword", name = "sword", categories = {"weapon"} }
    local container = { id = "rack", name = "rack", container = true,
        capacity = 10, contents = {}, accept = {"bottle"} }
    local ok, err = containment_mod.can_contain(item, container, nil, nil)
    eq(false, ok)
    eq(true, err:find("does not belong") ~= nil)
end)

test("can_contain validates category reject list", function()
    local item = { id = "oil", name = "oil", categories = {"flammable"} }
    local container = { id = "furnace", name = "furnace", container = true,
        capacity = 10, contents = {}, reject = {"flammable"} }
    local ok, err = containment_mod.can_contain(item, container, nil, nil)
    eq(false, ok)
    eq(true, err:find("cannot be placed") ~= nil)
end)

test("can_contain with surface — accessible", function()
    local item = { id = "cup", name = "cup", size = 1 }
    local furniture = {
        id = "desk", name = "desk",
        surfaces = {
            top = { accessible = true, contents = {}, capacity = 20 },
        },
    }
    local ok, err = containment_mod.can_contain(item, furniture, "top", nil)
    eq(true, ok)
end)

test("can_contain with surface — inaccessible", function()
    local item = { id = "cup", name = "cup", size = 1 }
    local furniture = {
        id = "desk", name = "desk",
        surfaces = {
            inside = { accessible = false, contents = {}, capacity = 20 },
        },
    }
    local ok, err = containment_mod.can_contain(item, furniture, "inside", nil)
    eq(false, ok)
    eq(true, err:find("not accessible") ~= nil)
end)

test("can_contain with nonexistent surface", function()
    local item = { id = "cup", name = "cup", size = 1 }
    local furniture = {
        id = "desk", name = "desk",
        surfaces = {
            top = { accessible = true, contents = {}, capacity = 20 },
        },
    }
    local ok, err = containment_mod.can_contain(item, furniture, "bottom", nil)
    eq(false, ok)
    eq(true, err:find("no ") ~= nil)
end)

test("multi-surface object without surface_name prompts user", function()
    local item = { id = "cup", name = "cup", size = 1 }
    local furniture = {
        id = "desk", name = "desk",
        surfaces = {
            top = { accessible = true, contents = {}, capacity = 20 },
        },
    }
    local ok, err = containment_mod.can_contain(item, furniture, nil, nil)
    eq(false, ok)
    eq(true, err:find("specify") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("round-trip — take then drop, drop then take")
-------------------------------------------------------------------------------

test("take then drop returns object to room", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "flask", name = "a flask",
        keywords = {"flask"}, portable = true,
    })

    handlers["take"](ctx, "flask")
    eq("flask", hand_id(ctx.player.hands[1]))
    eq(false, list_contains(room.contents, "flask"))

    handlers["drop"](ctx, "flask")
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(room.contents, "flask"))
    eq(room.id, reg:get("flask").location)
end)

test("put into container then take from container round-trip", function()
    local ctx, reg, room, handlers = make_ctx()
    local crate = {
        id = "crate", name = "a wooden crate",
        keywords = {"crate"}, container = true,
        contents = {}, capacity = 20,
    }
    place_in_room(ctx, crate)
    place_in_hand(ctx, {
        id = "lantern", name = "an oil lantern",
        keywords = {"lantern"}, portable = true, size = 2,
    })

    -- Put lantern in crate
    handlers["put"](ctx, "lantern in crate")
    eq(nil, ctx.player.hands[1])
    eq(true, list_contains(crate.contents, "lantern"))

    -- Take lantern from crate
    handlers["take"](ctx, "lantern from crate")
    eq("lantern", hand_id(ctx.player.hands[1]))
    eq(0, #crate.contents)
end)

-------------------------------------------------------------------------------
h.suite("registry — object store basics")
-------------------------------------------------------------------------------

test("register and get round-trip", function()
    local reg = registry_mod.new()
    reg:register("apple", { name = "apple" })
    local obj = reg:get("apple")
    eq("apple", obj.name)
    eq("apple", obj.id)
end)

test("remove removes object", function()
    local reg = registry_mod.new()
    reg:register("apple", { name = "apple" })
    reg:remove("apple")
    eq(nil, reg:get("apple"))
end)

test("find_by_keyword matches name", function()
    local reg = registry_mod.new()
    reg:register("apple-1", { name = "red apple" })
    local obj = reg:find_by_keyword("red apple")
    eq("apple-1", obj.id)
end)

test("find_by_keyword matches keywords array", function()
    local reg = registry_mod.new()
    reg:register("key-1", { name = "a brass key", keywords = {"key", "brass key"} })
    local obj = reg:find_by_keyword("key")
    eq("key-1", obj.id)
end)

test("list returns all objects", function()
    local reg = registry_mod.new()
    reg:register("a", { name = "A" })
    reg:register("b", { name = "B" })
    local all = reg:list()
    eq(2, #all)
end)

test("total_weight sums objects at location", function()
    local reg = registry_mod.new()
    reg:register("a", { name = "A", weight = 5, location = "room1" })
    reg:register("b", { name = "B", weight = 3, location = "room1" })
    reg:register("c", { name = "C", weight = 10, location = "room2" })
    eq(8, reg:total_weight("room1"))
end)

-------------------------------------------------------------------------------
h.suite("find_visible — object discovery in rooms")
-------------------------------------------------------------------------------

test("find_visible locates object in room contents", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "lamp", name = "an oil lamp",
        keywords = {"lamp"}, portable = true,
    })
    -- Use take as a proxy — if take works, find_visible found it
    handlers["take"](ctx, "lamp")
    eq("lamp", hand_id(ctx.player.hands[1]))
end)

test("find_visible finds object on accessible surface", function()
    local ctx, reg, room, handlers = make_ctx()
    local desk = {
        id = "desk", name = "a writing desk",
        keywords = {"desk"},
        surfaces = {
            top = { accessible = true, contents = { "pen" }, capacity = 10 },
        },
    }
    place_in_room(ctx, desk)
    reg:register("pen", {
        id = "pen", name = "a fountain pen",
        keywords = {"pen"}, portable = true,
        location = "desk.top",
    })

    handlers["take"](ctx, "pen")
    eq("pen", hand_id(ctx.player.hands[1]))
    eq(0, #desk.surfaces.top.contents)
end)

test("find_visible skips hidden objects", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "secret", name = "a hidden compartment",
        keywords = {"compartment"}, hidden = true,
    })

    local output = capture_print(function()
        handlers["take"](ctx, "compartment")
    end)
    eq(true, output:find("don't notice") ~= nil)
end)

-------------------------------------------------------------------------------
h.suite("edge cases — articles and keyword matching")
-------------------------------------------------------------------------------

test("take with article 'the' works", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "scroll", name = "an ancient scroll",
        keywords = {"scroll"}, portable = true,
    })

    handlers["take"](ctx, "the scroll")
    eq("scroll", hand_id(ctx.player.hands[1]))
end)

test("'pick up X' syntax works", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "hat", name = "a top hat",
        keywords = {"hat"}, portable = true,
    })

    handlers["take"](ctx, "up hat")
    eq("hat", hand_id(ctx.player.hands[1]))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
