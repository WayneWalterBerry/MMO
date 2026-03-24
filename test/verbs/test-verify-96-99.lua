-- test/verbs/test-verify-96-99.lua
-- Verification tests for search/container interaction cluster:
--   #96: Search narration names containers ("Inside the drawer" not bare "Inside")
--   #97: Search opens closed containers and narrates the opening
--   #98: "take cloak" works after "find cloak" discovers it in wardrobe
--   #99: "get pencil" works after search finds it in a container (dup of #98)
--
-- Nelson — verification pass for commit 7044275
-- Usage: lua test/verbs/test-verify-96-99.lua  (from repo root)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local search       = require("engine.search")
local registry_mod = require("engine.registry")
local containers   = require("engine.search.containers")
local verbs_mod    = require("engine.verbs")
local handlers     = verbs_mod.create()

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

local function full_search(ctx, target, scope, max_steps)
    max_steps = max_steps or 50
    if search.is_searching() then search.abort(ctx) end
    local all_output = {}
    local init_out = capture_print(function()
        search.search(ctx, target, scope)
    end)
    if init_out ~= "" then all_output[#all_output + 1] = init_out end

    local step = 0
    local continues = true
    while continues and step < max_steps do
        local out = capture_print(function()
            continues = search.tick(ctx)
        end)
        if out ~= "" then all_output[#all_output + 1] = out end
        step = step + 1
    end
    if search.is_searching() then search.abort(ctx) end
    return table.concat(all_output, "\n"), step
end

local function search_via_verb(ctx, verb, noun)
    local all = {}
    local out = capture_print(function() handlers[verb](ctx, noun) end)
    if out ~= "" then all[#all + 1] = out end

    local max = 50
    local step = 0
    while search.is_searching() and step < max do
        local o = capture_print(function() search.tick(ctx) end)
        if o ~= "" then all[#all + 1] = o end
        step = step + 1
    end
    return table.concat(all, "\n")
end

---------------------------------------------------------------------------
-- World builder: bedroom with nightstand (drawer) + wardrobe
---------------------------------------------------------------------------

local function make_bedroom()
    local reg = registry_mod.new()

    local room = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dark bedroom.",
        contents = {"nightstand", "wardrobe"},
        proximity_list = {"nightstand", "wardrobe"},
        exits = {},
        light_level = 0,
    }

    reg:register("nightstand", {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "table", "bedside table"},
        description = "A small nightstand with a drawer.",
        categories = {"furniture", "wooden", "container"},
        is_container = true,
        is_open = false,
        is_locked = false,
        _state = "closed",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, accessible = true, contents = {"candle-holder"} },
            inside = { capacity = 2, max_item_size = 1, accessible = false, contents = {"small-knife"} },
        },
        contents = {"candle-holder", "small-knife"},
        parts = {
            drawer = {
                id = "nightstand-drawer",
                name = "a small drawer",
                keywords = {"drawer", "small drawer"},
                surface = "inside",
                is_container = true,
                contents = {"small-knife"},
            },
        },
        states = {
            closed = { surfaces = { top = { accessible = true, contents = {} }, inside = { accessible = false, contents = {} } } },
            open   = { surfaces = { top = { accessible = true, contents = {} }, inside = { accessible = true, contents = {} } } },
        },
    })

    reg:register("candle-holder", {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "brass"},
        description = "A brass candle holder.",
        size = 1, portable = true,
    })

    reg:register("small-knife", {
        id = "small-knife",
        name = "a small knife",
        keywords = {"knife", "small knife"},
        description = "A small, sharp knife.",
        size = 1, portable = true,
        categories = {"weapon"},
    })

    reg:register("wardrobe", {
        id = "wardrobe",
        name = "a tall wardrobe",
        keywords = {"wardrobe", "armoire"},
        description = "A tall, dark wardrobe.",
        categories = {"furniture", "wooden", "large", "container"},
        is_container = true,
        is_open = false,
        is_locked = false,
        _state = "closed",
        surfaces = {
            inside = { capacity = 8, max_item_size = 4, accessible = false, contents = {"wool-cloak"} },
        },
        states = {
            closed = { surfaces = { inside = { accessible = false, contents = {} } } },
            open   = { surfaces = { inside = { accessible = true, contents = {} } } },
        },
    })

    reg:register("wool-cloak", {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak", "wool"},
        description = "A thick wool cloak, moth-eaten but warm.",
        size = 2, portable = true,
        wearable = true,
        wear = { slot = "back", layer = "outer", provides_warmth = true },
        categories = {"fabric", "warm", "wearable"},
    })

    local ctx = {
        registry = reg,
        current_room = room,
        time_offset = 0,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, worn_items = {}, bags = {}, state = {} },
        injuries = {},
    }

    return ctx, reg, room
