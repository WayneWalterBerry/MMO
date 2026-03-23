-- test/search/test-search-nested-containers-084.lua
-- Regression tests for Issue #84: search doesn't recurse into nested containers
--
-- The nightstand has a drawer (nested), which contains a matchbox (contents),
-- which contains matches (contents). "find match" must traverse all 3 levels.
--
-- Usage: lua test/search/test-search-nested-containers-084.lua
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
-- Context: 3-level nesting — nightstand → drawer → matchbox → matches
-- Mirrors start-room.lua data structure exactly.
---------------------------------------------------------------------------

local function make_deep_nesting_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "bedroom", name = "The Bedroom",
        description = "A dim bedchamber.",
        contents = {"nightstand"},
        proximity_list = {"nightstand"},
        light_level = 0,
    }

    -- 7 match objects inside matchbox
    local matches = {}
    for i = 1, 7 do
        matches[i] = {
            id = "match-" .. i, name = "a wooden match",
            keywords = {"match", "stick", "matchstick", "wooden match"},
            description = "A small wooden match.",
            size = 1, portable = true,
            categories = {"small", "consumable"},
        }
    end

    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches"},
        description = "A battered little cardboard matchbox.",
        container = true,
        accessible = false,
        is_open = false,
        contents = {"match-1", "match-2", "match-3", "match-4",
                     "match-5", "match-6", "match-7"},
        categories = {"small", "container"},
    }

    local drawer = {
        id = "drawer", name = "a small drawer",
        keywords = {"drawer", "small drawer", "nightstand drawer"},
        description = "A shallow wooden drawer.",
        container = true,
        accessible = false,
        is_open = false,
        contents = {"matchbox"},
        categories = {"furniture", "wooden", "container"},
    }

    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand", "table", "bedside table"},
        description = "A small nightstand with a drawer.",
        is_container = true,
        is_open = false,
        categories = {"furniture", "wooden", "container"},
        surfaces = {
            top = {
                accessible = true,
                contents = {},
            },
            inside = {
                accessible = false,
                contents = {"drawer"},
            },
        },
        parts = {
            drawer = {
                id = "drawer",
                name = "a small drawer",
                surface = "inside",
            },
        },
    }

    reg:register("bedroom", room)
    reg:register("nightstand", nightstand)
    reg:register("drawer", drawer)
    reg:register("matchbox", matchbox)
    for i = 1, 7 do
        reg:register("match-" .. i, matches[i])
    end

    return {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, state = {} },
    }
end

---------------------------------------------------------------------------
-- Unit tests: matches_target recurses into closed nested containers
---------------------------------------------------------------------------

print("=== #84: matches_target recurses into closed containers ===")

test("matches_target finds match inside closed matchbox", function()
    local ctx = make_deep_nesting_ctx()
    local matchbox = ctx.registry:get("matchbox")
    local result = traverse._matches_target(matchbox, "match", ctx.registry, 0)
    truthy(result, "should find 'match' inside closed matchbox via contents")
end)

test("matches_target finds match inside closed drawer (2-level)", function()
    local ctx = make_deep_nesting_ctx()
    local drawer = ctx.registry:get("drawer")
    local result = traverse._matches_target(drawer, "match", ctx.registry, 0)
    truthy(result, "should find 'match' through drawer → matchbox → match")
end)

test("matches_target finds matchbox inside closed drawer", function()
    local ctx = make_deep_nesting_ctx()
    local drawer = ctx.registry:get("drawer")
    local result = traverse._matches_target(drawer, "matchbox", ctx.registry, 0)
    truthy(result, "should find 'matchbox' in drawer.contents")
end)

---------------------------------------------------------------------------
-- Unit tests: find_deeper_match recurses through multiple levels
---------------------------------------------------------------------------

print("\n=== #84: find_deeper_match recurses through nesting ===")

test("find_deeper_match in drawer finds match object (not matchbox)", function()
    local ctx = make_deep_nesting_ctx()
    local drawer = ctx.registry:get("drawer")
    local result = traverse._find_deeper_match(drawer, "match", ctx.registry)
    truthy(result, "should find a deeper match")
    truthy(result.id:match("^match%-"), "should be an actual match object, got: " .. tostring(result.id))
end)

test("find_deeper_match in drawer finds matchbox for 'matchbox' target", function()
    local ctx = make_deep_nesting_ctx()
    local drawer = ctx.registry:get("drawer")
    local result = traverse._find_deeper_match(drawer, "matchbox", ctx.registry)
    truthy(result, "should find matchbox")
    eq("matchbox", result.id)
end)

test("find_deeper_match in matchbox finds match object", function()
    local ctx = make_deep_nesting_ctx()
    local matchbox = ctx.registry:get("matchbox")
    local result = traverse._find_deeper_match(matchbox, "match", ctx.registry)
    truthy(result, "should find match inside matchbox")
    truthy(result.id:match("^match%-"), "should be a match object, got: " .. tostring(result.id))
end)

---------------------------------------------------------------------------
-- Integration tests: full search traversal through 3-level nesting
---------------------------------------------------------------------------

print("\n=== #84: Full search traversal — 3-level nesting ===")

