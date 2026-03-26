-- test/rooms/test-portal-phase1.lua
-- Phase 1 portal system tests: template loading, find_portal_by_keyword,
-- portal-based movement, bidirectional sync, and legacy backward compatibility.
--
-- Must be run from repository root: lua test/rooms/test-portal-phase1.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function capture(fn)
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

local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deep_copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

---------------------------------------------------------------------------
-- Load verb handlers
---------------------------------------------------------------------------
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
local handlers

if verbs_ok and type(verbs_mod) == "table" and verbs_mod.create then
    local ok2, h2 = pcall(verbs_mod.create)
    if ok2 then handlers = h2 end
end

if not handlers then
    print("ERROR: Could not load verb handlers — tests cannot run")
    h.summary()
    os.exit(1)
end

---------------------------------------------------------------------------
-- Load portal template
---------------------------------------------------------------------------
local portal_template = dofile(script_dir .. "/../../src/meta/templates/portal.lua")

---------------------------------------------------------------------------
-- Mock portal objects for testing
---------------------------------------------------------------------------
local function make_portal_north()
    return {
        guid = "test-portal-north-guid",
        id = "test-door-north",
        name = "a heavy oak door",
        keywords = {"door", "oak door", "heavy door"},
        description = "A heavy oak door bound with iron bands.",
        template = "portal",
        categories = {"portal"},
        portal = {
            target = "hallway",
            bidirectional_id = "bedroom-hallway-passage",
            direction_hint = "north",
        },
        size = 5,
        weight = 100,
        portable = false,
        material = "oak",
        initial_state = "open",
        _state = "open",
        states = {
            locked = {
                traversable = false,
                description = "The heavy oak door is locked shut.",
                blocked_message = "The door is locked tight.",
            },
            closed = {
                traversable = false,
                description = "The heavy oak door is closed.",
            },
            open = {
                traversable = true,
                description = "The heavy oak door stands open.",
            },
            broken = {
                traversable = true,
                description = "The oak door hangs from its hinges, shattered.",
            },
        },
        transitions = {},
        on_feel = "Rough oak planks, cold iron bands.",
        on_smell = "Old wood and iron.",
        on_listen = "Silence.",
    }
end

local function make_portal_south()
    return {
        guid = "test-portal-south-guid",
        id = "test-door-south",
        name = "a heavy oak door",
        keywords = {"door", "oak door"},
        description = "A heavy oak door, seen from the hallway side.",
        template = "portal",
        categories = {"portal"},
        portal = {
            target = "start-room",
            bidirectional_id = "bedroom-hallway-passage",
            direction_hint = "south",
        },
        size = 5,
        weight = 100,
        portable = false,
        material = "oak",
        initial_state = "open",
        _state = "open",
        states = {
            locked = {
                traversable = false,
                description = "The heavy oak door is locked.",
            },
            closed = {
                traversable = false,
                description = "The heavy oak door is closed.",
            },
            open = {
                traversable = true,
                description = "The heavy oak door stands open.",
            },
            broken = {
                traversable = true,
                description = "The oak door hangs from its hinges.",
            },
        },
        transitions = {},
        on_feel = "Rough oak planks.",
    }
end

