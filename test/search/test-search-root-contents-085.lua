-- test/search/test-search-root-contents-085.lua
-- Regression tests for Issue #85: search doesn't traverse root container
-- contents of objects with surfaces.
--
-- The nightstand has surfaces (top) AND root contents (drawer).  Prior to
-- fix, expand_object only queued surfaces — the drawer was invisible to
-- room-wide search.  "find match" skipped the drawer entirely.
--
-- Usage: lua test/search/test-search-root-contents-085.lua
-- Must be run from repository root.

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
local function run_search_to_completion(ctx, target, scope)
    local all_output = {}
    capture_print(function()
        search.search(ctx, target, scope)
    end)
    local max_steps = 50
    local step = 0
    local continues = true
    while continues and step < max_steps do
        local output = capture_print(function()
            continues = search.tick(ctx)
        end)
        if output ~= "" then
            all_output[#all_output + 1] = output
        end
        step = step + 1
    end
    if search.is_searching() then
        capture_print(function() search.abort(ctx) end)
    end
    return table.concat(all_output, "\n")
end

---------------------------------------------------------------------------
-- Context: nightstand with surfaces (top) AND root contents (drawer).
-- This mirrors the REAL game data where the drawer is a nested composite
-- part flattened into nightstand.contents (NOT into a surface).
---------------------------------------------------------------------------

local function make_root_contents_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "bedroom", name = "The Bedroom",
        description = "A dim bedchamber.",
        contents = {"nightstand"},
        proximity_list = {"nightstand"},
        light_level = 0,
    }

    local match1 = {
        id = "match-1", name = "a wooden match",
        keywords = {"match", "stick", "matchstick", "wooden match"},
        description = "A small wooden match.",
        size = 1, portable = true,
        categories = {"small", "consumable"},
    }

    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches"},
        description = "A battered little cardboard matchbox.",
        container = true, is_open = false,
        contents = {"match-1"},
        categories = {"small", "container"},
    }

    local drawer = {
        id = "drawer", name = "a small drawer",
        keywords = {"drawer", "small drawer", "nightstand drawer"},
        description = "A shallow wooden drawer.",
        container = true, is_open = false,
        contents = {"matchbox"},
        categories = {"furniture", "wooden", "container"},
    }

    -- Key: nightstand has ONLY a top surface — no "inside" surface.
    -- The drawer is in root contents, not in any surface.
    local nightstand = {
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
        contents = {"drawer"},   -- drawer is a root content, NOT in any surface
        parts = {
            drawer = {
                id = "drawer",
                name = "a small drawer",
                keywords = {"drawer", "small drawer"},
            },
        },
    }

    local candle_holder = {
        id = "candle-holder", name = "a brass candle holder",
        keywords = {"candle holder", "holder", "brass holder"},
        description = "A brass candle holder.",
        size = 1, portable = true,
    }

    reg:register("bedroom", room)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("drawer", drawer)
    reg:register("matchbox", matchbox)
    reg:register("match-1", match1)

    return {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, state = {} },
    }
end

---------------------------------------------------------------------------
-- #85: expand_object must queue root container contents
---------------------------------------------------------------------------

print("=== #85: expand_object queues root container contents ===")

test("build_queue includes drawer from nightstand root contents", function()
    local ctx = make_root_contents_ctx()
    local queue = traverse.build_queue(ctx.current_room, nil, "match", ctx.registry, nil)
    -- Queue should contain nightstand, nightstand_top surface, AND the drawer
    local has_drawer = false
    for _, entry in ipairs(queue) do
        if entry.object_id == "drawer" then
            has_drawer = true
            break
        end
    end
    truthy(has_drawer,
        "queue must include drawer from nightstand root contents. Queue IDs: "
        .. table.concat((function()
            local ids = {}
            for _, e in ipairs(queue) do ids[#ids+1] = e.object_id end
            return ids
        end)(), ", "))
end)

test("build_queue places drawer after nightstand surfaces", function()
    local ctx = make_root_contents_ctx()
    local queue = traverse.build_queue(ctx.current_room, nil, "match", ctx.registry, nil)
    local nightstand_idx, drawer_idx
    for i, entry in ipairs(queue) do
        if entry.object_id == "nightstand" then nightstand_idx = i end
        if entry.object_id == "drawer" then drawer_idx = i end
    end
    truthy(nightstand_idx and drawer_idx, "both nightstand and drawer must be in queue")
    truthy(drawer_idx > nightstand_idx, "drawer should come after nightstand in queue")
end)

---------------------------------------------------------------------------
-- #85: Full search traversal — room-wide "find match" with root contents
---------------------------------------------------------------------------

print("\n=== #85: Room-wide 'find match' traverses root contents ===")

test("'find match' finds match through root-content drawer (not surface)", function()
    local ctx = make_root_contents_ctx()
    local output = run_search_to_completion(ctx, "match", nil)
    -- Should find the match
    local lower = output:lower()
    truthy(lower:find("found") or lower:find("match"),
        "search should find a match. Output: " .. output)
    -- Should NOT say "no match found"
    truthy(not lower:find("no match found"),
        "should NOT report 'no match found'. Output: " .. output)
end)

test("'find match' mentions the drawer during traversal", function()
    local ctx = make_root_contents_ctx()
    local output = run_search_to_completion(ctx, "match", nil)
    local lower = output:lower()
    truthy(lower:find("drawer"),
        "search output should mention the drawer. Output: " .. output)
end)

test("'find matchbox' finds matchbox inside root-content drawer", function()
    local ctx = make_root_contents_ctx()
    local output = run_search_to_completion(ctx, "matchbox", nil)
    local lower = output:lower()
    truthy(lower:find("matchbox"),
        "should find matchbox through root-content drawer. Output: " .. output)
    truthy(not lower:find("no matchbox found"),
        "should NOT report not found. Output: " .. output)
end)

test("'find drawer' finds drawer as root content of nightstand", function()
    local ctx = make_root_contents_ctx()
    local output = run_search_to_completion(ctx, "drawer", nil)
    local lower = output:lower()
    truthy(lower:find("drawer"),
        "should find drawer. Output: " .. output)
end)

test("undirected search enumerates drawer contents", function()
    local ctx = make_root_contents_ctx()
    local output = run_search_to_completion(ctx, nil, nil)
    local lower = output:lower()
    truthy(lower:find("matchbox") or lower:find("drawer"),
        "undirected search should visit the drawer or its contents. Output: " .. output)
end)

---------------------------------------------------------------------------
-- #85: visited set prevents double-expansion
---------------------------------------------------------------------------

print("\n=== #85: visited set prevents double processing ===")

test("drawer is not expanded twice if also in nested containers", function()
    local ctx = make_root_contents_ctx()
    local queue = traverse.build_queue(ctx.current_room, nil, nil, ctx.registry, nil)
    local drawer_count = 0
    for _, entry in ipairs(queue) do
        if entry.object_id == "drawer" then
            drawer_count = drawer_count + 1
        end
    end
    eq(1, drawer_count, "drawer should appear exactly once in queue")
end)

--- Results
os.exit(h.summary() > 0 and 1 or 0)
