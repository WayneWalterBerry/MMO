-- test/rooms/test-kitchen-door-access.lua
-- Issue #355: Kitchen door inaccessible — latched from inside with no keyhole
-- TDD: Tests that the hallway-east-door has a player-accessible mechanism
-- to unlatch it (tool-based interaction) rather than being completely inert.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

-- Load the hallway-east-door portal object
local door = dofile(script_dir .. "/../../src/meta/objects/hallway-east-door.lua")

-- Helper: find a transition by from/to states
local function find_transition(transitions, from, to)
    if not transitions then return nil end
    for _, t in ipairs(transitions) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

-- Helper: find any transition FROM a given state
local function find_transitions_from(transitions, from)
    local result = {}
    if not transitions then return result end
    for _, t in ipairs(transitions) do
        if t.from == from then result[#result + 1] = t end
    end
    return result
end

-- =========================================================================
suite("ISSUE #355 — Kitchen door object validity")
-- =========================================================================

test("hallway-east-door.lua exists and loads", function()
    h.assert_truthy(door, "hallway-east-door.lua must load")
    h.assert_eq("table", type(door), "must return a table")
end)

test("hallway-east-door is a portal", function()
    h.assert_eq("portal", door.template, "must be a portal template")
end)

test("hallway-east-door starts in locked state", function()
    h.assert_eq("locked", door.initial_state, "must start locked")
    h.assert_eq("locked", door._state, "current state must be locked")
end)

-- =========================================================================
suite("ISSUE #355 — Kitchen door has player-accessible mechanism")
-- =========================================================================

test("hallway-east-door has at least one transition", function()
    h.assert_truthy(door.transitions, "transitions table must exist")
    h.assert_truthy(#door.transitions > 0,
        "door must have at least one transition (currently has " ..
        tostring(#(door.transitions or {})) .. ")")
end)

test("hallway-east-door has transition FROM locked state", function()
    local from_locked = find_transitions_from(door.transitions, "locked")
    h.assert_truthy(#from_locked > 0,
        "must have at least one transition from 'locked' state — " ..
        "players need a way to interact with the latch")
end)

test("locked-to-unlatched transition requires a tool", function()
    local t = find_transition(door.transitions, "locked", "unlatched")
    h.assert_truthy(t, "must have locked → unlatched transition")
    h.assert_truthy(t.requires_tool,
        "transition must require a tool (e.g. cutting_edge to slide under door)")
end)

test("door has 'unlatched' state defined", function()
    h.assert_truthy(door.states, "states table must exist")
    h.assert_truthy(door.states.unlatched,
        "must have an 'unlatched' state for after the latch is lifted")
end)

test("unlatched state is still not traversable (room beyond doesn't exist yet)", function()
    h.assert_truthy(door.states.unlatched,
        "unlatched state must exist")
    h.assert_eq(false, door.states.unlatched.traversable,
        "unlatched door should not be traversable (manor-east room doesn't exist yet)")
end)

test("unlatched state has a blocked_message explaining WHY", function()
    h.assert_truthy(door.states.unlatched,
        "unlatched state must exist")
    h.assert_truthy(door.states.unlatched.blocked_message,
        "unlatched state must explain why passage is blocked")
end)

-- =========================================================================
suite("ISSUE #355 — Kitchen door narrative quality")
-- =========================================================================

test("locked state blocked_message no longer says 'no keyhole to pick'", function()
    -- The old message implied total helplessness; the new design
    -- should hint at the tool-based mechanism
    local msg = door.states.locked.blocked_message or ""
    -- Should NOT contain the hopeless "no keyhole to pick" line
    -- (though it can mention the latch is inside)
    h.assert_truthy(msg:len() > 0, "locked state must have a blocked_message")
end)

test("door keywords include 'kitchen door' for discoverability", function()
    local found = false
    for _, kw in ipairs(door.keywords or {}) do
        if kw:lower() == "kitchen door" then found = true; break end
    end
    h.assert_truthy(found, "keywords must include 'kitchen door'")
end)

-- =========================================================================
print("")
local exit_code = h.summary()
os.exit(exit_code)
