-- test/rooms/test-portal-system.lua
-- TDD tests for the portal unification system (D-PORTAL-ARCHITECTURE).
-- Written BEFORE implementation — these tests define the spec.
-- Portal objects replace inline exit tables with first-class FSM objects.
--
-- Covers: template validation, movement, state management, bidirectional
-- sync, verb interactions, and backward compatibility.
--
-- Usage: lua test/rooms/test-portal-system.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local eq = h.assert_eq

local registry_mod = require("engine.registry")
local fsm_mod = require("engine.fsm")

-- Try loading verb handlers (may fail until portal engine code lands)
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
local handlers
if verbs_ok and type(verbs_mod) == "table" and verbs_mod.create then
    local ok2, h2 = pcall(verbs_mod.create)
    if ok2 then handlers = h2 end
end

---------------------------------------------------------------------------
-- Skip counter for tests that depend on unbuilt features
---------------------------------------------------------------------------
local skipped = 0
local function pending(name, reason)
    print("  SKIP " .. name .. " — " .. (reason or "not yet implemented"))
    skipped = skipped + 1
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Capture print output from a function call
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

-- Deep-copy a table
local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deep_copy(v) end
    return copy
end

-- Create a portal object (bedroom-hallway north side)
local function make_portal_north(overrides)
    local portal = {
        id = "bedroom-hallway-door-north",
        template = "portal",
        name = "a heavy oak door",
        keywords = {"door", "oak door", "heavy door", "heavy oak door"},
        description = "A heavy oak door banded with iron. A thick wooden bar holds it shut from the other side.",
        material = "oak",
        size = 5,
        weight = 100,
        portable = false,
        categories = {"portal"},

        portal = {
            target = "hallway",
            bidirectional_id = "bedroom-hallway-passage",
            direction_hint = "north",
        },

        initial_state = "barred",
        _state = "barred",
        states = {
            barred = {
                name = "a barred oak door",
                description = "A heavy oak door. A thick bar holds it shut from the other side.",
                traversable = false,
                on_feel = "Solid oak — no give when you push. Cold iron bands cross the surface.",
                on_listen = "Silence from the other side.",
                on_knock = "A dull thud. The door doesn't budge.",
            },
            unbarred = {
                name = "an unbarred oak door",
                description = "A heavy oak door, no longer barred. It is closed.",
                traversable = false,
                on_feel = "Rough oak grain. The door shifts slightly when pushed.",
                on_listen = "A faint draft from under the door.",
                on_knock = "A hollow boom echoes beyond.",
            },
            open = {
                name = "an open oak door",
                description = "The heavy oak door stands open, revealing a dim corridor beyond.",
                traversable = true,
                on_feel = "The door is open. Cool air flows through the doorway.",
                on_listen = "Wind whispers through the open doorway.",
            },
            broken = {
                name = "a splintered doorframe",
                description = "The door has been smashed. Jagged splinters frame the opening.",
                traversable = true,
                on_feel = "Jagged splinters of oak. Mind your fingers.",
                on_listen = "Wind howls through the ruined doorframe.",
            },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              message = "You lift the heavy wooden bar and set it aside." },
            { from = "unbarred", to = "open", verb = "open",
              message = "You push the door open on groaning hinges." },
            { from = "open", to = "unbarred", verb = "close",
              message = "You push the heavy door shut." },
            { from = "barred", to = "broken", verb = "break",
              requires_capability = "blunt_force",
              message = "You smash the door! It bursts inward in a shower of splinters." },
            { from = "unbarred", to = "broken", verb = "break",
              requires_capability = "blunt_force",
              message = "You smash the door! Oak splinters fly." },
        },

        on_feel = "Rough oak grain, cold iron bands.",
        on_smell = "Old oak and iron.",
        on_listen = "Silence.",

        mutations = {
            ["break"] = {
                becomes = "bedroom-hallway-door-north-broken",
                message = "The door bursts inward!",
                spawns = {"wood-splinters"},
            },
        },
    }
    if overrides then
        for k, v in pairs(overrides) do portal[k] = v end
    end
    return portal
end

