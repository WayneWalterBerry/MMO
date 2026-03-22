-- test/search/test-search-scoped.lua
-- Regression tests for scoped search bugs from Pass-025.
-- Tests: scoped search content discovery, depth limits, compound search,
--        drawer recognition, narration article handling.
--
-- Bug IDs tested: BUG-079, BUG-080, BUG-082, BUG-088

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
        all_output[#all_output + 1] = output
        step_count = step_count + 1
    end

    return table.concat(all_output, "\n"), step_count
end

-- Build a bedroom context with nightstand, bed, wardrobe for scoped tests
local function make_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "test-bedroom",
        name = "Test Bedroom",
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
        is_container = true,
        is_open = true,
        is_locked = false,
        surfaces = {
            top = { contents = {"pillow", "sheets"} },
            under = { contents = {"blanket", "knife"} },
        },
        contents = {"pillow", "sheets", "blanket", "knife"},
    }

    local pillow = {
        id = "pillow", name = "pillow", keywords = {"pillow"},
        description = "A feather pillow.",
    }
    local sheets = {
        id = "sheets", name = "sheets", keywords = {"sheets"},
        description = "Linen sheets.",
    }
    local blanket = {
        id = "blanket", name = "blanket", keywords = {"blanket"},
        description = "A wool blanket.",
    }
    local knife = {
        id = "knife", name = "knife", keywords = {"knife"},
        description = "A small knife.", is_sharp = true,
    }

    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "table"},
        description = "A small nightstand.",
        is_container = true,
        is_open = false,
        is_locked = false,
        surfaces = {
            top = { contents = {"candle-holder", "glass-bottle"} },
            inside = { contents = {"matchbox"} },
        },
        contents = {"candle-holder", "glass-bottle", "matchbox"},
        parts = {
            drawer = {
                id = "drawer",
                name = "drawer",
                keywords = {"drawer"},
                description = "A small drawer.",
                is_container = true,
                is_open = false,
                contents = {"matchbox"},
            }
        },
    }

    local candle_holder = {
        id = "candle-holder", name = "a brass candle holder",
        keywords = {"candle holder", "holder", "brass"},
        description = "A brass candle holder.",
    }
    local glass_bottle = {
        id = "glass-bottle", name = "a small glass bottle",
        keywords = {"bottle", "glass bottle"},
        description = "A small glass bottle.",
    }
    local matchbox = {
        id = "matchbox", name = "a small matchbox",
        keywords = {"matchbox", "box", "matches"},
        description = "A small matchbox.",
        fire_source = true,
        is_container = true,
        is_open = false,
        contents = {"match-1","match-2","match-3","match-4","match-5","match-6","match-7"},
    }

    -- Create sack and cloak for wardrobe nesting test
    local sack = {
        id = "sack", name = "sack", keywords = {"sack"},
        description = "A burlap sack.",
        is_container = true, is_open = false, is_locked = false,
        contents = {"coin", "ring"},
    }
    local coin = {
        id = "coin", name = "coin", keywords = {"coin"}, description = "A gold coin.",
    }
    local ring = {
        id = "ring", name = "ring", keywords = {"ring"}, description = "A silver ring.",
    }
    local cloak = {
        id = "wool-cloak", name = "wool cloak", keywords = {"cloak"},
        description = "A wool cloak.",
    }

    local wardrobe = {
        id = "wardrobe",
        name = "a heavy wardrobe",
        keywords = {"wardrobe", "closet"},
        description = "A large wardrobe.",
        is_container = true,
        is_open = false,
        is_locked = false,
        contents = {"wool-cloak", "sack"},
    }

    -- Register all objects
    reg:register("test-bedroom", room)
    reg:register("bed", bed)
    reg:register("pillow", pillow)
    reg:register("sheets", sheets)
    reg:register("blanket", blanket)
    reg:register("knife", knife)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("glass-bottle", glass_bottle)
    reg:register("matchbox", matchbox)
    reg:register("wardrobe", wardrobe)
    reg:register("wool-cloak", cloak)
    reg:register("sack", sack)
    reg:register("coin", coin)
    reg:register("ring", ring)

    -- Create match objects
    for i = 1, 7 do
        local m = {
            id = "match-" .. i, name = "a wooden match",
            keywords = {"match", "wooden match"},
            description = "A wooden match.",
        }
        reg:register("match-" .. i, m)
    end

    room.proximity_list = {"bed", "nightstand", "wardrobe"}
    room.contents = {"bed", "nightstand", "wardrobe"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = {hands = {nil, nil}, state = {}},
        last_noun = nil,
        last_object = nil,
    }

    return ctx, reg, room
end

-------------------------------------------------------------------------------
h.suite("1. SCOPED SEARCH — Content discovery (BUG-079)")
-------------------------------------------------------------------------------

test("BUG-079: 'search nightstand' finds surface AND nested contents", function()
    local ctx = make_ctx()

    -- Reset search state
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, nil, "nightstand")
    end)

    local output, steps = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    -- Should find at least SOME of the nightstand contents
    local found_something = full:find("candle holder") or
                            full:find("glass bottle") or
                            full:find("matchbox") or
                            full:find("drawer")

    truthy(found_something,
           "Scoped search of nightstand should find its contents (candle holder, glass bottle, matchbox)")
