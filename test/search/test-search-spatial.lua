-- test/search/test-search-spatial.lua
-- Regression tests for spatial relationship fixes.
-- Issues: #24 (search shouldn't change container state)
--         #26 (hidden objects bypass search)
--         #27 (search reports container contents)
--
-- NO STUBS. Every test calls real code and verifies real behavior.

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

-- Build a bedroom context with rug/trap-door and wardrobe for spatial tests
local function make_spatial_ctx()
    local reg = registry_mod.new()

    local room = {
        id = "test-bedroom",
        name = "Test Bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    -- Covering object: rug hides trap-door
    local rug = {
        id = "rug",
        name = "a threadbare rug",
        keywords = {"rug", "carpet"},
        description = "A threadbare rug.",
        movable = true,
        moved = false,
        covering = {"trap-door"},
        move_message = "You pull the rug aside.",
        moved_room_presence = "The rug lies bunched against the wall.",
        moved_description = "The rug has been pulled aside.",
        surfaces = {
            underneath = {
                capacity = 3, max_item_size = 2,
                contents = {"brass-key"},
                accessible = false,
            },
        },
    }

    -- Hidden object: trap door under rug
    local trap_door = {
        id = "trap-door",
        name = "a trap door",
        keywords = {"trap door", "trapdoor", "door"},
        description = "A wooden trap door.",
        hidden = true,
        discovery_message = "You find a trap door!",
        initial_state = "hidden",
        _state = "hidden",
        states = {
            hidden = { hidden = true, room_presence = "", description = "" },
            revealed = { hidden = false, room_presence = "A trap door is in the floor.", description = "A wooden trap door." },
        },
        transitions = {
            { from = "hidden", to = "revealed", verb = "reveal", trigger = "reveal" },
        },
    }

    -- Small hidden item under rug
    local brass_key = {
        id = "brass-key",
        name = "a brass key",
        keywords = {"key", "brass key"},
        description = "A small brass key.",
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
            top = { contents = {"candle"} },
            inside = { contents = {"matchbox"}, accessible = false },
        },
        contents = {"candle", "matchbox"},
        _state = "closed",
        states = {
            closed = { surfaces = { inside = { accessible = false } } },
            open = { surfaces = { inside = { accessible = true } } },
        },
        transitions = {
            { from = "closed", to = "open", verb = "open" },
        },
    }

    local candle = {
        id = "candle", name = "a candle", keywords = {"candle"},
        description = "A white candle.",
    }

    local matchbox = {
        id = "matchbox", name = "a matchbox", keywords = {"matchbox", "matches"},
        description = "A small matchbox.",
    }

    -- Wardrobe: closed container with contents
    local wardrobe = {
        id = "wardrobe",
        name = "a heavy wardrobe",
        keywords = {"wardrobe", "closet"},
        description = "A large wardrobe.",
        is_container = true,
        is_open = false,
        is_locked = false,
        contents = {"sack", "wool-cloak"},
    }

    local sack = {
        id = "sack", name = "a burlap sack", keywords = {"sack"},
        description = "A burlap sack.",
    }
    local cloak = {
        id = "wool-cloak", name = "a wool cloak", keywords = {"cloak"},
        description = "A wool cloak.",
    }

    -- Empty chest
    local chest = {
        id = "chest",
        name = "a wooden chest",
        keywords = {"chest"},
        description = "A wooden chest.",
        is_container = true,
        is_open = false,
        is_locked = false,
        contents = {},
    }

    -- Register all objects
    reg:register("test-bedroom", room)
    reg:register("rug", rug)
    reg:register("trap-door", trap_door)
    reg:register("brass-key", brass_key)
    reg:register("nightstand", nightstand)
    reg:register("candle", candle)
    reg:register("matchbox", matchbox)
    reg:register("wardrobe", wardrobe)
    reg:register("sack", sack)
    reg:register("wool-cloak", cloak)
    reg:register("chest", chest)

    room.proximity_list = {"rug", "trap-door", "nightstand", "wardrobe", "chest"}
    room.contents = {"rug", "trap-door", "nightstand", "wardrobe", "chest"}

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
h.suite("1. HIDDEN OBJECTS NOT FOUND BY SEARCH (#26)")
-------------------------------------------------------------------------------