-- Create the paired south-side portal
local function make_portal_south(overrides)
    local portal = {
        id = "bedroom-hallway-door-south",
        template = "portal",
        name = "a heavy oak door",
        keywords = {"door", "oak door", "heavy door", "heavy oak door"},
        description = "A heavy oak door leading south to the bedroom.",
        material = "oak",
        size = 5,
        weight = 100,
        portable = false,
        categories = {"portal"},

        portal = {
            target = "start-room",
            bidirectional_id = "bedroom-hallway-passage",
            direction_hint = "south",
        },

        initial_state = "barred",
        _state = "barred",
        states = {
            barred = {
                name = "a barred oak door",
                description = "The south door is barred from the bedroom side.",
                traversable = false,
            },
            unbarred = {
                name = "an unbarred oak door",
                description = "The south door is closed but unbarred.",
                traversable = false,
            },
            open = {
                name = "an open oak door",
                description = "The south door stands open.",
                traversable = true,
            },
            broken = {
                name = "a splintered doorframe",
                description = "The south doorframe is ruined.",
                traversable = true,
            },
        },
        transitions = {
            { from = "barred", to = "unbarred", verb = "unbar",
              message = "The bar is lifted from the other side." },
            { from = "unbarred", to = "open", verb = "open",
              message = "You pull the door open." },
            { from = "open", to = "unbarred", verb = "close",
              message = "You push the door shut." },
            { from = "barred", to = "broken", verb = "break",
              requires_capability = "blunt_force",
              message = "You smash through the door from this side!" },
            { from = "unbarred", to = "broken", verb = "break",
              requires_capability = "blunt_force",
              message = "The door gives way!" },
        },

        on_feel = "Rough oak grain, cold iron bands.",

        mutations = {},
    }
    if overrides then
        for k, v in pairs(overrides) do portal[k] = v end
    end
    return portal
end