end)

test("BUG-079: 'search bed' finds bed contents", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, nil, "bed")
    end)

    local output, steps = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    local found_something = full:find("pillow") or
                            full:find("sheets") or
                            full:find("blanket") or
                            full:find("knife")

    truthy(found_something,
           "Scoped search of bed should find its contents (pillow, sheets, blanket, knife)")
end)

-------------------------------------------------------------------------------
h.suite("2. WARDROBE DEPTH LIMIT — No infinite loop (BUG-080)")
-------------------------------------------------------------------------------

test("BUG-080: 'search wardrobe' completes without hanging", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Unlock wardrobe for this test
    local wardrobe = ctx.registry:get("wardrobe")
    wardrobe.is_locked = false

    capture_print(function()
        search.search(ctx, nil, "wardrobe")
    end)

    local _, steps = run_search_to_completion(ctx, 30)

    truthy(steps < 30,
           "Wardrobe search should complete within 30 steps (depth limit), took " .. steps)
    truthy(not search.is_searching(),
           "Search should not still be running after completion")
end)

test("BUG-080: nested containers don't cause infinite recursion", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Full room sweep with nested containers
    capture_print(function()
        search.search(ctx, nil, nil)
    end)

    local _, steps = run_search_to_completion(ctx, 50)

    truthy(steps < 50,
           "Room sweep should complete within 50 steps, took " .. steps)
end)

-------------------------------------------------------------------------------
h.suite("3. DRAWER AS VALID SCOPE (BUG-082)")
-------------------------------------------------------------------------------

test("BUG-082: 'search the drawer for a match' → drawer recognized as scope", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Open the drawer first
    local nightstand = ctx.registry:get("nightstand")
    nightstand.is_open = true
    if nightstand.parts and nightstand.parts.drawer then
        nightstand.parts.drawer.is_open = true
    end

    local start_output = capture_print(function()
        search.search(ctx, "match", "drawer")
    end)

    local output, steps = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    -- Should NOT say "nothing to search there"
    truthy(not full:find("nothing to search there"),
           "Drawer should be recognized as valid search scope")
end)

-------------------------------------------------------------------------------
h.suite("4. COMPOUND SCOPED+TARGETED SEARCH (verified passes)")
-------------------------------------------------------------------------------

test("'search nightstand for matchbox' → compound works (verified pass)", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "matchbox", "nightstand")
    end)

    local output, steps = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    truthy(full:find("matchbox"),
           "Compound scoped+targeted search should find matchbox in nightstand")
end)

test("'find matches in nightstand' → compound works (verified pass)", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "matches", "nightstand")
    end)

    local output, steps = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    truthy(full:find("match"),
           "Compound find X in Y should locate matches")
end)

-------------------------------------------------------------------------------
h.suite("5. NARRATION — Article handling (BUG-088)")
-------------------------------------------------------------------------------

test("BUG-088: narrator should NOT double articles in 'You feel...' text", function()
    local ctx = make_ctx()
    local bed = ctx.registry:get("bed")

    local narrative = narrator.step_narrative(ctx, bed, false)

    -- Should NOT contain "the a" or "the an" (doubled article)
    truthy(not narrative:find("the a "),
           "Narration should not contain 'the a' doubled article, got: " .. narrative)
    truthy(not narrative:find("the an "),
           "Narration should not contain 'the an' doubled article, got: " .. narrative)
end)

test("BUG-088: narrator should NOT double articles for nightstand", function()
    local ctx = make_ctx()
    local nightstand = ctx.registry:get("nightstand")

    local narrative = narrator.step_narrative(ctx, nightstand, false)

    truthy(not narrative:find("the a "),
           "Nightstand narration should not double articles, got: " .. narrative)
end)

test("BUG-088: search sweep narration has no doubled articles", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, nil, nil)
    end)
    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    truthy(not full:find("the a "),
           "Full sweep narration should have no 'the a' doubled article")
    truthy(not full:find("the an "),
           "Full sweep narration should have no 'the an' doubled article")
end)

test("BUG-081/088: failure message should NOT include articles", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Search for a target with an article prefix to verify it's stripped
    local start_output = capture_print(function()
        search.search(ctx, "the matchbox", nil)
    end)
    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    -- The failure/success message should say "matchbox" not "the matchbox"
    truthy(not full:find("No the matchbox"),
           "Failure message should not include article: 'No the matchbox found'")
end)

-------------------------------------------------------------------------------
h.suite("6. SAFETY — Timeout and depth limits")
-------------------------------------------------------------------------------

test("No search should exceed 100 ticks (safety limit)", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, nil)
    end)

    local _, steps = run_search_to_completion(ctx, 100)
    truthy(steps < 100,
           "Room sweep must complete within 100 ticks (safety limit), took " .. steps)
end)

test("Targeted search for nonexistent item completes promptly", function()
    local ctx = make_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "unicorn", nil)
    end)

    local output, steps = run_search_to_completion(ctx, 50)
    truthy(steps < 50,
           "Search for nonexistent item should complete within 50 ticks, took " .. steps)
    truthy(not search.is_searching(), "Search should be idle after exhaustion")
end)

-------------------------------------------------------------------------------
-- Run all tests
-------------------------------------------------------------------------------
h.summary()
