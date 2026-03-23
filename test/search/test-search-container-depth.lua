-- test/search/test-search-container-depth.lua
-- Regression tests for Issues #22 and #34
--
-- #22: "look for matches" should search INSIDE containers for deeper matches.
--      When a container name matches the target (matchbox → match), peek inside
--      and return the actual match object instead of the container.
--
-- #34: Open containers should report their contents when the search target
--      isn't found inside (not just say "nothing there").
--
-- Usage: lua test/search/test-search-container-depth.lua
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

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "String not found") .. "\n  Expected: " .. needle .. "\n  In: " .. haystack)
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "String should NOT be found") .. "\n  Unexpected: " .. needle .. "\n  In: " .. haystack)
    end
end

-- Run a full search to completion, return all output
local function run_search_to_completion(ctx, target, scope)
    local all_output = {}
    capture_print(function()
        search.search(ctx, target, scope)
    end)
    local max_steps = 30
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
    -- Capture final completion message if search is still active
    if search.is_searching() then
        capture_print(function() search.abort(ctx) end)
    end
    return table.concat(all_output, "\n")
end

---------------------------------------------------------------------------
-- Context builders
---------------------------------------------------------------------------

--- Build a context with matchbox inside a nightstand drawer (Issue #22 scenario)
local function make_matchbox_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "bedroom", name = "Bedroom",
        description = "A dark bedroom.",
        contents = {"bed", "nightstand"},
        proximity_list = {"bed", "nightstand"},
        light_level = 0,
    }

    local bed = {
        id = "bed", name = "a large bed",
        keywords = {"bed"},
        description = "A four-poster bed.",
    }

    local match1 = {
        id = "match-1", name = "a wooden match",
        keywords = {"match", "matchstick", "wooden match"},
        description = "A small wooden match.",
    }

    local match2 = {
        id = "match-2", name = "a wooden match",
        keywords = {"match", "matchstick", "wooden match"},
        description = "A small wooden match.",
    }

    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches"},
        description = "A battered little cardboard matchbox.",
        container = true,
        accessible = false,
        contents = {"match-1", "match-2"},
    }

    local candle = {
        id = "candle", name = "a candle",
        keywords = {"candle"},
        description = "A white wax candle.",
    }

    local nightstand = {
        id = "nightstand", name = "a small nightstand",
        keywords = {"nightstand", "table"},
        description = "A small nightstand with a drawer.",
        is_container = true,
        is_open = false,
        surfaces = {
            inside = {
                accessible = false,
                contents = {"matchbox", "candle"},
            },
        },
    }

    reg:register("bedroom", room)
    reg:register("bed", bed)
    reg:register("nightstand", nightstand)
    reg:register("matchbox", matchbox)
    reg:register("candle", candle)
    reg:register("match-1", match1)
    reg:register("match-2", match2)

    return {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, state = {} },
    }
end

--- Build a context with an open wardrobe (Issue #34 scenario)
local function make_wardrobe_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "bedroom", name = "Bedroom",
        description = "A bedroom with a wardrobe.",
        contents = {"wardrobe"},
        proximity_list = {"wardrobe"},
        light_level = 0,
    }

    local cloak = {
        id = "cloak", name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        description = "A moth-eaten cloak.",
    }

    local sack = {
        id = "sack", name = "a burlap sack",
        keywords = {"sack", "burlap sack"},
        description = "A rough burlap sack.",
    }

    local wardrobe = {
        id = "wardrobe", name = "a heavy wardrobe",
        keywords = {"wardrobe", "closet"},
        description = "A large heavy wardrobe, standing open.",
        categories = {"furniture", "container"},
        is_open = true,
        contents = {"cloak", "sack"},
    }

    reg:register("bedroom", room)
    reg:register("wardrobe", wardrobe)
    reg:register("cloak", cloak)
    reg:register("sack", sack)

    return {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, state = {} },
    }
end

---------------------------------------------------------------------------
h.suite("Issue #22 — Search peeks inside containers for deeper match")
---------------------------------------------------------------------------

test("#22: find_deeper_match returns child when container has matching content", function()
    local ctx = make_matchbox_ctx()
    local matchbox = ctx.registry:get("matchbox")
    -- Directly test the traverse module by calling step on a matchbox entry
    local entry = {
        object_id = "matchbox",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = true,
        is_locked = false,
        is_open = false,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, "match", false, nil, nil)
    truthy(result.found, "Should find a match inside the matchbox")
    eq("match-1", result.item.id, "Should return the actual match, not the matchbox")
end)

