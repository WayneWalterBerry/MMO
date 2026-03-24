-- test/search/test-drawer-accessibility.lua
-- Issue #149: Search compound commands fail for drawer items.
-- Drawer→matchbox→match chain is invisible to get after search.
--
-- Root cause: _fv_surfaces in verbs/init.lua never searches
-- root-level contents of objects that have surfaces (like nightstand).
-- The drawer lives in nightstand.contents (not in any surface zone),
-- so find_visible never reaches drawer→matchbox→match.
--
-- TDD: Tests written FIRST before the fix.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

local search = require("engine.search")
local registry_mod = require("engine.registry")
local containers = require("engine.search.containers")
local containment_mod = require("engine.containment")
local verbs_mod = require("engine.verbs")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Extract hand ID (hands can hold object tables or string IDs)
local function hid(hand)
    if type(hand) == "table" then return hand.id end
    return hand
end

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
    if not ok then error(err) end
    return table.concat(lines, "\n")
end

local function run_search_to_completion(ctx, max_steps)
    max_steps = max_steps or 50
    local step_count = 0
    local continues = true
    local all_output = {}
    while continues and step_count < max_steps do
        local output = capture_print(function()
            continues = search.tick(ctx)
        end)
        if output ~= "" then
            all_output[#all_output + 1] = output
        end
        step_count = step_count + 1
    end
    return table.concat(all_output, "\n"), step_count
end

local function full_find(ctx, target, scope)
    if search.is_searching() then search.abort(ctx) end
    capture_print(function()
        search.find(ctx, target, scope)
    end)
    return run_search_to_completion(ctx)
end

local function full_search(ctx, target, scope)
    if search.is_searching() then search.abort(ctx) end
    capture_print(function()
        search.search(ctx, target, scope)
    end)
    return run_search_to_completion(ctx)
end

---------------------------------------------------------------------------
-- Context builder: nightstand with drawer→matchbox→match nesting.
-- Mirrors real game structure from start-room.lua.
---------------------------------------------------------------------------

local function make_nightstand_room()
    local reg = registry_mod.new()
    local handlers = verbs_mod.create()

    local room = {
        id = "test-room",
        name = "A dim bedchamber",
        description = "A room with a nightstand.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    -- Nightstand: has surfaces (top) but drawer is in root contents
    local nightstand = {
        id = "nightstand",
        name = "a nightstand",
        keywords = {"nightstand", "stand", "table"},
        description = "A small wooden nightstand.",
        is_container = true,
        container = true,
        surfaces = {
            top = {
                capacity = 3,
                max_item_size = 2,
                contents = {"candle-holder"},
                accessible = true,
            },
        },
        -- Drawer goes in root contents (no surfaces.inside on nightstand)
        contents = {"drawer"},
        parts = {
            drawer = {
                id = "drawer",
                name = "a drawer",
                keywords = {"drawer"},
                surface = "inside",
            },
        },
        proximity_list = {"nightstand"},
    }

    local candle_holder = {
        id = "candle-holder",
        name = "a candle holder",
        keywords = {"candle holder", "holder", "candleholder"},
        description = "A brass candle holder.",
        container = true,
        contents = {"candle"},
        location = "nightstand",
    }

    local candle = {
        id = "candle",
        name = "a candle",
        keywords = {"candle", "tallow candle"},
        description = "A stub of tallow candle.",
        location = "candle-holder",
    }

    -- Drawer: starts closed, accessible=false
    local drawer = {
        id = "drawer",
        name = "a drawer",
        keywords = {"drawer"},
        description = "A small wooden drawer.",
        container = true,
        is_container = true,
        accessible = false,
        is_open = false,
        contents = {"matchbox"},
        location = "nightstand",
    }

    -- Matchbox: closed container inside drawer
    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "match box"},
        description = "A battered little cardboard matchbox.",
        container = true,
        is_container = true,
        accessible = false,
        is_open = false,
        capacity = 10,
        max_item_size = 1,
        contents = {"match-1", "match-2"},
        categories = {"small", "container"},
        location = "drawer",
    }

    local match1 = {
        id = "match-1",
        name = "a wooden match",
        keywords = {"match", "matchstick", "wooden match"},
        description = "A small wooden match.",
        size = 1,
        portable = true,
        categories = {"small"},
        location = "matchbox",
    }

    local match2 = {
        id = "match-2",
        name = "a wooden match",
        keywords = {"match", "matchstick", "wooden match"},
        description = "A small wooden match.",
        size = 1,
        portable = true,
        categories = {"small"},
        location = "matchbox",
    }

    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("candle", candle)
    reg:register("drawer", drawer)
    reg:register("matchbox", matchbox)
    reg:register("match-1", match1)
    reg:register("match-2", match2)

    room.contents = {"nightstand"}
    room.proximity_list = {"nightstand"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        containment = containment_mod,
        verbs = handlers,
        known_objects = {},
        time_offset = 0,
        last_noun = nil,
        last_object = nil,
        game_start_time = os.time(),
    }

    return ctx, reg, room, nightstand, drawer, matchbox, match1, handlers