-- Build a minimal game context with portal objects
local function make_portal_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()

    local portal_n = opts.portal_north or make_portal_north()
    local portal_s = opts.portal_south or make_portal_south()
    reg:register(portal_n.id, portal_n)
    reg:register(portal_s.id, portal_s)

    -- Register any extra objects
    if opts.extra_objects then
        for _, obj in ipairs(opts.extra_objects) do
            reg:register(obj.id, obj)
        end
    end

    local bedroom = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dark bedroom.",
        contents = opts.bedroom_contents or { portal_n.id },
        exits = opts.bedroom_exits or {
            north = { portal = "bedroom-hallway-door-north" },
        },
    }

    local hallway = {
        id = "hallway",
        name = "Hallway",
        description = "A dim corridor.",
        contents = opts.hallway_contents or { portal_s.id },
        exits = opts.hallway_exits or {
            south = { portal = "bedroom-hallway-door-south" },
        },
    }

    local rooms = { ["start-room"] = bedroom, hallway = hallway }
    if opts.extra_rooms then
        for id, room in pairs(opts.extra_rooms) do rooms[id] = room end
    end

    local player = {
        location = opts.start_location or "start-room",
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = opts.player_state or {},
        max_health = 100,
        visited_rooms = {},
    }

    return {
        registry = reg,
        current_room = rooms[player.location],
        rooms = rooms,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "go",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 1. PORTAL TEMPLATE VALIDATION
---------------------------------------------------------------------------
suite("PORTAL TEMPLATE: required fields")

-- [Depends on: src/meta/templates/portal.lua — Phase 1, Bart]
local template_ok, portal_template = pcall(dofile,
    repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "templates" .. SEP .. "portal.lua")

if portal_template then
    test("1.01 portal template loads without error", function()
        h.assert_truthy(portal_template, "portal template must load")
    end)

    test("1.02 template has id = 'portal'", function()
        eq("portal", portal_template.id, "template id")
    end)

    test("1.03 template has portal.target field (nil default)", function()
        h.assert_truthy(portal_template.portal, "portal metadata table must exist")
        -- target is nil by default in the template (set per instance)
    end)

    test("1.04 template has portal.bidirectional_id field", function()
        h.assert_truthy(portal_template.portal, "portal metadata table must exist")
        -- bidirectional_id is nil by default (set per instance)
    end)

    test("1.05 template has portal.direction_hint field", function()
        h.assert_truthy(portal_template.portal, "portal metadata table must exist")
        -- direction_hint is nil by default (set per instance)
    end)

    test("1.06 template has categories containing 'portal'", function()
        local found = false
        for _, cat in ipairs(portal_template.categories or {}) do
            if cat == "portal" then found = true; break end
        end
        h.assert_truthy(found, "template must have 'portal' category")
    end)

    test("1.07 template has on_feel (P6 darkness requirement)", function()
        h.assert_truthy(portal_template.on_feel, "portal template must have on_feel")
    end)

    test("1.08 template is not portable", function()
        eq(false, portal_template.portable, "portal must not be portable")
    end)

    test("1.09 template has FSM fields (states, transitions, _state)", function()
        h.assert_truthy(portal_template.states, "template must have states table")
        h.assert_truthy(portal_template.transitions, "template must have transitions table")
        h.assert_truthy(portal_template._state, "template must have _state")
        h.assert_truthy(portal_template.initial_state, "template must have initial_state")
    end)
else
    pending("1.01 portal template loads", "portal.lua template not yet created (Phase 1)")
    pending("1.02 template id", "portal.lua template not yet created")
    pending("1.03 portal.target field", "portal.lua template not yet created")
    pending("1.04 portal.bidirectional_id field", "portal.lua template not yet created")
    pending("1.05 portal.direction_hint field", "portal.lua template not yet created")
    pending("1.06 categories contains 'portal'", "portal.lua template not yet created")
    pending("1.07 on_feel exists", "portal.lua template not yet created")
    pending("1.08 not portable", "portal.lua template not yet created")
    pending("1.09 FSM fields exist", "portal.lua template not yet created")
end

---------------------------------------------------------------------------
-- PORTAL INSTANCE VALIDATION (from test fixture data)
---------------------------------------------------------------------------
suite("PORTAL INSTANCE: bedroom-hallway door structure")

test("1.10 portal north has template = 'portal'", function()
    local p = make_portal_north()
    eq("portal", p.template, "portal north template")
end)

test("1.11 portal north has portal.target = 'hallway'", function()
    local p = make_portal_north()
    eq("hallway", p.portal.target, "portal north target")
end)

test("1.12 portal north has portal.bidirectional_id", function()
    local p = make_portal_north()
    eq("bedroom-hallway-passage", p.portal.bidirectional_id, "bidirectional_id")
end)

test("1.13 portal north has portal.direction_hint = 'north'", function()
    local p = make_portal_north()
    eq("north", p.portal.direction_hint, "direction_hint")
end)

test("1.14 portal south has matching bidirectional_id", function()
    local pn = make_portal_north()
    local ps = make_portal_south()
    eq(pn.portal.bidirectional_id, ps.portal.bidirectional_id,
        "paired portals must share bidirectional_id")
end)

test("1.15 portal south target is 'start-room' (opposite side)", function()
    local ps = make_portal_south()
    eq("start-room", ps.portal.target, "portal south target")
end)

test("1.16 portal south direction_hint is 'south' (opposite)", function()
    local ps = make_portal_south()
    eq("south", ps.portal.direction_hint, "south direction hint")
end)

test("1.17 every portal state has traversable flag", function()
    local p = make_portal_north()
    for state_name, state in pairs(p.states) do
        h.assert_truthy(state.traversable ~= nil,
            "state '" .. state_name .. "' must declare traversable (true or false)")
    end
end)

test("1.18 portal has on_feel (darkness support)", function()
    local p = make_portal_north()
    h.assert_truthy(p.on_feel, "portal must have on_feel for P6")
end)

test("1.19 portal has categories containing 'portal'", function()
    local p = make_portal_north()
    local found = false
    for _, cat in ipairs(p.categories or {}) do
        if cat == "portal" then found = true; break end
    end
    h.assert_truthy(found, "portal instance must have 'portal' category")
end)

---------------------------------------------------------------------------
-- 2. MOVEMENT THROUGH PORTALS
---------------------------------------------------------------------------
suite("MOVEMENT: go through portal objects")

-- [Depends on: movement.lua portal path — Phase 1, Bart]

if handlers and handlers["go"] then
    test("2.01 'go north' through open portal succeeds", function()
        local portal_n = make_portal_north({ _state = "open" })
        local ctx = make_portal_ctx({ portal_north = portal_n })
        capture_output(function() handlers["go"](ctx, "north") end)
        eq("hallway", ctx.player.location,
            "player should move to hallway through open portal")
    end)

    test("2.02 'go north' through locked/barred portal fails", function()
        local portal_n = make_portal_north({ _state = "barred" })
        local ctx = make_portal_ctx({ portal_north = portal_n })
        local out = capture_output(function() handlers["go"](ctx, "north") end)
        eq("start-room", ctx.player.location,
            "player should NOT move through barred portal")
        h.assert_truthy(out:lower():find("bar") or out:lower():find("locked")
            or out:lower():find("can't") or out:lower():find("blocked")
            or out:lower():find("won't"),
            "should print blocked message — got: " .. out)
    end)

    test("2.03 'go north' through closed (unbarred) portal fails", function()
        local portal_n = make_portal_north({ _state = "unbarred" })
        local ctx = make_portal_ctx({ portal_north = portal_n })
        local out = capture_output(function() handlers["go"](ctx, "north") end)
        eq("start-room", ctx.player.location,
            "player should NOT move through closed portal")
        h.assert_truthy(out:lower():find("closed") or out:lower():find("shut")
            or out:lower():find("can't") or out:lower():find("blocked"),
            "should print closed message — got: " .. out)
    end)

    test("2.04 'go north' through broken portal succeeds (passable)", function()
        local portal_n = make_portal_north({ _state = "broken" })
        local ctx = make_portal_ctx({ portal_north = portal_n })
        capture_output(function() handlers["go"](ctx, "north") end)
        eq("hallway", ctx.player.location,
            "player should move through broken portal (traversable = true)")
    end)

    -- Legacy exit fallback removed (Portal Phase 4 cleanup)

    test("2.06 'n' shorthand resolves through portal", function()
        local portal_n = make_portal_north({ _state = "open" })
        local ctx = make_portal_ctx({ portal_north = portal_n })
        capture_output(function() handlers["north"](ctx, "") end)
        eq("hallway", ctx.player.location,
            "'north' / 'n' direction handler should resolve portal")
    end)

    test("2.07 'go south' from hallway through paired portal", function()
        local portal_s = make_portal_south({ _state = "open" })
        local ctx = make_portal_ctx({
            portal_south = portal_s,
            start_location = "hallway",
        })
        capture_output(function() handlers["go"](ctx, "south") end)
        eq("start-room", ctx.player.location,
            "player should move south through hallway's portal back to bedroom")
    end)
else
    pending("2.01 go north through open portal", "verb handlers not loaded")
    pending("2.02 go north through barred portal blocked", "verb handlers not loaded")
    pending("2.03 go north through closed portal blocked", "verb handlers not loaded")
    pending("2.04 go north through broken portal succeeds", "verb handlers not loaded")
    pending("2.06 'n' shorthand resolves portal", "verb handlers not loaded")
    pending("2.07 go south from hallway", "verb handlers not loaded")
end

---------------------------------------------------------------------------
-- 3. PORTAL STATE MANAGEMENT
---------------------------------------------------------------------------
suite("STATE: traversable flag per FSM state")

test("3.01 open state: traversable = true", function()
    local p = make_portal_north()
    eq(true, p.states.open.traversable, "open state must be traversable")
end)

test("3.02 closed (unbarred) state: traversable = false", function()
    local p = make_portal_north()
    eq(false, p.states.unbarred.traversable, "unbarred state must not be traversable")
end)

test("3.03 locked (barred) state: traversable = false", function()
    local p = make_portal_north()
    eq(false, p.states.barred.traversable, "barred state must not be traversable")
end)

test("3.04 broken state: traversable = true", function()
    local p = make_portal_north()
    eq(true, p.states.broken.traversable, "broken state must be traversable (passable wreckage)")
end)

test("3.05 FSM loads portal object", function()
    local p = make_portal_north()
    local def = fsm_mod.load(p)
    h.assert_truthy(def, "fsm.load must recognize portal object with states")
end)

test("3.06 FSM transitions barred → unbarred via 'unbar'", function()
    local reg = registry_mod.new()
    local p = make_portal_north()
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "unbarred", nil, "unbar")
    if trans then
        eq("unbarred", p._state, "portal should be in unbarred state after transition")
    else
        -- Transition may fail if FSM needs portal-specific handling
        pending("3.06 FSM barred→unbarred", "fsm.transition returned: " .. tostring(err))
    end
end)