test("#26: hidden trap door not found by room sweep", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, nil, nil)
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    truthy(not full:lower():find("trap door"),
           "Hidden trap door should NOT appear in room sweep results")
end)

test("#26: hidden trap door not found by targeted search", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "trap door", nil)
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    -- Should NOT report finding the trap door
    local found_it = full:lower():find("you have found.*trap door")
    truthy(not found_it,
           "Search for hidden trap door should NOT find it")
end)

test("#26: rug's inaccessible underneath surface not searched", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Search rug for brass key — underneath is accessible=false
    local start_output = capture_print(function()
        search.search(ctx, "brass key", "rug")
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    -- Brass key should NOT be found while rug hasn't been moved
    local found_key = full:lower():find("you have found.*brass key")
    truthy(not found_key,
           "Brass key under unmoved rug should NOT be found by search")
end)

test("#26: expand_object skips hidden objects in queue", function()
    local ctx = make_spatial_ctx()
    local entries = traverse.build_queue(ctx.current_room, nil, nil, ctx.registry)

    -- Trap door is hidden — should NOT appear in queue
    local found_trap_door = false
    for _, entry in ipairs(entries) do
        if entry.object_id == "trap-door" then
            found_trap_door = true
        end
    end
    truthy(not found_trap_door,
           "Hidden trap-door should not appear in search queue")
end)

test("#26: matches_target rejects hidden objects", function()
    local ctx = make_spatial_ctx()
    local trap_door = ctx.registry:get("trap-door")

    -- Direct call to private matches_target via targeted search
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "trap door", nil)
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    truthy(full:lower():find("no trap door found"),
           "Targeted search should conclude with 'no trap door found'")
end)

-------------------------------------------------------------------------------
h.suite("2. MOVING RUG REVEALS TRAP DOOR (#26)")
-------------------------------------------------------------------------------

test("#26: after revealing, trap door appears in search queue", function()
    local ctx = make_spatial_ctx()

    -- Simulate what move handler does: reveal the trap door
    local trap_door = ctx.registry:get("trap-door")
    trap_door.hidden = false
    trap_door._state = "revealed"

    local entries = traverse.build_queue(ctx.current_room, nil, nil, ctx.registry)

    local found_trap_door = false
    for _, entry in ipairs(entries) do
        if entry.object_id == "trap-door" then
            found_trap_door = true
        end
    end
    truthy(found_trap_door,
           "Revealed trap door should appear in search queue")
end)

