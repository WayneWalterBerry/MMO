-- test/verbs/test-player-canonical-state.lua
-- Issue #104: Verify that player.lua is the canonical source of truth for
-- all player state, specifically that visited_rooms lives on ctx.player
-- (not on ctx directly).
--
-- Usage: lua test/verbs/test-player-canonical-state.lua
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
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_output(fn)
    local old_print = _G.print
    local buf = {}
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
        buf[#buf + 1] = table.concat(parts, "\t")
    end
    fn()
    _G.print = old_print
    return table.concat(buf, "\n")
end

local function make_rooms()
    return {
        bedroom = {
            id = "bedroom", name = "Bedroom",
            description = "A dark bedroom.",
            short_description = "The bedroom again.",
            exits = { north = { target = "hallway", open = true } },
        },
        hallway = {
            id = "hallway", name = "Hallway",
            description = "A long hallway with torches on the walls.",
            short_description = "The hallway.",
            exits = { south = { target = "bedroom", open = true },
                      east  = { target = "kitchen", open = true } },
        },
        kitchen = {
            id = "kitchen", name = "Kitchen",
            description = "A warm kitchen with a fireplace.",
            short_description = "The kitchen.",
            exits = { west = { target = "hallway", open = true } },
        },
    }
end

local function make_ctx()
    local rooms = make_rooms()
    local reg = registry_mod.new()
    return {
        registry = reg,
        current_room = rooms["bedroom"],
        rooms = rooms,
        player = {
            hands = { nil, nil },
            worn = {},
            injuries = {},
            bags = {},
            state = {},
            skills = {},
            location = "bedroom",
            visited_rooms = { bedroom = true },
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
-- 1. visited_rooms lives on player, not on context
---------------------------------------------------------------------------
suite("#104 — Player canonical state: visited_rooms on player")

test("visited_rooms is initialized on ctx.player", function()
    local ctx = make_ctx()
    truthy(ctx.player.visited_rooms, "ctx.player.visited_rooms should exist")
    eq(nil, ctx.visited_rooms, "ctx.visited_rooms should NOT exist (moved to player)")
end)

test("starting room is marked visited on player", function()
    local ctx = make_ctx()
    truthy(ctx.player.visited_rooms["bedroom"],
           "Starting room 'bedroom' should be in player.visited_rooms")
end)

test("movement adds target room to player.visited_rooms", function()
    local ctx = make_ctx()
    capture_output(function()
        handlers["north"](ctx, "")
    end)
    truthy(ctx.player.visited_rooms["hallway"],
           "After moving north, hallway should be in player.visited_rooms")
    eq("hallway", ctx.player.location,
       "Player location should update to hallway")
end)

test("movement preserves starting room in player.visited_rooms", function()
    local ctx = make_ctx()
    capture_output(function()
        handlers["north"](ctx, "")
    end)
    truthy(ctx.player.visited_rooms["bedroom"],
           "Starting room should still be in player.visited_rooms after move")
    truthy(ctx.player.visited_rooms["hallway"],
           "Target room should be added to player.visited_rooms")
end)

test("multiple moves accumulate in player.visited_rooms", function()
    local ctx = make_ctx()
    capture_output(function()
        handlers["north"](ctx, "")   -- bedroom -> hallway
        handlers["east"](ctx, "")    -- hallway -> kitchen
    end)
    truthy(ctx.player.visited_rooms["bedroom"],  "bedroom visited")
    truthy(ctx.player.visited_rooms["hallway"],  "hallway visited")
    truthy(ctx.player.visited_rooms["kitchen"],  "kitchen visited")
end)

test("go back also records visited_rooms on player", function()
    local ctx = make_ctx()
    capture_output(function()
        handlers["north"](ctx, "")    -- bedroom -> hallway
        handlers["back"](ctx, "")     -- hallway -> bedroom
    end)
    truthy(ctx.player.visited_rooms["bedroom"],
           "bedroom should be in visited_rooms after going back")
    truthy(ctx.player.visited_rooms["hallway"],
           "hallway should remain in visited_rooms after going back")
end)

test("no visited_rooms key leaks to ctx root level", function()
    local ctx = make_ctx()
    capture_output(function()
        handlers["north"](ctx, "")
    end)
    eq(nil, ctx.visited_rooms,
       "ctx.visited_rooms should not appear after movement")
end)

---------------------------------------------------------------------------
-- 2. Player state completeness — all canonical fields present
---------------------------------------------------------------------------
suite("#104 — Player canonical state: completeness")

test("player has all canonical state fields", function()
    local ctx = make_ctx()
    local p = ctx.player
    truthy(p.hands,          "player.hands should exist")
    truthy(p.worn ~= nil,    "player.worn should exist")
    truthy(p.skills ~= nil,  "player.skills should exist")
    truthy(p.location,       "player.location should exist")
    truthy(p.state ~= nil,   "player.state should exist")
    truthy(p.visited_rooms ~= nil, "player.visited_rooms should exist")
end)

h.summary()
