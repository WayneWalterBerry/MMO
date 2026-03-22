-- test/verbs/test-bugfixes-32-34.lua
-- Regression tests for Issues #32, #33, #34 (Pass 037)
--
-- #32: "move rug" should trigger spatial move, not navigation
-- #33: containers.is_container() should check categories array
-- #34: Accessible containers report contents when target not found
--
-- Usage: lua test/verbs/test-bugfixes-32-34.lua
-- Must be run from repository root.

package.path = "./test/parser/?.lua;./src/?.lua;./src/?/init.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local assert_eq = h.assert_eq
local assert_truthy = h.assert_truthy

local verbs_mod = require("engine.verbs")
local containers = require("engine.search.containers")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
    return table.concat(lines, "\n")
end

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "String not found") .. "\n  Expected: " .. needle .. "\n  In: " .. haystack)
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "String should NOT be found") .. "\n  Unexpected: " .. needle .. "\n  In: " .. haystack)
    end
end

-- Create verb handlers
local handlers = verbs_mod.create()

-- Create test context with a movable rug and room with exits
local function make_move_ctx()
    local rug = {
        id = "rug", name = "rug",
        keywords = {"rug", "carpet"},
        movable = true,
        description = "A worn rug.",
    }
    local curtains = {
        id = "curtains", name = "curtains",
        allows_daylight = true, hidden = true,
    }
    local objects = { rug = rug, curtains = curtains }
    local room = {
        id = "test_room", name = "Test Room",
        description = "A room with a rug.",
        contents = {"rug", "curtains"},
        exits = { north = { target = "hallway" } },
    }
    local reg = {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
    }
    return {
        registry = reg,
        current_room = room,
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {nil, nil}, worn_items = {}, bags = {}, worn = {} },
        injuries = {},
    }
end

---------------------------------------------------------------------------
suite("Issue #32 — 'move rug' triggers spatial move, not navigation")
---------------------------------------------------------------------------

test("#32: 'move rug' does NOT say 'You can't go that way'", function()
    local ctx = make_move_ctx()
    local output = capture_print(function()
        handlers["move"](ctx, "rug")
    end)
    assert_not_contains(output, "can't go that way",
        "'move rug' must not trigger navigation error")
end)

test("#32: 'move north' triggers navigation (direction detected)", function()
    local ctx = make_move_ctx()
    -- "move north" should try to navigate, not look for an object called "north"
    local output = capture_print(function()
        handlers["move"](ctx, "north")
    end)
    -- Navigation was attempted — should NOT say "Move what?" or "not found"
    assert_not_contains(output, "Move what?",
        "'move north' should be navigation, not 'Move what?'")
end)

test("#32: 'move n' triggers navigation (alias detected)", function()
    local ctx = make_move_ctx()
    local output = capture_print(function()
        handlers["move"](ctx, "n")
    end)
    assert_not_contains(output, "Move what?",
        "'move n' should be navigation")
end)

test("#32: 'move up' triggers navigation", function()
    local ctx = make_move_ctx()
    local output = capture_print(function()
        handlers["move"](ctx, "up")
    end)
    assert_not_contains(output, "Move what?",
        "'move up' should be navigation")
end)

test("#32: 'move back' triggers navigation", function()
    local ctx = make_move_ctx()
    local output = capture_print(function()
        handlers["move"](ctx, "back")
    end)
    -- Should try go back, not look for object called "back"
    assert_not_contains(output, "Move what?",
        "'move back' should be navigation")
end)

test("#32: 'shift rug' still works as synonym", function()
    local ctx = make_move_ctx()
    local output = capture_print(function()
        handlers["shift"](ctx, "rug")
    end)
    assert_not_contains(output, "can't go that way",
        "'shift rug' must not trigger navigation")
end)

test("#32: 'move' with no argument says 'Move what?'", function()
    local ctx = make_move_ctx()
    local output = capture_print(function()
        handlers["move"](ctx, "")
    end)
    assert_contains(output, "Move what?",
        "Empty 'move' should prompt")
end)

---------------------------------------------------------------------------
suite("Issue #33 — is_container() checks categories array")
---------------------------------------------------------------------------

test("#33: boolean flag is_container=true still works", function()
    local obj = { id = "chest", is_container = true }
    assert_truthy(containers.is_container(obj),
        "is_container=true should be detected")
end)

test("#33: boolean flag container=true still works", function()
    local obj = { id = "box", container = true }
    assert_truthy(containers.is_container(obj),
        "container=true should be detected")
end)

test("#33: categories={'container'} is detected", function()
    local obj = { id = "wardrobe", categories = {"furniture", "container"} }
    assert_truthy(containers.is_container(obj),
        "categories array with 'container' should be detected")
end)

test("#33: categories without 'container' is NOT detected", function()
    local obj = { id = "chair", categories = {"furniture", "seat"} }
    assert_truthy(not containers.is_container(obj),
        "categories without 'container' should not match")
end)

test("#33: nil object returns false", function()
    assert_truthy(not containers.is_container(nil),
        "nil should return false")
end)

test("#33: object with no flags and no categories returns false", function()
    local obj = { id = "rock" }
    assert_truthy(not containers.is_container(obj),
        "Plain object should not be a container")
end)

test("#33: categories-only container detected by is_open()", function()
    -- A categories-only container with no explicit is_open defaults to closed
    local obj = { id = "barrel", categories = {"container"} }
    assert_truthy(not containers.is_open(obj),
        "Categories-only container should default to closed")
end)

test("#33: categories-only container with is_open=true is open", function()
    local obj = { id = "barrel", categories = {"container"}, is_open = true }
    assert_truthy(containers.is_open(obj),
        "Categories container with is_open=true should be open")
end)

---------------------------------------------------------------------------
suite("Issue #34 — Accessible surface content reporting")
---------------------------------------------------------------------------

-- #34 is tested via the search traverse module (test-search-traverse.lua)
-- Here we verify the narrator function exists and the containers module
-- supports the content reporting path.

test("#34: containers.get_contents returns items list", function()
    local obj = {
        id = "wardrobe",
        categories = {"container"},
        is_open = true,
        contents = {"cloak", "sack"},
    }
    local items = containers.get_contents(obj)
    assert_eq(2, #items, "Should return 2 items")
    assert_eq("cloak", items[1])
    assert_eq("sack", items[2])
end)

test("#34: containers.get_contents handles 'contains' field too", function()
    local obj = {
        id = "barrel",
        categories = {"container"},
        is_open = true,
        contains = {"apple", "fish"},
    }
    local items = containers.get_contents(obj)
    assert_eq(2, #items, "Should return 2 items from 'contains' field")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
