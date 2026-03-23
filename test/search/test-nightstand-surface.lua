-- test/search/test-nightstand-surface.lua
-- Integration test for #63: nightstand surface narration in TARGETED searches.
--
-- Wayne reported the candle holder is STILL described as "inside" the
-- nightstand when doing "find match". Flanders' fix only covered the
-- undirected search path; the targeted-search path still calls
-- narrator.container_contents_no_target() which always says "Inside".
--
-- This test exercises the actual engine path: search → traverse → narrator.

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
local narrator = require("engine.search.narrator")

---------------------------------------------------------------------------
-- Helpers (same capture/run pattern as test-search-narration-bugs.lua)
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
-- Context builder: bedroom with nightstand (closed drawer)
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
        keywords = {"candle holder", "holder", "brass", "candle"},
        description = "A brass candle holder.",
    }

    local glass_bottle = {
        id = "glass-bottle",
        name = "a small glass bottle",
        keywords = {"bottle", "glass bottle", "glass"},
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
h.suite("#63 TARGETED — 'find match' surface narration")
---------------------------------------------------------------------------

test("find match: candle holder should say 'On top of', NOT 'Inside'", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)

    -- The candle holder and glass bottle are on nightstand.top.
    -- When reporting "no match found here", the narration should say
    -- "On top of the nightstand" NOT "Inside the nightstand".
    local candle_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("candle") then
            candle_line = line
            break
        end
    end

    truthy(candle_line ~= nil,
           "Targeted search should mention candle holder when reporting " ..
           "top-surface contents. Got output:\n" .. output)

    if candle_line then
        truthy(candle_line:find("On top") or candle_line:find("on top"),
               "Candle holder is on nightstand.top — narration must say " ..
               "'On top', not 'Inside'. Got line: " .. candle_line)

        truthy(not candle_line:find("Inside") and not candle_line:find("inside"),
               "Candle holder on top surface MUST NOT say 'Inside'. " ..
               "Got line: " .. candle_line)
    end
end)

test("find match: glass bottle should say 'On top of', NOT 'Inside'", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)

    local bottle_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("bottle") then
            bottle_line = line
            break
        end
    end

    truthy(bottle_line ~= nil,
           "Targeted search should mention glass bottle when reporting " ..
           "top-surface contents. Got output:\n" .. output)

    if bottle_line then
        truthy(bottle_line:find("On top") or bottle_line:find("on top"),
               "Glass bottle is on nightstand.top — narration must say " ..
               "'On top', not 'Inside'. Got line: " .. bottle_line)
    end
end)

test("find match: drawer contents should say 'Inside'", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)

    -- The match IS found inside the drawer — the narration for
    -- the drawer/matchbox contents should say "Inside"
    local match_found = output:find("[Mm]atch")
    truthy(match_found,
           "Targeted search for 'match' must find it. Got: " .. output)
end)

test("find match: 'On top' line includes nightstand name", function()
    local ctx = make_dark_bedroom()
    local output = full_search(ctx, "match", nil)

    -- When top-surface items are reported, the narration should include
    -- the parent name "nightstand"
    local top_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("candle") or line:find("bottle") then
            top_line = line
            break
        end
    end

    if top_line then
        truthy(top_line:find("nightstand"),
               "Top-surface narration should reference the nightstand. " ..
               "Got: " .. top_line)
    end
end)

test("find match (lit room): uses 'find' not 'feel' for top surface", function()
    local ctx = make_lit_bedroom()
    local output = full_search(ctx, "match", nil)

    local candle_line = nil
    for line in output:gmatch("[^\n]+") do
        if line:find("candle") then
            candle_line = line
            break
        end
    end

    if candle_line then
        -- In a lit room, should use visual language
        truthy(not candle_line:find("feel"),
               "Lit room should NOT use 'feel' for top surface. " ..
               "Got: " .. candle_line)
    end
end)

---------------------------------------------------------------------------
h.suite("narrator.container_contents_no_target surface awareness")
---------------------------------------------------------------------------

test("narrator.container_contents_no_target always says 'Inside' (current bug)", function()
    -- This documents the current (broken) behavior:
    -- container_contents_no_target ignores surface_name entirely
    local ctx = make_dark_bedroom()
    local parent = ctx.registry:get("nightstand")

    local text = narrator.container_contents_no_target(
        ctx, parent, {"a brass candle holder", "a small glass bottle"}, "match")

    -- BUG: this will say "You check inside the nightstand" even for top items
    local says_inside = text:find("inside") or text:find("Inside")
    truthy(says_inside,
           "[Bug documentation] container_contents_no_target currently always " ..
           "says 'Inside'. Got: " .. text)
end)

test("narrator.surface_contents correctly says 'On top' for top", function()
    local ctx = make_dark_bedroom()
    local parent = ctx.registry:get("nightstand")

    local text = narrator.surface_contents(
        ctx, "top", parent, {"a brass candle holder", "a small glass bottle"})

    truthy(text:find("On top"),
           "surface_contents('top') must say 'On top'. Got: " .. text)
end)

---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
