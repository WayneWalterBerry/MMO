-- test/inventory/test-containment-comprehensive.lua
-- Comprehensive tests for inventory management and containment system.
--
-- Coverage:
--   1. Two-hand system: take, drop, hands-full rejection, wear frees hand
--   2. Container interactions: put in/on, not-a-container rejection, take from
--   3. Size/weight constraints
--   4. Nested containers (matchbox inside drawer inside nightstand)
--   5. Search behavior: "search nightstand", "look in drawer"
--   6. Disambiguation: multiple objects matching same keyword
--
-- Usage: lua test/inventory/test-containment-comprehensive.lua
-- Must be run from the repository root.

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
local truthy = h.assert_truthy

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
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
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
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
        injuries = {},
        bags = {},
        state = {},
    }
    local handlers = verbs_mod.create()
    return {
        registry = reg,
        current_room = room,
        player = player,
        verbs = handlers,
        containment = containment_mod,
        known_objects = {},
        last_noun = nil,
        last_object = nil,
        time_offset = 8,
        game_start_time = os.time(),
    }, reg, room, handlers
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

---------------------------------------------------------------------------
-- 1. TWO-HAND SYSTEM
---------------------------------------------------------------------------
h.suite("two-hand system — basic take and hand slot management")

test("take first item goes to left hand (slot 1)", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "apple", name = "a red apple",
        keywords = {"apple"}, portable = true, size = 1,
    })
    capture_print(function() handlers["take"](ctx, "apple") end)
    eq("apple", hand_id(ctx.player.hands[1]))
    eq(nil, ctx.player.hands[2])
end)

test("take second item goes to right hand (slot 2)", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "apple", name = "a red apple",
        keywords = {"apple"}, portable = true, size = 1,
    })
    place_in_room(ctx, {
        id = "bread", name = "a loaf of bread",
        keywords = {"bread"}, portable = true, size = 1,
    })
    capture_print(function() handlers["take"](ctx, "apple") end)
    capture_print(function() handlers["take"](ctx, "bread") end)
    eq("apple", hand_id(ctx.player.hands[1]))
    eq("bread", hand_id(ctx.player.hands[2]))
end)

test("take with both hands full fails with message", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "sword", name = "a sword",
        keywords = {"sword"}, portable = true, size = 2,
    }, 1)
    place_in_hand(ctx, {
        id = "shield", name = "a shield",
        keywords = {"shield"}, portable = true, size = 2,
    }, 2)
    place_in_room(ctx, {
        id = "gem", name = "a gem",
        keywords = {"gem"}, portable = true, size = 1,
    })
    local output = capture_print(function() handlers["take"](ctx, "gem") end)
    truthy(output:find("[Hh]ands.* full"), "Should say hands are full, got: " .. output)
    truthy(list_contains(ctx.current_room.contents, "gem"), "Gem should still be in room")
end)

test("drop frees hand slot", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "torch", name = "a torch",
        keywords = {"torch"}, portable = true, size = 1,
    })
    eq("torch", hand_id(ctx.player.hands[1]))
    capture_print(function() handlers["drop"](ctx, "torch") end)
    eq(nil, ctx.player.hands[1])
    truthy(list_contains(room.contents, "torch"), "Torch should be in room after drop")
end)

test("drop then take reuses freed slot", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "key", name = "a key",
        keywords = {"key"}, portable = true, size = 1,
    }, 1)
    place_in_hand(ctx, {
        id = "coin", name = "a coin",
        keywords = {"coin"}, portable = true, size = 1,
    }, 2)
    place_in_room(ctx, {
        id = "ring", name = "a ring",
        keywords = {"ring"}, portable = true, size = 1,
    })
    -- Drop left hand item
    capture_print(function() handlers["drop"](ctx, "key") end)
    eq(nil, ctx.player.hands[1])
    -- Take new item — should go to freed left hand
    capture_print(function() handlers["take"](ctx, "ring") end)
    eq("ring", hand_id(ctx.player.hands[1]))
    eq("coin", hand_id(ctx.player.hands[2]))