end

---------------------------------------------------------------------------
-- Suite 1: Search opens drawer and matchbox — sets accessible
---------------------------------------------------------------------------

h.suite("1. Search opens nested containers in drawer chain (#149)")

test("search opens drawer (nightstand root content) during traversal", function()
    local ctx, reg, room, nightstand, drawer = make_nightstand_room()

    full_search(ctx, nil, "nightstand")

    truthy(containers.is_open(drawer),
        "drawer must be open after search nightstand; is_open=" .. tostring(drawer.is_open))
    truthy(drawer.accessible == true,
        "drawer.accessible must be true after search; got: " .. tostring(drawer.accessible))
end)

test("search opens matchbox inside drawer during traversal", function()
    local ctx, reg, room, nightstand, drawer, matchbox = make_nightstand_room()

    full_search(ctx, nil, "nightstand")

    truthy(containers.is_open(matchbox),
        "matchbox must be open after search nightstand; is_open=" .. tostring(matchbox.is_open))
    truthy(matchbox.accessible == true,
        "matchbox.accessible must be true after search; got: " .. tostring(matchbox.accessible))
end)

---------------------------------------------------------------------------
-- Suite 2: find match locates match inside drawer→matchbox chain
---------------------------------------------------------------------------

h.suite("2. find match works for drawer-nested items (#149)")

test("find match locates match-1 inside matchbox inside drawer", function()
    local ctx, reg, room, nightstand, drawer, matchbox, match1 = make_nightstand_room()

    local output = full_find(ctx, "match")

    -- Search should find the match
    truthy(ctx.last_noun ~= nil,
        "ctx.last_noun should be set after find match")
    eq("match-1", ctx.last_noun,
        "find should locate match-1 inside the matchbox")
end)

