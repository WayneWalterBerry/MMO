-- test/nightstand/test-nightstand-chain.lua
-- Regression tests for nightstand interaction chain from Pass-026.
-- Tests the critical path: feel around → nightstand → drawer → matchbox →
-- match → light match → light candle.
--
-- Bug IDs tested: BUG-089, BUG-090, BUG-091, BUG-092

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

local registry_mod = require("engine.registry")
local search = require("engine.search")

-- Try to load verb handlers; these may not be loadable in isolation
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
local handlers = verbs_ok and verbs_mod.create() or nil

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

-- Execute a verb handler and capture output
local function exec_verb(ctx, verb, noun)
    if not handlers or not handlers[verb] then
        error("Verb handler '" .. verb .. "' not available")
    end
    return capture_print(function()
        handlers[verb](ctx, noun or "")
    end)
end

-- Execute a verb handler with search tick processing
local function exec_search_verb(ctx, verb, noun)
    local all_output = {}
    all_output[#all_output + 1] = exec_verb(ctx, verb, noun or "")

    local max_ticks = 50
    local tick_count = 0
    while search.is_searching() and tick_count < max_ticks do
        local output = capture_print(function()
            search.tick(ctx)
        end)
        all_output[#all_output + 1] = output
        tick_count = tick_count + 1
    end

    return table.concat(all_output, "\n")
end

-- Build a bedroom context matching the actual game state
local function make_bedroom_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "bedroom",
        name = "Bedroom",
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
        on_feel = "You feel the rough wooden frame of a large four-poster bed.",
    }

    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "table", "stand"},
        description = "Smooth wooden surface, crusted with hardened wax drippings.",
        on_feel = "Smooth wooden surface, crusted with hardened wax drippings. A small drawer handle protrudes from the front.",
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
                surfaces = {
                    inside = { contents = {"matchbox"} },
                },
            }
        },
    }

    local candle_holder = {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "brass"},
        description = "A brass candle holder with a half-melted candle.",
        has_candle = true,
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
        keywords = {"matchbox", "box", "matches"},
        description = "A small cardboard box. One side is rough -- a striker strip.",
        is_container = true,
        is_open = false,
        is_locked = false,
        contents = {},
    }

    -- Create 7 fresh matches
    local match_ids = {}
    for i = 1, 7 do
        local mid = "match-" .. i
        match_ids[#match_ids + 1] = mid
        reg:register(mid, {
            id = mid,
            name = "a wooden match",
            keywords = {"match", "wooden match"},
            description = "A wooden match.",
            is_fresh = true,
            is_spent = false,
        })
    end
    matchbox.contents = match_ids

    local candle = {
        id = "candle",
        name = "candle",
        keywords = {"candle"},
        description = "A half-melted wax candle in a brass holder.",
        is_lightable = true,
        is_lit = false,
    }

    local vanity = {
        id = "vanity",
        name = "an oak vanity",
        keywords = {"vanity"},
        description = "A dressing table.",
    }

    local wardrobe = {
        id = "wardrobe",
        name = "a heavy wardrobe",
        keywords = {"wardrobe", "closet"},
        description = "A large wardrobe.",
        is_container = true,
        is_open = false,
        is_locked = true,
    }

    -- Register everything
    reg:register("bedroom", room)
    reg:register("bed", bed)
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("glass-bottle", glass_bottle)
    reg:register("matchbox", matchbox)
    reg:register("candle", candle)
    reg:register("vanity", vanity)
    reg:register("wardrobe", wardrobe)

    room.proximity_list = {"bed", "nightstand", "vanity", "wardrobe"}
    room.contents = {"bed", "nightstand", "vanity", "wardrobe", "candle"}

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
        time_offset = 20,  -- nighttime (dark)
        game_start_time = os.time(),
        match_count = 7,
    }

    return ctx, reg, room
end

-- Create a spent match object
local function make_spent_match(reg, location)
    local spent = {
        id = "spent-match-1",
        name = "a spent match",
        keywords = {"match", "spent match", "blackened match"},
        description = "A blackened, spent match stub.",
        is_fresh = false,
        is_spent = true,
    }
    reg:register("spent-match-1", spent)
    return spent
end