test("#22: search for 'match' finds actual match inside matchbox (not matchbox itself)", function()
    local ctx = make_matchbox_ctx()
    local output = run_search_to_completion(ctx, "match", nil)
    -- The search should find the match object, not stop at the matchbox
    assert_contains(output, "wooden match", "Should report finding the actual match")
end)

test("#22: search for 'matchbox' still finds the matchbox directly", function()
    local ctx = make_matchbox_ctx()
    local output = run_search_to_completion(ctx, "matchbox", nil)
    assert_contains(output, "matchbox", "Should find the matchbox when searching for it")
end)

test("#22: search for 'candle' still works (non-container match unaffected)", function()
    local ctx = make_matchbox_ctx()
    local output = run_search_to_completion(ctx, "candle", nil)
    assert_contains(output, "candle", "Should find the candle")
end)

test("#22: deeper match narrative mentions peeking inside container", function()
    local ctx = make_matchbox_ctx()
    -- Process the nightstand surface entry that contains the matchbox
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
    truthy(result.found, "Should find match")
    -- Narrative should mention peeking inside the matchbox
    assert_contains(result.narrative, "matchbox", "Narrative should mention the matchbox container")
end)

test("#22: empty matchbox returns matchbox itself (no deeper match)", function()
    local ctx = make_matchbox_ctx()
    local matchbox = ctx.registry:get("matchbox")
    matchbox.contents = {} -- Empty the matchbox
    local entry = {
        object_id = "matchbox",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = true,
        is_locked = false,
        is_open = false,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, "match", false, nil, nil)
    truthy(result.found, "Should still find matchbox when empty")
    eq("matchbox", result.item.id, "Should return the matchbox itself when empty")
end)

test("#22: non-container match does not trigger deeper search", function()
    local ctx = make_matchbox_ctx()
    local entry = {
        object_id = "candle",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = false,
        is_locked = false,
        is_open = false,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, "candle", false, nil, nil)
    truthy(result.found, "Should find candle")
    eq("candle", result.item.id, "Should return candle directly")
end)

---------------------------------------------------------------------------
h.suite("Issue #34 — Open containers report contents when target not found")
---------------------------------------------------------------------------

test("#34: open wardrobe reports contents when target not found", function()
    local ctx = make_wardrobe_ctx()
    local entry = {
        object_id = "wardrobe",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = true,
        is_locked = false,
        is_open = true,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, "sword", false, nil, nil)
    truthy(not result.found, "Should not find sword")
    assert_contains(result.narrative, "cloak", "Should mention the cloak inside")
    assert_contains(result.narrative, "sack", "Should mention the sack inside")
    assert_contains(result.narrative, "sword", "Should mention what was being searched for")
end)

test("#34: open wardrobe finds target when it IS inside", function()
    local ctx = make_wardrobe_ctx()
    local entry = {
        object_id = "wardrobe",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = true,
        is_locked = false,
        is_open = true,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, "cloak", false, nil, nil)
    truthy(result.found, "Should find cloak inside wardrobe")
    eq("cloak", result.item.id, "Should return the cloak")
end)

test("#34: full search reports wardrobe contents (not 'nothing there')", function()
    local ctx = make_wardrobe_ctx()
    local output = run_search_to_completion(ctx, "sword", nil)
    assert_not_contains(output, "nothing there", "Should NOT say 'nothing there' for open container")
    assert_contains(output, "cloak", "Should list what's inside the wardrobe")
end)

test("#34: open empty container shows step narrative", function()
    local ctx = make_wardrobe_ctx()
    local wardrobe = ctx.registry:get("wardrobe")
    wardrobe.contents = {} -- Empty the wardrobe
    local entry = {
        object_id = "wardrobe",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = true,
        is_locked = false,
        is_open = true,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, "sword", false, nil, nil)
    truthy(not result.found, "Should not find sword")
    truthy(result.narrative ~= "", "Should have some narrative")
end)

test("#34: undirected search of open container lists contents", function()
    local ctx = make_wardrobe_ctx()
    local entry = {
        object_id = "wardrobe",
        type = "object",
        depth = 0,
        parent_id = nil,
        is_container = true,
        is_locked = false,
        is_open = true,
        surface_name = nil,
    }
    local result = traverse.step(ctx, entry, nil, false, nil, nil)
    truthy(not result.found, "Undirected search doesn't set found")
    assert_contains(result.narrative, "cloak", "Should list contents")
    assert_contains(result.narrative, "sack", "Should list all contents")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