---------------------------------------------------------------------------
-- Suite 3: get match via verb handler after search (#149 core bug)
-- This is the ACTUAL failing scenario — the verb handler's find_visible
-- uses _fv_surfaces which doesn't traverse nightstand.contents→drawer.
---------------------------------------------------------------------------

h.suite("3. get match via verb handler after search (#149 core)")

test("get match succeeds after search opened drawer chain", function()
    local ctx, reg, room, nightstand, drawer, matchbox, match1, handlers = make_nightstand_room()

    -- First: search the nightstand to open everything
    full_search(ctx, nil, "nightstand")

    -- Verify pre-conditions: containers are open
    truthy(drawer.accessible == true, "pre: drawer accessible")
    truthy(matchbox.accessible == true, "pre: matchbox accessible")

    -- THE BUG: 'get match' handler should find match-1 via find_visible
    local output = capture_print(function()
        handlers["get"](ctx, "match")
    end)

    -- If the match was picked up, it should be in a hand
    local in_hand = (hid(ctx.player.hands[1]) == "match-1" or hid(ctx.player.hands[2]) == "match-1")
    truthy(in_hand,
        "match-1 must be in player's hand after 'get match'; hands=" ..
        tostring(hid(ctx.player.hands[1])) .. "," .. tostring(hid(ctx.player.hands[2])) ..
        " output: " .. output)
end)

test("get matchbox finds it after search opened drawer (even if not portable)", function()
    local ctx, reg, room, nightstand, drawer, matchbox, match1, handlers = make_nightstand_room()

    full_search(ctx, nil, "nightstand")

    -- The matchbox is found but may not be portable — the key test is that
    -- find_visible CAN see it (no "nothing called that nearby" message)
    local output = capture_print(function()
        handlers["get"](ctx, "matchbox")
    end)

    -- Should NOT get the "don't notice anything" message — matchbox is visible
    local not_found = output:find("don't notice anything") ~= nil
    truthy(not not_found,
        "matchbox must be findable via get after search; output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 4: find X, get X compound command for drawer items
---------------------------------------------------------------------------

h.suite("4. Compound find+get for drawer items (#149)")

test("find match then get match — compound command scenario", function()
    local ctx, reg, room, nightstand, drawer, matchbox, match1, handlers = make_nightstand_room()

    -- Step 1: find match (opens containers along the way)
    full_find(ctx, "match")

    truthy(drawer.accessible == true,
        "drawer must be accessible after find match")
    truthy(matchbox.accessible == true,
        "matchbox must be accessible after find match")

    -- Step 2: get match (the second half of the compound command)
    local output = capture_print(function()
        handlers["get"](ctx, "match")
    end)

    local in_hand = (hid(ctx.player.hands[1]) == "match-1" or hid(ctx.player.hands[2]) == "match-1")
    truthy(in_hand,
        "match-1 must be in player's hand after find+get; hands=" ..
        tostring(hid(ctx.player.hands[1])) .. "," .. tostring(hid(ctx.player.hands[2])) ..
        " output: " .. output)
end)

---------------------------------------------------------------------------
-- Suite 5: Deep nesting — all levels become accessible
---------------------------------------------------------------------------

h.suite("5. Deep nesting accessibility propagation (#149)")

test("3-level chain: drawer→matchbox→match all accessible after search", function()
    local ctx, reg, room, nightstand, drawer, matchbox, match1 = make_nightstand_room()

    full_search(ctx, nil, "nightstand")

    truthy(drawer.accessible == true, "drawer accessible")
    truthy(containers.is_open(drawer), "drawer open")
    truthy(matchbox.accessible == true, "matchbox accessible")
    truthy(containers.is_open(matchbox), "matchbox open")
    eq(2, #matchbox.contents, "matchbox should still contain 2 matches")
end)

test("nightstand surfaces still accessible after search", function()
    local ctx, reg, room, nightstand = make_nightstand_room()

    full_search(ctx, nil, "nightstand")

    truthy(nightstand.surfaces.top.accessible ~= false,
        "nightstand.surfaces.top must remain accessible")
    local found = false
    for _, id in ipairs(nightstand.surfaces.top.contents) do
        if id == "candle-holder" then found = true; break end
    end
    truthy(found, "candle-holder still on nightstand top")
end)

---------------------------------------------------------------------------
-- Suite 6: Wardrobe regression — surface-based containers still work
---------------------------------------------------------------------------

h.suite("6. Wardrobe regression — surface-based containers still work (#149)")

test("get needle from wardrobe→sack (surface-based path still works)", function()
    local reg = registry_mod.new()
    local handlers = verbs_mod.create()

    local wardrobe = {
        id = "wardrobe",
        name = "a wardrobe",
        keywords = {"wardrobe"},
        container = true,
        is_container = true,
        surfaces = {
            inside = {
                capacity = 10,
                contents = {"sack"},
                accessible = true,
            },
        },
        contents = {},
    }

    local sack = {
        id = "sack",
        name = "a burlap sack",
        keywords = {"sack", "burlap sack"},
        container = true,
        accessible = true,
        is_open = true,
        contents = {"needle"},
    }

    local needle = {
        id = "needle",
        name = "a needle",
        keywords = {"needle"},
        description = "A sewing needle.",
        portable = true,
        size = 1,
    }

    reg:register("wardrobe", wardrobe)
    reg:register("sack", sack)
    reg:register("needle", needle)

    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A room.",
        contents = {"wardrobe"},
        proximity_list = {"wardrobe"},
        exits = {},
        light_level = 0,
    }

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        containment = containment_mod,
        verbs = handlers,
        known_objects = {},
        time_offset = 0,
        last_noun = nil,
        last_object = nil,
        game_start_time = os.time(),
    }

    local output = capture_print(function()
        handlers["get"](ctx, "needle")
    end)

    local in_hand = (hid(ctx.player.hands[1]) == "needle" or hid(ctx.player.hands[2]) == "needle")
    truthy(in_hand,
        "needle must be in hand after 'get needle' from wardrobe→sack; hands=" ..
        tostring(hid(ctx.player.hands[1])) .. "," .. tostring(hid(ctx.player.hands[2])) ..
        " output: " .. output)
end)

local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
