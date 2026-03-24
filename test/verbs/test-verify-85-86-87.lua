-- test/verbs/test-verify-85-86-87.lua
-- Verification tests for Issues #85, #86, #87 (Smithers' fixes)
--
-- #85: "find match" search traversal — expand_object queues root container
--      contents (not just surfaces). Matchbox inside drawer inside nightstand
--      must be found by room-wide search.
-- #86: "wear cloak" auto-pickup from containers — should auto-take and wear
--      from an open container without "aren't holding" error.
-- #87: "get matchbox" from containers — should be able to take items from
--      open nested containers via explicit "get X from Y" syntax.
--
-- Usage: lua test/verbs/test-verify-85-86-87.lua
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
    local old_print = _G.print
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
-- Shared test context builders
---------------------------------------------------------------------------

-- Nightstand with drawer (root content) containing matchbox containing match.
-- Mirrors the real game data: drawer is in nightstand.contents, NOT in a surface.
local function make_nightstand_ctx(drawer_open)
    local objects = {
        ["curtains"] = {
            id = "curtains", name = "curtains",
            allows_daylight = true, hidden = true,
        },
        ["match-1"] = {
            id = "match-1", name = "a wooden match",
            keywords = {"match", "stick", "matchstick", "wooden match"},
            description = "A small wooden match.",
            size = 1, portable = true,
            categories = {"small", "consumable"},
        },
        ["matchbox"] = {
            id = "matchbox", name = "a small matchbox",
            keywords = {"matchbox", "match box", "box of matches"},
            description = "A battered little cardboard matchbox.",
            container = true, is_open = true,
            contents = {"match-1"},
            size = 1, portable = true,
            categories = {"small", "container"},
        },
        ["drawer"] = {
            id = "drawer", name = "a small drawer",
            keywords = {"drawer", "small drawer", "nightstand drawer"},
            description = "A shallow wooden drawer.",
            container = true,
            is_open = drawer_open,
            accessible = drawer_open and true or false,
            contents = {"matchbox"},
            categories = {"furniture", "wooden", "container"},
        },
        ["candle-holder"] = {
            id = "candle-holder", name = "a brass candle holder",
            keywords = {"candle holder", "holder", "brass holder"},
            description = "A brass candle holder.",
            size = 1, portable = true,
        },
        ["nightstand"] = {
            id = "nightstand", name = "a small nightstand",
            keywords = {"nightstand", "table", "bedside table"},
            description = "A small nightstand with a drawer.",
            categories = {"furniture", "wooden"},
            surfaces = {
                top = {
                    accessible = true,
                    contents = {"candle-holder"},
                },
            },
            contents = {"drawer"},
            parts = {
                drawer = {
                    id = "drawer",
                    name = "a small drawer",
                    keywords = {"drawer", "small drawer"},
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
            id = "bedroom", name = "The Bedroom",
            description = "A dim bedchamber.",
            contents = {"curtains", "nightstand"},
            exits = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
    }
end

-- Wardrobe with wearable cloak inside
local function make_wardrobe_ctx(wardrobe_open)
    local accessible = wardrobe_open and true or false

    local objects = {
        ["curtains"] = {
            id = "curtains", name = "curtains",
            allows_daylight = true, hidden = true,
        },
        ["wool-cloak"] = {
            id = "wool-cloak", name = "a moth-eaten wool cloak",
            keywords = {"cloak", "wool cloak", "wool", "moth-eaten"},
            description = "A thick wool cloak, moth-eaten but warm.",
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
            _state = wardrobe_open and "open" or "closed",
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
-- #85: Search traversal — verify expand_object queues root container contents
---------------------------------------------------------------------------

h.suite("VERIFY #85: search traversal of root container contents")

-- We verify #85 by using the search module directly (same as the existing
-- test-search-root-contents-085.lua) but checking the end-to-end scenario:
-- "find match" when match is inside matchbox inside drawer inside nightstand.

local search_ok, search = pcall(require, "engine.search")
local traverse_ok, traverse = pcall(require, "engine.search.traverse")
local registry_ok, registry_mod = pcall(require, "engine.registry")

if search_ok and traverse_ok and registry_ok then

    -- Build a proper registry for search tests
    local function make_search_ctx(drawer_open)
        local reg = registry_mod.new()

        local room = {
            id = "bedroom", name = "The Bedroom",
            description = "A dim bedchamber.",
            contents = {"nightstand"},
            proximity_list = {"nightstand"},
            light_level = 0,
        }

        reg:register("bedroom", room)
        reg:register("nightstand", {
            id = "nightstand", name = "a small nightstand",
            keywords = {"nightstand", "table", "bedside table"},
            description = "A small nightstand with a drawer.",
            categories = {"furniture", "wooden"},
            surfaces = {
                top = { accessible = true, contents = {"candle-holder"} },
            },
            contents = {"drawer"},
            parts = {
                drawer = { id = "drawer", name = "a small drawer",
                           keywords = {"drawer", "small drawer"} },
            },
        })
        reg:register("candle-holder", {
            id = "candle-holder", name = "a brass candle holder",
            keywords = {"candle holder", "holder"},
            size = 1, portable = true,
        })
        reg:register("drawer", {
            id = "drawer", name = "a small drawer",
            keywords = {"drawer", "small drawer", "nightstand drawer"},
            container = true,
            is_open = drawer_open,
            contents = {"matchbox"},
            categories = {"furniture", "wooden", "container"},
        })
        reg:register("matchbox", {
            id = "matchbox", name = "a small matchbox",
            keywords = {"matchbox", "match box", "box of matches"},
            container = true, is_open = true,
            contents = {"match-1"},
            categories = {"small", "container"},
        })
        reg:register("match-1", {
            id = "match-1", name = "a wooden match",
            keywords = {"match", "stick", "matchstick"},
            size = 1, portable = true,
        })

        return {
            registry = reg,
            current_room = room,
            player = { hands = {nil, nil}, state = {} },
        }
    end

    -- Helper to run search to completion
    local function run_search(ctx, target, scope)
        local all_output = {}
        local old_print = _G.print
        local function cap_print(...)
            local parts = {}
            for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
            all_output[#all_output + 1] = table.concat(parts, "\t")
        end

        _G.print = cap_print
        search.search(ctx, target, scope)
        local max = 50
        local step = 0
        local continues = true
        while continues and step < max do
            continues = search.tick(ctx)
            step = step + 1
        end
        if search.is_searching() then search.abort(ctx) end
        _G.print = old_print
        return table.concat(all_output, "\n")
    end

    test("#85: build_queue includes drawer from nightstand root contents", function()
        local ctx = make_search_ctx(true)
        local queue = traverse.build_queue(ctx.current_room, nil, "match", ctx.registry, nil)
        local has_drawer = false
        for _, entry in ipairs(queue) do
            if entry.object_id == "drawer" then has_drawer = true; break end
        end
        truthy(has_drawer,
            "queue must include drawer from nightstand root contents")
    end)

    test("#85: 'find match' discovers match through root-content drawer", function()
        local ctx = make_search_ctx(true)
        local output = run_search(ctx, "match", nil)
        local lower = output:lower()
        truthy(lower:find("found") or lower:find("match"),
            "search should find a match. Output: " .. output)
        truthy(not lower:find("no match found"),
            "should NOT report 'no match found'. Output: " .. output)
    end)

    test("#85: 'find matchbox' discovers matchbox inside drawer", function()
        local ctx = make_search_ctx(true)
        local output = run_search(ctx, "matchbox", nil)
        local lower = output:lower()
        truthy(lower:find("matchbox"),
            "should find matchbox inside drawer. Output: " .. output)
    end)

else
    print("  [SKIP] Search module not available for #85 tests")
end

---------------------------------------------------------------------------
-- #86: Wear auto-pickup from open container
---------------------------------------------------------------------------

h.suite("VERIFY #86: wear auto-pickup from container")

test("#86: 'wear cloak' auto-takes from open wardrobe and wears", function()
    local ctx = make_wardrobe_ctx(true)
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    local lower = output:lower()
    -- Should NOT say "you aren't holding that"
    truthy(not lower:find("aren't holding"),
        "should auto-take from open wardrobe, not say 'aren't holding'. Output: " .. output)
    -- Should indicate the cloak was taken and/or worn
    truthy(lower:find("take") or lower:find("put") or lower:find("warmth") or lower:find("wear") or lower:find("don"),
        "should mention taking or wearing the cloak. Output: " .. output)
end)

test("#86: cloak moves from wardrobe to player.worn", function()
    local ctx = make_wardrobe_ctx(true)
    capture_output(function() handlers["wear"](ctx, "cloak") end)

    -- Cloak should be in player.worn
    local found_worn = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "wool-cloak" then found_worn = true; break end
    end
    truthy(found_worn, "wool-cloak should be in player.worn after wear")

    -- Cloak should be removed from wardrobe
    local wardrobe = ctx.registry:get("wardrobe")
    local still_inside = false
    for _, id in ipairs(wardrobe.surfaces.inside.contents or {}) do
        if id == "wool-cloak" then still_inside = true; break end
    end
    truthy(not still_inside, "wool-cloak should be removed from wardrobe")
end)

test("#86: 'wear cloak' from CLOSED wardrobe gives helpful message", function()
    local ctx = make_wardrobe_ctx(false)
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak")
    end)
    local lower = output:lower()
    -- Should NOT just say "you aren't holding that" — must be more helpful
    truthy(not lower:find("aren't holding"),
        "closed wardrobe should give helpful message, not generic error. Output: " .. output)
end)

---------------------------------------------------------------------------
-- #87: Get item from container (explicit "get X from Y")
---------------------------------------------------------------------------

h.suite("VERIFY #87: get item from open container")

test("#87: 'get matchbox from drawer' takes matchbox from open drawer", function()
    local ctx = make_nightstand_ctx(true)
    local output = capture_output(function()
        handlers["get"](ctx, "matchbox from drawer")
    end)
    local lower = output:lower()
    -- Should successfully take the matchbox
    truthy(lower:find("take") or lower:find("matchbox"),
        "should take matchbox from drawer. Output: " .. output)
    truthy(not lower:find("don't see") and not lower:find("no matchbox"),
        "should NOT say 'don't see'. Output: " .. output)
end)

test("#87: matchbox removed from drawer after 'get matchbox from drawer'", function()
    local ctx = make_nightstand_ctx(true)
    capture_output(function() handlers["get"](ctx, "matchbox from drawer") end)

    local drawer = ctx.registry:get("drawer")
    local still_there = false
    for _, id in ipairs(drawer.contents or {}) do
        if id == "matchbox" then still_there = true; break end
    end
    truthy(not still_there, "matchbox should be removed from drawer.contents")
end)

test("#87: matchbox in player hand after 'get matchbox from drawer'", function()
    local ctx = make_nightstand_ctx(true)
    capture_output(function() handlers["get"](ctx, "matchbox from drawer") end)

    local in_hand = false
    for i = 1, 2 do
        local h = ctx.player.hands[i]
        if h then
            local id = type(h) == "table" and h.id or h
            if id == "matchbox" then in_hand = true; break end
        end
    end
    truthy(in_hand, "matchbox should be in player's hand after get")
end)

test("#87: 'get matchbox from drawer' fails when drawer is closed", function()
    local ctx = make_nightstand_ctx(false)
    local output = capture_output(function()
        handlers["get"](ctx, "matchbox from drawer")
    end)
    local lower = output:lower()
    -- Should not silently succeed — drawer is closed
    truthy(not lower:find("you take"),
        "should not take from closed drawer. Output: " .. output)
end)

test("#87: 'get match from matchbox' works (nested container)", function()
    local ctx = make_nightstand_ctx(true)
    -- First take matchbox to hand
    local matchbox = ctx.registry:get("matchbox")
    matchbox.location = "player"
    ctx.player.hands[1] = matchbox
    -- Remove from drawer
    ctx.registry:get("drawer").contents = {}

    local output = capture_output(function()
        handlers["get"](ctx, "match from matchbox")
    end)
    local lower = output:lower()
    truthy(lower:find("take") or lower:find("match"),
        "should take match from held matchbox. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Regression: basic take still works
---------------------------------------------------------------------------

h.suite("REGRESSION: basic take from room floor")

test("take portable item from room floor works normally", function()
    local ctx = make_nightstand_ctx(true)
    -- Place matchbox directly in room (not in container)
    local matchbox = ctx.registry:get("matchbox")
    ctx.current_room.contents[#ctx.current_room.contents + 1] = "matchbox"
    ctx.registry:get("drawer").contents = {}  -- remove from drawer

    local output = capture_output(function()
        handlers["take"](ctx, "matchbox")
    end)
    local lower = output:lower()
    truthy(lower:find("take") or lower:find("matchbox"),
        "should take matchbox from floor. Output: " .. output)
end)

--- Results
os.exit(h.summary() > 0 and 1 or 0)