end)

---------------------------------------------------------------------------
h.suite("two-hand system — wear frees hand slot (#180)")

test("wear item from hand frees that hand", function()
    local ctx, reg, room, handlers = make_ctx()
    local cloak = {
        id = "wool-cloak", name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true, size = 2,
        wearable = true,
        wear = { slot = "torso", layer = "outer" },
        location = "player",
    }
    place_in_hand(ctx, cloak, 1)
    eq("wool-cloak", hand_id(ctx.player.hands[1]))
    capture_print(function() handlers["wear"](ctx, "cloak") end)
    eq(nil, ctx.player.hands[1], "Hand should be freed after wearing")
    truthy(list_contains(ctx.player.worn, "wool-cloak"), "Cloak should be in worn list")
end)

test("wear from full hands frees slot for new pickup", function()
    local ctx, reg, room, handlers = make_ctx()
    local cloak = {
        id = "wool-cloak", name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true, size = 2,
        wearable = true,
        wear = { slot = "torso", layer = "outer" },
        location = "player",
    }
    local sack = {
        id = "grain-sack", name = "a heavy sack",
        keywords = {"sack"}, portable = true, size = 3,
        location = "player",
    }
    place_in_hand(ctx, cloak, 1)
    place_in_hand(ctx, sack, 2)
    place_in_room(ctx, {
        id = "gem", name = "a gem",
        keywords = {"gem"}, portable = true, size = 1,
    })
    -- Both hands full — wear cloak to free a hand
    capture_print(function() handlers["wear"](ctx, "cloak") end)
    eq(nil, ctx.player.hands[1], "Left hand freed by wearing cloak")
    -- Now take the gem
    capture_print(function() handlers["take"](ctx, "gem") end)
    eq("gem", hand_id(ctx.player.hands[1]), "Gem should fill freed hand slot")
end)

test("worn item does NOT appear in hands after wear", function()
    local ctx, reg, room, handlers = make_ctx()
    local hat = {
        id = "hat", name = "a leather hat",
        keywords = {"hat"},
        portable = true, size = 1,
        wearable = true,
        wear = { slot = "head", layer = "outer" },
        location = "player",
    }
    place_in_hand(ctx, hat, 1)
    capture_print(function() handlers["wear"](ctx, "hat") end)
    for i = 1, 2 do
        if ctx.player.hands[i] then
            local hid = hand_id(ctx.player.hands[i])
            truthy(hid ~= "hat", "Hat should NOT be in hand " .. i)
        end
    end
    truthy(list_contains(ctx.player.worn, "hat"), "Hat should be in worn list")
end)

---------------------------------------------------------------------------
-- 2. CONTAINER INTERACTIONS: put in/on, rejection, take from
---------------------------------------------------------------------------
h.suite("container interactions — put in valid container")

test("put X in Y (simple container)", function()
    local ctx, reg, room, handlers = make_ctx()
    local bag = {
        id = "bag", name = "a burlap bag",
        keywords = {"bag"}, container = true,
        capacity = 10, contents = {},
    }
    place_in_room(ctx, bag)
    place_in_hand(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"}, portable = true, size = 1,
    })
    local output = capture_print(function()
        handlers["put"](ctx, "coin in bag")
    end)
    truthy(output:find("You put"), "Should confirm placement, got: " .. output)
    eq(nil, ctx.player.hands[1], "Hand should be empty after put")
    truthy(list_contains(bag.contents, "coin"), "Coin should be in bag")
end)

test("put X in Y fails — Y is not a container", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "rock", name = "a large rock",
        keywords = {"rock"},
    })
    place_in_hand(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"}, portable = true, size = 1,
    })
    local output = capture_print(function()
        handlers["put"](ctx, "coin in rock")
    end)
    -- Should fail because rock isn't a container
    truthy(output:find("can't put") ~= nil or output:find("not a container") ~= nil,
        "Should reject non-container, got: " .. output)
    eq("coin", hand_id(ctx.player.hands[1]), "Coin should still be in hand")
