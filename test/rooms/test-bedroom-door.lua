-- test/rooms/test-bedroom-door.lua
-- Regression tests for the bedroom north door (exit metadata).
-- Locks down current behavior BEFORE refactoring into an interactable object.
-- Must be run from repository root: lua test/rooms/test-bedroom-door.lua

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

-- Load the room metadata table directly (it returns a plain Lua table)
local room = dofile(script_dir .. "/../../src/meta/rooms/start-room.lua")

local north = room.exits and room.exits.north
local window = room.exits and room.exits.window
local down = room.exits and room.exits.down

-- Load portal objects that replaced inline exit metadata (Portal Phase 3)
local portal = dofile(script_dir .. "/../../src/meta/objects/bedroom-hallway-door-north.lua")
local window_portal = dofile(script_dir .. "/../../src/meta/objects/bedroom-courtyard-window-out.lua")
local trapdoor_portal = dofile(script_dir .. "/../../src/meta/objects/bedroom-cellar-trapdoor-down.lua")

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

-- Deep-copy an exit table so mutations don't leak between tests
local function copy_exit(ex)
    local t = {}
    for k, v in pairs(ex) do
        if type(v) == "table" then
            t[k] = copy_exit(v)
        else
            t[k] = v
        end
    end
    return t
end

-- Build a minimal ctx with a room whose north exit is a fresh copy
local function make_ctx(overrides)
    overrides = overrides or {}
    local exit = copy_exit(north)
    for k, v in pairs(overrides) do exit[k] = v end
    return {
        current_room = {
            id = "start-room",
            name = "The Bedroom",
            exits = { north = exit },
            contents = {},
        },
        player = {
            location = "start-room",
            hands = { nil, nil },
            injuries = {},
            inventory = overrides._inventory or {},
        },
        rooms = {
            hallway = { id = "hallway", name = "Hallway", exits = {}, contents = {} },
        },
        known_objects = {},
        registry = {
            get = function(self, id) return nil end,
            find_by_keyword = function(self, kw) return nil end,
        },
    }
end

---------------------------------------------------------------------------
-- DOOR STATE TESTS
---------------------------------------------------------------------------
suite("DOOR STATE: north exit metadata")

test("1. North exit exists and is a table", function()
    h.assert_truthy(north, "north exit must exist")
    h.assert_eq("table", type(north), "north exit must be a table")
end)

test("2. North exit is a portal reference", function()
    h.assert_truthy(north.portal, "north exit must be a portal reference")
    h.assert_eq("bedroom-hallway-door-north", north.portal, "portal id")
end)

test("3. Portal starts non-traversable (barred)", function()
    h.assert_eq("barred", portal._state, "portal must start barred")
    h.assert_eq(false, portal.states.barred.traversable, "barred state must not be traversable")
end)

test("4. Portal has no key_id (bar mechanism, not key lock)", function()
    h.assert_nil(portal.key_id, "key_id must be nil — door is barred, not keyed")
end)

test("5. Portal is breakable (has break transition)", function()
    local has_break = false
    for _, t in ipairs(portal.transitions) do
        if t.verb == "break" then has_break = true; break end
    end
    h.assert_truthy(has_break, "portal must have a break transition")
end)

test("6. Break transition requires_strength is 3", function()
    local brk
    for _, t in ipairs(portal.transitions) do
        if t.verb == "break" and t.from == "barred" then brk = t; break end
    end
    h.assert_truthy(brk, "break transition must exist")
    h.assert_eq(3, brk.requires_strength, "requires_strength must be 3")
end)

test("7. Portal name is 'a heavy oak door'", function()
    h.assert_eq("a heavy oak door", portal.name, "portal name")
end)

test("8. Portal starts non-traversable (barred = closed+locked)", function()
    h.assert_eq(false, portal.states[portal._state].traversable,
        "portal must start non-traversable")
end)

test("9. Portal is not hidden", function()
    h.assert_nil(portal.hidden, "portal must not be hidden")
end)

test("10. Portal is not broken initially", function()
    h.assert_truthy(portal._state ~= "broken", "portal must not start broken")
end)

test("11. Portal target is 'hallway'", function()
    h.assert_eq("hallway", portal.portal.target, "portal target room")
end)

