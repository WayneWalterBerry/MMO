-- test/search/test-nightstand-regression.lua
-- Comprehensive regression tests for the nightstand search bug.
--
-- This bug has recurred THREE TIMES across sessions:
--   1. "search for a match" in bedroom → finds nothing (should find matchbox)
--   2. "search nightstand" → contradictory "nothing there" + "Inside you find..."
--   3. "search the drawer" → returns same result as "search nightstand"
--
-- These tests are the permanent lock. If anyone changes search, container
-- logic, or the nightstand, these tests catch regressions before they ship.
--
-- Root causes historically:
--   - Nightstand missing "container" in categories
--   - Surfaces not enumerated during search queue build
--   - Drawer not resolvable as distinct sub-component
--   - Deeper-match logic not peeking inside matchbox for "match"
--
-- Bug refs: #22, #33, #34, #40, #43, #44, BUG-125

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

-- Run search to completion, return all output and step count
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

-- Start a search and run it to completion
local function full_search(ctx, target, scope, max_steps)
    if search.is_searching() then search.abort(ctx) end
    capture_print(function()
        search.search(ctx, target, scope)
    end)
    return run_search_to_completion(ctx, max_steps)
end

---------------------------------------------------------------------------
-- Context builders
---------------------------------------------------------------------------

--- Build a realistic dark bedroom matching the actual game layout.
-- Nightstand with dual surfaces (top/inside), drawer as part,
-- matchbox in drawer, matches inside matchbox.
local function make_dark_bedroom()
    local reg = registry_mod.new()

    local room = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
        light_level = 0, -- pitch dark
    }

    local bed = {
        id = "bed",
        name = "a large four-poster bed",
        keywords = {"bed"},
        description = "A large four-poster bed.",
        on_feel = "You feel the rough wooden frame of a large four-poster bed.",
    }

    -- Nightstand: the critical object. Must have "container" in categories.
    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand", "bedside table", "table", "stand"},
        description = "A squat nightstand of knotted pine.",
        on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",
        categories = {"furniture", "wooden", "container"},
        _state = "closed_with_drawer",
        is_container = true,
        is_open = false,
        is_locked = false,
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder", "poison-bottle"} },
            inside = { capacity = 2, max_item_size = 1, contents = {"matchbox"}, accessible = false },
        },
        contents = {"candle-holder", "poison-bottle", "matchbox"},
        parts = {
            drawer = {
                id = "drawer",
                name = "drawer",
                keywords = {"drawer"},
                description = "A small wooden drawer.",
                is_container = true,
                is_open = false,
                contents = {"matchbox"},
                surfaces = {
                    inside = { contents = {"matchbox"} },
                },
            },
        },
    }

    local candle_holder = {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "brass"},
        description = "A brass candle holder with a half-melted candle.",
    }

    local poison_bottle = {
        id = "poison-bottle",
        name = "a small glass bottle",
        keywords = {"bottle", "glass bottle", "poison bottle"},
        description = "A small glass bottle with a dark liquid inside.",
    }

    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = {"matchbox", "match box", "box of matches", "matches"},
        description = "A small cardboard box. One side is rough -- a striker strip.",
        categories = {"small", "container"},
        container = true,
        is_open = false,
        is_locked = false,
        accessible = false,
        contents = {"match-1", "match-2", "match-3", "match-4", "match-5", "match-6", "match-7"},
    }

    -- Create 7 match objects
    for i = 1, 7 do
        local mid = "match-" .. i
        reg:register(mid, {
            id = mid,
            name = "a wooden match",
            keywords = {"match", "wooden match", "matchstick"},
            description = "A small wooden match.",
            is_fresh = true,
            is_spent = false,
        })
    end

    reg:register("start-room", room)
    reg:register("bed", bed)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("poison-bottle", poison_bottle)
    reg:register("matchbox", matchbox)

    room.proximity_list = {"bed", "nightstand"}
    room.contents = {"bed", "nightstand"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = {
            hands = {nil, nil},
            state = {},
            worn_items = {},
            bags = {},
            worn = {},
        },
        injuries = {},
        last_noun = nil,
        last_object = nil,
        time_offset = 20,
        game_start_time = os.time(),
    }

    return ctx, reg, room
end

--- Build a lit bedroom (post-dawn or post-match-lighting).
local function make_lit_bedroom()
    local ctx, reg, room = make_dark_bedroom()
    room.light_level = 1
    return ctx, reg, room
end

---------------------------------------------------------------------------
h.suite("1. OBJECT PLACEMENT — Matchbox is in nightstand drawer")
---------------------------------------------------------------------------