test("'find match' finds matches inside matchbox inside drawer inside nightstand", function()
    local ctx = make_deep_nesting_ctx()
    local output = run_search_to_completion(ctx, "match", nil)
    -- Search should find an actual match, not report "no match"
    truthy(output:lower():find("match"), "output should mention match")
    -- Should NOT say "no match" or "nothing"
    local lower = output:lower()
    local no_match_fail = lower:find("no match") or lower:find("but no match")
    truthy(not no_match_fail,
        "should NOT report 'no match' — search must find matches through nesting. Output: " .. output)
end)

test("'find matchbox' finds matchbox inside drawer", function()
    local ctx = make_deep_nesting_ctx()
    local output = run_search_to_completion(ctx, "matchbox", nil)
    truthy(output:lower():find("matchbox"), "output should mention matchbox")
end)

test("'find drawer' finds drawer nested in nightstand", function()
    local ctx = make_deep_nesting_ctx()
    local output = run_search_to_completion(ctx, "drawer", nil)
    truthy(output:lower():find("drawer"), "output should mention drawer")
end)

---------------------------------------------------------------------------
-- traverse.step unit test: verify step result for nested target
---------------------------------------------------------------------------

print("\n=== #84: traverse.step finds nested targets ===")

test("step on inside surface finds 'match' through drawer→matchbox→match", function()
    local ctx = make_deep_nesting_ctx()
    local entry = {
        object_id = "nightstand_inside",
        type = "surface",
        depth = 0,
        parent_id = "nightstand",
        is_container = false,
        is_locked = false,
        is_open = true,
        surface_name = "inside",
    }
    local result = traverse.step(ctx, entry, "match", false, nil, nil)
    truthy(result.found, "should find 'match' inside nightstand's drawer. Narrative: " .. tostring(result.narrative))
    truthy(result.item, "should return a result item")
    truthy(result.item.id:match("^match%-"),
        "found item should be an actual match, got: " .. tostring(result.item.id))
end)

test("step on inside surface finds 'matchbox' through drawer", function()
    local ctx = make_deep_nesting_ctx()
    local entry = {
        object_id = "nightstand_inside",
        type = "surface",
        depth = 0,
        parent_id = "nightstand",
        is_container = false,
        is_locked = false,
        is_open = true,
        surface_name = "inside",
    }
    local result = traverse.step(ctx, entry, "matchbox", false, nil, nil)
    truthy(result.found, "should find 'matchbox' inside drawer. Narrative: " .. tostring(result.narrative))
    truthy(result.item, "should return a result item")
    eq("matchbox", result.item.id)
end)

test("step on inside surface finds 'drawer' directly", function()
    local ctx = make_deep_nesting_ctx()
    local entry = {
        object_id = "nightstand_inside",
        type = "surface",
        depth = 0,
        parent_id = "nightstand",
        is_container = false,
        is_locked = false,
        is_open = true,
        surface_name = "inside",
    }
    local result = traverse.step(ctx, entry, "drawer", false, nil, nil)
    truthy(result.found, "should find 'drawer'. Narrative: " .. tostring(result.narrative))
    truthy(result.item, "should return a result item")
    eq("drawer", result.item.id)
end)

---------------------------------------------------------------------------
-- Loader flatten_instances: verify 3-level deep nesting is flattened
---------------------------------------------------------------------------

print("\n=== #84: flatten_instances handles 3-level nesting ===")

local loader = require("engine.loader")

test("flatten_instances handles nightstand→drawer→matchbox→match", function()
    local instances = {
        { id = "nightstand", type_id = "ns-guid",
            nested = {
                { id = "drawer", type_id = "dr-guid",
                    contents = {
                        { id = "matchbox", type_id = "mb-guid",
                            contents = {
                                { id = "match-1", type_id = "m-guid" },
                                { id = "match-2", type_id = "m-guid" },
                            },
                        },
                    },
                },
            },
        },
    }

    local flat = loader.flatten_instances(instances)

    -- All 5 objects should be in flat list
    eq(5, #flat, "should have 5 flattened instances")

    -- Check locations
    local locs = {}
    for _, inst in ipairs(flat) do
        locs[inst.id] = inst.location
    end

    eq("room",       locs["nightstand"], "nightstand should be at room level")
    eq("nightstand", locs["drawer"],     "drawer should be inside nightstand")
    eq("drawer",     locs["matchbox"],   "matchbox should be inside drawer")
    eq("matchbox",   locs["match-1"],    "match-1 should be inside matchbox")
    eq("matchbox",   locs["match-2"],    "match-2 should be inside matchbox")
end)

test("flatten_instances clears nested/contents after walking", function()
    local instances = {
        { id = "nightstand", type_id = "ns-guid",
            nested = {
                { id = "drawer", type_id = "dr-guid",
                    contents = {
                        { id = "matchbox", type_id = "mb-guid" },
                    },
                },
            },
        },
    }

    local flat = loader.flatten_instances(instances)

    -- nested and contents arrays should be nil after flattening
    local ns = flat[1]
    eq(nil, ns.nested, "nightstand.nested should be nil after flatten")

    local dr
    for _, inst in ipairs(flat) do
        if inst.id == "drawer" then dr = inst; break end
    end
    truthy(dr, "drawer should exist in flat list")
    eq(nil, dr.contents, "drawer.contents should be nil after flatten (was instance array)")
end)

---------------------------------------------------------------------------
-- Results
---------------------------------------------------------------------------

h.summary()