test("12. Portal has bidirectional_id (replaces passage_id)", function()
    h.assert_truthy(portal.portal.bidirectional_id,
        "portal must have bidirectional_id for paired sync")
end)

---------------------------------------------------------------------------
-- MUTATION STRUCTURE TESTS
---------------------------------------------------------------------------
suite("PORTAL FSM: transition structure verification")

-- Helper to find a transition by from/to
local function find_portal_transition(from, to)
    for _, t in ipairs(portal.transitions) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

test("13. Transitions table exists and is non-empty", function()
    h.assert_truthy(portal.transitions, "transitions table must exist")
    h.assert_truthy(#portal.transitions > 0, "transitions must not be empty")
end)

test("14. Has 'close' transition (open → unbarred)", function()
    h.assert_truthy(find_portal_transition("open", "unbarred"),
        "close transition must exist")
end)

test("15. Has 'open' transition (unbarred → open)", function()
    h.assert_truthy(find_portal_transition("unbarred", "open"),
        "open transition must exist")
end)

test("16. Has 'break' transition (barred → broken)", function()
    h.assert_truthy(find_portal_transition("barred", "broken"),
        "break transition must exist")
end)

test("17. Open requires unbarred state (no barred → open path)", function()
    local direct = find_portal_transition("barred", "open")
    h.assert_nil(direct, "no direct barred → open transition should exist")
end)

test("18. Cannot open from barred state", function()
    local open_t = find_portal_transition("barred", "open")
    h.assert_nil(open_t, "open from barred must not exist — must unbar first")
end)

test("19. Can open from unbarred state", function()
    local open_t = find_portal_transition("unbarred", "open")
    h.assert_truthy(open_t, "open from unbarred must exist")
    h.assert_eq("open", open_t.verb, "transition verb must be 'open'")
end)

test("20. Close transition leads to non-traversable state", function()
    local close_t = find_portal_transition("open", "unbarred")
    h.assert_truthy(close_t, "close transition must exist")
    h.assert_eq(false, portal.states.unbarred.traversable,
        "unbarred state must not be traversable (door is closed)")
end)

test("21. Open transition leads to traversable state", function()
    local open_t = find_portal_transition("unbarred", "open")
    h.assert_truthy(open_t, "open transition must exist")
    h.assert_eq(true, portal.states.open.traversable,
        "open state must be traversable")
end)

test("22. Break transition leads to traversable state", function()
    local brk = find_portal_transition("barred", "broken")
    h.assert_truthy(brk, "break transition must exist")
    h.assert_eq(true, portal.states.broken.traversable,
        "broken state must be traversable")
end)

test("23. Broken state is traversable (replaces locked=false)", function()
    h.assert_eq(true, portal.states.broken.traversable,
        "broken state must be traversable — door is destroyed")
end)

test("24. Broken state has distinct name", function()
    h.assert_truthy(portal.states.broken.name, "broken state must have a name")
    h.assert_truthy(portal.states.broken.name ~= portal.name,
        "broken state name must differ from initial name")
end)

test("25. Break transition spawns wood-splinters", function()
    local brk = find_portal_transition("barred", "broken")
    h.assert_truthy(brk, "break transition must exist")
    h.assert_truthy(brk.spawns, "break transition must have spawns")
    h.assert_eq("wood-splinters", brk.spawns[1], "first spawn must be wood-splinters")
end)

---------------------------------------------------------------------------
-- INTERACTION TESTS (via verb handlers)
---------------------------------------------------------------------------
suite("DOOR INTERACTIONS: open door while locked")

-- Load verb handlers — the engine exposes a create_handlers(deps) function
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
local handlers
if verbs_ok and type(verbs_mod) == "table" and verbs_mod.create_handlers then
    -- Provide minimal dependencies so handlers can initialise
    local noop = function() end
    local stub_mod = { process = noop, tick = noop, get_transitions = function() return {} end }
    local ok2, h2 = pcall(verbs_mod.create_handlers, {
        fsm = stub_mod,
        effects = stub_mod,
        injury = stub_mod,
        context_window = { set_previous_room = noop },
        traverse_effects = { process = noop },
    })
    if ok2 then handlers = h2 end
end

if handlers and handlers["open"] then
    test("26. 'open door' while locked prints 'It is locked.'", function()
        local ctx = make_ctx()
        local out = capture(function() handlers["open"](ctx, "door") end)
        h.assert_truthy(out:find("locked"),
            "opening locked door must mention 'locked' — got: " .. out)
    end)

    test("27. 'open door' after unlocking succeeds", function()
        local ctx = make_ctx({ locked = false })
        local out = capture(function() handlers["open"](ctx, "door") end)
        h.assert_truthy(out:find("open") or out:find("swing") or out:find("hinge"),
            "opening unlocked door must succeed — got: " .. out)
    end)

    test("28. After open mutation, exit.open becomes true", function()
        local ctx = make_ctx({ locked = false })
        capture(function() handlers["open"](ctx, "door") end)
        h.assert_eq(true, ctx.current_room.exits.north.open,
            "door must be open after open handler")
    end)
else
    pending("26. 'open door' while locked prints rejection",
        "verb handlers could not be loaded for unit testing")
    pending("27. 'open door' after unlocking succeeds",
        "verb handlers could not be loaded for unit testing")
    pending("28. After open mutation, exit.open becomes true",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
suite("DOOR INTERACTIONS: unlock door")

if handlers and handlers["unlock"] then
    test("29. 'unlock door' with no key_id prints 'no visible keyhole'", function()
        local ctx = make_ctx()
        local out = capture(function() handlers["unlock"](ctx, "door") end)
        h.assert_truthy(out:lower():find("keyhole") or out:lower():find("no key"),
            "unlock barred door must mention no keyhole — got: " .. out)
    end)
else
    pending("29. 'unlock door' with no key_id prints rejection",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
suite("DOOR INTERACTIONS: brass key vs bedroom door")

test("30. Brass key (for cellar) does not match bedroom door key_id", function()
    -- The brass key's target is the storage-cellar door (key_id = "brass-key").
    -- The bedroom door has key_id = nil, so no key can unlock it via the key mechanism.
    h.assert_nil(north.key_id,
        "bedroom door key_id must be nil — brass key cannot unlock it")
end)

---------------------------------------------------------------------------
-- MOVEMENT TESTS (walking through the door)
---------------------------------------------------------------------------
suite("DOOR MOVEMENT: cannot traverse locked/closed door")

if handlers and handlers["go"] then
    test("31. 'go north' with locked door prints locked message", function()
        local ctx = make_ctx()
        local out = capture(function() handlers["go"](ctx, "north") end)
        h.assert_truthy(out:lower():find("locked"),
            "traversing locked door must mention 'locked' — got: " .. out)
    end)

    test("32. 'go north' with closed (unlocked) door prints closed message", function()
        local ctx = make_ctx({ locked = false, open = false })
        local out = capture(function() handlers["go"](ctx, "north") end)
        h.assert_truthy(out:lower():find("closed"),
            "traversing closed door must mention 'closed' — got: " .. out)
    end)

    test("33. 'go north' with open door succeeds (changes location)", function()
        local ctx = make_ctx({ locked = false, open = true })
        capture(function() handlers["go"](ctx, "north") end)
        h.assert_eq("hallway", ctx.player.location,
            "player must move to hallway after traversing open door")
    end)
else
    pending("31. 'go north' locked door blocks movement",
        "verb handlers could not be loaded for unit testing")
    pending("32. 'go north' closed door blocks movement",
        "verb handlers could not be loaded for unit testing")
    pending("33. 'go north' open door moves player",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- EXIT INTEGRITY TESTS (all room exits)
---------------------------------------------------------------------------
suite("EXIT INTEGRITY: all bedroom exits")

test("34. Room has exactly 3 exits", function()
    local count = 0
    for _ in pairs(room.exits) do count = count + 1 end
    h.assert_eq(3, count, "bedroom must have 3 exits (north, window, down)")
end)

test("35. North exit exists", function()
    h.assert_truthy(room.exits.north, "north exit must exist")
end)

test("36. Window exit exists", function()
    h.assert_truthy(room.exits.window, "window exit must exist")
end)

test("37. Down exit exists", function()
    h.assert_truthy(room.exits.down, "down exit must exist")
end)

test("38. Window starts non-traversable (locked latch)", function()
    local state = window_portal.states[window_portal._state]
    h.assert_truthy(state and not state.traversable,
        "window portal must start non-traversable (locked)")
end)

test("39. Window target is 'courtyard'", function()
    h.assert_eq("courtyard", window_portal.portal.target, "window portal target")
end)

test("40. Down exit starts hidden", function()
    h.assert_eq("hidden", trapdoor_portal._state,
        "trap door portal must start in hidden state")
end)

test("41. Down exit target is 'cellar'", function()
    h.assert_eq("cellar", trapdoor_portal.portal.target, "trap door portal target")
end)

test("42. Down exit is not locked (hidden, not keyed)", function()
    h.assert_truthy(trapdoor_portal._state ~= "locked",
        "trap door must be hidden, not locked")
end)

test("43. Down exit portal has trap door keywords", function()
    local has_trapdoor = false
    for _, kw in ipairs(trapdoor_portal.keywords or {}) do
        if kw:lower():find("trap door") or kw:lower():find("trapdoor") then
            has_trapdoor = true; break
        end
    end
    h.assert_truthy(has_trapdoor,
        "trap door portal must have trap door keyword")
end)

---------------------------------------------------------------------------
-- DOOR KEYWORDS TESTS
---------------------------------------------------------------------------
suite("DOOR KEYWORDS: exit matching")

test("44. Portal has keywords array", function()
    h.assert_truthy(portal.keywords, "keywords must exist")
    h.assert_truthy(#portal.keywords > 0, "keywords must not be empty")
end)

test("45. Keywords include 'door'", function()
    local found = false
    for _, kw in ipairs(portal.keywords) do
        if kw:lower():find("door") then found = true; break end
    end
    h.assert_truthy(found, "keywords must include a 'door' keyword")
end)

test("46. Keywords include 'barred door'", function()
    local found = false
    for _, kw in ipairs(portal.keywords) do
        if kw == "barred door" then found = true; break end
    end
    h.assert_truthy(found, "keywords must include 'barred door'")
end)

---------------------------------------------------------------------------
-- DOOR SIZE CONSTRAINTS
---------------------------------------------------------------------------
suite("DOOR CONSTRAINTS: passage limits")

test("47. max_carry_size is 4", function()
    h.assert_eq(4, portal.max_carry_size, "max_carry_size")
end)

test("48. max_carry_weight is 50", function()
    h.assert_eq(50, portal.max_carry_weight, "max_carry_weight")
end)

test("49. player_max_size is 5", function()
    h.assert_eq(5, portal.player_max_size, "player_max_size")
end)

test("50. requires_hands_free is false", function()
    h.assert_eq(false, portal.requires_hands_free, "requires_hands_free")
end)

---------------------------------------------------------------------------
-- DESCRIPTION TESTS
---------------------------------------------------------------------------
suite("DOOR DESCRIPTIONS: narrative text")

test("51. Portal description mentions 'barred' or 'bar'", function()
    h.assert_truthy(portal.description:lower():find("bar"),
        "description must mention the bar mechanism")
end)

test("52. Portal on_examine mentions no keyhole", function()
    h.assert_truthy(portal.on_examine:lower():find("no keyhole"),
        "on_examine must state there is no keyhole on this side")
end)

test("53. Close transition has a message", function()
    local close_t = find_portal_transition("open", "unbarred")
    h.assert_truthy(close_t, "close transition must exist")
    h.assert_truthy(close_t.message, "close transition must have a message")
end)

test("54. Open transition has a message", function()
    local open_t = find_portal_transition("unbarred", "open")
    h.assert_truthy(open_t, "open transition must exist")
    h.assert_truthy(open_t.message, "open transition must have a message")
end)

test("55. Break transition has a message", function()
    local brk = find_portal_transition("barred", "broken")
    h.assert_truthy(brk, "break transition must exist")
    h.assert_truthy(brk.message, "break transition must have a message")
end)

---------------------------------------------------------------------------
-- NEGATIVE TESTS
---------------------------------------------------------------------------
suite("NEGATIVE: door cannot be seen through")

test("56. Door has no 'see_through' property", function()
    h.assert_nil(north.see_through,
        "door must not have see_through — it's solid oak")
end)

test("57. Portal is bidirectional (not one-way)", function()
    h.assert_truthy(portal.portal.bidirectional_id,
        "portal must have bidirectional_id — not one-way")
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