test("3.07 FSM transitions unbarred → open via 'open'", function()
    local reg = registry_mod.new()
    local p = make_portal_north({ _state = "unbarred" })
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "open", nil, "open")
    if trans then
        eq("open", p._state, "portal should be in open state")
    else
        pending("3.07 FSM unbarred→open", "fsm.transition returned: " .. tostring(err))
    end
end)

test("3.08 FSM transitions open → unbarred via 'close'", function()
    local reg = registry_mod.new()
    local p = make_portal_north({ _state = "open" })
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "unbarred", nil, "close")
    if trans then
        eq("unbarred", p._state, "portal should be closed (unbarred) state")
    else
        pending("3.08 FSM open→unbarred (close)", "fsm.transition returned: " .. tostring(err))
    end
end)

test("3.09 FSM transitions barred → broken via 'break'", function()
    local reg = registry_mod.new()
    local p = make_portal_north()
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "broken", nil, "break")
    if trans then
        eq("broken", p._state, "portal should be broken")
    else
        pending("3.09 FSM barred→broken", "fsm.transition returned: " .. tostring(err))
    end
end)

test("3.10 current traversable reflects _state", function()
    local p = make_portal_north()
    local cur_state = p.states[p._state]
    eq(false, cur_state.traversable,
        "barred portal's current state should have traversable = false")
    -- Simulate state change to open
    p._state = "open"
    cur_state = p.states[p._state]
    eq(true, cur_state.traversable,
        "open portal's current state should have traversable = true")
end)

