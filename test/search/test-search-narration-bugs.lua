-- test/search/test-search-narration-bugs.lua
-- Regression tests for search narration bugs #63, #64, #65.
--
-- #63: Surface items on top of nightstand reported as "inside"
-- #64: Search doesn't narrate opening drawer/matchbox
-- #65: "a wooden match" singular when matchbox contains multiple
--
-- Each bug has dedicated tests + integration scenarios.

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

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

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

local function full_search(ctx, target, scope, max_steps)
    if search.is_searching() then search.abort(ctx) end
    capture_print(function()
        search.search(ctx, target, scope)
    end)
    return run_search_to_completion(ctx, max_steps)
end

---------------------------------------------------------------------------
-- Context builder: dark bedroom with nightstand + drawer + matchbox
---------------------------------------------------------------------------

local function make_dark_bedroom()
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
        keywords = {"bed"},
        description = "A large four-poster bed.",
    }

    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand", "bedside table"},
        description = "A squat nightstand of knotted pine.",
        categories = {"furniture", "wooden", "container"},
        is_container = true,
        is_open = false,
        is_locked = false,
        _state = "closed_with_drawer",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder", "glass-bottle"} },
            inside = { capacity = 2, max_item_size = 1, contents = {"matchbox"}, accessible = false },
        },
        contents = {"candle-holder", "glass-bottle", "matchbox"},
        parts = {
            drawer = {
                id = "nightstand-drawer",
                name = "a small drawer",
                keywords = {"drawer", "small drawer"},
                surface = "inside",
                is_container = true,
                contents = {"matchbox"},
            },
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

    local glass_bottle = {
        id = "glass-bottle",
        name = "a small glass bottle",
        keywords = {"bottle", "glass bottle"},
        description = "A small glass bottle.",
    }

    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches"},
        categories = {"small", "container"},
        container = true,
        is_open = false,
        is_locked = false,
        contents = {"match-1", "match-2", "match-3", "match-4", "match-5", "match-6", "match-7"},
    }

    for i = 1, 7 do
        local mid = "match-" .. i
        reg:register(mid, {
            id = mid,
            name = "a wooden match",
            keywords = {"match", "wooden match"},
            description = "A small wooden match.",
        })
    end

    reg:register("start-room", room)
    reg:register("bed", bed)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("glass-bottle", glass_bottle)
    reg:register("matchbox", matchbox)

    room.proximity_list = {"bed", "nightstand"}
    room.contents = {"bed", "nightstand"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, state = {} },
        last_noun = nil,
        last_object = nil,
        time_offset = 20,
    }

    return ctx, reg, room
end

local function make_lit_bedroom()
    local ctx, reg, room = make_dark_bedroom()
    room.light_level = 1
    return ctx, reg, room
end

---------------------------------------------------------------------------
h.suite("#63 — Surface items: 'On top' vs 'Inside' narration")
---------------------------------------------------------------------------

test("#63: undirected search says 'On top' for top-surface items (dark)", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    truthy(output:find("On top"),
           "Top-surface items should use 'On top' narration. Got: " .. output)
end)

test("#63: undirected search does NOT say 'Inside' for top-surface items", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- Split output into lines: the line about candle holder / glass bottle
    -- should NOT say "Inside"
    local top_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("candle") or line:find("bottle") then
            top_line = line
            break
        end
    end
    truthy(top_line ~= nil, "Should mention candle holder or bottle")
    truthy(not top_line:find("^Inside"),
           "Top-surface line must NOT start with 'Inside'. Got: " .. top_line)
end)

test("#63: 'On top' mentions parent name (nightstand)", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    truthy(output:find("On top of the.*nightstand"),
           "Should say 'On top of the nightstand'. Got: " .. output)
end)

test("#63: top-surface uses 'feel' in darkness", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    local top_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("On top") then top_line = line; break end
    end
    truthy(top_line ~= nil, "Should have 'On top' line")
    truthy(top_line:find("feel"),
           "Dark room should use 'feel' for top surface. Got: " .. top_line)
end)

test("#63: top-surface uses 'find' in lit room", function()
    local ctx = make_lit_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    local top_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("On top") then top_line = line; break end
    end
    truthy(top_line ~= nil, "Should have 'On top' line in lit room")
    truthy(top_line:find("find"),
           "Lit room should use 'find' for top surface. Got: " .. top_line)
end)