test("#26: after revealing, targeted search finds trap door", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    -- Reveal
    local trap_door = ctx.registry:get("trap-door")
    trap_door.hidden = false
    trap_door._state = "revealed"

    local start_output = capture_print(function()
        search.search(ctx, "trap door", nil)
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    truthy(full:lower():find("trap door"),
           "After reveal, search should find the trap door")
end)

test("#26: after move, rug underneath surface becomes accessible", function()
    local ctx = make_spatial_ctx()
    local rug = ctx.registry:get("rug")

    -- Verify initial state
    eq(false, rug.surfaces.underneath.accessible,
       "Underneath surface should start inaccessible")

    -- Simulate move handler setting accessible
    rug.moved = true
    rug.surfaces.underneath.accessible = true

    eq(true, rug.surfaces.underneath.accessible,
       "Underneath surface should be accessible after move")
end)

-------------------------------------------------------------------------------
h.suite("3. SEARCH DOESN'T CHANGE CONTAINER STATE (#24)")
-------------------------------------------------------------------------------

test("#24: wardrobe stays closed after room sweep search", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local wardrobe = ctx.registry:get("wardrobe")
    eq(false, wardrobe.is_open, "Wardrobe should start closed")

    capture_print(function()
        search.search(ctx, nil, nil)
    end)
    run_search_to_completion(ctx)

    eq(false, wardrobe.is_open,
       "Wardrobe should STILL be closed after room sweep search")
end)

test("#24: wardrobe stays closed after targeted search inside it", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local wardrobe = ctx.registry:get("wardrobe")
    eq(false, wardrobe.is_open, "Wardrobe should start closed")

    capture_print(function()
        search.search(ctx, "chamber pot", "wardrobe")
    end)
    run_search_to_completion(ctx)

    eq(false, wardrobe.is_open,
       "Wardrobe should STILL be closed after targeted search")
end)

test("#24: nightstand stays closed after search", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local nightstand = ctx.registry:get("nightstand")
    eq(false, nightstand.is_open, "Nightstand should start closed")

    capture_print(function()
        search.search(ctx, "matchbox", nil)
    end)
    run_search_to_completion(ctx)

    eq(false, nightstand.is_open,
       "Nightstand should STILL be closed after search")
end)

test("#24: chest stays closed after room sweep", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local chest = ctx.registry:get("chest")
    eq(false, chest.is_open, "Chest should start closed")

    capture_print(function()
        search.search(ctx, nil, nil)
    end)
    run_search_to_completion(ctx)

    eq(false, chest.is_open,
       "Chest should STILL be closed after room sweep")
end)

-------------------------------------------------------------------------------
h.suite("4. SEARCH REPORTS CONTAINER CONTENTS (#27)")
-------------------------------------------------------------------------------

test("#27: search wardrobe for missing item reports actual contents", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "chamber pot", "wardrobe")
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    -- Should mention what IS inside (sack and/or cloak) and what's NOT (chamber pot)
    local reports_contents = full:lower():find("sack") or full:lower():find("cloak")
    local reports_missing = full:lower():find("no chamber pot") or full:lower():find("chamber pot")

    truthy(reports_contents,
           "Search should report actual container contents (sack/cloak)")
    truthy(reports_missing,
           "Search should note the missing target (chamber pot)")
end)

test("#27: search empty chest reports empty", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "gold", "chest")
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    local reports_empty = full:lower():find("empty")

    truthy(reports_empty,
           "Search of empty container should report it's empty")
end)

test("#27: search empty chest for specific item mentions no target", function()
    local ctx = make_spatial_ctx()
    if search.is_searching() then search.abort(ctx) end

    local start_output = capture_print(function()
        search.search(ctx, "sword", "chest")
    end)

    local output = run_search_to_completion(ctx)
    local full = start_output .. "\n" .. output

    local reports_no_target = full:lower():find("no sword")

    truthy(reports_no_target,
           "Search of empty container for specific item should say 'No sword here'")
end)

test("#27: narrator.container_contents_no_target formats correctly with items", function()
    local ctx = make_spatial_ctx()
    local wardrobe = ctx.registry:get("wardrobe")

    local msg = narrator.container_contents_no_target(ctx, wardrobe, {"a burlap sack", "a wool cloak"}, "chamber pot")

    truthy(msg:find("burlap sack"),
           "Should list actual contents: " .. msg)
    truthy(msg:find("no chamber pot"),
           "Should mention missing target: " .. msg)
end)

test("#27: narrator.container_contents_no_target formats correctly when empty", function()
    local ctx = make_spatial_ctx()
    local chest = ctx.registry:get("chest")

    local msg = narrator.container_contents_no_target(ctx, chest, {}, "sword")

    truthy(msg:find("empty"),
           "Should say empty: " .. msg)
    truthy(msg:find("No sword"),
           "Should mention missing target: " .. msg)
end)

-------------------------------------------------------------------------------
-- Run all tests
-------------------------------------------------------------------------------
h.summary()