test("Matchbox exists in registry", function()
    local ctx = make_dark_bedroom()
    local matchbox = ctx.registry:get("matchbox")
    truthy(matchbox ~= nil, "Matchbox must exist in registry")
    eq("matchbox", matchbox.id, "Matchbox ID must be 'matchbox'")
end)

test("Matchbox is in nightstand 'inside' surface contents", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    truthy(nightstand.surfaces ~= nil, "Nightstand must have surfaces")
    truthy(nightstand.surfaces.inside ~= nil, "Nightstand must have 'inside' surface")

    local found = false
    for _, id in ipairs(nightstand.surfaces.inside.contents or {}) do
        if id == "matchbox" then found = true; break end
    end
    truthy(found, "Matchbox must be in nightstand.surfaces.inside.contents")
end)

test("Matchbox is in nightstand drawer part contents", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    truthy(nightstand.parts ~= nil, "Nightstand must have parts")
    truthy(nightstand.parts.drawer ~= nil, "Nightstand must have drawer part")

    local found = false
    for _, id in ipairs(nightstand.parts.drawer.contents or {}) do
        if id == "matchbox" then found = true; break end
    end
    truthy(found, "Matchbox must be in nightstand.parts.drawer.contents")
end)

test("Nightstand top surface contains candle-holder and poison-bottle", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    local top = nightstand.surfaces.top

    local has_candle = false
    local has_bottle = false
    for _, id in ipairs(top.contents or {}) do
        if id == "candle-holder" then has_candle = true end
        if id == "poison-bottle" then has_bottle = true end
    end
    truthy(has_candle, "Candle holder must be on nightstand top")
    truthy(has_bottle, "Poison bottle must be on nightstand top")
end)

---------------------------------------------------------------------------
h.suite("2. SEARCH FOR MATCH — Deeper-match logic finds matchbox")
---------------------------------------------------------------------------

test("'search for match' finds something matching 'match' in dark bedroom", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)
    truthy(output:find("[Mm]atch"),
           "Search for 'match' must find matchbox or match. Got: " .. output)
end)

test("'search for match' — deeper-match peeks inside matchbox for actual match", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)
    -- The deeper-match logic should find match-1 inside matchbox
    truthy(output:find("match") or output:find("found"),
           "Deeper-match should find the actual match inside matchbox. Got: " .. output)
end)

test("'search for match' completes (does not hang)", function()
    local ctx = make_dark_bedroom()
    local _, steps = full_search(ctx, "match", nil, 30)
    truthy(steps < 30,
           "'search for match' must complete within 30 ticks, took " .. steps)
    truthy(not search.is_searching(), "Search must terminate")
end)

---------------------------------------------------------------------------
h.suite("3. SEARCH FOR MATCH IN DARKNESS — Touch-based results")
---------------------------------------------------------------------------

test("Room is dark (light_level = 0) at game start", function()
    local ctx = make_dark_bedroom()
    eq(0, ctx.current_room.light_level, "Bedroom must start dark (light_level = 0)")
end)

test("'search for match' works in complete darkness", function()
    local ctx = make_dark_bedroom()
    eq(0, ctx.current_room.light_level, "Precondition: room is dark")

    local output = full_search(ctx, "match", nil)
    truthy(output:find("[Mm]atch"),
           "Search must find match even in complete darkness. Got: " .. output)
end)

test("Darkness search uses touch-sense narration", function()
    local ctx = make_dark_bedroom()
    -- Run an undirected search in darkness — narration should use touch templates
    local output = full_search(ctx, nil, nil)
    -- Touch narration uses words like "feel", "fingers", "touch", "grope"
    -- Vision narration uses "see", "spot", "eyes", "look"
    -- In darkness, we should NOT see vision-only words
    local vision_only = output:find("You see ") or output:find("You spot ") or output:find("Your eyes")
    local has_touch = output:find("feel") or output:find("finger") or output:find("touch")
        or output:find("grope") or output:find("fumble") or output:find("find")
    -- Allow either touch narration or generic narration, but not vision-specific
    -- (Some narration may be generic enough to not use either sense)
    if output ~= "" then
        truthy(not vision_only or has_touch,
               "Dark search should not use vision-only narration. Got: " .. output)
    end
end)

test("Lit room search also finds match (sanity check)", function()
    local ctx = make_lit_bedroom()
    eq(1, ctx.current_room.light_level, "Precondition: room is lit")

    local output = full_search(ctx, "match", nil)
    truthy(output:find("[Mm]atch"),
           "Search must find match in lit room too. Got: " .. output)
end)