test("#63: 'Inside' narration still used for inside-surface items", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- The inside surface (drawer) should still use "Inside" language
    local has_inside = output:find("Inside the") or output:find("Inside,")
    truthy(has_inside,
           "Inside-surface items should use 'Inside' narration. Got: " .. output)
end)

test("#63: narrator.surface_contents distinguishes top vs inside", function()
    local ctx = make_dark_bedroom()
    local parent = ctx.registry:get("nightstand")

    local top_text = narrator.surface_contents(ctx, "top", parent, {"a candle", "a bottle"})
    local inside_text = narrator.surface_contents(ctx, "inside", parent, {"a matchbox"})

    truthy(top_text:find("On top"),
           "top surface should say 'On top'. Got: " .. top_text)
    truthy(inside_text:find("Inside"),
           "inside surface should say 'Inside'. Got: " .. inside_text)
    truthy(not top_text:find("^Inside"),
           "top surface must NOT start with 'Inside'. Got: " .. top_text)
end)

---------------------------------------------------------------------------
h.suite("#64 — Drawer/matchbox opening narration during search")
---------------------------------------------------------------------------

test("#64: undirected search narrates drawer opening", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    truthy(output:find("drawer") or output:find("pull it open"),
           "Should narrate drawer discovery/opening. Got: " .. output)
end)

test("#64: drawer opening uses part name", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    truthy(output:find("drawer"),
           "Opening narration should mention 'drawer'. Got: " .. output)
end)

test("#64: search narrates opening the matchbox", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    truthy(output:find("[Oo]pen the.*matchbox") or output:find("[Oo]pen the.*match box"),
           "Should narrate opening the matchbox. Got: " .. output)
end)

test("#64: matchbox contents are narrated after opening", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- After "open the matchbox" there should be "Inside" with match content
    local after_open = output:match("[Oo]pen the.-matchbox(.+)")
    truthy(after_open ~= nil, "Should have content after matchbox opening")
    if after_open then
        truthy(after_open:find("match"),
               "After opening matchbox, should mention matches. Got: " .. after_open)
    end
end)

test("#64: targeted search for match also narrates drawer opening", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)

    truthy(output:find("drawer") or output:find("pull it open"),
           "Targeted search should also narrate drawer opening. Got: " .. output)
end)

test("#64: narrator.container_opening generates opening text", function()
    local ctx = make_dark_bedroom()
    local text = narrator.container_opening(ctx, "a small drawer")
    truthy(text:find("drawer"),
           "container_opening should mention the part name. Got: " .. text)
    truthy(text:find("pull it open") or text:find("open it"),
           "container_opening should describe opening. Got: " .. text)
end)

test("#64: narrator.nested_container_opening generates opening text", function()
    local ctx = make_dark_bedroom()
    local matchbox = ctx.registry:get("matchbox")
    local text = narrator.nested_container_opening(ctx, matchbox)
    truthy(text:find("matchbox"),
           "nested_container_opening should mention container name. Got: " .. text)
    truthy(text:find("[Oo]pen"),
           "nested_container_opening should describe opening. Got: " .. text)
end)

test("#64: narrator.container_part_contents references part name", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    local part = nightstand.parts.drawer
    local text = narrator.container_part_contents(ctx, part, {"a small matchbox"})
    truthy(text:find("drawer"),
           "container_part_contents should reference the drawer. Got: " .. text)
    truthy(text:find("matchbox"),
           "container_part_contents should list contents. Got: " .. text)
end)

test("#64: full narration sequence includes all three steps", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- Step 1: drawer opening
    local has_opening = output:find("drawer") and output:find("pull it open")
    -- Step 2: drawer contents → matchbox
    local has_contents = output:find("matchbox")
    -- Step 3: matchbox opening + contents → matches
    local has_nested = output:find("[Oo]pen the.*matchbox")

    truthy(has_opening,
           "Must narrate drawer opening. Got: " .. output)
    truthy(has_contents,
           "Must list matchbox in drawer. Got: " .. output)
    truthy(has_nested,
           "Must narrate matchbox opening. Got: " .. output)
end)

---------------------------------------------------------------------------
h.suite("#65 — Plural match narration (several wooden matches)")
---------------------------------------------------------------------------