end

---------------------------------------------------------------------------
-- World builder: office with desk-box containing pencil (#99 scenario)
---------------------------------------------------------------------------

local function make_office()
    local reg = registry_mod.new()

    local room = {
        id = "office",
        name = "The Office",
        description = "A tidy office.",
        contents = {"desk-box"},
        proximity_list = {"desk-box"},
        exits = {},
        light_level = 0,
    }

    reg:register("desk-box", {
        id = "desk-box",
        name = "a small wooden box",
        keywords = {"box", "wooden box", "desk box"},
        description = "A small box on the desk.",
        categories = {"furniture", "container"},
        is_container = true,
        is_open = false,
        is_locked = false,
        _state = "closed",
        surfaces = {
            inside = { capacity = 4, max_item_size = 2, accessible = false, contents = {"pencil"} },
        },
        states = {
            closed = { surfaces = { inside = { accessible = false, contents = {} } } },
            open   = { surfaces = { inside = { accessible = true, contents = {} } } },
        },
    })

    reg:register("pencil", {
        id = "pencil",
        name = "a pencil",
        keywords = {"pencil"},
        description = "A sharpened pencil.",
        size = 1, portable = true,
    })

    local ctx = {
        registry = reg,
        current_room = room,
        time_offset = 0,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn = {}, worn_items = {}, bags = {}, state = {} },
        injuries = {},
    }

    return ctx, reg
end

---------------------------------------------------------------------------
-- SUITE 1: BUG #96 — Search narration must name the container
---------------------------------------------------------------------------

h.suite("VERIFY #96: search narration names containers")

test("#96-a: searching for knife — narration says 'the drawer' not bare 'Inside'", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, "knife")
    local lower = output:lower()
    -- Must NOT have bare "Inside," without naming what container
    if lower:find("inside,") and not lower:find("inside the") then
        error("Bare 'Inside,' without container name.\nOutput:\n" .. output)
    end
    -- Must mention drawer or nightstand by name
    truthy(lower:find("drawer") or lower:find("nightstand"),
        "Narration must name the container (drawer/nightstand).\nOutput:\n" .. output)
end)

test("#96-b: searching for cloak — narration says 'the wardrobe'", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, "cloak")
    local lower = output:lower()
    truthy(lower:find("wardrobe"),
        "Narration must name 'wardrobe' when describing its contents.\nOutput:\n" .. output)
end)

test("#96-c: room-wide search — all container refs are named", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, nil)  -- undirected sweep
    local lower = output:lower()
    -- Every "inside" mention should be followed by "the <something>"
    for line in output:gmatch("[^\n]+") do
        local ll = line:lower()
        if ll:find("^inside,") or ll:find("^inside ") then
            truthy(ll:find("inside the"),
                "Line starts with bare 'Inside' — must name container.\nLine: " .. line)
        end
    end
end)

---------------------------------------------------------------------------
-- SUITE 2: BUG #97 — Search narrates opening closed containers
---------------------------------------------------------------------------