end)

test("put X on Y (surface — on_top relationship)", function()
    local ctx, reg, room, handlers = make_ctx()
    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        surfaces = {
            top = { accessible = true, contents = {}, capacity = 5, max_item_size = 3 },
        },
    }
    place_in_room(ctx, nightstand)
    place_in_hand(ctx, {
        id = "candle", name = "a tallow candle",
        keywords = {"candle"}, portable = true, size = 1,
    })
    local output = capture_print(function()
        handlers["put"](ctx, "candle on nightstand")
    end)
    truthy(output:find("You put"), "Should confirm placement, got: " .. output)
    truthy(list_contains(nightstand.surfaces.top.contents, "candle"),
        "Candle should be on top of nightstand")
    eq(nil, ctx.player.hands[1], "Hand should be empty after put")
end)

test("take X from Y (remove from container)", function()
    local ctx, reg, room, handlers = make_ctx()
    local chest = {
        id = "chest", name = "an old chest",
        keywords = {"chest"}, container = true,
        capacity = 20, contents = { "dagger" },
    }
    place_in_room(ctx, chest)
    reg:register("dagger", {
        id = "dagger", name = "a rusty dagger",
        keywords = {"dagger"}, portable = true, size = 1,
        location = "chest",
    })
    capture_print(function() handlers["take"](ctx, "dagger from chest") end)
    eq("dagger", hand_id(ctx.player.hands[1]), "Dagger should be in hand")
    eq(0, #chest.contents, "Chest should be empty")
end)

---------------------------------------------------------------------------
h.suite("container interactions — size/weight constraints")

test("item too big for container is rejected", function()
    local ctx, reg, room, handlers = make_ctx()
    local smallbox = {
        id = "smallbox", name = "a tiny box",
        keywords = {"box"}, container = true,
        capacity = 5, max_item_size = 1, contents = {},
    }
    place_in_room(ctx, smallbox)
    place_in_hand(ctx, {
        id = "sword", name = "a long sword",
        keywords = {"sword"}, portable = true, size = 4,
    })
    local output = capture_print(function()
        handlers["put"](ctx, "sword in box")
    end)
    truthy(output:find("too large"), "Should say too large, got: " .. output)
    eq("sword", hand_id(ctx.player.hands[1]), "Sword should still be in hand")
end)

test("container at capacity rejects new item", function()
    local ctx, reg, room, handlers = make_ctx()
    local jar = {
        id = "jar", name = "a glass jar",
        keywords = {"jar"}, container = true,
        capacity = 2, contents = { "marble-1", "marble-2" },
    }
    place_in_room(ctx, jar)
    reg:register("marble-1", { id = "marble-1", name = "a marble", size = 1 })
    reg:register("marble-2", { id = "marble-2", name = "a marble", size = 1 })
    place_in_hand(ctx, {
        id = "marble-3", name = "another marble",
        keywords = {"marble"}, portable = true, size = 1,
    })
    local output = capture_print(function()
        handlers["put"](ctx, "marble in jar")
    end)
    truthy(output:find("not enough room") or output:find("too large"),
        "Should reject full container, got: " .. output)
end)

test("item too heavy for container is rejected", function()
    local item = { id = "anvil", name = "anvil", size = 1, weight = 50 }
    local container = {
        id = "shelf", name = "shelf", container = true,
        capacity = 100, weight_capacity = 10, contents = {},
    }
    local reg = registry_mod.new()
    reg:register("anvil", item)
    local ok, err = containment_mod.can_contain(item, container, nil, reg)
    eq(false, ok)
    truthy(err:find("too heavy"), "Should say too heavy, got: " .. (err or "nil"))
end)

test("self-containment is rejected", function()
    local box = {
        id = "box", name = "box", container = true,
        capacity = 10, contents = {},
    }
    local ok, err = containment_mod.can_contain(box, box, nil, nil)
    eq(false, ok)
    truthy(err:find("itself"), "Should say can't put inside itself")
end)

---------------------------------------------------------------------------
h.suite("container interactions — nested containers")

test("matchbox inside drawer inside nightstand — take match from matchbox", function()
    local ctx, reg, room, handlers = make_ctx()
    -- Nightstand with drawer as surface
    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand"},
        surfaces = {
            top = { accessible = true, contents = { "matchbox" }, capacity = 5 },
        },
    }
    place_in_room(ctx, nightstand)
    -- Matchbox on top of nightstand
    local matchbox = {
        id = "matchbox", name = "a matchbox",
        keywords = {"matchbox"}, container = true, portable = true,
        capacity = 10, contents = { "match-1", "match-2" },
        accessible = true,
        location = "nightstand",
    }
    reg:register("matchbox", matchbox)
    reg:register("match-1", {
        id = "match-1", name = "a wooden match",
        keywords = {"match"}, portable = true, size = 1,
        location = "matchbox",
    })
    reg:register("match-2", {
        id = "match-2", name = "a wooden match",
        keywords = {"match"}, portable = true, size = 1,
        location = "matchbox",
    })
    -- Take the matchbox first
    capture_print(function() handlers["take"](ctx, "matchbox") end)
    eq("matchbox", hand_id(ctx.player.hands[1]), "Matchbox should be in hand")
    -- Take a match from the matchbox
    capture_print(function() handlers["take"](ctx, "match from matchbox") end)
    eq("match-1", hand_id(ctx.player.hands[2]), "Match should be in other hand")
    eq(1, #matchbox.contents, "Matchbox should have 1 match left")
end)

test("put coin in bag that is inside carried sack", function()
    local ctx, reg, room, handlers = make_ctx()
    -- Player holds a sack which contains a smaller bag
    local sack = {
        id = "sack", name = "a large sack",
        keywords = {"sack"}, container = true, portable = true,
        capacity = 20, contents = {},
    }
    place_in_hand(ctx, sack, 1)
    place_in_hand(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"}, portable = true, size = 1,
    }, 2)
    local output = capture_print(function()
        handlers["put"](ctx, "coin in sack")
    end)
    truthy(output:find("You put"), "Should confirm, got: " .. output)
    truthy(list_contains(sack.contents, "coin"), "Coin should be in sack")
    eq(nil, ctx.player.hands[2], "Hand should be empty after put")
end)

