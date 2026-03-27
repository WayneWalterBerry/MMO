-- test/verbs/test-goto.lua
-- Tests for the `goto` admin/debug teleport command.
--
-- Usage: lua test/verbs/test-goto.lua
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
        exits = {},
    }
    local cellar = {
        id = "cellar",
        name = "Cellar",
        description = "A cold stone cellar.",
        short_description = "A dank cellar.",
        contents = {},
        exits = {},
    }
    local crypt = {
        id = "crypt",
        name = "Crypt",
        description = "A dusty crypt with stone sarcophagi.",
        short_description = "The crypt is silent.",
        contents = {},
        exits = {},
    }
    return {
        bedroom = bedroom,
        cellar = cellar,
        crypt = crypt,
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
-- 1. goto valid room — player moves, room enter triggers
---------------------------------------------------------------------------
suite("goto — valid room teleportation")

test("goto cellar moves player to cellar", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["goto"](ctx, "cellar")
    end)
    eq("cellar", ctx.current_room.id, "Should be in cellar")
    eq("cellar", ctx.player.location, "player.location should be cellar")
    h.assert_truthy(output:find("You materialize in Cellar"),
        "Should print materialize message")
end)

test("goto crypt moves player to crypt", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["goto"](ctx, "crypt")
    end)
    eq("crypt", ctx.current_room.id, "Should be in crypt")
    h.assert_truthy(output:find("You materialize in Crypt"),
        "Should print materialize message for crypt")
end)

test("goto marks room as visited", function()
    local ctx = make_ctx()
    capture_output(function()
        handlers["goto"](ctx, "cellar")
    end)
    eq(true, ctx.player.visited_rooms["cellar"], "cellar should be marked visited")
end)

---------------------------------------------------------------------------
-- 2. goto invalid room — error message
---------------------------------------------------------------------------
suite("goto — invalid room")

test("goto nonexistent room prints error", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["goto"](ctx, "narnia")
    end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom")
    h.assert_truthy(output:find("No room called 'narnia' exists"),
        "Should print helpful error for invalid room")
end)

---------------------------------------------------------------------------
-- 3. goto with no argument — helpful error
---------------------------------------------------------------------------
suite("goto — no argument")

test("goto with empty noun prints usage", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["goto"](ctx, "")
    end)
    eq("bedroom", ctx.current_room.id, "Should stay in bedroom")
    h.assert_truthy(output:find("Goto where"),
        "Should print usage hint")
end)

---------------------------------------------------------------------------
-- 4. Player inventory preserved after goto
---------------------------------------------------------------------------
suite("goto — inventory preserved")

test("hands and worn items survive teleport", function()
    local ctx = make_ctx()
    ctx.player.hands = { "sword-001", "shield-002" }
    ctx.player.worn = { torso = "cloak-003" }
    capture_output(function()
        handlers["goto"](ctx, "cellar")
    end)
    eq("cellar", ctx.current_room.id, "Should be in cellar")
    eq("sword-001", ctx.player.hands[1], "Left hand preserved")
    eq("shield-002", ctx.player.hands[2], "Right hand preserved")
    eq("cloak-003", ctx.player.worn.torso, "Worn cloak preserved")
end)

---------------------------------------------------------------------------
-- 5. goto same room — works (no crash)
---------------------------------------------------------------------------
suite("goto — same room")

test("goto current room does not crash", function()
    local ctx = make_ctx()
    local output = capture_output(function()
        handlers["goto"](ctx, "bedroom")
    end)
    eq("bedroom", ctx.current_room.id, "Should still be in bedroom")
    h.assert_truthy(output:find("You materialize in Bedroom"),
        "Should print materialize message even for same room")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
h.summary()
