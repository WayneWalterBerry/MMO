-- test/search/test-search-bugs-096-099.lua
-- Regression tests for search/container interaction cluster:
--   #96: Search narration says "Inside" without naming the container
--   #97: Search bypasses closed containers — should narrate opening
--   #98: "take X" fails after "find X" discovers item in container
--   #99: Same as #98 but with pencil (duplicate, same root cause)

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
-- Context builder: dark bedroom with nightstand (drawer) + wardrobe
-- Two closed containers with items inside, to cover both #96 scenarios
---------------------------------------------------------------------------

local function make_test_room()
    local reg = registry_mod.new()

    local room = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dark bedroom.",
        contents = {},
        exits = {},
        light_level = 0,
    }

    -- Nightstand with a closed drawer containing a matchbox and a small knife
    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = {"nightstand", "night stand"},
        description = "A squat nightstand.",
        categories = {"furniture", "container"},
        is_container = true,
        is_open = false,
        is_locked = false,
        _state = "closed",
        surfaces = {
            top = { capacity = 3, max_item_size = 2, contents = {"candle-holder"} },
            inside = { capacity = 2, max_item_size = 1, contents = {"small-knife"}, accessible = false },
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
            closed = {
                surfaces = {
                    top = { capacity = 3, max_item_size = 2, contents = {} },
                    inside = { capacity = 2, max_item_size = 1, contents = {}, accessible = false },
                },
            },
            open = {
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

    local small_knife = {
        id = "small-knife",
        name = "a small knife",
        keywords = {"knife", "small knife"},
        description = "A small, sharp knife.",
        categories = {"weapon"},
    }

    -- Wardrobe: a closed container with a moth-eaten wool cloak inside
    local wardrobe = {
        id = "wardrobe",
        name = "a tall wardrobe",
        keywords = {"wardrobe"},
        description = "A tall, dark wardrobe.",
        categories = {"furniture", "container"},
        is_container = true,
        is_open = false,
        is_locked = false,
        contents = {"wool-cloak"},
    }

    local wool_cloak = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        description = "A moth-eaten wool cloak.",
        categories = {"wearable"},
    }

    -- Register everything
    reg:register("nightstand", nightstand)
    reg:register("candle-holder", candle_holder)
    reg:register("small-knife", small_knife)
    reg:register("wardrobe", wardrobe)
    reg:register("wool-cloak", wool_cloak)

    room.contents = {"nightstand", "wardrobe"}
    room.proximity_list = {"nightstand", "wardrobe"}

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        time_offset = 0,
    }

    return ctx, reg, room
end

---------------------------------------------------------------------------
-- #96: Search narration must include container name
---------------------------------------------------------------------------

h.suite("1. BUG #96 — Container name in search narration")

test("#96: 'Inside the drawer' not bare 'Inside' for targeted search miss", function()
    local ctx = make_test_room()
    -- Search for "candle" — should find the candle holder on top,
    -- but the drawer contents should say "Inside the drawer" not bare "Inside"
    local output = full_search(ctx, "candle")
    -- The narration about what's inside the drawer should name the drawer
    if output:find("Inside,") then
        error("Bare 'Inside,' without container name found.\nOutput:\n" .. output)
    end
    -- Check that container-interior narration names the container
    if output:lower():find("inside") and not output:lower():find("inside the") then
        error("Found 'Inside' without 'the <container>' following it.\nOutput:\n" .. output)
    end
end)

test("#96: surface_contents includes container name for 'inside' surface", function()
    local ctx = make_test_room()
    local parent = ctx.registry:get("nightstand")
    -- Call narrator.surface_contents for an "inside" surface
    local result = narrator.surface_contents(ctx, "inside", parent,
        {"a small knife"}, "candle")
    -- Must include the container name, not just "Inside, you feel:"
    truthy(not result:match("^Inside, "),
        "Should NOT start with bare 'Inside,' — must name the container.\nGot: " .. result)
    truthy(result:lower():find("nightstand") or result:lower():find("drawer"),
        "Should mention the container name.\nGot: " .. result)
end)

test("#96: nested_container_contents includes container name", function()
    local ctx = make_test_room()
    local container = ctx.registry:get("wardrobe")
    -- Call narrator.nested_container_contents
    local result = narrator.nested_container_contents(ctx, container, {"a moth-eaten wool cloak"})
    truthy(not result:match("^Inside, "),
        "Should NOT start with bare 'Inside,' — must name the container.\nGot: " .. result)
    truthy(result:lower():find("wardrobe"),
        "Should mention 'wardrobe'.\nGot: " .. result)
end)

---------------------------------------------------------------------------
-- #97: Search should narrate opening closed containers
---------------------------------------------------------------------------

h.suite("2. BUG #97 — Search narrates opening closed containers")

