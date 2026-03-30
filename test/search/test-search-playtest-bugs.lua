-- test/search/test-search-playtest-bugs.lua
-- Regression tests for play-test bugs #40, #43, #44
-- #40: Contradictory narration ("nothing there" + "Inside you find...")
-- #43: "search for a match" finds nothing in the dark bedroom
-- #44: Matches/matchbox missing from nightstand

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
    local result = fn()
    _G.print = old_print
    return table.concat(lines, "\n"), result
end

--- Build a realistic bedroom context matching start-room.lua layout.
-- Nightstand uses surfaces (top/inside) with accessible=false for drawer.
-- Matchbox is in nightstand.inside surface, with match objects inside matchbox.
local function make_bedroom_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
        light_level = 0, -- dark
    }

    local bed = {
        id = "bed",
        name = "bed",
        keywords = {"bed"},
        description = "A four-poster bed.",
    }

    -- Nightstand: furniture with surfaces (like the real nightstand.lua)
    -- Has "container" in categories so surfaces can be peeked during search.
    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand", "bedside table"},
        description = "A squat nightstand of knotted pine.",
        categories = {"furniture", "wooden", "container"},
        _state = "closed_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder", "poison-bottle"} },
            inside = { capacity = 2, max_item_size = 1, contents = {"matchbox"}, accessible = false },
        },
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
        keywords = {"bottle", "glass bottle", "poison bottle"},
        description = "A small glass bottle.",
    }

    local matchbox = {
        id = "matchbox",
        name = "Matchbox",
        keywords = {"matchbox", "box", "matches"},
        description = "A small box of matches.",
        is_container = true,
        is_open = false,
        contents = {"match-1", "match-2", "match-3"},
    }

    local match1 = {
        id = "match-1",
        name = "Match",
        keywords = {"match"},
        description = "A wooden match.",
    }
    local match2 = {
        id = "match-2",
        name = "Match",
        keywords = {"match"},
        description = "A wooden match.",
    }
    local match3 = {
        id = "match-3",
        name = "Match",
        keywords = {"match"},
        description = "A wooden match.",
    }

    reg:register("start-room", room)
    reg:register("bed", bed)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("poison-bottle", poison_bottle)
    reg:register("matchbox", matchbox)
    reg:register("match-1", match1)
    reg:register("match-2", match2)
    reg:register("match-3", match3)

    room.proximity_list = {"bed", "nightstand"}
    room.contents = {"bed", "nightstand"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = {hands = {nil, nil}, state = {}},
        last_noun = nil,
        last_object = nil,
    }

    return ctx, reg, room
end

-- Run search to completion, return all output
local function run_search_to_completion(ctx)
    local all_output = {}
    local max_steps = 30
    local step_count = 0
    local continues = true

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

-------------------------------------------------------------------------------
h.suite("#43/#44 — Matchbox findable via 'search for match' in dark bedroom")
-------------------------------------------------------------------------------

test("#43: 'search for match' finds matchbox in nightstand drawer", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "match", nil)
    end)

    local output = run_search_to_completion(ctx)
    truthy(output:find("[Mm]atch"), "Search should find something matching 'match'")
    truthy(not search.is_searching(), "Search should complete (target found)")
end)

test("#43: Deeper-match logic finds actual match inside matchbox", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "match", nil)
    end)

    local output = run_search_to_completion(ctx)
    -- The deeper-match logic should peek inside matchbox and find "Match"
    truthy(output:find("You have found") or output:find("[Mm]atch"),
           "Should find match via deeper-match into matchbox")
end)

test("#44: Matchbox is in nightstand 'inside' surface contents", function()
    local ctx = make_bedroom_ctx()
    local nightstand = ctx.registry:get("nightstand")
    local inside = nightstand.surfaces and nightstand.surfaces.inside
    truthy(inside ~= nil, "Nightstand should have 'inside' surface")
    truthy(inside and inside.contents, "Inside surface should have contents")

    local found_matchbox = false
    for _, id in ipairs(inside.contents or {}) do
        if id == "matchbox" then found_matchbox = true end
    end
    truthy(found_matchbox, "Matchbox should be in nightstand.inside.contents")
end)