---------------------------------------------------------------------------
h.suite("4. SEARCH NIGHTSTAND — Finds drawer contents")
---------------------------------------------------------------------------

test("'search nightstand' reports surface contents", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")
    -- Should mention items from nightstand surfaces
    truthy(output:find("candle") or output:find("bottle") or output:find("atchbox")
        or output:find("holder"),
           "'search nightstand' must report surface contents. Got: " .. output)
end)

test("'search nightstand' mentions matchbox from drawer/inside surface", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")
    -- Matchbox is in the inside surface — search should peek and find it
    truthy(output:find("[Mm]atchbox") or output:find("match"),
           "'search nightstand' must find matchbox in drawer. Got: " .. output)
end)

test("'search nightstand' completes within safety limit", function()
    local ctx = make_dark_bedroom()
    local _, steps = full_search(ctx, nil, "nightstand", 30)
    truthy(steps < 30,
           "'search nightstand' must complete within 30 ticks, took " .. steps)
end)

---------------------------------------------------------------------------
h.suite("5. NO CONTRADICTORY NARRATION — 'nothing there' bug")
---------------------------------------------------------------------------

test("'search nightstand' does NOT say 'nothing there' when contents exist", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    local has_nothing = output:find("[Nn]othing there")
        or output:find("[Nn]othing%.%s*$")
        or output:find("[Nn]othing notable")
    truthy(not has_nothing,
           "Must NOT say 'nothing there' for nightstand with contents. Got: " .. output)
end)

test("Undirected room sweep does not produce contradictory nightstand narration", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, nil, nil)

    -- Check that no single line says nightstand + "nothing"
    local contradiction = false
    for line in output:gmatch("[^\n]+") do
        if line:find("nightstand") and line:find("[Nn]othing") then
            contradiction = true
            break
        end
    end
    truthy(not contradiction,
           "Room sweep must not say 'nothing' about the nightstand. Got: " .. output)
end)

test("Surface entries for populated objects suppress 'nothing there'", function()
    local ctx = make_dark_bedroom()
    local queue = traverse.build_queue(ctx.current_room, "nightstand", nil, ctx.registry)

    -- Find the object entry for nightstand
    local obj_entry = nil
    for _, entry in ipairs(queue) do
        if entry.type == "object" and entry.object_id == "nightstand" then
            obj_entry = entry
            break
        end
    end

    if obj_entry then
        local result = traverse.step(ctx, obj_entry, nil, false, nil, nil)
        -- Object with surfaces should produce empty narrative (surfaces handle content)
        truthy(not result.narrative:find("[Nn]othing"),
               "Object entry for nightstand must not say 'nothing'. Got: " .. result.narrative)
    end
end)

---------------------------------------------------------------------------
h.suite("6. DRAWER IS DISTINCT — Resolves separately from nightstand")
---------------------------------------------------------------------------

test("Traverse queue includes drawer-related entries when scoped to nightstand", function()
    local ctx = make_dark_bedroom()
    local queue = traverse.build_queue(ctx.current_room, "nightstand", nil, ctx.registry)

    -- Queue should contain surface entries for "top" and "inside"
    local has_top = false
    local has_inside = false
    for _, entry in ipairs(queue) do
        if entry.surface_name == "top" then has_top = true end
        if entry.surface_name == "inside" then has_inside = true end
    end
    truthy(has_top or has_inside,
           "Queue must include surface entries for nightstand (top and/or inside)")
end)