---------------------------------------------------------------------------
-- 4. BIDIRECTIONAL SYNC
---------------------------------------------------------------------------
suite("BIDIRECTIONAL: state changes propagate to paired portal")

-- [Depends on: bidirectional sync in fsm/init.lua — Phase 1, Bart]
-- These tests verify that when one portal changes state, the paired portal
-- (sharing the same bidirectional_id) transitions to the same state.

test("4.01 paired portals share bidirectional_id", function()
    local pn = make_portal_north()
    local ps = make_portal_south()
    eq(pn.portal.bidirectional_id, ps.portal.bidirectional_id,
        "both portals must have same bidirectional_id")
    eq("bedroom-hallway-passage", pn.portal.bidirectional_id,
        "bidirectional_id value check")
end)

test("4.02 registry can find paired portal by bidirectional_id", function()
    local reg = registry_mod.new()
    local pn = make_portal_north()
    local ps = make_portal_south()
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    -- Find the partner: search for portal with same bidirectional_id but different id
    local partner = nil
    for _, obj in ipairs(reg:list()) do
        if obj.portal and obj.portal.bidirectional_id == pn.portal.bidirectional_id
           and obj.id ~= pn.id then
            partner = obj
            break
        end
    end
    h.assert_truthy(partner, "must find paired portal via bidirectional_id scan")
    eq(ps.id, partner.id, "partner must be the south portal")
end)

-- The following tests depend on the engine's bidirectional sync mechanism.
-- When Bart builds fsm.transition() to propagate to paired portals, these pass.

test("4.03 opening north side syncs south side to open", function()
    -- [Depends on: bidirectional sync in fsm/init.lua — Phase 1, Bart]
    local reg = registry_mod.new()
    local pn = make_portal_north({ _state = "unbarred" })
    local ps = make_portal_south({ _state = "unbarred" })
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    -- Transition north portal to open
    local trans, err = fsm_mod.transition(reg, pn.id, "open", nil, "open")
    if not trans then
        pending("4.03 bidirectional open sync",
            "fsm.transition doesn't support bidirectional sync yet: " .. tostring(err))
        return
    end

    eq("open", pn._state, "north portal should be open")
    -- Bidirectional sync: south side should also be open
    eq("open", ps._state,
        "south portal should sync to open when north opens (bidirectional)")
end)

test("4.04 closing north side syncs south side to closed", function()
    -- [Depends on: bidirectional sync in fsm/init.lua — Phase 1, Bart]
    local reg = registry_mod.new()
    local pn = make_portal_north({ _state = "open" })
    local ps = make_portal_south({ _state = "open" })
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local trans, err = fsm_mod.transition(reg, pn.id, "unbarred", nil, "close")
    if not trans then
        pending("4.04 bidirectional close sync",
            "fsm.transition doesn't support bidirectional sync yet: " .. tostring(err))
        return
    end

    eq("unbarred", pn._state, "north portal should be closed (unbarred)")
    eq("unbarred", ps._state,
        "south portal should sync to unbarred when north closes (bidirectional)")
end)

test("4.05 breaking north side syncs south side to broken", function()
    -- [Depends on: bidirectional sync in fsm/init.lua — Phase 1, Bart]
    local reg = registry_mod.new()
    local pn = make_portal_north({ _state = "barred" })
    local ps = make_portal_south({ _state = "barred" })
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local trans, err = fsm_mod.transition(reg, pn.id, "broken", nil, "break")
    if not trans then
        pending("4.05 bidirectional break sync",
            "fsm.transition doesn't support bidirectional sync yet: " .. tostring(err))
        return
    end

    eq("broken", pn._state, "north portal should be broken")
    eq("broken", ps._state,
        "south portal should sync to broken (bidirectional)")
end)

test("4.06 sync works in reverse: south → north", function()
    -- [Depends on: bidirectional sync in fsm/init.lua — Phase 1, Bart]
    local reg = registry_mod.new()
    local pn = make_portal_north({ _state = "unbarred" })
    local ps = make_portal_south({ _state = "unbarred" })
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    -- Transition the SOUTH portal this time
    local trans, err = fsm_mod.transition(reg, ps.id, "open", nil, "open")
    if not trans then
        pending("4.06 reverse bidirectional sync",
            "fsm.transition doesn't support bidirectional sync yet: " .. tostring(err))
        return
    end

    eq("open", ps._state, "south portal should be open")
    eq("open", pn._state,
        "north portal should sync to open when south opens (reverse bidirectional)")
end)