h.suite("VERIFY #97: search narrates opening closed containers")

test("#97-a: finding knife in closed drawer produces 'open'/'pull' narration", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, "knife")
    local lower = output:lower()
    truthy(lower:find("open") or lower:find("pull"),
        "Should narrate opening the drawer.\nOutput:\n" .. output)
end)

test("#97-b: finding cloak in closed wardrobe produces 'open'/'pull' narration", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, "cloak")
    local lower = output:lower()
    truthy(lower:find("open") or lower:find("pull"),
        "Should narrate opening the wardrobe.\nOutput:\n" .. output)
end)

test("#97-c: opening narration appears BEFORE contents narration", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, "cloak")
    local lower = output:lower()
    local open_pos = lower:find("open") or lower:find("pull")
    local inside_pos = lower:find("inside the")
    if open_pos and inside_pos then
        truthy(open_pos < inside_pos,
            "Opening narration must come before contents.\nOutput:\n" .. output)
    else
        -- At minimum, one of these should exist
        truthy(open_pos or inside_pos,
            "Expected opening or contents narration.\nOutput:\n" .. output)
    end
end)

test("#97-d: wardrobe is_open=true after search enters it", function()
    local ctx, reg = make_bedroom()
    local wardrobe = reg:get("wardrobe")
    eq(false, containers.is_open(wardrobe), "wardrobe starts closed")
    full_search(ctx, "cloak")
    truthy(containers.is_open(wardrobe),
        "wardrobe must be open after search found cloak inside")
end)

test("#97-e: nightstand inside surface accessible after search enters it", function()
    local ctx, reg = make_bedroom()
    local ns = reg:get("nightstand")
    eq(false, ns.surfaces.inside.accessible, "inside starts inaccessible")
    full_search(ctx, "knife")
    truthy(ns.surfaces.inside.accessible ~= false,
        "inside surface must be accessible after search opened the drawer")
end)

---------------------------------------------------------------------------
-- SUITE 3: BUG #98 — "take cloak" after "find cloak" in closed wardrobe
---------------------------------------------------------------------------

h.suite("VERIFY #98: take after find (wardrobe + cloak)")

test("#98-a: 'find cloak' then 'take cloak' — full verb flow", function()
    local ctx, reg = make_bedroom()

    -- Step 1: find cloak (via verb handler → search engine)
    local find_out = search_via_verb(ctx, "find", "cloak")
    local lower = find_out:lower()
    truthy(lower:find("cloak"),
        "find should discover the cloak.\nOutput:\n" .. find_out)

    -- Step 2: take cloak (via verb handler)
    local take_out = capture_print(function()
        handlers["take"](ctx, "cloak")
    end)
    local take_lower = take_out:lower()
    -- Must NOT say "don't see" or "aren't holding"
    truthy(not take_lower:find("don't see") and not take_lower:find("no cloak"),
        "take should find the cloak (container was opened by search).\nOutput:\n" .. take_out)
    -- Should say "You take ..."
    truthy(take_lower:find("take") or take_lower:find("cloak"),
        "Should confirm taking the cloak.\nOutput:\n" .. take_out)
end)

test("#98-b: cloak is in player hand after find→take flow", function()
    local ctx, reg = make_bedroom()

    search_via_verb(ctx, "find", "cloak")
    capture_print(function() handlers["take"](ctx, "cloak") end)

    local in_hand = false
    for i = 1, 2 do
        local h_item = ctx.player.hands[i]
        if h_item then
            local id = type(h_item) == "table" and h_item.id or h_item
            if id == "wool-cloak" then in_hand = true; break end
        end
    end
    truthy(in_hand, "wool-cloak should be in player's hand after find→take")
end)

