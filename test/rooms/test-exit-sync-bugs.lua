-- test/rooms/test-exit-sync-bugs.lua
-- TDD tests for P0 exit-sync bugs #214, #216, #217.
-- The player is trapped in the bedroom because FSM transitions on objects
-- (door, window) don't sync state to the exit table.
--
-- Must be run from repository root: lua test/rooms/test-exit-sync-bugs.lua

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

local skipped = 0
local function pending(name, reason)
    print("  SKIP " .. name .. " — " .. (reason or "not yet implemented"))
    skipped = skipped + 1
end

-- Capture print output from a function call
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

-- Deep-copy a table (handles nested tables, preserves functions)
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

-- Load room and object metadata directly
local room_meta = dofile(script_dir .. "/../../src/meta/rooms/start-room.lua")
local portal_meta = dofile(script_dir .. "/../../src/meta/objects/bedroom-hallway-door-north.lua")
local window_portal_meta = dofile(script_dir .. "/../../src/meta/objects/bedroom-courtyard-window-out.lua")

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
    print("  verbs_ok=" .. tostring(verbs_ok) .. " verbs_mod=" .. tostring(verbs_mod))
    h.summary()
    os.exit(1)
end

---------------------------------------------------------------------------
-- Context builder: creates a test ctx with bedroom, door object, window
-- object, and exits. Mimics the real game state.
---------------------------------------------------------------------------
local function make_ctx(overrides)
    overrides = overrides or {}

    local room = deep_copy(room_meta)
    local portal_obj = deep_copy(portal_meta)
    local win_portal = deep_copy(window_portal_meta)
    -- Start portal from "closed" to match old window.lua test behavior
    -- (the latch is already unlocked; open transition works)
    win_portal._state = "closed"

    -- Registry includes portal (replaces bedroom-door for north exit) and window portal
    local reg_store = {
        ["bedroom-hallway-door-north"] = portal_obj,
        ["bedroom-courtyard-window-out"] = win_portal,
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
        all = function(self) return reg_store end,
        list = function(self)
            local result = {}
            for _, obj in pairs(reg_store) do result[#result + 1] = obj end
            return result
        end,
    }

    -- Room contents include the portal and window portal objects
    room.contents = room.contents or {}
    table.insert(room.contents, "bedroom-hallway-door-north")
    table.insert(room.contents, "bedroom-courtyard-window-out")

    local ctx = {
        current_room = room,
        game_start_time = os.time(),
        player = {
            location = "start-room",
            hands = { nil, nil },
            injuries = {},
            visited_rooms = {},
        },
        rooms = {
            ["start-room"] = room,
            hallway = { id = "hallway", name = "Hallway", exits = {}, contents = {} },
            courtyard = { id = "courtyard", name = "Courtyard", exits = {}, contents = {} },
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

    -- Apply overrides to exit states (window exit is now a portal ref)
    if overrides.window_exit then
        for k, v in pairs(overrides.window_exit) do
            if type(win_portal) == "table" then
                win_portal[k] = v
            end
        end
    end

    return ctx, portal_obj, win_portal
end

---------------------------------------------------------------------------
-- BUG #216: Breaking bedroom door doesn't unlock the north exit
---------------------------------------------------------------------------
suite("BUG #216: break door must sync exit to open+unlocked")

test("#216-1: break door FSM transition succeeds (barred → broken)", function()
    local ctx, portal = make_ctx()
    h.assert_eq("barred", portal._state, "portal starts barred")
    local out = capture(function() handlers["break"](ctx, "door") end)
    h.assert_eq("broken", portal._state, "portal must transition to broken state")
end)

test("#216-2: after break door, portal is traversable", function()
    local ctx, portal = make_ctx()
    local out = capture(function() handlers["break"](ctx, "door") end)
    local state = portal.states[portal._state]
    h.assert_truthy(state and state.traversable,
        "portal must be traversable after break — state: " .. tostring(portal._state))
end)

test("#216-3: after break door, portal is no longer barred", function()
    local ctx, portal = make_ctx()
    capture(function() handlers["break"](ctx, "door") end)
    h.assert_truthy(portal._state ~= "barred",
        "portal must not be barred after break — got: " .. tostring(portal._state))
end)

test("#216-4: after break door, portal state is broken", function()
    local ctx, portal = make_ctx()
    capture(function() handlers["break"](ctx, "door") end)
    h.assert_eq("broken", portal._state,
        "portal must be in broken state — got: " .. tostring(portal._state))
end)

test("#216-5: after break door, 'go north' must succeed (player moves to hallway)", function()
    local ctx, portal = make_ctx()
    capture(function() handlers["break"](ctx, "door") end)
    capture(function() handlers["go"](ctx, "north") end)
    h.assert_eq("hallway", ctx.player.location,
        "player must reach hallway after breaking door — at: " .. tostring(ctx.player.location))
end)

test("#216-6: break message prints correctly", function()
    local ctx, door = make_ctx()
    local out = capture(function() handlers["break"](ctx, "door") end)
    h.assert_truthy(out:find("burst") or out:find("crack") or out:find("splinter"),
        "break message should describe destruction — got: " .. out:sub(1, 200))
end)

---------------------------------------------------------------------------
-- BUG #217: Window exit stays locked after opening the window
---------------------------------------------------------------------------
suite("BUG #217: open window must sync exit to open+unlocked")

test("#217-1: open window FSM transition succeeds (closed → open)", function()
    local ctx, _, win_portal = make_ctx()
    h.assert_eq("closed", win_portal._state, "window portal starts closed")
    local out = capture(function() handlers["open"](ctx, "window") end)
    h.assert_eq("open", win_portal._state, "window portal must transition to open state")
end)

test("#217-2: after open window, window portal is traversable", function()
    local ctx, _, win_portal = make_ctx()
    capture(function() handlers["open"](ctx, "window") end)
    local state = win_portal.states[win_portal._state]
    h.assert_truthy(state and state.traversable,
        "window portal must be traversable after open — state: " .. tostring(win_portal._state))
end)

test("#217-3: after open window, window portal state is 'open'", function()
    local ctx, _, win_portal = make_ctx()
    capture(function() handlers["open"](ctx, "window") end)
    h.assert_eq("open", win_portal._state,
        "window portal must be in open state — got: " .. tostring(win_portal._state))
end)

test("#217-4: after open window, 'go window' must succeed (player moves to courtyard)", function()
    local ctx, _, win_portal = make_ctx()
    capture(function() handlers["open"](ctx, "window") end)
    capture(function() handlers["go"](ctx, "window") end)
    h.assert_eq("courtyard", ctx.player.location,
        "player must reach courtyard after opening window — at: " .. tostring(ctx.player.location))
end)

test("#217-5: close window after opening transitions portal back to closed", function()
    local ctx, _, win_portal = make_ctx()
    capture(function() handlers["open"](ctx, "window") end)
    h.assert_eq("open", win_portal._state, "portal should be open")
    capture(function() handlers["close"](ctx, "window") end)
    h.assert_eq("closed", win_portal._state, "window portal FSM should be closed")
    local state = win_portal.states[win_portal._state]
    h.assert_truthy(state and not state.traversable,
        "window portal must not be traversable after closing")
end)

test("#217-6: open message prints correctly", function()
    local ctx = make_ctx()
    local out = capture(function() handlers["open"](ctx, "window") end)
    h.assert_truthy(out:find("unlatch") or out:find("push") or out:find("open"),
        "open message should describe opening — got: " .. out:sub(1, 200))
end)

---------------------------------------------------------------------------
-- BUG #214: exit window fails after breaking window
---------------------------------------------------------------------------
suite("BUG #214: exit/go window after break must be traversable")

test("#214-1: break window transitions portal to broken (traversable)", function()
    local ctx, _, win_portal = make_ctx()
    capture(function() handlers["break"](ctx, "window") end)
    h.assert_eq("broken", win_portal._state,
        "window portal must be in broken state — got: " .. tostring(win_portal._state))
    local state = win_portal.states[win_portal._state]
    h.assert_truthy(state and state.traversable,
        "window portal must be traversable after break")
end)

test("#214-2: after break window, 'go window' reaches courtyard", function()
    local ctx = make_ctx()
    capture(function() handlers["break"](ctx, "window") end)
    capture(function() handlers["go"](ctx, "window") end)
    h.assert_eq("courtyard", ctx.player.location,
        "player must reach courtyard after breaking window — at: " .. tostring(ctx.player.location))
end)

test("#214-3: after break window, 'enter window' reaches courtyard", function()
    local ctx = make_ctx()
    capture(function() handlers["break"](ctx, "window") end)
    capture(function() handlers["enter"](ctx, "window") end)
    h.assert_eq("courtyard", ctx.player.location,
        "player must reach courtyard via enter — at: " .. tostring(ctx.player.location))
end)

test("#214-4: broken window portal keeps 'window' in keywords", function()
    local ctx, _, win_portal = make_ctx()
    capture(function() handlers["break"](ctx, "window") end)
    local has_window = false
    if win_portal.keywords then
        for _, k in ipairs(win_portal.keywords) do
            if k:lower():find("window", 1, true) then
                has_window = true
                break
            end
        end
    end
    h.assert_truthy(has_window,
        "broken window portal must still have 'window' in keywords")
end)

---------------------------------------------------------------------------
-- BUG #216 + #217 combined: door open after unbar syncs exit
---------------------------------------------------------------------------
suite("EXIT SYNC: door unbar then open syncs exit correctly")

test("door unbar → open → go north succeeds", function()
    local ctx, portal = make_ctx()
    -- Simulate unbar first: manually transition portal barred → unbarred
    capture(function()
        portal._state = "unbarred"
        if portal.states and portal.states.unbarred then
            for k, v in pairs(portal.states.unbarred) do
                if type(v) ~= "function" then portal[k] = v end
            end
        end
    end)
    -- Now open the door via verb handler
    capture(function() handlers["open"](ctx, "door") end)
    h.assert_eq("open", portal._state, "portal should be open after open verb")
    local state = portal.states[portal._state]
    h.assert_truthy(state and state.traversable,
        "portal must be traversable after opening")
    -- Movement must succeed
    capture(function() handlers["go"](ctx, "north") end)
    h.assert_eq("hallway", ctx.player.location,
        "player must reach hallway")
end)

---------------------------------------------------------------------------
-- Regression: existing exit-only path still works
---------------------------------------------------------------------------
suite("REGRESSION: portal-based exits work")

test("portal ref resolves correctly for window exit", function()
    local cw_ok, cw = pcall(require, "engine.parser.context")
    if cw_ok and cw and cw.reset then cw.reset() end
    local ctx, _, win_portal = make_ctx()
    -- Verify the exit is a portal reference
    local exit = ctx.current_room.exits.window
    h.assert_truthy(exit and exit.portal,
        "window exit must be a portal reference")
    -- Verify portal resolves from registry
    local resolved = ctx.registry:get(exit.portal)
    h.assert_truthy(resolved,
        "portal ref must resolve from registry")
    h.assert_truthy(resolved.portal and resolved.portal.target,
        "resolved portal must have target")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
if skipped > 0 then
    print("  Skipped: " .. skipped)
end
local exit_code = h.summary()
os.exit(exit_code)