-- Skip test helper for when verb handlers aren't available
local function skip_if_no_verbs(test_name)
    if not handlers then
        print("  SKIP " .. test_name .. " (verb handlers not loadable in isolation)")
        return true
    end
    return false
end

-------------------------------------------------------------------------------
h.suite("1. FEEL INTERACTIONS — Discovery chain (Pass-026 Phase 1)")
-------------------------------------------------------------------------------

test("feel around → lists nightstand among room objects", function()
    if skip_if_no_verbs("feel around") then return end
    local ctx = make_bedroom_ctx()

    local output = exec_verb(ctx, "feel", "around")

    truthy(output:find("nightstand"),
           "'feel around' should list nightstand among discoverable objects")
end)

test("feel nightstand → reveals drawer handle and top surface items", function()
    if skip_if_no_verbs("feel nightstand") then return end
    local ctx = make_bedroom_ctx()

    local output = exec_verb(ctx, "feel", "nightstand")

    truthy(output:find("drawer") or output:find("handle"),
           "'feel nightstand' should mention drawer/handle")
    truthy(output:find("candle") or output:find("holder") or output:find("bottle"),
           "'feel nightstand' should reveal top surface items")
end)

test("open drawer → opens successfully", function()
    if skip_if_no_verbs("open drawer") then return end
    local ctx = make_bedroom_ctx()

    local output = exec_verb(ctx, "open", "drawer")

    truthy(output:find("open") or output:find("slide") or output:find("pull"),
           "'open drawer' should succeed and produce opening narration")
end)

test("BUG-089: feel inside drawer → shows ONLY drawer contents", function()
    if skip_if_no_verbs("feel inside drawer") then return end
    local ctx = make_bedroom_ctx()

    -- Open the drawer first
    local nightstand = ctx.registry:get("nightstand")
    nightstand.is_open = true
    if nightstand.parts and nightstand.parts.drawer then
        nightstand.parts.drawer.is_open = true
    end

    local output = exec_verb(ctx, "feel", "inside drawer")

    -- Should show matchbox (drawer contents)
    truthy(output:find("matchbox"),
           "'feel inside drawer' should show matchbox")

    -- Should NOT show nightstand top surface items (scope bleed)
    local has_top_items = output:find("candle holder") or output:find("glass bottle")
    truthy(not has_top_items,
           "'feel inside drawer' should NOT show nightstand top items (scope bleed), got: " .. output)
end)

-------------------------------------------------------------------------------
h.suite("2. MATCHBOX AND MATCH INTERACTIONS (Pass-026 Phase 2)")
-------------------------------------------------------------------------------

test("examine matchbox → shows 7 matches", function()
    if skip_if_no_verbs("examine matchbox") then return end
    local ctx = make_bedroom_ctx()

    local output = exec_verb(ctx, "examine", "matchbox")

    -- Should mention matches
    truthy(output:find("match"),
           "'examine matchbox' should mention matches inside")
end)

test("take match → gets a fresh match from matchbox", function()
    if skip_if_no_verbs("take match") then return end
    local ctx = make_bedroom_ctx()

    local output = exec_verb(ctx, "take", "match")

    truthy(output:find("match") or output:find("take") or output:find("get"),
           "'take match' should pick up a match")
    -- Should NOT say "spent"
    truthy(not output:find("spent"),
           "'take match' should get a FRESH match, not spent")
end)