test("#43: Nightstand is flagged as container (categories)", function()
    local ctx = make_bedroom_ctx()
    local nightstand = ctx.registry:get("nightstand")
    truthy(containers.is_container(nightstand),
           "Nightstand should be recognized as container")
end)

test("#43: Search works in darkness (light_level = 0)", function()
    local ctx = make_bedroom_ctx()
    eq(0, ctx.current_room.light_level, "Room should be dark")
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "match", nil)
    end)

    local output = run_search_to_completion(ctx)
    -- Search should still work in darkness (uses touch sense)
    truthy(output:find("[Mm]atch"),
           "Search should find match even in complete darkness")
end)

-------------------------------------------------------------------------------
h.suite("#40 — No contradictory narration for objects with surfaces")
-------------------------------------------------------------------------------

test("#40: Undirected search of nightstand does NOT say 'nothing there'", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, "nightstand")
    end)

    local output = run_search_to_completion(ctx)
    -- Should NOT contain "nothing there" or "Nothing." for the nightstand
    local has_nothing = output:find("[Nn]othing there") or output:find("[Nn]othing%.") or output:find("[Nn]othing notable")
    truthy(not has_nothing,
           "Should NOT say 'nothing there' when nightstand has contents in surfaces. Got: " .. output)
end)

test("#40: Undirected search of nightstand DOES report surface contents", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, "nightstand")
    end)

    local output = run_search_to_completion(ctx)
    -- Should report contents from surfaces
    truthy(output:find("candle") or output:find("bottle") or output:find("atchbox"),
           "Should report surface contents. Got: " .. output)
end)

test("#40: Room sweep skips 'nothing there' for nightstand", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, nil)
    end)

    local output = run_search_to_completion(ctx)
    -- Check that no single line contains BOTH nightstand and "nothing there"
    local nightstand_nothing = false
    for line in output:gmatch("[^\n]+") do
        if line:find("nightstand") and line:find("[Nn]othing") then
            nightstand_nothing = true
            break
        end
    end
    truthy(not nightstand_nothing,
           "Nightstand should not say 'nothing there' during room sweep")
end)

test("#40: Targeted search for nightstand still finds it", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "nightstand", nil)
    end)

    local output = run_search_to_completion(ctx)
    truthy(output:find("nightstand") or output:find("found"),
           "Targeted search should still find nightstand by name")
end)

-------------------------------------------------------------------------------
h.suite("TRAVERSE STEP — Surface objects suppress object-entry narration")
-------------------------------------------------------------------------------

test("traverse.step: object with surfaces returns enumerate narrative (undirected)", function()
    local ctx = make_bedroom_ctx()
    local queue = traverse.build_queue(ctx.current_room, "nightstand", nil, ctx.registry)

    -- Find the object entry for nightstand (not a surface entry)
    local obj_entry = nil
    for _, entry in ipairs(queue) do
        if entry.type == "object" and entry.object_id == "nightstand" then
            obj_entry = entry
            break
        end
    end
    truthy(obj_entry ~= nil, "Should have nightstand object entry in queue")

    local result = traverse.step(ctx, obj_entry, nil, false, nil, nil)
    truthy(result.narrative:find("nightstand"),
       "Object with surfaces should enumerate the object in undirected search")
end)

test("traverse.step: object with surfaces returns match if targeted", function()
    local ctx = make_bedroom_ctx()
    local queue = traverse.build_queue(ctx.current_room, nil, "nightstand", ctx.registry)

    local obj_entry = nil
    for _, entry in ipairs(queue) do
        if entry.type == "object" and entry.object_id == "nightstand" then
            obj_entry = entry
            break
        end
    end
    truthy(obj_entry ~= nil, "Should have nightstand object entry")

    local result = traverse.step(ctx, obj_entry, "nightstand", false, nil, nil)
    truthy(result.found, "Should find nightstand when targeted by name")
    eq("nightstand", result.item.id, "Found item should be nightstand")
end)

-------------------------------------------------------------------------------

-- Print summary
h.summary()
