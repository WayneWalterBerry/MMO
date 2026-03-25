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

test("2. North exit type is 'door'", function()
    h.assert_eq("door", north.type, "north exit type")
end)

test("3. Door starts locked", function()
    h.assert_eq(true, north.locked, "door must start locked")
end)

test("4. Door has no key_id (bar mechanism, not key lock)", function()
    h.assert_nil(north.key_id, "key_id must be nil — door is barred, not keyed")
end)

test("5. Door is breakable", function()
    h.assert_eq(true, north.breakable, "door must be breakable")
end)

test("6. Break difficulty is 3", function()
    h.assert_eq(3, north.break_difficulty, "break_difficulty must be 3")
end)

test("7. Door name is 'a heavy oak door'", function()
    h.assert_eq("a heavy oak door", north.name, "door name")
end)

test("8. Door starts closed (open = false)", function()
    h.assert_eq(false, north.open, "door must start closed")
end)

test("9. Door is not hidden", function()
    h.assert_eq(false, north.hidden, "door must not be hidden")
end)

test("10. Door is not broken initially", function()
    h.assert_eq(false, north.broken, "door must not start broken")
end)

test("11. Door target is 'hallway'", function()
    h.assert_eq("hallway", north.target, "north exit target room")
end)

test("12. Door has passage_id 'bedroom-hallway-door'", function()
    h.assert_eq("bedroom-hallway-door", north.passage_id, "passage_id")
end)

---------------------------------------------------------------------------
-- MUTATION STRUCTURE TESTS
---------------------------------------------------------------------------
suite("DOOR MUTATIONS: structure verification")

test("13. Mutations table exists", function()
    h.assert_truthy(north.mutations, "mutations table must exist")
end)

test("14. Has 'close' mutation", function()
    h.assert_truthy(north.mutations.close, "close mutation must exist")
end)

test("15. Has 'open' mutation", function()
    h.assert_truthy(north.mutations.open, "open mutation must exist")
end)

test("16. Has 'break' mutation", function()
    h.assert_truthy(north.mutations["break"], "break mutation must exist")
end)

test("17. Open mutation has a condition function", function()
    h.assert_eq("function", type(north.mutations.open.condition),
        "open mutation condition must be a function")
end)

test("18. Open condition rejects when locked", function()
    local locked_exit = copy_exit(north)
    locked_exit.locked = true
    local result = north.mutations.open.condition(locked_exit)
    h.assert_truthy(not result, "open condition must fail when door is locked")
end)

test("19. Open condition allows when unlocked", function()
    local unlocked_exit = copy_exit(north)
    unlocked_exit.locked = false
    local result = north.mutations.open.condition(unlocked_exit)
    h.assert_truthy(result, "open condition must pass when door is unlocked")
end)

test("20. Close mutation sets open = false", function()
    local becomes = north.mutations.close.becomes_exit
    h.assert_truthy(becomes, "close mutation must have becomes_exit")
    h.assert_eq(false, becomes.open, "close becomes_exit must set open = false")
end)

test("21. Open mutation sets open = true", function()
    local becomes = north.mutations.open.becomes_exit
    h.assert_truthy(becomes, "open mutation must have becomes_exit")
    h.assert_eq(true, becomes.open, "open becomes_exit must set open = true")
end)

test("22. Break mutation sets broken = true and open = true", function()
    local becomes = north.mutations["break"].becomes_exit
    h.assert_truthy(becomes, "break mutation must have becomes_exit")
    h.assert_eq(true, becomes.broken, "break becomes_exit must set broken = true")
    h.assert_eq(true, becomes.open, "break becomes_exit must set open = true")
end)

test("23. Break mutation sets locked = false", function()
    local becomes = north.mutations["break"].becomes_exit
    h.assert_eq(false, becomes.locked, "break becomes_exit must unlock the door")
end)