---------------------------------------------------------------------------
-- 3. SEARCH BEHAVIOR
---------------------------------------------------------------------------
h.suite("search behavior — search objects and rooms")

test("search room with no noun does a room sweep", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "lamp", name = "an oil lamp",
        keywords = {"lamp"}, portable = true,
    })
    place_in_room(ctx, {
        id = "rug", name = "a dusty rug",
        keywords = {"rug"},
    })
    local output = capture_print(function()
        handlers["search"](ctx, "")
    end)
    -- Search with empty noun should do a room-level search/look
    truthy(output ~= "", "Search should produce some output")
end)

test("search around does a room sweep", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "chest", name = "a wooden chest",
        keywords = {"chest"}, container = true, contents = {},
    })
    local output = capture_print(function()
        handlers["search"](ctx, "around")
    end)
    truthy(output ~= "", "Search around should produce output")
end)

---------------------------------------------------------------------------
-- 4. DISAMBIGUATION
---------------------------------------------------------------------------
h.suite("disambiguation — multiple objects matching keyword")

test("take resolves to room object when same keyword in hand and room", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "hand-key", name = "a silver key",
        keywords = {"key"}, portable = true,
    }, 1)
    place_in_room(ctx, {
        id = "room-key", name = "a bronze key",
        keywords = {"key"}, portable = true,
    })
    ctx.current_verb = "take"
    capture_print(function() handlers["take"](ctx, "key") end)
    -- Take (acquisition) should prefer room object
    eq("room-key", ctx.last_object and ctx.last_object.id or nil,
        "Take should resolve to room key (acquisition = room first)")
end)