test("#97: search for item in closed drawer narrates opening", function()
    local ctx = make_test_room()
    local output = full_search(ctx, "knife")
    -- Should narrate pulling open / opening the drawer
    truthy(output:lower():find("open") or output:lower():find("pull"),
        "Should narrate opening the drawer.\nOutput:\n" .. output)
end)

test("#97: search for item in closed wardrobe narrates opening", function()
    local ctx = make_test_room()
    local output = full_search(ctx, "cloak")
    -- Should narrate opening the wardrobe
    truthy(output:lower():find("open") or output:lower():find("pull"),
        "Should narrate opening the wardrobe.\nOutput:\n" .. output)
    truthy(output:lower():find("wardrobe"),
        "Should mention wardrobe by name.\nOutput:\n" .. output)
end)

test("#97: container state changes to open after search enters it", function()
    local ctx, reg = make_test_room()
    local wardrobe = reg:get("wardrobe")
    -- Verify initially closed
    eq(false, containers.is_open(wardrobe), "wardrobe should start closed")
    -- Search for cloak (inside wardrobe)
    full_search(ctx, "cloak")
    -- After search, wardrobe should be open
    truthy(containers.is_open(wardrobe),
        "wardrobe should be open after search entered it")
end)

test("#97: nightstand drawer surface becomes accessible after search", function()
    local ctx, reg = make_test_room()
    local nightstand = reg:get("nightstand")
    -- Verify initially closed
    eq(false, nightstand.surfaces.inside.accessible,
        "inside surface should start inaccessible")
    -- Search for knife (inside drawer)
    full_search(ctx, "knife")
    -- After search, surface should be accessible
    truthy(nightstand.surfaces.inside.accessible ~= false,
        "inside surface should be accessible after search opened the drawer")
end)

---------------------------------------------------------------------------
-- #98/#99: Items accessible to take after find discovers them
---------------------------------------------------------------------------

h.suite("3. BUGS #98/#99 — Take after find")

test("#98: wardrobe is open after finding cloak, item reachable", function()
    local ctx, reg = make_test_room()
    local wardrobe = reg:get("wardrobe")
    -- Find the cloak
    full_search(ctx, "cloak")
    -- Wardrobe should now be open
    truthy(containers.is_open(wardrobe),
        "wardrobe must be open so take can reach items inside")
    -- Cloak should be accessible (container is open)
    truthy(wardrobe.is_open == true or wardrobe.open == true,
        "wardrobe.is_open should be true after search")
end)

test("#98: nightstand drawer accessible after finding knife", function()
    local ctx, reg = make_test_room()
    local nightstand = reg:get("nightstand")
    -- Find the knife
    full_search(ctx, "knife")
    -- The inside surface should now be accessible
    truthy(nightstand.surfaces.inside.accessible ~= false,
        "drawer surface must be accessible so take can find items inside")
end)

test("#99: same root cause — find pencil in closed container then take", function()
    -- Create a room with a closed box containing a pencil
    local reg = registry_mod.new()
    local room = {
        id = "office",
        name = "The Office",
        contents = {"desk-box"},
        proximity_list = {"desk-box"},
        exits = {},
        light_level = 0,
    }
    local box = {
        id = "desk-box",
        name = "a small wooden box",
        keywords = {"box", "wooden box"},
        is_container = true,
        is_open = false,
        is_locked = false,
        contents = {"pencil"},
    }
    local pencil = {
        id = "pencil",
        name = "a pencil",
        keywords = {"pencil"},
    }
    reg:register("desk-box", box)
    reg:register("pencil", pencil)

    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = {nil, nil}, worn = {}, state = {} },
        time_offset = 0,
    }

    -- Find the pencil
    full_search(ctx, "pencil")
    -- Box should be open now
    truthy(containers.is_open(box),
        "box must be open after search found pencil inside")
end)

---------------------------------------------------------------------------
-- Integration: full flow (#96 + #97 + #98)
---------------------------------------------------------------------------

h.suite("4. Integration — search narrates container name + opens + enables take")

test("Integration: find candle — drawer narration names container, opens it", function()
    local ctx, reg = make_test_room()
    local nightstand = reg:get("nightstand")
    -- Search for "candle" — top surface has candle-holder (will match),
    -- but we also need the drawer narration to name the drawer
    -- The search may end early finding candle-holder on top.
    -- So let's search for "knife" which is inside the drawer
    local output = full_search(ctx, "knife")
    -- Must name the drawer/container in narration
    truthy(output:lower():find("drawer") or output:lower():find("nightstand"),
        "Should name the container.\nOutput:\n" .. output)
    -- Must narrate opening
    truthy(output:lower():find("open") or output:lower():find("pull"),
        "Should narrate opening.\nOutput:\n" .. output)
    -- Drawer surface should now be accessible
    truthy(nightstand.surfaces.inside.accessible ~= false,
        "Drawer surface must be accessible after search")
end)

local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
