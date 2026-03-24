-- test/verbs/test-event-output.lua
-- Tests for the event_output one-shot flavor text system (Phase A6b).
--
-- The event_output system fires once per event key (on_wear, on_take, on_drop,
-- on_remove_worn, on_eat, on_drink) then nils out that key so it never fires
-- again.
--
-- Covers:
--   1. Wear wool cloak → flavor text prints (event_output.on_wear fires)
--   2. Wear wool cloak AGAIN → no text (already consumed/nil'd)
--   3. Take object with event_output.on_take → text prints once
--   4. Object without event_output → no error, no output
--   5. Multiple events on same object → each fires independently
--
-- Usage: lua test/verbs/test-event-output.lua
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

local function make_ctx(objects, room_contents)
    local reg = make_registry(objects)
    return {
        registry = reg,
        current_room = {
            id = "test-room", name = "Test Room",
            description = "A plain room for testing.",
            contents = room_contents or {},
            exits = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
    }
end

---------------------------------------------------------------------------
-- Suite 1: on_wear event_output
---------------------------------------------------------------------------
h.suite("event_output: on_wear fires once")

test("wear wool cloak prints event_output flavor text", function()
    local cloak = {
        id = "wool-cloak", name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true, size = 3, weight = 3,
        wear = { slot = "back", layer = "outer", provides_warmth = true },
        event_output = {
            on_wear = "I need to get better outfits. I look like a peasant.",
        },
        location = "player",
    }
    local ctx = make_ctx({ ["wool-cloak"] = cloak })
    ctx.player.hands[1] = cloak

    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)

    truthy(output:find("peasant"),
        "event_output.on_wear text should appear. Output: " .. output)
end)

test("event_output.on_wear is nil'd after first wear", function()
    local cloak = {
        id = "wool-cloak", name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true, size = 3, weight = 3,
        wear = { slot = "back", layer = "outer", provides_warmth = true },
        event_output = {
            on_wear = "I need to get better outfits. I look like a peasant.",
        },
        location = "player",
    }
    local ctx = make_ctx({ ["wool-cloak"] = cloak })
    ctx.player.hands[1] = cloak

    capture_output(function() handlers["wear"](ctx, "cloak") end)

    eq(nil, cloak.event_output["on_wear"],
        "on_wear should be nil after first wear")
end)

test("wear wool cloak AGAIN produces no event_output text", function()
    local cloak = {
        id = "wool-cloak", name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true, size = 3, weight = 3,
        wear = { slot = "back", layer = "outer", provides_warmth = true },
        event_output = {
            on_wear = "I need to get better outfits. I look like a peasant.",
        },
        location = "player",
    }
    local ctx = make_ctx({ ["wool-cloak"] = cloak })
    ctx.player.hands[1] = cloak

    -- First wear: consume the event
    capture_output(function() handlers["wear"](ctx, "cloak") end)

    -- Remove cloak (put it back in hand)
    capture_output(function() handlers["remove"](ctx, "cloak") end)

    -- Second wear: event_output should NOT fire
    local output2 = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)

    truthy(not output2:find("peasant"),
        "event_output.on_wear should NOT appear on second wear. Output: " .. output2)
end)

---------------------------------------------------------------------------
-- Suite 2: on_take event_output
---------------------------------------------------------------------------
h.suite("event_output: on_take fires once")

test("take object with event_output.on_take prints flavor text", function()
    local gem = {
        id = "test-gem", name = "a glowing gem",
        keywords = {"gem", "glowing gem"},
        portable = true, size = 1, weight = 1,
        event_output = {
            on_take = "The gem pulses warmly in your hand.",
        },
        location = "test-room",
    }
    local ctx = make_ctx({ ["test-gem"] = gem }, {"test-gem"})

    local output = capture_output(function()
        handlers["take"](ctx, "gem")
    end)

    truthy(output:find("pulses warmly"),
        "event_output.on_take text should appear. Output: " .. output)
end)

test("event_output.on_take is nil'd after first take", function()
    local gem = {
        id = "test-gem", name = "a glowing gem",
        keywords = {"gem", "glowing gem"},
        portable = true, size = 1, weight = 1,
        event_output = {
            on_take = "The gem pulses warmly in your hand.",
        },
        location = "test-room",
    }
    local ctx = make_ctx({ ["test-gem"] = gem }, {"test-gem"})

    capture_output(function() handlers["take"](ctx, "gem") end)

    eq(nil, gem.event_output["on_take"],
        "on_take should be nil after first take")
end)

test("take same object again produces no event_output text", function()
    local gem = {
        id = "test-gem", name = "a glowing gem",
        keywords = {"gem", "glowing gem"},
        portable = true, size = 1, weight = 1,
        event_output = {
            on_take = "The gem pulses warmly in your hand.",
        },
        location = "test-room",
    }
    local ctx = make_ctx({ ["test-gem"] = gem }, {"test-gem"})

    -- First take
    capture_output(function() handlers["take"](ctx, "gem") end)

    -- Drop it
    capture_output(function() handlers["drop"](ctx, "gem") end)

    -- Second take: on_take should be consumed
    local output2 = capture_output(function()
        handlers["take"](ctx, "gem")
    end)

    truthy(not output2:find("pulses warmly"),
        "event_output.on_take should NOT appear on second take. Output: " .. output2)
end)

---------------------------------------------------------------------------
-- Suite 3: object without event_output
---------------------------------------------------------------------------
h.suite("event_output: absent = no error")

