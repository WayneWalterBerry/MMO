-- test/inventory/test-search-order.lua
-- Tests for verb-dependent object search order in find_visible.
--
-- Verifies the core design from docs/architecture/player/inventory.md:
--   Interaction verbs (use, light, drink, …) → Hands first
--   Acquisition verbs (take, examine, look, …) → Room first
--
-- When an object with the same keyword exists in BOTH hands and room,
-- the verb category determines which one find_visible returns.

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
        game_start_time = os.time(),
        time_offset = 4,
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

-- Register an object and put it in the player's hand
local function place_in_hand(ctx, obj_def, hand_slot)
    ctx.registry:register(obj_def.id, obj_def)
    hand_slot = hand_slot or 1
    if ctx.player.hands[1] == nil and hand_slot == 1 then
        ctx.player.hands[1] = obj_def.id
    elseif ctx.player.hands[2] == nil then
        ctx.player.hands[2] = obj_def.id
    end
    obj_def.location = "player"
    return obj_def
end

-------------------------------------------------------------------------------
h.suite("verb-dependent search — interaction verbs (hands first)")
-------------------------------------------------------------------------------

-- "light candle" with candle in hands AND in room → light handler calls
-- find_in_inventory first (hands-first), so it finds the held candle.
-- Verify via state change on the held candle (not ctx.last_object, which
-- is only set by find_visible, not find_in_inventory).
test("'light candle' acts on held candle (find_in_inventory path)", function()
    local ctx, reg, room, handlers = make_ctx()

    -- Candle on the floor
    place_in_room(ctx, {
        id = "room-candle", name = "a tallow candle",
        keywords = {"candle"}, portable = true,
        _state = "unlit",
        states = {
            unlit = {
                description = "An unlit candle.",
                transitions = {{ verb = "light", to = "lit",
                    message = "You light the candle." }},
            },
            lit = { description = "A lit candle." },
        },
    })

    -- Candle in hand (no requires_tool so it lights directly)
    place_in_hand(ctx, {
        id = "hand-candle", name = "a beeswax candle",
        keywords = {"candle"}, portable = true,
        _state = "unlit",
        states = {
            unlit = { description = "An unlit beeswax candle." },
            lit = { description = "A lit beeswax candle." },
        },
        transitions = {
            { from = "unlit", to = "lit", verb = "light",
              message = "You light the beeswax candle." },
        },
    })

    ctx.current_verb = "light"
    capture_print(function()
        handlers["light"](ctx, "candle")
    end)

    -- light handler uses find_in_inventory (hands-first), so hand candle is lit
    local hand_obj = reg:get("hand-candle")
    local room_obj = reg:get("room-candle")
    eq("lit", hand_obj._state,
       "light should act on held candle (via find_in_inventory)")
    eq("unlit", room_obj._state,
       "room candle should remain unlit")
end)

-- "drink wine" with wine in hands → drink handler calls find_in_inventory
-- first (always hands-first), not find_visible. Verify it doesn't say
-- "pick that up first" (which would mean find_in_inventory failed).
test("'drink wine' acts on wine in hands", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_hand(ctx, {
        id = "wine-bottle", name = "a bottle of wine",
        keywords = {"wine", "bottle"},
        portable = true,
    })

    ctx.current_verb = "drink"
    local output = capture_print(function()
        handlers["drink"](ctx, "wine")
    end)

    -- drink handler found wine via find_in_inventory (hands-first).
    -- It should NOT say "pick that up first" or "don't see that".
    eq(true, output:find("pick that up") == nil,
       "drink should find wine in hands via find_in_inventory")
end)

-- "open box" with box in hands AND in room → should pick hands
test("'open box' finds held box over room box", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "room-box", name = "a wooden box",
        keywords = {"box"},
        _state = "closed",
        states = {
            closed = {
                description = "A closed box.",
                transitions = {{ verb = "open", to = "open",
                    message = "You open the wooden box." }},
            },
            open = { description = "An open box." },
        },
    })

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
    })

    ctx.current_verb = "open"
    capture_print(function()
        handlers["open"](ctx, "box")
    end)

    eq("hand-box", ctx.last_object and ctx.last_object.id or nil,
       "open (interaction verb) should find hand box first")
end)

-- "close lid" with lid in hands AND in room → should pick hands
test("'close' is an interaction verb (hands first)", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "room-chest", name = "a chest",
        keywords = {"chest"},
        _state = "open",
        states = {
            open = {
                description = "An open chest.",
                transitions = {{ verb = "close", to = "closed",
                    message = "You close the chest." }},
            },
            closed = { description = "A closed chest." },
        },
    })

    place_in_hand(ctx, {
        id = "hand-chest", name = "a small chest",
        keywords = {"chest"},
        _state = "open",
        states = {
            open = {
                description = "An open small chest.",
                transitions = {{ verb = "close", to = "closed",
                    message = "You close the small chest." }},
            },
            closed = { description = "A closed small chest." },
        },
    })

    ctx.current_verb = "close"
    capture_print(function()
        handlers["close"](ctx, "chest")
    end)

    eq("hand-chest", ctx.last_object and ctx.last_object.id or nil,
       "close (interaction verb) should find hand chest first")
end)

-------------------------------------------------------------------------------
h.suite("verb-dependent search — acquisition verbs (room first)")
-------------------------------------------------------------------------------