test("#98-c: cloak removed from wardrobe after find→take", function()
    local ctx, reg = make_bedroom()
    local wardrobe = reg:get("wardrobe")

    search_via_verb(ctx, "find", "cloak")
    capture_print(function() handlers["take"](ctx, "cloak") end)

    local still_inside = false
    for _, id in ipairs(wardrobe.surfaces.inside.contents or {}) do
        if id == "wool-cloak" then still_inside = true; break end
    end
    truthy(not still_inside,
        "wool-cloak should be removed from wardrobe.surfaces.inside.contents")
end)

---------------------------------------------------------------------------
-- SUITE 4: BUG #99 — "get pencil" after search finds it in a box
---------------------------------------------------------------------------

h.suite("VERIFY #99: get after search (box + pencil — duplicate of #98)")

test("#99-a: 'find pencil' opens box, 'get pencil' succeeds", function()
    local ctx, reg = make_office()

    -- find pencil
    local find_out = search_via_verb(ctx, "search", "pencil")
    local lower = find_out:lower()
    truthy(lower:find("pencil"),
        "search should discover the pencil.\nOutput:\n" .. find_out)

    -- box should now be open
    local box = reg:get("desk-box")
    truthy(containers.is_open(box),
        "box must be open after search found pencil inside")

    -- get pencil
    local get_out = capture_print(function()
        handlers["get"](ctx, "pencil")
    end)
    local get_lower = get_out:lower()
    truthy(not get_lower:find("don't see") and not get_lower:find("no pencil"),
        "get should find the pencil.\nOutput:\n" .. get_out)
    truthy(get_lower:find("take") or get_lower:find("pencil"),
        "Should confirm taking the pencil.\nOutput:\n" .. get_out)
end)

test("#99-b: pencil in hand, removed from box after search→get", function()
    local ctx, reg = make_office()
    local box = reg:get("desk-box")

    search_via_verb(ctx, "search", "pencil")
    capture_print(function() handlers["get"](ctx, "pencil") end)

    -- pencil in hand
    local in_hand = false
    for i = 1, 2 do
        local h_item = ctx.player.hands[i]
        if h_item then
            local id = type(h_item) == "table" and h_item.id or h_item
            if id == "pencil" then in_hand = true; break end
        end
    end
    truthy(in_hand, "pencil should be in player's hand")

    -- pencil removed from box
    local still = false
    for _, id in ipairs(box.surfaces.inside.contents or {}) do
        if id == "pencil" then still = true; break end
    end
    truthy(not still, "pencil should be removed from box")
end)

test("#99-c: narration names the box when searching", function()
    local ctx = make_office()
    local output = full_search(ctx, "pencil")
    local lower = output:lower()
    truthy(lower:find("box") or lower:find("wooden"),
        "Narration should name the container.\nOutput:\n" .. output)
end)

---------------------------------------------------------------------------
-- SUITE 5: Cross-cutting regression checks
---------------------------------------------------------------------------

h.suite("REGRESSION: search + take sanity checks")

test("REG: take from already-open container still works", function()
    local ctx, reg = make_bedroom()
    -- Pre-open the wardrobe
    local wardrobe = reg:get("wardrobe")
    wardrobe.is_open = true
    wardrobe.surfaces.inside.accessible = true

    local output = capture_print(function()
        handlers["take"](ctx, "cloak")
    end)
    local lower = output:lower()
    truthy(lower:find("take") or lower:find("cloak"),
        "Should take cloak from already-open wardrobe.\nOutput:\n" .. output)
end)

test("REG: search for missing item does not crash", function()
    local ctx = make_bedroom()
    local output = full_search(ctx, "banana")
    -- Should complete without error; banana not found
    truthy(type(output) == "string", "Search should return output without crashing")
end)

test("REG: search does not open locked containers", function()
    local ctx, reg = make_bedroom()
    local wardrobe = reg:get("wardrobe")
    wardrobe.is_locked = true
    full_search(ctx, "cloak")
    truthy(not containers.is_open(wardrobe),
        "Locked wardrobe must NOT be opened by search")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