---------------------------------------------------------------------------
-- Context builder for portal tests
---------------------------------------------------------------------------
local function make_portal_ctx(opts)
    opts = opts or {}

    local portal_north = opts.portal_north or make_portal_north()
    local portal_south = opts.portal_south or make_portal_south()

    local bedroom = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dim bedchamber.",
        short_description = "A dim bedchamber.",
        contents = {"test-door-north"},
        exits = opts.bedroom_exits or {
            north = { portal = "test-door-north" },
        },
    }

    local hallway = {
        id = "hallway",
        name = "The Hallway",
        description = "A long hallway.",
        short_description = "A long hallway.",
        contents = {"test-door-south"},
        exits = opts.hallway_exits or {
            south = { portal = "test-door-south" },
        },
    }

    local reg_store = {
        ["test-door-north"] = portal_north,
        ["test-door-south"] = portal_south,
    }

    local registry = {
        get = function(self, id) return reg_store[id] end,
        find_by_keyword = function(self, kw)
            for _, obj in pairs(reg_store) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k:lower() == kw:lower() then return obj end
                    end
                end
            end
            return nil
        end,
        register = function(self, id, obj) reg_store[id] = obj end,
    }

    local ctx = {
        current_room = bedroom,
        game_start_time = os.time(),
        player = {
            location = "start-room",
            hands = { nil, nil },
            injuries = {},
            visited_rooms = { ["start-room"] = true },
            state = { hints_shown = {} },
        },
        rooms = {
            ["start-room"] = bedroom,
            hallway = hallway,
        },
        known_objects = {},
        registry = registry,
        object_sources = {},
        templates = {},
        loader = {
            load_source = function() return nil end,
            resolve_template = function(o) return o end,
        },
        verbs = handlers,
    }

    return ctx, portal_north, portal_south
end

---------------------------------------------------------------------------
-- 1. Template loading
---------------------------------------------------------------------------
suite("Portal template validation")

test("portal template loads without error", function()
    h.assert_eq("table", type(portal_template), "template should be a table")
end)

test("portal template has correct id", function()
    h.assert_eq("portal", portal_template.id, "template id must be 'portal'")
end)