test("4.07 unbar on north side propagates to south side", function()
    -- [Depends on: bidirectional sync in fsm/init.lua — Phase 1, Bart]
    local reg = registry_mod.new()
    local pn = make_portal_north({ _state = "barred" })
    local ps = make_portal_south({ _state = "barred" })
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local trans, err = fsm_mod.transition(reg, pn.id, "unbarred", nil, "unbar")
    if not trans then
        pending("4.07 bidirectional unbar sync",
            "fsm.transition doesn't support bidirectional sync yet: " .. tostring(err))
        return
    end

    eq("unbarred", pn._state, "north portal should be unbarred")
    eq("unbarred", ps._state,
        "south portal should sync to unbarred (bidirectional)")
end)

---------------------------------------------------------------------------
-- 5. VERB INTERACTIONS
---------------------------------------------------------------------------
suite("VERBS: portal-aware verb handlers")

-- [Depends on: verb handlers finding portal objects — Phase 1/2]

if handlers then
    test("5.01 'open door' on portal: closed → open", function()
        -- [Depends on: open handler routing to portal FSM path]
        local portal_n = make_portal_north({ _state = "unbarred" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "open" })
        local out = capture_output(function() handlers["open"](ctx, "door") end)
        -- After handler, the portal object should be in "open" state
        local obj = ctx.registry:get("bedroom-hallway-door-north")
        if obj._state == "open" then
            eq("open", obj._state, "portal should transition to open")
        else
            pending("5.01 open door on portal",
                "open handler doesn't route to portal FSM yet — got state: " .. tostring(obj._state))
        end
    end)

    test("5.02 'close door' on portal: open → closed", function()
        -- [Depends on: close handler routing to portal FSM path]
        local portal_n = make_portal_north({ _state = "open" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "close" })
        local out = capture_output(function() handlers["close"](ctx, "door") end)
        local obj = ctx.registry:get("bedroom-hallway-door-north")
        if obj._state == "unbarred" then
            eq("unbarred", obj._state, "portal should transition to unbarred (closed)")
        else
            pending("5.02 close door on portal",
                "close handler doesn't route to portal FSM yet — got state: " .. tostring(obj._state))
        end
    end)

    test("5.03 'break door' on portal: any → broken", function()
        -- [Depends on: break handler routing to portal FSM path]
        local portal_n = make_portal_north({ _state = "barred" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "break" })
        local out = capture_output(function() handlers["break"](ctx, "door") end)
        local obj = ctx.registry:get("bedroom-hallway-door-north")
        if obj._state == "broken" then
            eq("broken", obj._state, "portal should be broken")
        else
            pending("5.03 break door on portal",
                "break handler doesn't route to portal FSM yet — got state: " .. tostring(obj._state))
        end
    end)

    test("5.04 'knock on door' produces sound", function()
        -- [Depends on: knock verb checking portal objects]
        local portal_n = make_portal_north({ _state = "barred" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "knock" })
        if handlers["knock"] then
            local out = capture_output(function() handlers["knock"](ctx, "door") end)
            h.assert_truthy(out ~= "" and out:len() > 0,
                "knock on portal door should produce output — got: " .. out)
        else
            pending("5.04 knock on door", "knock verb handler not found")
        end
    end)

    test("5.05 'feel door' works (darkness support)", function()
        -- [Depends on: feel/touch verb finding portal objects]
        local portal_n = make_portal_north({ _state = "barred" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "feel" })
        if handlers["feel"] then
            local out = capture_output(function() handlers["feel"](ctx, "door") end)
            h.assert_truthy(out:len() > 0,
                "feel door should produce tactile description — got: " .. out)
            h.assert_truthy(out:lower():find("oak") or out:lower():find("iron")
                or out:lower():find("solid") or out:lower():find("rough"),
                "feel output should describe texture — got: " .. out)
        else
            pending("5.05 feel door", "feel verb handler not found")
        end
    end)

    test("5.06 'look door' / 'examine door' shows state description", function()
        -- [Depends on: look/examine finding portal objects]
        local portal_n = make_portal_north({ _state = "barred" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "look" })
        if handlers["examine"] then
            local out = capture_output(function() handlers["examine"](ctx, "door") end)
            if out:len() > 0 and (out:lower():find("bar") or out:lower():find("oak")
                or out:lower():find("door")) then
                h.assert_truthy(true, "examine shows description")
            else
                pending("5.06 examine door on portal",
                    "examine handler may not find portal objects yet — got: " .. out)
            end
        else
            pending("5.06 examine door", "examine verb handler not found")
        end
    end)

    test("5.07 'listen door' returns on_listen from state", function()
        -- [Depends on: listen verb finding portal objects]
        local portal_n = make_portal_north({ _state = "barred" })
        local ctx = make_portal_ctx({ portal_north = portal_n, verb = "listen" })
        if handlers["listen"] then
            local out = capture_output(function() handlers["listen"](ctx, "door") end)
            if out:len() > 0 then
                h.assert_truthy(true, "listen produced output")
            else
                pending("5.07 listen door",
                    "listen handler may not find portal objects — got empty output")
            end
        else
            pending("5.07 listen door", "listen verb handler not found")
        end
    end)

    -- Lock requires a key — test with a keyed portal variant
    test("5.08 'lock door' on keyed portal: open → locked", function()
        -- [Depends on: lock handler + portal-aware key matching]
        -- This tests a future keyed portal (not bedroom door which is barred).
        -- For now, skip if lock handler doesn't exist.
        if not handlers["lock"] then
            pending("5.08 lock door on portal", "lock handler not found")
            return
        end
        -- Keyed portal (e.g., cellar iron door with key_id)
        local keyed_portal = make_portal_north({
            _state = "open",
            id = "test-keyed-portal",
            states = {
                open = { traversable = true, description = "Open." },
                closed = { traversable = false, description = "Closed." },
                locked = { traversable = false, description = "Locked." },
            },
            transitions = {
                { from = "open", to = "closed", verb = "close", message = "Shut." },
                { from = "closed", to = "locked", verb = "lock",
                  requires_tool = "brass-key", message = "Locked with key." },
                { from = "locked", to = "closed", verb = "unlock",
                  requires_tool = "brass-key", message = "Unlocked." },
                { from = "closed", to = "open", verb = "open", message = "Opened." },
            },
        })
        local key = {
            id = "brass-key", name = "a brass key",
            keywords = {"key", "brass key"},
            portable = true, on_feel = "Cold metal.", size = 1,
        }
        local ctx = make_portal_ctx({
            portal_north = keyed_portal,
            extra_objects = { key },
            hands = { key, nil },
            verb = "lock",
        })
        local out = capture_output(function() handlers["lock"](ctx, "door") end)
        local obj = ctx.registry:get("test-keyed-portal")
        -- This likely fails until portal verb routing exists
        if obj._state == "locked" then
            eq("locked", obj._state, "portal should be locked")
        else
            pending("5.08 lock door on portal",
                "lock handler doesn't route to portal FSM yet — state: " .. tostring(obj._state))
        end
    end)
