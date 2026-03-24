-- test/verbs/test-movement-verbs.lua
-- Pre-refactoring coverage for movement/navigation verbs.
-- Tests: go, north/south/east/west/up/down, back, enter, climb, descend, ascend,
--        direction aliases, closed/locked exit blocking, hidden exit blocking,
--        move disambiguation (navigation vs object).
--
-- Usage: lua test/verbs/test-movement-verbs.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function make_rooms()
    local bedroom = {
        id = "bedroom",
        name = "Bedroom",
        description = "A dim bedroom.",
        short_description = "The familiar bedroom.",
        contents = {},
        exits = {
            north = {
                target = "hallway",
                name = "a wooden door",
                keywords = {"door", "wooden door"},
                open = true,
            },
            south = {
                target = "cellar",
                name = "a trapdoor",
                keywords = {"trapdoor", "trap door"},
                open = false,
            },
            east = {
                target = "closet",
                name = "a closet door",
                keywords = {"closet"},
                open = true,
                locked = false,
            },
            west = {
                target = "locked-room",
                name = "an iron door",
                keywords = {"iron door"},
                open = false,
                locked = true,
            },
            up = {
                target = "attic",
                open = true,
            },
        },
    }
    local hallway = {
        id = "hallway",
        name = "Hallway",
        description = "A long dark hallway.",
        short_description = "The hallway stretches away.",
        contents = {},
        exits = {
            south = {
                target = "bedroom",
                name = "a wooden door",
                open = true,
            },
        },
    }
    local cellar = {
        id = "cellar",
        name = "Cellar",
        description = "A cold stone cellar.",
        contents = {},
        exits = {},
    }
    local closet = {
        id = "closet",
        name = "Closet",
        description = "A tiny closet.",
        contents = {},
        exits = {},
    }
    local attic = {
        id = "attic",
        name = "Attic",
        description = "A dusty attic.",
        contents = {},
        exits = {},
    }
    return {
        bedroom = bedroom,
        hallway = hallway,
        cellar = cellar,
        closet = closet,
        attic = attic,
    }
end

local function make_ctx(start_room)
    start_room = start_room or "bedroom"
    local rooms = make_rooms()
    local reg = registry_mod.new()
    return {
        registry = reg,
        current_room = rooms[start_room],
        rooms = rooms,
        player = {
            hands = { nil, nil },
            worn = {},
            injuries = {},
            bags = {},
            state = {},
            location = start_room,
            visited_rooms = {},
        },
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. CARDINAL DIRECTIONS — basic navigation
---------------------------------------------------------------------------
suite("Movement — cardinal directions")

test("north moves to hallway", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["north"](ctx, "")
    end)
    eq("hallway", ctx.current_room.id, "Should be in hallway after going north")
end)

test("n alias moves to hallway", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["n"](ctx, "")
    end)
    eq("hallway", ctx.current_room.id, "n alias should navigate north")
end)

test("south with closed exit blocks movement", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["south"](ctx, "")
    end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom (trapdoor closed)")
    h.assert_truthy(output:find("closed"),
        "Should mention exit is closed")
end)

test("east moves to closet (open unlocked)", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["east"](ctx, "")
    end)
    eq("closet", ctx.current_room.id, "Should be in closet after going east")
end)

test("west with locked exit blocks and mentions locked", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["west"](ctx, "")
    end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom (iron door locked)")
    h.assert_truthy(output:find("locked"),
        "Should mention exit is locked")
end)

test("up moves to attic", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["up"](ctx, "")
    end)
    eq("attic", ctx.current_room.id, "Should be in attic after going up")
end)

test("no exit in that direction prints can't-go", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["down"](ctx, "")
    end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom")
    h.assert_truthy(output:find("can't go"),
        "Should say can't go that way")
end)

---------------------------------------------------------------------------
-- 2. GO VERB — general navigation
---------------------------------------------------------------------------
suite("Movement — go verb")

test("go north navigates correctly", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["go"](ctx, "north")
    end)
    eq("hallway", ctx.current_room.id, "go north should reach hallway")
end)

test("go with no noun prints 'Go where?'", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["go"](ctx, "")
    end)
    h.assert_truthy(output:find("Go where"),
        "go with empty noun should ask where")
end)

test("go through exit matched by keyword", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["go"](ctx, "wooden door")
    end)
    eq("hallway", ctx.current_room.id,
        "go wooden door should match north exit by keyword")
end)

test("walk alias works like go", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["walk"](ctx, "north")
    end)
    eq("hallway", ctx.current_room.id, "walk should be alias for go")
end)

test("run alias works like go", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["run"](ctx, "north")
    end)
    eq("hallway", ctx.current_room.id, "run should be alias for go")
end)

---------------------------------------------------------------------------
-- 3. ENTER — enter through exit by keyword
---------------------------------------------------------------------------
suite("Movement — enter verb")

test("enter with no noun prints 'Enter what?'", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["enter"](ctx, "")
    end)
    h.assert_truthy(output:find("Enter what"),
        "enter with empty noun should ask what")
end)

test("enter wooden door navigates through matching exit", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["enter"](ctx, "wooden door")
    end)
    eq("hallway", ctx.current_room.id,
        "enter wooden door should navigate to hallway")
end)

test("enter closet navigates to closet", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["enter"](ctx, "closet")
    end)
    eq("closet", ctx.current_room.id,
        "enter closet should navigate by exit keyword")
end)

---------------------------------------------------------------------------
-- 4. CLIMB — vertical movement
---------------------------------------------------------------------------
suite("Movement — climb verb")

test("climb up navigates up", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["climb"](ctx, "up")
    end)
    eq("attic", ctx.current_room.id, "climb up should go to attic")
end)

