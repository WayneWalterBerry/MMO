-- test/verbs/test-wear-zone-266.lua
-- Regression tests for Issue #266: wear verb ignores target body zone
--
-- "wear pot on head" should succeed when pot's wear.slot == "head".
-- "wear pot on feet" should be rejected (wrong zone).
-- Applies to all wearables, not just chamber pot.
--
-- Usage: lua test/verbs/test-wear-zone-266.lua
-- Must be run from repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local verbs_mod = require("engine.verbs")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local handlers = verbs_mod.create()

local function capture_output(fn)
    local captured = {}
    local old_print = print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler call failed: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

---------------------------------------------------------------------------
-- Helper: build a context with a wearable item in the player's hand
---------------------------------------------------------------------------
local function make_ctx(obj_def)
    local objects = {}
    objects[obj_def.id] = obj_def

    local reg = {
        _objects = objects,
        get = function(self, id) return self._objects[id] end,
    }

    local ctx = {
        registry = reg,
        current_room = {
            id = "test_room", name = "Test Room",
            description = "A test room.",
            contents = {},
            exits = {},
        },
        time_offset = 8,
        game_start_time = os.time(),
        player = { hands = {obj_def, nil}, worn = {}, bags = {}, worn_items = {} },
        injuries = {},
    }
    return ctx
end

---------------------------------------------------------------------------
-- #266: wear with matching zone should succeed
---------------------------------------------------------------------------

h.suite("#266: wear with matching body zone succeeds")

test("wear pot on head — succeeds when wear.slot is head", function()
    local pot = {
        id = "chamber-pot", name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot", "ceramic pot", "helmet"},
        portable = true,
        wear = { slot = "head", layer = "outer", coverage = 0.8,
                 fit = "makeshift", wear_quality = "makeshift" },
    }
    local ctx = make_ctx(pot)
    local output = capture_output(function()
        handlers["wear"](ctx, "pot on head")
    end)
    local lower = output:lower()
    -- Should NOT say "can't wear" — the zone matches the default slot
    truthy(not lower:find("can't wear"),
        "should not reject 'wear pot on head' when slot is head. Output: " .. output)
    -- Should be in worn list
    local found = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "chamber-pot" then found = true; break end
    end
    truthy(found, "chamber-pot should be in player.worn after 'wear pot on head'")
end)

test("wear spittoon on head — succeeds for brass spittoon", function()
    local spittoon = {
        id = "brass-spittoon", name = "a brass spittoon",
        keywords = {"spittoon", "brass spittoon", "helmet"},
        portable = true,
        wear = { slot = "head", layer = "outer", coverage = 0.7,
                 fit = "makeshift", provides_armor = 2, wear_quality = "makeshift" },
    }
    local ctx = make_ctx(spittoon)
    local output = capture_output(function()
        handlers["wear"](ctx, "spittoon on head")
    end)
    local lower = output:lower()
    truthy(not lower:find("can't wear"),
        "should not reject 'wear spittoon on head'. Output: " .. output)
    local found = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "brass-spittoon" then found = true; break end
    end
    truthy(found, "brass-spittoon should be in player.worn")
end)

test("wear cloak on back — succeeds when wear.slot is back", function()
    local cloak = {
        id = "wool-cloak", name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true,
        wear = { slot = "back", layer = "outer", provides_warmth = true },
    }
    local ctx = make_ctx(cloak)
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak on back")
    end)
    local lower = output:lower()
    truthy(not lower:find("can't wear"),
        "should not reject 'wear cloak on back'. Output: " .. output)
    local found = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "wool-cloak" then found = true; break end
    end
    truthy(found, "wool-cloak should be in player.worn after 'wear cloak on back'")
end)

---------------------------------------------------------------------------
-- #266: wear with WRONG zone should be rejected
---------------------------------------------------------------------------

h.suite("#266: wear with wrong body zone is rejected")

test("wear pot on feet — rejected (pot is head slot)", function()
    local pot = {
        id = "chamber-pot", name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot"},
        portable = true,
        wear = { slot = "head", layer = "outer" },
    }
    local ctx = make_ctx(pot)
    local output = capture_output(function()
        handlers["wear"](ctx, "pot on feet")
    end)
    local lower = output:lower()
    truthy(lower:find("can't wear"),
        "should reject 'wear pot on feet'. Output: " .. output)
    -- Should NOT be in worn list
    local found = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "chamber-pot" then found = true; break end
    end
    truthy(not found, "chamber-pot should NOT be in player.worn after rejected wear")
end)

test("wear cloak on head — rejected (cloak is back slot)", function()
    local cloak = {
        id = "wool-cloak", name = "a wool cloak",
        keywords = {"cloak", "wool cloak"},
        portable = true,
        wear = { slot = "back", layer = "outer" },
    }
    local ctx = make_ctx(cloak)
    local output = capture_output(function()
        handlers["wear"](ctx, "cloak on head")
    end)
    local lower = output:lower()
    truthy(lower:find("can't wear"),
        "should reject 'wear cloak on head'. Output: " .. output)
end)

---------------------------------------------------------------------------
-- #266: wear WITHOUT zone still works (regression)
---------------------------------------------------------------------------

h.suite("#266: wear without zone still works (regression)")

test("wear pot — works without specifying zone", function()
    local pot = {
        id = "chamber-pot", name = "a ceramic chamber pot",
        keywords = {"chamber pot", "pot"},
        portable = true,
        wear = { slot = "head", layer = "outer", wear_quality = "makeshift" },
    }
    local ctx = make_ctx(pot)
    local output = capture_output(function()
        handlers["wear"](ctx, "pot")
    end)
    local lower = output:lower()
    truthy(not lower:find("can't wear"),
        "plain 'wear pot' should still work. Output: " .. output)
    local found = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "chamber-pot" then found = true; break end
    end
    truthy(found, "chamber-pot should be in player.worn after plain 'wear pot'")
end)

---------------------------------------------------------------------------
-- #266: wear_alternate still works (regression)
---------------------------------------------------------------------------

h.suite("#266: wear_alternate still works (regression)")

test("wear sack on head — uses wear_alternate if declared", function()
    local sack = {
        id = "burlap-sack", name = "a burlap sack",
        keywords = {"sack", "burlap sack"},
        portable = true,
        wear = { slot = "back", layer = "outer" },
        wear_alternate = {
            head = { slot = "head", blocks_vision = true },
        },
    }
    local ctx = make_ctx(sack)
    local output = capture_output(function()
        handlers["wear"](ctx, "sack on head")
    end)
    local lower = output:lower()
    truthy(lower:find("over your head") or lower:find("dark") or lower:find("put"),
        "should use wear_alternate for head. Output: " .. output)
    local found = false
    for _, id in ipairs(ctx.player.worn or {}) do
        if id == "burlap-sack" then found = true; break end
    end
    truthy(found, "burlap-sack should be in player.worn via wear_alternate")
end)

--- Results
os.exit(h.summary() > 0 and 1 or 0)