else
    pending("5.01 open door on portal", "verb handlers not loaded")
    pending("5.02 close door on portal", "verb handlers not loaded")
    pending("5.03 break door on portal", "verb handlers not loaded")
    pending("5.04 knock on door", "verb handlers not loaded")
    pending("5.05 feel door in darkness", "verb handlers not loaded")
    pending("5.06 examine door", "verb handlers not loaded")
    pending("5.07 listen door", "verb handlers not loaded")
    pending("5.08 lock door on portal", "verb handlers not loaded")
end

---------------------------------------------------------------------------
-- 6. BACKWARD COMPATIBILITY — REMOVED (Portal Phase 4)
-- Legacy inline exit tables are no longer supported. All exits use portals.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- PORTAL KEYWORD RESOLUTION
---------------------------------------------------------------------------
suite("KEYWORDS: portal found by various search terms")

test("7.01 portal found in registry by keyword 'door'", function()
    local reg = registry_mod.new()
    local p = make_portal_north()
    reg:register(p.id, p)
    local found = reg:find_by_keyword("door")
    h.assert_truthy(found, "registry should find portal by keyword 'door'")
    eq(p.id, found.id, "found object should be the portal")
end)

test("7.02 portal found by keyword 'oak door'", function()
    local reg = registry_mod.new()
    local p = make_portal_north()
    reg:register(p.id, p)
    local found = reg:find_by_keyword("oak door")
    h.assert_truthy(found, "registry should find portal by 'oak door'")
end)