test("#65: narrator.aggregate_items groups duplicates", function()
    local items = {"a wooden match", "a wooden match", "a wooden match",
                   "a wooden match", "a wooden match", "a wooden match", "a wooden match"}
    local agg = narrator.aggregate_items(items)
    eq(1, #agg, "7 identical items should aggregate to 1 entry")
    truthy(agg[1]:find("several"),
           "7 items should say 'several'. Got: " .. agg[1])
    truthy(agg[1]:find("match"),
           "Aggregated item should still mention 'match'. Got: " .. agg[1])
end)

test("#65: aggregate_items handles 2 items as 'a couple of'", function()
    local items = {"a wooden match", "a wooden match"}
    local agg = narrator.aggregate_items(items)
    eq(1, #agg, "2 identical items should aggregate to 1")
    truthy(agg[1]:find("couple"),
           "2 items should say 'a couple of'. Got: " .. agg[1])
end)

test("#65: aggregate_items preserves single items unchanged", function()
    local items = {"a small matchbox", "a brass key"}
    local agg = narrator.aggregate_items(items)
    eq(2, #agg, "2 different items should stay as 2")
    eq("a small matchbox", agg[1])
    eq("a brass key", agg[2])
end)

test("#65: aggregate_items handles mixed duplicates", function()
    local items = {"a wooden match", "a wooden match", "a wooden match", "a brass key"}
    local agg = narrator.aggregate_items(items)
    eq(2, #agg, "3 matches + 1 key = 2 entries")
    truthy(agg[1]:find("several.*match"),
           "3 matches should say 'several'. Got: " .. agg[1])
    eq("a brass key", agg[2])
end)

test("#65: matchbox contents narrated as plural in undirected search", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- Should NOT say "a wooden match, a wooden match, a wooden match..."
    local repeated_match = output:find("a wooden match,.*a wooden match")
    truthy(not repeated_match,
           "Should NOT repeat 'a wooden match' for each match. Got: " .. output)

    -- Should say "several wooden matches"
    truthy(output:find("several wooden match"),
           "Should say 'several wooden matches'. Got: " .. output)
end)

test("#65: aggregate_items pluralizes 'match' to 'matches'", function()
    local items = {"a wooden match", "a wooden match", "a wooden match"}
    local agg = narrator.aggregate_items(items)
    truthy(agg[1]:find("matches"),
           "Should pluralize 'match' to 'matches'. Got: " .. agg[1])
end)

test("#65: empty items list returns empty", function()
    local agg = narrator.aggregate_items({})
    eq(0, #agg, "Empty input should return empty output")
end)

---------------------------------------------------------------------------
h.suite("INTEGRATION — Full narration sequence end-to-end")
---------------------------------------------------------------------------

test("Full room sweep: top surface shows 'On top', drawer shows opening", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, nil)

    -- Top surface
    truthy(output:find("On top"),
           "Room sweep should include 'On top' narration. Got: " .. output)

    -- Drawer
    truthy(output:find("drawer"),
           "Room sweep should mention the drawer. Got: " .. output)
end)

test("Scoped search nightstand: complete narration", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- Verify all key narration elements are present
    local has_top = output:find("On top")
    local has_drawer = output:find("drawer")
    local has_matchbox = output:find("matchbox")

    truthy(has_top ~= nil, "Must have 'On top'. Got: " .. output)
    truthy(has_drawer ~= nil, "Must mention drawer. Got: " .. output)
    truthy(has_matchbox ~= nil, "Must mention matchbox. Got: " .. output)
end)

test("Search still completes within safety limit", function()
    local ctx = make_dark_bedroom()
    local _, steps = full_search(ctx, nil, "nightstand", 30)
    truthy(steps < 30, "Must complete within 30 ticks, took " .. steps)
    truthy(not search.is_searching(), "Search must terminate")
end)

test("Targeted search for match still finds it", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)
    truthy(output:find("[Mm]atch"),
           "Must still find match. Got: " .. output)
end)

test("Nightstand state not mutated after search", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    eq(false, nightstand.is_open, "Nightstand starts closed")

    full_search(ctx, nil, "nightstand")

    eq(false, nightstand.is_open,
       "Nightstand must still be closed after search (#24)")
end)

test("Matchbox state not mutated after search", function()
    local ctx = make_dark_bedroom()
    local matchbox = ctx.registry:get("matchbox")
    eq(false, matchbox.is_open, "Matchbox starts closed")

    full_search(ctx, nil, "nightstand")

    eq(false, matchbox.is_open,
       "Matchbox must still be closed after search (#24)")
end)

test("Lit room uses visual narration", function()
    local ctx = make_lit_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    -- In a lit room, "On top" should use "find" not "feel"
    local top_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("On top") then top_line = line; break end
    end
    if top_line then
        truthy(top_line:find("find"),
               "Lit room top-surface should use 'find'. Got: " .. top_line)
    end
end)

---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