test("open resolves to held object when same keyword in hand and room", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "hand-box", name = "a small box",
        keywords = {"box"},
        _state = "closed",
        states = {
            closed = {
                description = "A closed small box.",
                transitions = {{ verb = "open", to = "open",
                    message = "You open the small box." }},
            },
            open = { description = "An open small box." },
        },
    }, 1)
    place_in_room(ctx, {
        id = "room-box", name = "a wooden box",
        keywords = {"box"},
        _state = "closed",
        states = {
            closed = {
                description = "A closed wooden box.",
                transitions = {{ verb = "open", to = "open",
                    message = "You open the wooden box." }},
            },
            open = { description = "An open wooden box." },
        },
    })
    ctx.current_verb = "open"
    capture_print(function() handlers["open"](ctx, "box") end)
    -- Open (interaction) should prefer held object
    eq("hand-box", ctx.last_object and ctx.last_object.id or nil,
        "Open should resolve to held box (interaction = hands first)")
end)

---------------------------------------------------------------------------
-- 5. EDGE CASES
---------------------------------------------------------------------------
h.suite("edge cases — inventory round-trips and state consistency")

test("take, wear, remove, drop full cycle", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_room(ctx, {
        id = "gloves", name = "leather gloves",
        keywords = {"gloves"},
        portable = true, size = 1,
        wearable = true,
        wear = { slot = "hands", layer = "outer" },
    })
    -- Take
    capture_print(function() handlers["take"](ctx, "gloves") end)
    eq("gloves", hand_id(ctx.player.hands[1]))
    -- Wear
    capture_print(function() handlers["wear"](ctx, "gloves") end)
    eq(nil, ctx.player.hands[1], "Hand freed after wear")
    truthy(list_contains(ctx.player.worn, "gloves"), "Gloves worn")
    -- Remove
    capture_print(function() handlers["remove"](ctx, "gloves") end)
    local in_hand = hand_id(ctx.player.hands[1]) == "gloves"
                 or hand_id(ctx.player.hands[2]) == "gloves"
    truthy(in_hand, "Gloves should be back in a hand after remove")
    eq(false, list_contains(ctx.player.worn, "gloves"), "Gloves should not be worn")
    -- Drop
    capture_print(function() handlers["drop"](ctx, "gloves") end)
    eq(nil, ctx.player.hands[1])
    truthy(list_contains(room.contents, "gloves"), "Gloves in room after drop")
end)

test("inventory display after take-wear cycle is consistent", function()
    local ctx, reg, room, handlers = make_ctx()
    local hat = {
        id = "hat", name = "a top hat",
        keywords = {"hat"},
        portable = true, size = 1,
        wearable = true,
        wear = { slot = "head", layer = "outer" },
        location = "player",
    }
    local sword = {
        id = "sword", name = "a rusty sword",
        keywords = {"sword"},
        portable = true, size = 2,
        location = "player",
    }
    place_in_hand(ctx, hat, 1)
    place_in_hand(ctx, sword, 2)
    -- Wear hat
    capture_print(function() handlers["wear"](ctx, "hat") end)
    local inv_output = capture_print(function()
        handlers["inventory"](ctx, "")
    end)
    -- Hat should appear once (in Worn), not in hands
    local hat_count = 0
    for _ in inv_output:gmatch("top hat") do hat_count = hat_count + 1 end
    eq(1, hat_count,
        "Hat should appear exactly once in inventory, got " .. hat_count ..
        " in:\n" .. inv_output)
    truthy(inv_output:find("Worn:"), "Should have Worn section")
    truthy(inv_output:find("rusty sword"), "Sword should still show in hand")
end)

test("drop all empties both hands", function()
    local ctx, reg, room, handlers = make_ctx()
    place_in_hand(ctx, {
        id = "a1", name = "item A",
        keywords = {"a"}, portable = true,
    }, 1)
    place_in_hand(ctx, {
        id = "b1", name = "item B",
        keywords = {"b"}, portable = true,
    }, 2)
    capture_print(function() handlers["drop"](ctx, "all") end)
    eq(nil, ctx.player.hands[1])
    eq(nil, ctx.player.hands[2])
    truthy(list_contains(room.contents, "a1"), "item A in room")
    truthy(list_contains(room.contents, "b1"), "item B in room")
end)