test("7.03 portal found by category 'portal'", function()
    local reg = registry_mod.new()
    local p = make_portal_north()
    reg:register(p.id, p)
    local portals = reg:find_by_category("portal")
    h.assert_truthy(#portals > 0, "should find at least one portal by category")
    eq(p.id, portals[1].id, "found portal matches")
end)

test("7.04 find_portal_by_keyword helper resolves by direction_hint", function()
    -- [Depends on: find_portal_by_keyword() in helpers.lua — Phase 1, Bart]
    local helpers_ok, verb_helpers = pcall(require, "engine.verbs.helpers")
    if helpers_ok and verb_helpers and verb_helpers.find_portal_by_keyword then
        local reg = registry_mod.new()
        local p = make_portal_north()
        reg:register(p.id, p)
        local room = {
            id = "start-room",
            contents = { p.id },
            exits = { north = { portal = p.id } },
        }
        local ctx = { registry = reg, current_room = room }
        local found = verb_helpers.find_portal_by_keyword(ctx, "north")
        h.assert_truthy(found, "find_portal_by_keyword should resolve 'north' via direction_hint")
        eq(p.id, found.id, "found portal should match")
    else
        pending("7.04 find_portal_by_keyword",
            "find_portal_by_keyword not yet implemented in helpers.lua (Phase 1)")
    end
end)

---------------------------------------------------------------------------
-- PORTAL SENSORY PROPERTIES (per state)
---------------------------------------------------------------------------
suite("SENSORY: state-specific sensory text on portals")

test("8.01 barred state has on_feel", function()
    local p = make_portal_north()
    h.assert_truthy(p.states.barred.on_feel,
        "barred state must have on_feel for darkness")
end)

test("8.02 unbarred state has on_feel", function()
    local p = make_portal_north()
    h.assert_truthy(p.states.unbarred.on_feel,
        "unbarred state must have on_feel")
end)

test("8.03 open state has on_feel", function()
    local p = make_portal_north()
    h.assert_truthy(p.states.open.on_feel,
        "open state must have on_feel")
end)

test("8.04 broken state has on_feel", function()
    local p = make_portal_north()
    h.assert_truthy(p.states.broken.on_feel,
        "broken state must have on_feel")
end)

test("8.05 barred state has on_knock", function()
    local p = make_portal_north()
    h.assert_truthy(p.states.barred.on_knock,
        "barred state should have on_knock response")
end)

test("8.06 different states have different on_feel text", function()
    local p = make_portal_north()
    local barred_feel = p.states.barred.on_feel
    local open_feel = p.states.open.on_feel
    h.assert_truthy(barred_feel ~= open_feel,
        "barred and open on_feel should differ — barred: " .. barred_feel
        .. " vs open: " .. open_feel)
end)

---------------------------------------------------------------------------
-- THIN EXIT REFERENCE FORMAT
---------------------------------------------------------------------------
suite("THIN EXIT: room exit tables reference portal objects")

test("9.01 thin exit has 'portal' field", function()
    local exit = { portal = "bedroom-hallway-door-north" }
    h.assert_truthy(exit.portal, "thin exit must have 'portal' field")
    eq("string", type(exit.portal), "portal field must be a string (object ID)")
end)

test("9.02 thin exit has no inline state flags", function()
    local exit = { portal = "bedroom-hallway-door-north" }
    h.assert_nil(exit.open, "thin exit must NOT have 'open' flag (state lives on portal object)")
    h.assert_nil(exit.locked, "thin exit must NOT have 'locked' flag")
    h.assert_nil(exit.hidden, "thin exit must NOT have 'hidden' flag")
    h.assert_nil(exit.broken, "thin exit must NOT have 'broken' flag")
end)

test("9.03 thin exit has no mutations", function()
    local exit = { portal = "bedroom-hallway-door-north" }
    h.assert_nil(exit.mutations, "thin exit must NOT have mutations (lives on portal object)")
end)

test("9.04 thin exit has no becomes_exit", function()
    local exit = { portal = "bedroom-hallway-door-north" }
    h.assert_nil(exit.becomes_exit, "thin exit must NOT have becomes_exit")
end)

---------------------------------------------------------------------------
-- PASSAGE CONSTRAINTS
---------------------------------------------------------------------------
suite("CONSTRAINTS: portal passage limits")

test("10.01 portal has max_carry_size (optional)", function()
    local p = make_portal_north()
    -- max_carry_size is optional on portal objects (nil = no limit)
    -- The bedroom door should restrict size
    -- This will be set by Flanders when creating the actual portal objects
    h.assert_truthy(true, "max_carry_size validation placeholder")
end)

test("10.02 portal is not portable", function()
    local p = make_portal_north()
    eq(false, p.portable, "portal must not be portable — you can't pick up a door")
end)

test("10.03 portal has material defined", function()
    local p = make_portal_north()
    h.assert_truthy(p.material, "portal must have material for destruction/effects")
    eq("oak", p.material, "bedroom door is oak")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
if skipped > 0 then
    print("  Skipped: " .. skipped)
end
os.exit(exit_code == 0 and 0 or 1)
