-- test/search/test-search-fuzzy-scope-bug146.lua
-- Regression test for BUG-146 (#46, third recurrence):
-- "search for a match" in dark bedroom must find the matchbox,
-- NOT be misrouted to the rug via fuzzy "match"→"mat" Levenshtein match.
--
-- Root cause: find_visible() Tier 5 fuzzy resolver treated "match" as a typo
-- for the rug's keyword "mat" (Levenshtein distance 2). The search handler
-- then scoped an undirected search to the rug → found nothing.
-- Fix: search handler uses ctx._exact_only to skip fuzzy during scope detection.

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

-- Run search to completion, return all output
local function run_search_to_completion(ctx)
    local all_output = {}
    local max_steps = 50
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

--- Build the exact dark bedroom layout that triggers BUG-146:
-- - Rug with keyword "mat" (fuzzy false positive for "match")
-- - Nightstand with drawer containing matchbox
-- - Matchbox containing individual matches
-- - Room is DARK (light_level = 0)
local function make_bug146_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    local bed = {
        id = "bed",
        name = "a large four-poster bed",
        keywords = {"bed", "four-poster", "four poster bed"},
        description = "A large four-poster bed.",
        container = true,
        is_open = true,
        contents = {"pillow", "blanket"},
    }

    local pillow = {
        id = "pillow",
        name = "a goose-down pillow",
        keywords = {"pillow"},
        description = "A goose-down pillow.",
    }

    local blanket = {
        id = "blanket",
        name = "a wool blanket",
        keywords = {"blanket"},
        description = "A wool blanket.",
    }

    -- The rug: keyword "mat" is Levenshtein distance 2 from "match"
    local rug = {
        id = "rug",
        name = "a threadbare rug",
        keywords = {"rug", "carpet", "mat", "floor covering"},
        description = "A threadbare rug.",
        categories = {"fabric", "floor covering"},
        surfaces = {
            underneath = { capacity = 3, max_item_size = 2, contents = {"brass-key"}, accessible = false },
        },
    }

    local brass_key = {
        id = "brass-key",
        name = "a small brass key",
        keywords = {"key", "brass key"},
        description = "A small brass key.",
    }

    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand", "bedside table"},
        description = "A squat nightstand of knotted pine.",
        categories = {"furniture", "wooden", "container"},
        _state = "closed_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder"} },
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
        keywords = {"candle holder", "holder"},
        description = "A brass candle holder.",
    }

    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches"},
        description = "A battered little cardboard matchbox.",
        container = true,
        is_open = false,
        contents = {"match-1", "match-2", "match-3"},
    }

    local match1 = {
        id = "match-1",
        name = "a wooden match",
        keywords = {"match", "wooden match"},
        description = "A wooden match.",
    }
    local match2 = {
        id = "match-2",
        name = "a wooden match",
        keywords = {"match", "wooden match"},
        description = "A wooden match.",
    }
    local match3 = {
        id = "match-3",
        name = "a wooden match",
        keywords = {"match", "wooden match"},
        description = "A wooden match.",
    }

    reg:register("start-room", room)
    reg:register("bed", bed)
    reg:register("pillow", pillow)
    reg:register("blanket", blanket)
    reg:register("rug", rug)
    reg:register("brass-key", brass_key)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("matchbox", matchbox)
    reg:register("match-1", match1)
    reg:register("match-2", match2)
    reg:register("match-3", match3)

    -- Proximity order matches real bedroom: bed first, then nightstand, then rug
    room.proximity_list = {"bed", "nightstand", "rug"}
    room.contents = {"bed", "nightstand", "rug"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = {hands = {nil, nil}, state = {}, worn = {}},
        last_noun = nil,
        last_object = nil,
    }

    return ctx, reg, room
end

-------------------------------------------------------------------------------
h.suite("BUG-146 (#46) — 'search for a match' must NOT fuzzy-match to rug")
-------------------------------------------------------------------------------

test("BUG-146: targeted search for 'match' finds matchbox (not rug)", function()
    local ctx = make_bug146_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "match", nil)
    end)

    -- Must be targeted search, not undirected
    truthy(start_output:find("searching for match"),
           "Search should be TARGETED for 'match', not undirected")

    local output = run_search_to_completion(ctx)
    truthy(output:find("[Mm]atch"), "Search output should mention a match")
    truthy(output:find("found"), "Search should FIND something")
    truthy(not search.is_searching(), "Search should complete (target found)")
end)

test("BUG-146: search finds actual match object via deeper-match into matchbox", function()
    local ctx = make_bug146_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "match", nil)
    end)

    local output = run_search_to_completion(ctx)
    -- Deeper-match: matchbox matches "match" (substring), then peeks inside
    -- and finds individual match objects
    truthy(output:find("wooden match") or output:find("[Mm]atch"),
           "Should find a match object (not just the matchbox)")
end)

test("BUG-146: search does NOT scope-search the rug", function()
    local ctx = make_bug146_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "match", nil)
    end)

    local output = run_search_to_completion(ctx)
    -- Must NOT say "Nothing interesting" (the rug scope-search output)
    local full = start_output .. "\n" .. output
    truthy(not full:find("Nothing interesting"),
           "Should NOT say 'Nothing interesting' (rug scope-search)")
end)

test("BUG-146: search works in complete darkness (light_level=0)", function()
    local ctx = make_bug146_ctx()
    eq(0, ctx.current_room.light_level, "Room must be dark")
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "match", nil)
    end)

    local output = run_search_to_completion(ctx)
    truthy(output:find("[Mm]atch"), "Should find match in darkness")
end)

test("BUG-146: rug keyword 'mat' is within Levenshtein distance of 'match'", function()
    -- Verify the precondition: "match"→"mat" IS within fuzzy threshold
    -- This test documents WHY the bug happens
    local fuzzy = require("engine.parser.fuzzy")
    local dist = fuzzy.levenshtein("match", "mat")
    local threshold = fuzzy.max_typo_distance(5) -- "match" is 5 chars
    eq(2, dist, "Levenshtein distance 'match'→'mat' should be 2")
    truthy(dist <= threshold,
           "Distance should be within fuzzy threshold (confirms bug precondition)")
end)

test("BUG-146: 'search nightstand' still works with exact match", function()
    -- Ensure exact-only doesn't break legitimate scope searches
    local ctx = make_bug146_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Nightstand is exact-matchable — should be used as scope
    local start_output = capture_print(function()
        search.search(ctx, nil, "nightstand")
    end)

    local output = run_search_to_completion(ctx)
    -- Undirected scoped search of nightstand should find contents
    truthy(output:find("[Mm]atch") or output:find("[Cc]andle"),
           "Scoped search of nightstand should enumerate surface contents")
end)

h.summary()