test("24. Break mutation changes type to 'hole in wall'", function()
    local becomes = north.mutations["break"].becomes_exit
    h.assert_eq("hole in wall", becomes.type, "broken door type")
end)

test("25. Break mutation spawns wood-splinters", function()
    local spawns = north.mutations["break"].spawns
    h.assert_truthy(spawns, "break mutation must have spawns")
    h.assert_eq("wood-splinters", spawns[1], "first spawn must be wood-splinters")
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

test("38. Window starts locked", function()
    h.assert_eq(true, window.locked, "window must start locked")
end)

test("39. Window target is 'courtyard'", function()
    h.assert_eq("courtyard", window.target, "window target")
end)

test("40. Down exit starts hidden", function()
    h.assert_eq(true, down.hidden, "trap door must start hidden")
end)

test("41. Down exit target is 'cellar'", function()
    h.assert_eq("cellar", down.target, "trap door target")
end)

test("42. Down exit is not locked", function()
    h.assert_eq(false, down.locked, "trap door must not be locked")
end)

test("43. Down exit type is 'trap_door'", function()
    h.assert_eq("trap_door", down.type, "trap door type")
end)

---------------------------------------------------------------------------
-- DOOR KEYWORDS TESTS
---------------------------------------------------------------------------
suite("DOOR KEYWORDS: exit matching")

test("44. North exit has keywords array", function()
    h.assert_truthy(north.keywords, "keywords must exist")
    h.assert_truthy(#north.keywords > 0, "keywords must not be empty")
end)

test("45. Keywords include 'door'", function()
    local found = false
    for _, kw in ipairs(north.keywords) do
        if kw:lower():find("door") then found = true; break end
    end
    h.assert_truthy(found, "keywords must include a 'door' keyword")
end)

test("46. Keywords include 'barred door'", function()
    local found = false
    for _, kw in ipairs(north.keywords) do
        if kw == "barred door" then found = true; break end
    end
    h.assert_truthy(found, "keywords must include 'barred door'")
end)

---------------------------------------------------------------------------
-- DOOR SIZE CONSTRAINTS
---------------------------------------------------------------------------
suite("DOOR CONSTRAINTS: passage limits")

test("47. max_carry_size is 4", function()
    h.assert_eq(4, north.max_carry_size, "max_carry_size")
end)

test("48. max_carry_weight is 50", function()
    h.assert_eq(50, north.max_carry_weight, "max_carry_weight")
end)

test("49. player_max_size is 5", function()
    h.assert_eq(5, north.player_max_size, "player_max_size")
end)

test("50. requires_hands_free is false", function()
    h.assert_eq(false, north.requires_hands_free, "requires_hands_free")
end)

---------------------------------------------------------------------------
-- DESCRIPTION TESTS
---------------------------------------------------------------------------
suite("DOOR DESCRIPTIONS: narrative text")

test("51. Door description mentions 'barred' or 'bar'", function()
    h.assert_truthy(north.description:lower():find("bar"),
        "description must mention the bar mechanism")
end)

test("52. Door description mentions no keyhole", function()
    h.assert_truthy(north.description:lower():find("no keyhole"),
        "description must state there is no keyhole on this side")
end)

test("53. Close mutation has a message", function()
    h.assert_truthy(north.mutations.close.message,
        "close mutation must have a message")
end)

test("54. Open mutation has a message", function()
    h.assert_truthy(north.mutations.open.message,
        "open mutation must have a message")
end)

test("55. Break mutation has a message", function()
    h.assert_truthy(north.mutations["break"].message,
        "break mutation must have a message")
end)

---------------------------------------------------------------------------
-- NEGATIVE TESTS
---------------------------------------------------------------------------
suite("NEGATIVE: door cannot be seen through")

test("56. Door has no 'see_through' property", function()
    h.assert_nil(north.see_through,
        "door must not have see_through — it's solid oak")
end)

test("57. Door is not one-way", function()
    h.assert_eq(false, north.one_way, "door must not be one-way")
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