test("portal template has guid", function()
    h.assert_eq("string", type(portal_template.guid), "template must have a guid")
    h.assert_eq(true, #portal_template.guid > 0, "guid must not be empty")
end)

test("portal template has portal metadata table", function()
    h.assert_eq("table", type(portal_template.portal), "portal field must be a table")
end)

test("portal template has FSM defaults", function()
    h.assert_eq("open", portal_template.initial_state, "default initial_state must be 'open'")
    h.assert_eq("open", portal_template._state, "default _state must be 'open'")
    h.assert_eq("table", type(portal_template.states), "states must be a table")
    h.assert_eq(true, portal_template.states.open.traversable, "open state must be traversable")
end)

test("portal template has on_feel (P6 darkness)", function()
    h.assert_eq("string", type(portal_template.on_feel), "on_feel must be defined")
end)

test("portal template has portal category", function()
    local has_portal_cat = false
    for _, c in ipairs(portal_template.categories or {}) do
        if c == "portal" then has_portal_cat = true; break end
    end
    h.assert_eq(true, has_portal_cat, "categories must include 'portal'")
end)

test("portal template is not portable", function()
    h.assert_eq(false, portal_template.portable, "portals must not be portable")
end)

---------------------------------------------------------------------------
-- 2. find_portal_by_keyword
---------------------------------------------------------------------------
suite("find_portal_by_keyword resolution")

test("finds portal by keyword", function()
    local ctx, portal_n = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    local found = helpers.find_portal_by_keyword(ctx, "door")
    h.assert_eq(true, found ~= nil, "should find portal by keyword 'door'")
    h.assert_eq("test-door-north", found.id, "should find the north portal")
end)

test("finds portal by direction_hint", function()
    local ctx, portal_n = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    local found = helpers.find_portal_by_keyword(ctx, "north")
    h.assert_eq(true, found ~= nil, "should find portal by direction hint 'north'")
    h.assert_eq("test-door-north", found.id, "should find north portal by hint")
end)

test("returns nil for non-matching keyword", function()
    local ctx = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    local found = helpers.find_portal_by_keyword(ctx, "window")
    h.assert_eq(nil, found, "should not find non-existent portal")
end)

test("returns nil for empty keyword", function()
    local ctx = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    local found = helpers.find_portal_by_keyword(ctx, "")
    h.assert_eq(nil, found, "should return nil for empty keyword")
end)

test("skips hidden portals", function()
    local portal_n = make_portal_north()
    portal_n.hidden = true
    local ctx = make_portal_ctx({ portal_north = portal_n })
    local helpers = require("engine.verbs.helpers")
    local found = helpers.find_portal_by_keyword(ctx, "door")
    h.assert_eq(nil, found, "should skip hidden portals")
end)

---------------------------------------------------------------------------
-- 3. Movement via portal (thin exit reference)
---------------------------------------------------------------------------
suite("Portal-based movement — thin exit reference")

test("go north through open portal moves player", function()
    local ctx = make_portal_ctx()
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("hallway", ctx.player.location, "player should move to hallway")
end)

test("go north through closed portal blocks movement", function()
    local portal_n = make_portal_north()
    portal_n._state = "closed"
    local ctx = make_portal_ctx({ portal_north = portal_n })
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("start-room", ctx.player.location, "player should stay in bedroom")
    h.assert_eq(true, out:find("closed") ~= nil, "should print closed message")
end)

test("go north through locked portal shows locked message", function()
    local portal_n = make_portal_north()
    portal_n._state = "locked"
    local ctx = make_portal_ctx({ portal_north = portal_n })
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("start-room", ctx.player.location, "player should stay in bedroom")
    h.assert_eq(true, out:find("locked") ~= nil, "should print locked message")
end)

test("go north through broken portal allows movement", function()
    local portal_n = make_portal_north()
    portal_n._state = "broken"
    local ctx = make_portal_ctx({ portal_north = portal_n })
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("hallway", ctx.player.location, "player should move through broken portal")
end)

test("portal blocked_message is used when defined", function()
    local portal_n = make_portal_north()
    portal_n._state = "locked"
    local ctx = make_portal_ctx({ portal_north = portal_n })
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq(true, out:find("locked tight") ~= nil, "should use custom blocked_message")
end)

test("go <keyword> resolves portal by keyword", function()
    local ctx = make_portal_ctx()
    local out = capture(function() handlers["go"](ctx, "door") end)
    h.assert_eq("hallway", ctx.player.location, "go door should move to hallway via portal")
end)

test("portal target room not found shows appropriate message", function()
    local portal_n = make_portal_north()
    portal_n.portal.target = "nonexistent-room"
    local ctx = make_portal_ctx({ portal_north = portal_n })
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("start-room", ctx.player.location, "player should stay put")
    h.assert_eq(true, out:find("cannot yet reach") ~= nil, "should show unreachable message")
end)

---------------------------------------------------------------------------
-- 4. Bidirectional sync
---------------------------------------------------------------------------
suite("Bidirectional portal sync")

test("sync updates paired portal state", function()
    local ctx, portal_n, portal_s = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    -- Change north portal to closed
    portal_n._state = "closed"
    -- Apply state properties
    for k, v in pairs(portal_n.states.closed) do
        portal_n[k] = v
    end
    -- Sync
    helpers.sync_bidirectional_portal(ctx, portal_n)
    h.assert_eq("closed", portal_s._state, "paired portal should also be closed")
end)

test("sync to locked propagates correctly", function()
    local ctx, portal_n, portal_s = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    portal_n._state = "locked"
    helpers.sync_bidirectional_portal(ctx, portal_n)
    h.assert_eq("locked", portal_s._state, "paired portal should become locked")
end)

test("sync to open propagates correctly", function()
    local ctx, portal_n, portal_s = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    -- Start both closed
    portal_n._state = "closed"
    portal_s._state = "closed"
    -- Open north
    portal_n._state = "open"
    helpers.sync_bidirectional_portal(ctx, portal_n)
    h.assert_eq("open", portal_s._state, "paired portal should become open")
end)

test("sync to broken propagates correctly", function()
    local ctx, portal_n, portal_s = make_portal_ctx()
    local helpers = require("engine.verbs.helpers")
    portal_n._state = "broken"
    helpers.sync_bidirectional_portal(ctx, portal_n)
    h.assert_eq("broken", portal_s._state, "paired portal should become broken")
end)

test("sync does nothing without bidirectional_id", function()
    local portal_n = make_portal_north()
    portal_n.portal.bidirectional_id = nil
    local ctx, _, portal_s = make_portal_ctx({ portal_north = portal_n })
    local helpers = require("engine.verbs.helpers")
    portal_n._state = "closed"
    helpers.sync_bidirectional_portal(ctx, portal_n)
    h.assert_eq("open", portal_s._state, "unlinked portal should not change")
end)

test("sync does not affect portals with different bidirectional_id", function()
    local portal_s = make_portal_south()
    portal_s.portal.bidirectional_id = "different-passage"
    local ctx, portal_n = make_portal_ctx({ portal_south = portal_s })
    local helpers = require("engine.verbs.helpers")
    portal_n._state = "closed"
    helpers.sync_bidirectional_portal(ctx, portal_n)
    h.assert_eq("open", portal_s._state, "mismatched bidirectional_id should not sync")
end)

---------------------------------------------------------------------------
-- 5. Legacy backward compatibility
---------------------------------------------------------------------------
suite("Legacy exit backward compatibility")

test("legacy string exit still works", function()
    local ctx = make_portal_ctx({
        bedroom_exits = {
            north = "hallway",
        },
    })
    -- Remove portal from contents so portal path is not triggered
    ctx.current_room.contents = {}
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("hallway", ctx.player.location, "legacy string exit should move player")
end)

test("legacy table exit with open=true still works", function()
    local ctx = make_portal_ctx({
        bedroom_exits = {
            north = {
                target = "hallway",
                name = "an old door",
                open = true,
                locked = false,
            },
        },
    })
    -- Remove portal from contents so portal path is not triggered
    ctx.current_room.contents = {}
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("hallway", ctx.player.location, "legacy open exit should move player")
end)

test("legacy table exit with open=false blocks movement", function()
    local ctx = make_portal_ctx({
        bedroom_exits = {
            north = {
                target = "hallway",
                name = "a closed door",
                open = false,
                locked = false,
            },
        },
    })
    ctx.current_room.contents = {}
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("start-room", ctx.player.location, "legacy closed exit should block")
    h.assert_eq(true, out:find("closed") ~= nil, "should show closed message")
end)

test("legacy locked exit shows locked message", function()
    local ctx = make_portal_ctx({
        bedroom_exits = {
            north = {
                target = "hallway",
                name = "a locked door",
                open = false,
                locked = true,
            },
        },
    })
    ctx.current_room.contents = {}
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("start-room", ctx.player.location, "legacy locked exit should block")
    h.assert_eq(true, out:find("locked") ~= nil, "should show locked message")
end)

---------------------------------------------------------------------------
-- 6. Portal traverse effects
---------------------------------------------------------------------------
suite("Portal traverse effects")

test("portal on_traverse fires wind effect", function()
    local portal_n = make_portal_north()
    portal_n.on_traverse = {
        type = "wind_effect",
        description = "A cold draft blows through the doorway.",
        extinguishes = {"candle"},
    }
    local ctx = make_portal_ctx({ portal_north = portal_n })
    -- Give player a lit candle
    local candle = {
        id = "candle", name = "candle", keywords = {"candle"},
        _state = "lit",
        states = {
            lit = { casts_light = true },
            extinguished = { casts_light = false },
            unlit = { casts_light = false },
        },
        transitions = {
            { from = "lit", to = "extinguished", trigger = "auto", condition = "timer_expired" },
            { from = "lit", to = "unlit", verb = "extinguish" },
        },
    }
    ctx.player.hands = { "candle", nil }
    ctx.registry:register("candle", candle)
    local out = capture(function() handlers["north"](ctx, "") end)
    h.assert_eq("hallway", ctx.player.location, "player should move through portal")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code)