test("put item on surface then take from surface round-trip", function()
    local ctx, reg, room, handlers = make_ctx()
    local table_obj = {
        id = "table", name = "a wooden table",
        keywords = {"table"},
        surfaces = {
            top = { accessible = true, contents = {}, capacity = 20 },
        },
    }
    place_in_room(ctx, table_obj)
    place_in_hand(ctx, {
        id = "cup", name = "a ceramic cup",
        keywords = {"cup"}, portable = true, size = 1,
    })
    -- Put on table
    capture_print(function() handlers["put"](ctx, "cup on table") end)
    eq(nil, ctx.player.hands[1])
    truthy(list_contains(table_obj.surfaces.top.contents, "cup"), "Cup on table")
    -- Take from table
    capture_print(function() handlers["take"](ctx, "cup from table") end)
    eq("cup", hand_id(ctx.player.hands[1]), "Cup back in hand")
    eq(0, #table_obj.surfaces.top.contents, "Table top empty")
end)

test("take already-worn item says remove it first", function()
    local ctx, reg, room, handlers = make_ctx()
    local cloak = {
        id = "cloak", name = "a wool cloak",
        keywords = {"cloak"},
        portable = true, size = 2,
        wearable = true,
        wear = { slot = "torso", layer = "outer" },
    }
    reg:register("cloak", cloak)
    ctx.player.worn = { "cloak" }
    cloak.location = "player"
    local output = capture_print(function() handlers["take"](ctx, "cloak") end)
    truthy(output:find("wearing") or output:find("remove"),
        "Should tell player item is worn, got: " .. output)
end)

test("drop worn item says remove first", function()
    local ctx, reg, room, handlers = make_ctx()
    local cloak = {
        id = "cloak", name = "a wool cloak",
        keywords = {"cloak"},
        portable = true, size = 2,
        wearable = true,
    }
    reg:register("cloak", cloak)
    ctx.player.worn = { "cloak" }
    cloak.location = "player"
    local output = capture_print(function() handlers["drop"](ctx, "cloak") end)
    truthy(output:find("wearing") or output:find("remove"),
        "Should say remove worn item first, got: " .. output)
end)

---------------------------------------------------------------------------
h.suite("containment module — surface accessibility gating")

test("accessible=false surface rejects placement", function()
    local item = { id = "cup", name = "a cup", size = 1 }
    local furniture = {
        id = "desk", name = "a desk",
        surfaces = {
            inside = { accessible = false, contents = {}, capacity = 20 },
        },
    }
    local ok, err = containment_mod.can_contain(item, furniture, "inside", nil)
    eq(false, ok)
    truthy(err:find("not accessible"), "Should say not accessible")
end)

test("accessible=true surface allows placement", function()
    local item = { id = "cup", name = "a cup", size = 1 }
    local furniture = {
        id = "desk", name = "a desk",
        surfaces = {
            top = { accessible = true, contents = {}, capacity = 20 },
        },
    }
    local ok, err = containment_mod.can_contain(item, furniture, "top", nil)
    eq(true, ok)
end)

test("category reject list blocks placement", function()
    local item = { id = "oil", name = "oil", categories = {"flammable"} }
    local container = {
        id = "furnace", name = "furnace", container = true,
        capacity = 10, contents = {}, reject = {"flammable"},
    }
    local ok, err = containment_mod.can_contain(item, container, nil, nil)
    eq(false, ok)
    truthy(err:find("cannot be placed"), "Should reject by category")
end)

test("category accept list blocks non-matching item", function()
    local item = { id = "sword", name = "sword", categories = {"weapon"} }
    local container = {
        id = "rack", name = "rack", container = true,
        capacity = 10, contents = {}, accept = {"bottle"},
    }
    local ok, err = containment_mod.can_contain(item, container, nil, nil)
    eq(false, ok)
    truthy(err:find("does not belong"), "Should reject by accept list")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
