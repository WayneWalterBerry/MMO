-- test/verbs/test-wear-container-086.lua
-- Regression tests for Issue #86: 'wear' after finding item in container
--
-- After "find cloak" finds the wool cloak in the wardrobe, "wear cloak"
-- should auto-take from an open container and wear, or give a helpful
-- message if the container is closed.
--
-- Usage: lua test/verbs/test-wear-container-086.lua
-- Must be run from repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

-- Create verb handlers
local handlers = verbs_mod.create()

-- Helper: capture print output
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

---------------------------------------------------------------------------
-- Build context with wardrobe containing a wearable cloak
---------------------------------------------------------------------------

local function make_wear_ctx(wardrobe_open)
    local accessible = wardrobe_open and true or false
    local wardrobe_state = wardrobe_open and "open" or "closed"

    local objects = {
        ["curtains"] = {
            id = "curtains", name = "curtains",
            allows_daylight = true, hidden = true,
        },
        ["wool-cloak"] = {
            id = "wool-cloak", name = "a moth-eaten wool cloak",
            keywords = {"cloak", "wool cloak", "wool", "moth-eaten"},
            description = "A thick wool cloak.",
            size = 2, weight = 3, portable = true,
            wearable = true,
            wear = { slot = "back", layer = "outer", provides_warmth = true },
            categories = {"fabric", "warm", "wearable"},
        },
        ["wardrobe"] = {
            id = "wardrobe", name = "a heavy wardrobe",
            keywords = {"wardrobe", "heavy wardrobe", "armoire"},
            description = "A heavy oak wardrobe.",
            categories = {"furniture", "wooden", "large", "container"},
            _state = wardrobe_state,
            surfaces = {
                inside = {
                    capacity = 8, max_item_size = 4,
                    accessible = accessible,
                    contents = {"wool-cloak"},
                },
            },
            states = {
                closed = {
                    surfaces = {
                        inside = { accessible = false, contents = {} },
                    },
                },
                open = {
                    surfaces = {
                        inside = { accessible = true, contents = {} },
                    },
                },
            },
        },
    }

    local reg = {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
    }

    return {
        registry = reg,
        current_room = {
            id = "test_room", name = "Test Room",
            description = "A test room.",
            contents = {"curtains", "wardrobe"},
            exits = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
    }
end

---------------------------------------------------------------------------
-- #86: Wear auto-pickup from open container
---------------------------------------------------------------------------

h.suite("#86: wear auto-pickup from open container")

test("wear cloak auto-takes from open wardrobe", function()
    local ctx = make_wear_ctx(true)
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    local lower = output:lower()
    truthy(not lower:find("aren't holding"),
        "should auto-take from open wardrobe, not say 'aren't holding'. Output: " .. output)
    truthy(lower:find("take") or lower:find("put") or lower:find("warmth"),
        "should mention taking or wearing the cloak. Output: " .. output)
end)

test("cloak is removed from wardrobe after auto-take+wear", function()
    local ctx = make_wear_ctx(true)
    capture_output(function() handlers["wear"](ctx, "cloak") end)
    local wardrobe = ctx.registry:get("wardrobe")
    local inside = wardrobe.surfaces.inside
    local cloak_still_there = false
    for _, id in ipairs(inside.contents or {}) do
        if id == "wool-cloak" then cloak_still_there = true end
    end
    truthy(not cloak_still_there,
        "wool-cloak should be removed from wardrobe contents after wear")
end)

test("cloak is in player worn list after auto-take+wear", function()
    local ctx = make_wear_ctx(true)
    capture_output(function() handlers["wear"](ctx, "cloak") end)
    local found_worn = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "wool-cloak" then found_worn = true; break end
    end
    truthy(found_worn, "wool-cloak should be in player.worn after wear")
end)

---------------------------------------------------------------------------
-- #86: Wear from closed container gives helpful message
---------------------------------------------------------------------------

h.suite("#86: wear from closed container gives helpful message")

test("wear cloak from closed wardrobe gives take-first message", function()
    local ctx = make_wear_ctx(false)
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    local lower = output:lower()
    truthy(lower:find("need to take") or lower:find("take.*first"),
        "should tell player to take item first. Output: " .. output)
    truthy(not lower:find("aren't holding"),
        "should give helpful message, not 'aren't holding'. Output: " .. output)
end)

test("cloak stays in wardrobe when container is closed", function()
    local ctx = make_wear_ctx(false)
    capture_output(function() handlers["wear"](ctx, "cloak") end)
    local wardrobe = ctx.registry:get("wardrobe")
    local found = false
    for _, id in ipairs(wardrobe.surfaces.inside.contents or {}) do
        if id == "wool-cloak" then found = true; break end
    end
    truthy(found, "wool-cloak should remain in closed wardrobe")
end)

---------------------------------------------------------------------------
-- #86: Wear from hands still works (regression check)
---------------------------------------------------------------------------

h.suite("#86: wear from hands still works (regression)")

test("wear cloak from hands works normally", function()
    local ctx = make_wear_ctx(false)
    local cloak = ctx.registry:get("wool-cloak")
    -- Remove from wardrobe
    ctx.registry:get("wardrobe").surfaces.inside.contents = {}
    -- Put cloak in hand
    cloak.location = "player"
    ctx.player.hands[1] = cloak
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    local lower = output:lower()
    truthy(lower:find("put") or lower:find("warmth") or lower:find("on your"),
        "should wear the cloak from hand. Output: " .. output)
end)

---------------------------------------------------------------------------
-- #86: Wear with full hands
---------------------------------------------------------------------------

h.suite("#86: wear with full hands")

test("wear from open container with full hands reports full", function()
    local ctx = make_wear_ctx(true)
    local r1 = { id = "rock1", name = "a rock", keywords = {"rock"} }
    local r2 = { id = "rock2", name = "a stone", keywords = {"stone"} }
    ctx.registry._objects["rock1"] = r1
    ctx.registry._objects["rock2"] = r2
    ctx.player.hands[1] = r1
    ctx.player.hands[2] = r2
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    local lower = output:lower()
    truthy(lower:find("hands are full") or lower:find("drop something"),
        "should report hands are full. Output: " .. output)
end)

--- Results
os.exit(h.summary() > 0 and 1 or 0)
