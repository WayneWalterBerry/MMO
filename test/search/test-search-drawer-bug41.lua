-- test/search/test-search-drawer-bug41.lua
-- Regression tests for #41: "search the drawer" must be distinct from
-- "search nightstand". The drawer is a searchable sub-container with its
-- own contents and narration.
--
-- Bug: "search drawer" resolved to the parent nightstand and produced
-- identical output to "search nightstand".
--
-- Fix: Pass part_surface through search pipeline so traverse.build_queue
-- filters to only the part's mapped surface.

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
local traverse = require("engine.search.traverse")
local containers = require("engine.search.containers")
local narrator = require("engine.search.narrator")

-- Capture printed output
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

-- Run search to completion with safety limit
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

-- Start a search and run to completion
local function full_search(ctx, target, scope, part_surface, max_steps)
    if search.is_searching() then search.abort(ctx) end
    local start_output = capture_print(function()
        search.search(ctx, target, scope, part_surface)
    end)
    local output, steps = run_search_to_completion(ctx, max_steps)
    return start_output .. "\n" .. output, steps
end

---------------------------------------------------------------------------
-- Context builders
---------------------------------------------------------------------------

--- Dark bedroom with nightstand (drawer closed).
-- Nightstand top: candle-holder, poison-bottle
-- Nightstand inside (drawer): matchbox, thimble
local function make_dark_bedroom_closed()
    local reg = registry_mod.new()

    local room = {
        id = "test-bedroom",
        name = "Test Bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand", "bedside table"},
        description = "A squat nightstand of knotted pine.",
        categories = {"furniture", "wooden", "container"},
        _state = "closed_with_drawer",
        is_container = true,
        is_open = false,
        is_locked = false,
        states = {
            closed_with_drawer = {
                surfaces = {
                    top = { capacity = 3, max_item_size = 2, contents = {} },
                    inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
                },
            },
            open_with_drawer = {
                surfaces = {
                    top = { capacity = 3, max_item_size = 2, contents = {} },
                    inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = true },
                },
            },
        },
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder", "poison-bottle"} },
            inside = { capacity = 2, max_item_size = 1, contents = {"matchbox", "thimble"}, accessible = false },
        },
        contents = {"candle-holder", "poison-bottle", "matchbox", "thimble"},
        parts = {
            drawer = {
                id = "nightstand-drawer",
                name = "a small drawer",
                keywords = {"drawer", "small drawer", "nightstand drawer"},
                surface = "inside",
                description = "A small wooden drawer.",
                is_container = true,
                is_open = false,
                contents = {"matchbox", "thimble"},
            },
            legs = {
                id = "nightstand-legs",
                detachable = false,
                keywords = {"leg", "legs"},
                name = "four wooden legs",
            },
        },
    }

    local candle_holder = {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "brass"},
        description = "A brass candle holder.",
    }
    local poison_bottle = {
        id = "poison-bottle",
        name = "a small glass bottle",
        keywords = {"bottle", "glass bottle"},
        description = "A small glass bottle.",
    }
    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "box of matches"},
        description = "A small matchbox.",
        categories = {"small", "container"},
        container = true,
        is_open = false,
        contents = {},
    }
    local thimble = {
        id = "thimble",
        name = "a brass thimble",
        keywords = {"thimble"},
        description = "A small brass thimble.",
    }

    reg:register("test-bedroom", room)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("poison-bottle", poison_bottle)
    reg:register("matchbox", matchbox)
    reg:register("thimble", thimble)

    room.proximity_list = {"nightstand"}
    room.contents = {"nightstand"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, state = {}, worn_items = {}, bags = {}, worn = {} },
        injuries = {},
        last_noun = nil,
        last_object = nil,
        time_offset = 20,
        game_start_time = os.time(),
    }

    return ctx, reg, room
end

--- Same bedroom but drawer is open (accessible = true).
local function make_dark_bedroom_open()
    local ctx, reg, room = make_dark_bedroom_closed()
    local nightstand = reg:get("nightstand")
    nightstand._state = "open_with_drawer"
    nightstand.surfaces.inside.accessible = true
    return ctx, reg, room
end