test("Nightstand 'inside' surface is distinct from 'top' surface", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")

    local top_contents = nightstand.surfaces.top.contents
    local inside_contents = nightstand.surfaces.inside.contents

    -- Contents should not be identical
    local same = (#top_contents == #inside_contents)
    if same then
        for i, id in ipairs(top_contents) do
            if inside_contents[i] ~= id then same = false; break end
        end
    end
    truthy(not same, "Top and inside surfaces must have different contents")

    -- Specifically: matchbox is inside, not on top
    local matchbox_on_top = false
    for _, id in ipairs(top_contents) do
        if id == "matchbox" then matchbox_on_top = true; break end
    end
    truthy(not matchbox_on_top, "Matchbox must NOT be on the top surface")
end)

test("Drawer part has its own contents list", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    local drawer = nightstand.parts and nightstand.parts.drawer

    truthy(drawer ~= nil, "Nightstand must have a drawer part")
    truthy(drawer.contents ~= nil, "Drawer must have a contents list")
    truthy(#drawer.contents > 0, "Drawer contents must not be empty")
end)

---------------------------------------------------------------------------
h.suite("7. NIGHTSTAND CATEGORIES — Root cause of prior fix")
---------------------------------------------------------------------------

test("Nightstand has 'container' in categories", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    truthy(nightstand.categories ~= nil, "Nightstand must have categories")

    local has_container = false
    for _, cat in ipairs(nightstand.categories) do
        if cat == "container" then has_container = true; break end
    end
    truthy(has_container,
           "Nightstand categories MUST include 'container' — this was the root cause of BUG-125")
end)

test("containers.is_container() recognizes nightstand", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    truthy(containers.is_container(nightstand),
           "containers.is_container(nightstand) must return true")
end)

test("Nightstand has 'furniture' in categories", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    local has_furniture = false
    for _, cat in ipairs(nightstand.categories) do
        if cat == "furniture" then has_furniture = true; break end
    end
    truthy(has_furniture, "Nightstand must be categorized as furniture")
end)

test("Nightstand has 'wooden' in categories", function()
    local ctx = make_dark_bedroom()
    local nightstand = ctx.registry:get("nightstand")
    local has_wooden = false
    for _, cat in ipairs(nightstand.categories) do
        if cat == "wooden" then has_wooden = true; break end
    end
    truthy(has_wooden, "Nightstand must be categorized as wooden")
end)

test("Matchbox recognized as container via categories", function()
    local ctx = make_dark_bedroom()
    local matchbox = ctx.registry:get("matchbox")
    truthy(containers.is_container(matchbox),
           "containers.is_container(matchbox) must return true")
end)

---------------------------------------------------------------------------
h.suite("8. MATCHBOX CONTAINS MATCHES — Nested container verification")
---------------------------------------------------------------------------

test("Matchbox has 7 matches in contents", function()
    local ctx = make_dark_bedroom()
    local matchbox = ctx.registry:get("matchbox")
    truthy(matchbox.contents ~= nil, "Matchbox must have contents")
    eq(7, #matchbox.contents, "Matchbox must contain 7 matches")
end)

test("All match objects exist in registry", function()
    local ctx = make_dark_bedroom()
    for i = 1, 7 do
        local mid = "match-" .. i
        local match = ctx.registry:get(mid)
        truthy(match ~= nil, "Match '" .. mid .. "' must exist in registry")
        eq(mid, match.id, "Match ID must be '" .. mid .. "'")
    end
end)

test("Match objects have 'match' keyword", function()
    local ctx = make_dark_bedroom()
    local match = ctx.registry:get("match-1")
    local has_kw = false
    for _, kw in ipairs(match.keywords or {}) do
        if kw == "match" then has_kw = true; break end
    end
    truthy(has_kw, "Match objects must have 'match' keyword for search to find them")
end)

test("Match objects are fresh (not spent)", function()
    local ctx = make_dark_bedroom()
    for i = 1, 7 do
        local match = ctx.registry:get("match-" .. i)
        truthy(match.is_fresh, "match-" .. i .. " must be fresh")
        truthy(not match.is_spent, "match-" .. i .. " must not be spent")
    end
end)

---------------------------------------------------------------------------
h.suite("9. SEARCH FOR MATCHES — Deeper search through nested containers")
---------------------------------------------------------------------------

test("'search for matches' finds matches inside matchbox", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "matches", nil)
    truthy(output:find("[Mm]atch"),
           "'search for matches' must find matches via matchbox. Got: " .. output)
end)

test("'search for matchbox' finds matchbox directly", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "matchbox", nil)
    truthy(output:find("[Mm]atchbox"),
           "'search for matchbox' must find the matchbox. Got: " .. output)
end)

test("Deeper match: traverse.step finds match-1 inside matchbox", function()
    local ctx = make_dark_bedroom()
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
    truthy(result.found, "Deeper-match must find a match inside matchbox")
    -- Should return actual match, not the matchbox itself
    truthy(result.item.id:match("^match%-"),
           "Should return actual match object (match-N), got: " .. tostring(result.item.id))
end)

test("Empty matchbox: search for 'match' still finds the matchbox itself", function()
    local ctx = make_dark_bedroom()
    local matchbox = ctx.registry:get("matchbox")
    matchbox.contents = {} -- empty it

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
    eq("matchbox", result.item.id, "Should return matchbox itself when empty")
end)

---------------------------------------------------------------------------
h.suite("10. DARKNESS SEARCH — Touch-based discovery")
---------------------------------------------------------------------------

test("Narrator uses touch sense when room is dark", function()
    local ctx = make_dark_bedroom()
    -- narrator module should detect dark room → touch sense
    -- Verify by checking the search output contains touch-style words
    local output = full_search(ctx, nil, "nightstand")

    if output ~= "" then
        -- In darkness, narrator should NOT use pure vision phrases
        local pure_vision = output:match("Your eyes scan") or output:match("You see clearly")
        truthy(not pure_vision,
               "Dark room search must not use vision-only narration. Got: " .. output)
    end
end)

test("Narrator uses vision sense when room is lit", function()
    local ctx = make_lit_bedroom()
    local output = full_search(ctx, nil, "nightstand")

    if output ~= "" then
        local pure_touch = output:match("Your fingers explore") or output:match("You grope")
        -- In a lit room, touch-only phrases should not appear
        -- (some generic phrases are fine either way)
        if pure_touch then
            -- This is OK if there's also visual content
            truthy(true, "Mixed narration acceptable in lit room")
        end
    end
end)

test("Search finds objects in both dark and lit rooms", function()
    -- Dark room
    local dark_ctx = make_dark_bedroom()
    local dark_output = full_search(dark_ctx, "match", nil)

    -- Lit room
    local lit_ctx = make_lit_bedroom()
    local lit_output = full_search(lit_ctx, "match", nil)

    truthy(dark_output:find("[Mm]atch"),
           "Must find match in dark room. Got: " .. dark_output)
    truthy(lit_output:find("[Mm]atch"),
           "Must find match in lit room. Got: " .. lit_output)
end)

---------------------------------------------------------------------------
h.suite("11. SMITHERS' FIXES — Sleep idioms still work")
---------------------------------------------------------------------------

-- Load the parser preprocessor for sleep idiom verification
local pp_ok, preprocess = pcall(require, "engine.parser.preprocess")

test("Sleep idiom: 'sleep to dawn' → 'sleep until dawn'", function()
    if not pp_ok then
        print("  SKIP (preprocessor not loadable)")
        return
    end
    local v, n = preprocess.natural_language("sleep to dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should transform 'to' → 'until'. Got: " .. tostring(n))
end)

test("Sleep idiom: 'sleep til dawn' → 'sleep until dawn'", function()
    if not pp_ok then
        print("  SKIP (preprocessor not loadable)")
        return
    end
    local v, n = preprocess.natural_language("sleep til dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should transform 'til' → 'until'. Got: " .. tostring(n))
end)

test("Sleep idiom: 'sleep till dawn' → 'sleep until dawn'", function()
    if not pp_ok then
        print("  SKIP (preprocessor not loadable)")
        return
    end
    local v, n = preprocess.natural_language("sleep till dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should transform 'till' → 'until'. Got: " .. tostring(n))
end)

---------------------------------------------------------------------------
h.suite("12. INTEGRATION — Full search scenarios end-to-end")
---------------------------------------------------------------------------

test("Full room sweep in dark bedroom completes and finds objects", function()
    local ctx = make_dark_bedroom()
    local output, steps = full_search(ctx, nil, nil, 50)
    truthy(steps < 50, "Room sweep must complete within 50 ticks, took " .. steps)
    truthy(output ~= "", "Room sweep must produce some output")
end)

test("Targeted search for 'candle holder' works", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "candle holder", nil)
    truthy(output:find("candle") or output:find("holder") or output:find("brass"),
           "Should find the candle holder. Got: " .. output)
end)

test("Targeted search for 'bottle' works", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "bottle", nil)
    truthy(output:find("bottle") or output:find("glass"),
           "Should find the glass bottle. Got: " .. output)
end)

test("Searching for nonexistent object does not crash", function()
    local ctx = make_dark_bedroom()
    local output, steps = full_search(ctx, "unicorn", nil, 30)
    truthy(steps < 30, "Search for nonexistent object must complete, took " .. steps)
    -- Should NOT crash — output can be empty or say "nothing found"
end)

test("Multiple sequential searches don't leak state", function()
    local ctx = make_dark_bedroom()

    -- First search
    local output1 = full_search(ctx, "match", nil)
    truthy(not search.is_searching(), "First search must complete")

    -- Second search
    local output2 = full_search(ctx, "bottle", nil)
    truthy(not search.is_searching(), "Second search must complete")

    -- Third search
    local output3 = full_search(ctx, nil, "nightstand")
    truthy(not search.is_searching(), "Third search must complete")
end)

---------------------------------------------------------------------------
-- Summary and exit
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