test("object without event_output wears without error", function()
    local hat = {
        id = "test-hat", name = "a plain hat",
        keywords = {"hat", "plain hat"},
        portable = true, size = 1, weight = 1,
        wear = { slot = "head", layer = "outer" },
        location = "player",
    }
    local ctx = make_ctx({ ["test-hat"] = hat })
    ctx.player.hands[1] = hat

    h.assert_no_error(function()
        capture_output(function() handlers["wear"](ctx, "hat") end)
    end, "wearing object without event_output should not error")
end)

test("object without event_output produces no event text on take", function()
    local rock = {
        id = "test-rock", name = "a plain rock",
        keywords = {"rock", "plain rock"},
        portable = true, size = 1, weight = 1,
        location = "test-room",
    }
    local ctx = make_ctx({ ["test-rock"] = rock }, {"test-rock"})

    local output = capture_output(function()
        handlers["take"](ctx, "rock")
    end)

    -- Should contain "take" message but no event flavor
    truthy(output:find("take") or output:find("Take"),
        "should still get the take message. Output: " .. output)
end)

test("object with empty event_output table wears without error", function()
    local scarf = {
        id = "test-scarf", name = "a scarf",
        keywords = {"scarf"},
        portable = true, size = 1, weight = 1,
        wear = { slot = "back", layer = "outer" },
        event_output = {},
        location = "player",
    }
    local ctx = make_ctx({ ["test-scarf"] = scarf })
    ctx.player.hands[1] = scarf

    h.assert_no_error(function()
        capture_output(function() handlers["wear"](ctx, "scarf") end)
    end, "wearing object with empty event_output should not error")
end)

---------------------------------------------------------------------------
-- Suite 4: multiple events on same object fire independently
---------------------------------------------------------------------------
h.suite("event_output: multiple events fire independently")

test("on_take fires without affecting on_wear", function()
    local cloak = {
        id = "multi-cloak", name = "a magic cloak",
        keywords = {"cloak", "magic cloak"},
        portable = true, size = 2, weight = 2,
        wear = { slot = "back", layer = "outer" },
        event_output = {
            on_take = "It feels oddly alive in your hands.",
            on_wear = "The cloak settles around your shoulders with a sigh.",
        },
        location = "test-room",
    }
    local ctx = make_ctx({ ["multi-cloak"] = cloak }, {"multi-cloak"})

    -- Take: on_take fires
    local take_output = capture_output(function()
        handlers["take"](ctx, "cloak")
    end)
    truthy(take_output:find("oddly alive"),
        "on_take should fire. Output: " .. take_output)

    -- on_take consumed, on_wear intact
    eq(nil, cloak.event_output["on_take"], "on_take should be nil'd")
    truthy(cloak.event_output["on_wear"] ~= nil,
        "on_wear should still be present after on_take consumed")

    -- Wear: on_wear fires
    local wear_output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    truthy(wear_output:find("sigh"),
        "on_wear should fire independently. Output: " .. wear_output)
    eq(nil, cloak.event_output["on_wear"], "on_wear should be nil'd after wear")
end)

test("on_drop fires without affecting other events", function()
    local gem = {
        id = "multi-gem", name = "a cursed gem",
        keywords = {"gem", "cursed gem"},
        portable = true, size = 1, weight = 1,
        event_output = {
            on_take = "Your fingers tingle.",
            on_drop = "The gem screams as it leaves your grasp.",
        },
        location = "test-room",
    }
    local ctx = make_ctx({ ["multi-gem"] = gem }, {"multi-gem"})

    -- Take: on_take fires
    capture_output(function() handlers["take"](ctx, "gem") end)
    eq(nil, gem.event_output["on_take"], "on_take consumed")
    truthy(gem.event_output["on_drop"] ~= nil, "on_drop still intact after take")

    -- Drop: on_drop fires
    local drop_output = capture_output(function()
        handlers["drop"](ctx, "gem")
    end)
    truthy(drop_output:find("screams"),
        "on_drop should fire. Output: " .. drop_output)
    eq(nil, gem.event_output["on_drop"], "on_drop consumed after drop")
end)

test("on_remove_worn fires independently of on_wear", function()
    local cloak = {
        id = "remove-cloak", name = "a dusty cloak",
        keywords = {"cloak", "dusty cloak"},
        portable = true, size = 2, weight = 2,
        wear = { slot = "back", layer = "outer" },
        event_output = {
            on_wear = "Dust billows as you put it on.",
            on_remove_worn = "You feel naked without it.",
        },
        location = "player",
    }
    local ctx = make_ctx({ ["remove-cloak"] = cloak })
    ctx.player.hands[1] = cloak

    -- Wear: on_wear fires
    capture_output(function() handlers["wear"](ctx, "cloak") end)
    eq(nil, cloak.event_output["on_wear"], "on_wear consumed")
    truthy(cloak.event_output["on_remove_worn"] ~= nil,
        "on_remove_worn still intact after wear")

    -- Remove: on_remove_worn fires
    local remove_output = capture_output(function()
        handlers["remove"](ctx, "cloak")
    end)
    truthy(remove_output:find("naked"),
        "on_remove_worn should fire. Output: " .. remove_output)
    eq(nil, cloak.event_output["on_remove_worn"],
        "on_remove_worn consumed after remove")
end)

--- Results
os.exit(h.summary() > 0 and 1 or 0)