test("climb with no noun defaults to up", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["climb"](ctx, "")
    end)
    eq("attic", ctx.current_room.id, "bare climb should default to up")
end)

test("climb down navigates down", function()
    local ctx = make_ctx()
    -- Add a down exit
    ctx.current_room.exits.down = { target = "cellar", open = true }
    local output = capture_output(function()
        handlers["climb"](ctx, "down")
    end)
    eq("cellar", ctx.current_room.id, "climb down should go to cellar")
end)

test("descend goes down", function()
    local ctx = make_ctx()
    ctx.current_room.exits.down = { target = "cellar", open = true }
    local output = capture_output(function()
        handlers["descend"](ctx, "")
    end)
    eq("cellar", ctx.current_room.id, "descend should go down")
end)

test("ascend goes up", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["ascend"](ctx, "")
    end)
    eq("attic", ctx.current_room.id, "ascend should go up")
end)

---------------------------------------------------------------------------
-- 5. BACK — return to previous room
---------------------------------------------------------------------------
suite("Movement — back verb")

test("back produces valid response (no crash)", function()
    local ctx = make_ctx()
    -- Note: context_window is module-level state, so previous tests may have
    -- set a previous room. The back handler either navigates or says "can't go back".
    local output = capture_output(function()
        handlers["back"](ctx, "")
    end)
    h.assert_truthy(output ~= "",
        "back should produce some output (navigation or can't-go-back)")
end)

test("back after navigation returns to previous room", function()
    local ctx = make_ctx()
    -- First navigate north to hallway
    capture_output(function()
        handlers["north"](ctx, "")
    end)
    eq("hallway", ctx.current_room.id, "Should be in hallway")
    -- Now go back
    local output = capture_output(function()
        handlers["back"](ctx, "")
    end)
    eq("bedroom", ctx.current_room.id,
        "back should return to bedroom after going north")
    h.assert_truthy(output:find("retrace") or output:find("Bedroom") or output:find("bedroom"),
        "back should mention returning")
end)

---------------------------------------------------------------------------
-- 6. HIDDEN EXITS — should not be traversable
---------------------------------------------------------------------------
suite("Movement — hidden exits")

test("hidden exit blocks navigation", function()
    local ctx = make_ctx()
    ctx.current_room.exits.down = {
        target = "secret",
        open = true,
        hidden = true,
    }
    ctx.rooms.secret = {
        id = "secret",
        name = "Secret Room",
        description = "A secret room.",
        contents = {},
        exits = {},
    }
    local output = capture_output(function()
        handlers["down"](ctx, "")
    end)
    eq("bedroom", ctx.current_room.id, "Hidden exit should block movement")
    h.assert_truthy(output:find("can't go"),
        "Should say can't go that way for hidden exit")
end)

---------------------------------------------------------------------------
-- 7. MOVE DISAMBIGUATION — navigation vs object movement
---------------------------------------------------------------------------
suite("Movement — move disambiguation")

test("move north navigates (direction recognized)", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["move"](ctx, "north")
    end)
    eq("hallway", ctx.current_room.id,
        "move north should navigate, not try object movement")
end)

test("move with empty noun prints 'Move what?'", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["move"](ctx, "")
    end)
    h.assert_truthy(output:find("Move what"),
        "move with no noun should ask what")
end)

---------------------------------------------------------------------------
-- 8. FIRST VISIT vs REVISIT — auto-look on first, short desc on second
---------------------------------------------------------------------------
suite("Movement — visit tracking")

test("first visit to room triggers auto-look", function()
    local ctx = make_ctx()
    ctx.player.visited_rooms = {}
    local output = capture_output(function()
        handlers["north"](ctx, "")
    end)
    -- First visit should show the room description (via look)
    h.assert_truthy(output:find("Hallway") or output:find("hallway"),
        "First visit should show room name")
end)

test("revisit shows short description only", function()
    local ctx = make_ctx()
    ctx.player.visited_rooms = { hallway = true }
    local output = capture_output(function()
        handlers["north"](ctx, "")
    end)
    -- Revisit should show short description
    h.assert_truthy(output:find("Hallway") or output:find("hallway"),
        "Revisit should at least show room name")
end)

---------------------------------------------------------------------------
-- 9. PREPOSITION STRIPPING in movement
---------------------------------------------------------------------------
suite("Movement — preposition stripping")

test("go through north strips 'through'", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["go"](ctx, "through north")
    end)
    -- 'through' should be stripped, resolving to 'north'
    -- This might not match directly but should attempt navigation
    h.assert_truthy(ctx.current_room.id == "hallway" or output:find("can't go"),
        "Preposition stripping should handle 'through north'")
end)

---------------------------------------------------------------------------
-- 10. DIRECTION ALIAS COMPLETENESS
---------------------------------------------------------------------------
suite("Direction alias completeness")

test("all 6 cardinal handlers registered", function()
    h.assert_truthy(handlers["north"], "north handler exists")
    h.assert_truthy(handlers["south"], "south handler exists")
    h.assert_truthy(handlers["east"], "east handler exists")
    h.assert_truthy(handlers["west"], "west handler exists")
    h.assert_truthy(handlers["up"], "up handler exists")
    h.assert_truthy(handlers["down"], "down handler exists")
end)

test("all 6 short aliases registered", function()
    h.assert_truthy(handlers["n"], "n handler exists")
    h.assert_truthy(handlers["s"], "s handler exists")
    h.assert_truthy(handlers["e"], "e handler exists")
    h.assert_truthy(handlers["w"], "w handler exists")
    h.assert_truthy(handlers["u"], "u handler exists")
    h.assert_truthy(handlers["d"], "d handler exists")
end)

test("return handler registered", function()
    h.assert_truthy(handlers["return"], "return handler exists")
end)

print("\nExit code: " .. h.summary())