--- Lit version (for vision-mode narration tests).
local function make_lit_bedroom_open()
    local ctx, reg, room = make_dark_bedroom_open()
    room.light_level = 1
    return ctx, reg, room
end

---------------------------------------------------------------------------
h.suite("1. QUEUE BUILDING — part_surface filters correctly")
---------------------------------------------------------------------------

test("build_queue with part_surface='inside' includes only inside surface", function()
    local ctx = make_dark_bedroom_open()
    local queue = traverse.build_queue(ctx.current_room, "nightstand", nil, ctx.registry, "inside")

    -- Should have exactly 1 entry: the inside surface
    eq(1, #queue, "Queue must have exactly 1 entry for part_surface='inside', got " .. #queue)
    eq("surface", queue[1].type, "Entry must be surface type")
    eq("inside", queue[1].surface_name, "Entry must be the 'inside' surface")
    truthy(queue[1].direct_part_search, "Entry must have direct_part_search flag")
end)

test("build_queue without part_surface includes all entries", function()
    local ctx = make_dark_bedroom_open()
    local queue = traverse.build_queue(ctx.current_room, "nightstand", nil, ctx.registry, nil)

    -- Should have object + top + inside = 3 entries
    local has_object = false
    local has_top = false
    local has_inside = false
    for _, entry in ipairs(queue) do
        if entry.type == "object" then has_object = true end
        if entry.surface_name == "top" then has_top = true end
        if entry.surface_name == "inside" then has_inside = true end
    end
    truthy(has_object, "Queue must include object entry")
    truthy(has_top, "Queue must include top surface")
    truthy(has_inside, "Queue must include inside surface")
end)

test("build_queue via part fallback picks up surface from part definition", function()
    local ctx = make_dark_bedroom_open()
    -- Simulate what happens when build_queue is called with scope="nightstand-drawer"
    -- (part ID not in proximity list → falls through to BUG-082 part search)
    local queue = traverse.build_queue(ctx.current_room, "nightstand-drawer", nil, ctx.registry)

    -- Should filter to the inside surface only
    eq(1, #queue, "Queue must have exactly 1 entry when scope is part ID, got " .. #queue)
    eq("inside", queue[1].surface_name, "Entry must be inside surface")
    truthy(queue[1].direct_part_search, "Entry must have direct_part_search flag")
end)

---------------------------------------------------------------------------
h.suite("2. SEARCH DRAWER (open) — distinct from search nightstand")
---------------------------------------------------------------------------

test("'search drawer' (open) shows drawer contents", function()
    local ctx = make_dark_bedroom_open()
    local output = full_search(ctx, nil, "nightstand", "inside")

    truthy(output:find("matchbox") or output:find("thimble"),
           "'search drawer' must find drawer contents. Got: " .. output)
end)

test("'search drawer' (open) uses drawer-specific narration", function()
    local ctx = make_dark_bedroom_open()
    local output = full_search(ctx, nil, "nightstand", "inside")

    truthy(output:find("rummage through the drawer"),
           "'search drawer' must use 'rummage through the drawer' narration. Got: " .. output)
end)

test("'search drawer' does NOT mention nightstand top surface items", function()
    local ctx = make_dark_bedroom_open()
    local output = full_search(ctx, nil, "nightstand", "inside")

    local has_top_items = output:find("candle holder") or output:find("poison") or output:find("glass bottle")
    truthy(not has_top_items,
           "'search drawer' must NOT show top surface items. Got: " .. output)
end)

test("'search nightstand' mentions both top and inside contents", function()
    local ctx = make_dark_bedroom_open()
    local output = full_search(ctx, nil, "nightstand", nil)

    -- Should find at least one top item and at least one inside item
    local has_top = output:find("candle") or output:find("bottle")
    local has_inside = output:find("matchbox") or output:find("thimble")
    truthy(has_top, "'search nightstand' must find top items. Got: " .. output)
    truthy(has_inside, "'search nightstand' must find inside items. Got: " .. output)
end)

test("'search drawer' and 'search nightstand' produce DIFFERENT output", function()
    local ctx1 = make_dark_bedroom_open()
    local ctx2 = make_dark_bedroom_open()

    local drawer_output = full_search(ctx1, nil, "nightstand", "inside")
    local nightstand_output = full_search(ctx2, nil, "nightstand", nil)

    truthy(drawer_output ~= nightstand_output,
           "Drawer and nightstand searches must produce different output")
end)

---------------------------------------------------------------------------
h.suite("3. SEARCH DRAWER (closed) — blocked message")
---------------------------------------------------------------------------

test("'search drawer' when closed says open it first", function()
    local ctx = make_dark_bedroom_closed()
    local output = full_search(ctx, nil, "nightstand", "inside")

    truthy(output:find("closed") or output:find("open it first") or output:find("need to open"),
           "'search drawer' when closed must mention opening. Got: " .. output)
end)

test("'search drawer' when closed does NOT show drawer contents", function()
    local ctx = make_dark_bedroom_closed()
    local output = full_search(ctx, nil, "nightstand", "inside")

    local shows_contents = output:find("matchbox") or output:find("thimble")
    truthy(not shows_contents,
           "Closed drawer search must NOT reveal contents. Got: " .. output)
end)

test("'search nightstand' when closed still peeks into drawer", function()
    local ctx = make_dark_bedroom_closed()
    local output = full_search(ctx, nil, "nightstand", nil)

    -- Existing peek behavior: search nightstand can peek even when drawer is closed
    local finds_something = output:find("matchbox") or output:find("thimble")
        or output:find("candle") or output:find("bottle")
    truthy(finds_something,
           "'search nightstand' must still find contents when closed. Got: " .. output)
end)

---------------------------------------------------------------------------
h.suite("4. ARTICLE HANDLING — 'search the drawer' = 'search drawer'")
---------------------------------------------------------------------------

test("part_surface filtering works regardless of article", function()
    -- Articles are stripped before find_visible in the verb handler.
    -- This test validates the search pipeline itself treats the same
    -- part_surface identically.
    local ctx1 = make_dark_bedroom_open()
    local ctx2 = make_dark_bedroom_open()

    local output1 = full_search(ctx1, nil, "nightstand", "inside")
    local output2 = full_search(ctx2, nil, "nightstand", "inside")

    eq(output1, output2, "'search drawer' and 'search the drawer' must produce same output")
end)

---------------------------------------------------------------------------
h.suite("5. OPEN DRAWER THEN SEARCH — shows contents")
---------------------------------------------------------------------------

test("open drawer then search shows drawer contents", function()
    local ctx = make_dark_bedroom_closed()
    local nightstand = ctx.registry:get("nightstand")

    -- Simulate opening the drawer (FSM state transition)
    nightstand._state = "open_with_drawer"
    nightstand.surfaces.inside.accessible = true

    local output = full_search(ctx, nil, "nightstand", "inside")
    truthy(output:find("matchbox") or output:find("thimble"),
           "After opening, search drawer must find contents. Got: " .. output)
end)

test("open drawer then search uses rummage narration", function()
    local ctx = make_dark_bedroom_closed()
    local nightstand = ctx.registry:get("nightstand")

    -- Open the drawer
    nightstand._state = "open_with_drawer"
    nightstand.surfaces.inside.accessible = true

    local output = full_search(ctx, nil, "nightstand", "inside")
    truthy(output:find("rummage"),
           "After opening, drawer search must use rummage narration. Got: " .. output)
end)

---------------------------------------------------------------------------
h.suite("6. EMPTY DRAWER — correct narration")
---------------------------------------------------------------------------

test("search empty open drawer says empty", function()
    local ctx = make_dark_bedroom_open()
    local nightstand = ctx.registry:get("nightstand")

    -- Empty the drawer
    nightstand.surfaces.inside.contents = {}

    local output = full_search(ctx, nil, "nightstand", "inside")
    truthy(output:find("empty") or output:find("nothing"),
           "Empty drawer search must mention empty. Got: " .. output)
end)

test("search empty open drawer uses rummage narration", function()
    local ctx = make_dark_bedroom_open()
    local nightstand = ctx.registry:get("nightstand")
    nightstand.surfaces.inside.contents = {}

    local output = full_search(ctx, nil, "nightstand", "inside")
    truthy(output:find("rummage"),
           "Empty drawer must still use rummage narration. Got: " .. output)
end)

---------------------------------------------------------------------------
h.suite("7. NARRATOR — part-specific narrative functions")
---------------------------------------------------------------------------

test("narrator.part_closed returns closed message", function()
    local ctx = { current_room = { light_level = 0 } }
    local parent = { name = "a small nightstand" }
    local msg = narrator.part_closed(ctx, "inside", parent)
    truthy(msg:find("closed"), "part_closed must mention closed. Got: " .. msg)
    truthy(msg:find("open"), "part_closed must mention opening. Got: " .. msg)
end)

test("narrator.part_contents returns rummage message with items", function()
    local ctx = { current_room = { light_level = 0 } }
    local parent = { name = "a small nightstand" }
    local msg = narrator.part_contents(ctx, "inside", parent, {"matchbox", "thimble"})
    truthy(msg:find("rummage"), "part_contents must say rummage. Got: " .. msg)
    truthy(msg:find("matchbox"), "part_contents must list items. Got: " .. msg)
    truthy(msg:find("thimble"), "part_contents must list all items. Got: " .. msg)
end)

test("narrator.part_empty returns rummage+empty message", function()
    local ctx = { current_room = { light_level = 0 } }
    local parent = { name = "a small nightstand" }
    local msg = narrator.part_empty(ctx, "inside", parent)
    truthy(msg:find("rummage"), "part_empty must say rummage. Got: " .. msg)
    truthy(msg:find("empty"), "part_empty must say empty. Got: " .. msg)
end)

---------------------------------------------------------------------------
h.suite("8. SEARCH.SEARCH API — part_surface parameter")
---------------------------------------------------------------------------

test("search.search accepts part_surface parameter without error", function()
    local ctx = make_dark_bedroom_open()
    local ok = true
    local start_output = capture_print(function()
        ok = pcall(function()
            search.search(ctx, nil, "nightstand", "inside")
        end)
    end)
    truthy(ok, "search.search must accept part_surface parameter")
    -- Clean up
    if search.is_searching() then search.abort(ctx) end
end)

test("search.search with nil part_surface behaves as before", function()
    local ctx = make_dark_bedroom_open()
    local start_output = capture_print(function()
        search.search(ctx, nil, "nightstand", nil)
    end)
    truthy(start_output:find("begin searching"), "Should begin searching. Got: " .. start_output)
    if search.is_searching() then search.abort(ctx) end
end)

---------------------------------------------------------------------------
h.suite("9. NIGHTSTAND OBJECT — part surface mapping")
---------------------------------------------------------------------------

test("nightstand drawer part has surface='inside'", function()
    -- Load the actual nightstand object definition
    local nightstand = dofile(script_dir .. "/../../src/meta/objects/nightstand.lua")
    truthy(nightstand.parts ~= nil, "Nightstand must have parts")
    truthy(nightstand.parts.drawer ~= nil, "Nightstand must have drawer part")
    eq("inside", nightstand.parts.drawer.surface,
       "Drawer part must have surface='inside' mapping")
end)

---------------------------------------------------------------------------
h.suite("10. SAFETY — no infinite loops or crashes")
---------------------------------------------------------------------------

test("search drawer completes within safety limit", function()
    local ctx = make_dark_bedroom_open()
    local _, steps = full_search(ctx, nil, "nightstand", "inside", 30)
    truthy(steps < 30,
           "'search drawer' must complete within 30 ticks, took " .. steps)
    truthy(not search.is_searching(), "Search must terminate")
end)

test("search closed drawer completes within safety limit", function()
    local ctx = make_dark_bedroom_closed()
    local _, steps = full_search(ctx, nil, "nightstand", "inside", 30)
    truthy(steps < 30,
           "'search closed drawer' must complete within 30 ticks, took " .. steps)
    truthy(not search.is_searching(), "Search must terminate")
end)

test("search drawer then search nightstand sequentially works", function()
    local ctx = make_dark_bedroom_open()

    local output1 = full_search(ctx, nil, "nightstand", "inside")
    local output2 = full_search(ctx, nil, "nightstand", nil)

    truthy(output1 ~= "", "First search must produce output")
    truthy(output2 ~= "", "Second search must produce output")
    truthy(not search.is_searching(), "No active search after completion")
end)

---------------------------------------------------------------------------
-- Summary and exit
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