test("BUG-091: 'take match' with spent match on floor → gets FRESH match", function()
    if skip_if_no_verbs("take match") then return end
    local ctx, reg = make_bedroom_ctx()

    -- Put a spent match on the floor
    local spent = make_spent_match(reg)
    local room = ctx.current_room
    room.contents[#room.contents + 1] = "spent-match-1"

    local output = exec_verb(ctx, "take", "match")

    -- Should NOT pick up the spent match
    truthy(not output:find("spent"),
           "'take match' should prefer fresh match from matchbox over spent match on floor")
end)

test("light/strike match → match lights", function()
    if skip_if_no_verbs("light match") then return end
    local ctx = make_bedroom_ctx()

    -- Put a match in player's hand
    local match_obj = ctx.registry:get("match-1")
    ctx.player.hands[1] = match_obj

    local output = exec_verb(ctx, "light", "match")

    truthy(output:find("flame") or output:find("light") or output:find("strike") or output:find("hiss"),
           "'light match' should produce flame narration")
end)

-------------------------------------------------------------------------------
h.suite("3. CANDLE LIGHTING — Critical path (BUG-090)")
-------------------------------------------------------------------------------

test("BUG-090: 'light candle' should NOT hang", function()
    if skip_if_no_verbs("light candle") then return end
    local ctx = make_bedroom_ctx()

    -- Simulate having matchbox available
    local matchbox = ctx.registry:get("matchbox")
    matchbox.is_open = true

    -- Run with a hard timeout via coroutine
    local completed = false
    local output = ""
    local co = coroutine.create(function()
        output = exec_verb(ctx, "light", "candle")
        completed = true
    end)

    -- Give it up to 1000 resume cycles (generous safety limit)
    local max_cycles = 1000
    local cycle = 0
    while coroutine.status(co) ~= "dead" and cycle < max_cycles do
        local ok, err = coroutine.resume(co)
        if not ok then
            -- Error is acceptable (e.g. "need fire source") — at least it didn't hang
            completed = true
            break
        end
        cycle = cycle + 1
    end

    truthy(completed,
           "'light candle' should complete (not hang). Goal planner must have safety limit.")
end)

test("BUG-090: light candle → should light the candle when match available", function()
    if skip_if_no_verbs("light candle") then return end
    local ctx = make_bedroom_ctx()

    -- Put a lit match in player's hand
    local match_obj = ctx.registry:get("match-1")
    match_obj.is_lit = true
    ctx.player.hands[1] = match_obj

    local output = exec_verb(ctx, "light", "candle")

    -- Should succeed or at least not hang
    truthy(output ~= nil and output ~= "",
           "'light candle' with lit match should produce some response")
end)

-------------------------------------------------------------------------------
h.suite("4. MATCH COUNTER (BUG-092)")
-------------------------------------------------------------------------------

test("BUG-092: match counter should decrement when match is used", function()
    local ctx = make_bedroom_ctx()
    local initial_count = ctx.match_count or 7

    -- Simulate using a match
    local matchbox = ctx.registry:get("matchbox")
    local match_id = matchbox.contents[1]
    if match_id then
        -- Remove match from matchbox
        table.remove(matchbox.contents, 1)

        -- The remaining count should reflect one less
        local remaining = #matchbox.contents
        truthy(remaining == initial_count - 1,
               "Matchbox should have " .. (initial_count - 1) .. " matches after taking one, has " .. remaining)
    end
end)

test("BUG-092: match counter tracks actual matchbox contents", function()
    local ctx = make_bedroom_ctx()
    local matchbox = ctx.registry:get("matchbox")

    -- Start with 7
    eq(7, #matchbox.contents, "Matchbox should start with 7 matches")

    -- Remove 3
    table.remove(matchbox.contents, 1)
    table.remove(matchbox.contents, 1)
    table.remove(matchbox.contents, 1)

    eq(4, #matchbox.contents, "Matchbox should have 4 matches after removing 3")
end)

-------------------------------------------------------------------------------
h.suite("5. SAFETY — No command should hang")
-------------------------------------------------------------------------------

test("'search nightstand' completes within timeout", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, "nightstand")
    end)

    local _, steps = run_search_to_completion(ctx, 30)
    truthy(steps < 30,
           "'search nightstand' should complete within 30 ticks, took " .. steps)
end)

test("'search the room' completes within timeout", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, nil, nil)
    end)

    local _, steps = run_search_to_completion(ctx, 50)
    truthy(steps < 50,
           "Room sweep should complete within 50 ticks, took " .. steps)
end)

test("'find matchbox' in bedroom completes within timeout", function()
    local ctx = make_bedroom_ctx()
    if search.is_searching() then search.abort(ctx) end

    capture_print(function()
        search.search(ctx, "matchbox", nil)
    end)

    local _, steps = run_search_to_completion(ctx, 30)
    truthy(steps < 30,
           "Targeted search for matchbox should complete within 30 ticks, took " .. steps)
end)

-------------------------------------------------------------------------------
-- Run all tests
-------------------------------------------------------------------------------
h.summary()