-- "take candle" with candle in hands AND in room → should pick room
test("'take candle' finds room candle over held candle", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "room-candle", name = "a tallow candle",
        keywords = {"candle"}, portable = true,
    })

    place_in_hand(ctx, {
        id = "hand-candle", name = "a beeswax candle",
        keywords = {"candle"}, portable = true,
    })

    ctx.current_verb = "take"
    capture_print(function()
        handlers["take"](ctx, "candle")
    end)

    -- take should find the ROOM candle (room-first for acquisition)
    -- The player already holds hand-candle; take resolves to room-candle
    eq("room-candle", ctx.last_object and ctx.last_object.id or nil,
       "take (acquisition verb) should find room candle first")
end)

-- "examine painting" on wall → should find it (room first)
test("'examine painting' finds painting in room", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "painting", name = "a landscape painting",
        keywords = {"painting"},
        description = "A beautiful landscape in oils.",
    })

    ctx.current_verb = "examine"
    capture_print(function()
        handlers["examine"](ctx, "painting")
    end)

    eq("painting", ctx.last_object and ctx.last_object.id or nil,
       "examine (acquisition verb) should find painting in room")
end)

-- "feel statue" with statue only in room → should find it
test("'feel statue' finds statue in room (acquisition)", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "statue", name = "a marble statue",
        keywords = {"statue"},
        description = "A smooth marble figure.",
        feel = "Cool, polished stone beneath your fingertips.",
    })

    ctx.current_verb = "feel"
    capture_print(function()
        handlers["feel"](ctx, "statue")
    end)

    eq("statue", ctx.last_object and ctx.last_object.id or nil,
       "feel (acquisition verb) should find statue in room")
end)

-- "search crate" with crate in room → room-first search
test("'search' uses acquisition order (room first)", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "crate", name = "a wooden crate",
        keywords = {"crate"},
        description = "A battered crate.",
    })

    ctx.current_verb = "search"
    capture_print(function()
        handlers["search"](ctx, "crate")
    end)

    eq("crate", ctx.last_object and ctx.last_object.id or nil,
       "search (acquisition verb) should find crate in room")
end)

-------------------------------------------------------------------------------
h.suite("verb-dependent search — disambiguation (same keyword, different locations)")
-------------------------------------------------------------------------------

-- The canonical test: box in hand + box in room.
-- "open" → hand (interaction). "take" → room (acquisition). Same noun, different results.
test("same keyword resolves differently for open vs take", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "floor-box", name = "a floor box",
        keywords = {"box"}, portable = true,
    })

    place_in_hand(ctx, {
        id = "held-box", name = "a held box",
        keywords = {"box"}, portable = true,
    })

    -- "open box" → interaction → held-box
    ctx.current_verb = "open"
    ctx.last_object = nil
    capture_print(function()
        handlers["open"](ctx, "box")
    end)
    eq("held-box", ctx.last_object and ctx.last_object.id or nil,
       "open should resolve to held box")

    -- "take box" → acquisition → floor-box
    ctx.current_verb = "take"
    ctx.last_object = nil
    capture_print(function()
        handlers["take"](ctx, "box")
    end)
    eq("floor-box", ctx.last_object and ctx.last_object.id or nil,
       "take should resolve to floor box")
end)

-- "close chest" with chest in hand AND in room → hand (interaction)
-- "examine chest" with chest in hand AND in room → room (acquisition)
test("close vs examine resolve same keyword to different objects", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "room-chest", name = "a heavy chest",
        keywords = {"chest"},
        description = "A large iron-bound chest.",
    })

    place_in_hand(ctx, {
        id = "hand-chest", name = "a small chest",
        keywords = {"chest"},
    })

    -- "close chest" → interaction → hand-chest
    ctx.current_verb = "close"
    ctx.last_object = nil
    capture_print(function()
        handlers["close"](ctx, "chest")
    end)
    eq("hand-chest", ctx.last_object and ctx.last_object.id or nil,
       "close should resolve to held chest")

    -- "examine chest" → acquisition → room-chest
    ctx.current_verb = "examine"
    ctx.last_object = nil
    capture_print(function()
        handlers["examine"](ctx, "chest")
    end)
    eq("room-chest", ctx.last_object and ctx.last_object.id or nil,
       "examine should resolve to room chest")
end)

-------------------------------------------------------------------------------
h.suite("verb-dependent search — fallback (object in only one location)")
-------------------------------------------------------------------------------

-- Interaction verb but object only in room → still finds it
test("interaction verb finds room object when nothing in hands", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_room(ctx, {
        id = "lever", name = "a rusty lever",
        keywords = {"lever"},
        description = "A lever set into the wall.",
    })

    ctx.current_verb = "open"
    capture_print(function()
        handlers["open"](ctx, "lever")
    end)

    eq("lever", ctx.last_object and ctx.last_object.id or nil,
       "interaction verb should fall back to room when hands empty")
end)

-- Acquisition verb but object only in hands → still finds it
test("acquisition verb finds hand object when nothing in room", function()
    local ctx, reg, room, handlers = make_ctx()

    place_in_hand(ctx, {
        id = "coin", name = "a gold coin",
        keywords = {"coin"},
        description = "A shiny gold coin.",
    })

    ctx.current_verb = "examine"
    capture_print(function()
        handlers["examine"](ctx, "coin")
    end)

    eq("coin", ctx.last_object and ctx.last_object.id or nil,
       "acquisition verb should fall back to hands when room empty")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
