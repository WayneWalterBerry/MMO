-- test/objects/test-bedroom-door-object.lua
-- Tests for the bedroom-hallway-door-north portal object (replaces bedroom-door.lua).
-- Validates object structure, FSM states, sensory metadata, and portal linkage.
-- Must be run from repository root: lua test/objects/test-bedroom-door-object.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the portal object and start-room
---------------------------------------------------------------------------
local door = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/bedroom-hallway-door-north.lua")
local room = dofile(script_dir .. "/../../src/meta/worlds/manor/rooms/start-room.lua")

---------------------------------------------------------------------------
-- IDENTITY & STRUCTURE
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: identity")

test("1. Object loads without error", function()
    h.assert_truthy(door, "bedroom-hallway-door-north.lua must load")
end)

test("2. Object id is 'bedroom-hallway-door-north'", function()
    h.assert_eq("bedroom-hallway-door-north", door.id, "object id")
end)

test("3. Object has a valid GUID", function()
    h.assert_truthy(door.guid, "guid must exist")
    h.assert_truthy(door.guid:match("{.*}"), "guid must be in brace format")
end)

test("4. Template is 'portal'", function()
    h.assert_eq("portal", door.template, "template")
end)

test("5. Material is 'oak'", function()
    h.assert_eq("oak", door.material, "material")
end)

test("6. Size is appropriate", function()
    h.assert_truthy(door.size and door.size > 0, "size must be positive")
end)

test("7. Not portable", function()
    h.assert_eq(false, door.portable, "portable must be false")
end)

---------------------------------------------------------------------------
-- KEYWORDS
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: keywords")

test("8. Keywords table exists and is non-empty", function()
    h.assert_truthy(door.keywords, "keywords must exist")
    h.assert_truthy(#door.keywords > 0, "keywords must not be empty")
end)

local function has_keyword(kw)
    for _, k in ipairs(door.keywords) do
        if k == kw then return true end
    end
    return false
end

test("9. Keywords include 'door'", function()
    h.assert_truthy(has_keyword("door"), "must include 'door'")
end)

test("10. Keywords include 'barred door'", function()
    h.assert_truthy(has_keyword("barred door"), "must include 'barred door'")
end)

test("11. Keywords include 'heavy oak door'", function()
    h.assert_truthy(has_keyword("heavy oak door"), "must include 'heavy oak door'")
end)

test("12. Keywords include 'heavy oak door'", function()
    h.assert_truthy(has_keyword("heavy oak door"), "must include 'heavy oak door'")
end)

---------------------------------------------------------------------------
-- FSM STATE STRUCTURE
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: FSM states")

test("13. Initial state is 'barred'", function()
    h.assert_eq("barred", door.initial_state, "initial_state")
end)

test("14. _state matches initial_state", function()
    h.assert_eq(door.initial_state, door._state, "_state must match initial_state")
end)

test("15. States table exists", function()
    h.assert_truthy(door.states, "states table must exist")
end)

test("16. Has 'barred' state", function()
    h.assert_truthy(door.states.barred, "barred state must exist")
end)

test("17. Has 'unbarred' state", function()
    h.assert_truthy(door.states.unbarred, "unbarred state must exist")
end)

test("18. Has 'open' state", function()
    h.assert_truthy(door.states.open, "open state must exist")
end)

test("19. Has 'broken' state", function()
    h.assert_truthy(door.states.broken, "broken state must exist")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS: top-level
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: sensory descriptions (top-level)")

test("20. Has description", function()
    h.assert_truthy(door.description, "description must exist")
    h.assert_truthy(#door.description > 0, "description must not be empty")
end)

test("21. Description mentions 'barred'", function()
    h.assert_truthy(door.description:lower():find("barred"),
        "description must mention 'barred'")
end)

test("22. Has room_presence", function()
    h.assert_truthy(door.room_presence, "room_presence must exist")
end)

test("23. Has on_feel", function()
    h.assert_truthy(door.on_feel, "on_feel must exist")
end)

test("24. Has on_listen", function()
    h.assert_truthy(door.on_listen, "on_listen must exist")
end)

test("25. Has on_knock", function()
    h.assert_truthy(door.on_knock, "on_knock must exist")
end)

test("26. Has on_push", function()
    h.assert_truthy(door.on_push, "on_push must exist")
end)

test("27. Has on_pull", function()
    h.assert_truthy(door.on_pull, "on_pull must exist")
end)

test("28. Has on_smell", function()
    h.assert_truthy(door.on_smell, "on_smell must exist")
end)

test("29. Has on_examine", function()
    h.assert_truthy(door.on_examine, "on_examine must exist")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS: per-state
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: sensory descriptions (per-state)")

local sensory_fields = {"on_examine", "on_feel", "on_listen", "on_knock", "on_push", "on_pull", "on_smell"}

for _, state_name in ipairs({"barred", "unbarred", "open", "broken"}) do
    for _, field in ipairs(sensory_fields) do
        test("State '" .. state_name .. "' has " .. field, function()
            h.assert_truthy(door.states[state_name][field],
                state_name .. "." .. field .. " must exist")
        end)
    end
end

---------------------------------------------------------------------------
-- TRANSITIONS
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: transitions")

test("58. Transitions table exists and is non-empty", function()
    h.assert_truthy(door.transitions, "transitions must exist")
    h.assert_truthy(#door.transitions > 0, "transitions must not be empty")
end)

local function find_transition(from, to)
    for _, t in ipairs(door.transitions) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

test("59. Has barred -> unbarred transition", function()
    h.assert_truthy(find_transition("barred", "unbarred"),
        "barred -> unbarred transition must exist")
end)

test("60. Has unbarred -> open transition", function()
    h.assert_truthy(find_transition("unbarred", "open"),
        "unbarred -> open transition must exist")
end)

test("61. Has open -> unbarred (close) transition", function()
    h.assert_truthy(find_transition("open", "unbarred"),
        "open -> unbarred (close) transition must exist")
end)

test("62. Has barred -> broken (break) transition", function()
    h.assert_truthy(find_transition("barred", "broken"),
        "barred -> broken (break) transition must exist")
end)

test("63. Break transition has a message", function()
    local t = find_transition("barred", "broken")
    h.assert_truthy(t.message, "break transition must have a message")
end)

test("64. Open transition verb is 'open'", function()
    local t = find_transition("unbarred", "open")
    h.assert_eq("open", t.verb, "open transition verb")
end)

test("65. Close transition verb is 'close'", function()
    local t = find_transition("open", "unbarred")
    h.assert_eq("close", t.verb, "close transition verb")
end)

---------------------------------------------------------------------------
-- EXIT LINKAGE
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: exit linkage")

test("66. Has portal metadata", function()
    h.assert_truthy(door.portal, "portal table must exist")
end)

test("67. Portal target is 'hallway'", function()
    h.assert_eq("hallway", door.portal.target, "portal target")
end)

test("68. Has bidirectional_id for paired sync", function()
    h.assert_truthy(door.portal.bidirectional_id,
        "portal must have bidirectional_id")
end)

test("69. North exit uses portal ref in start-room", function()
    local north = room.exits and room.exits.north
    h.assert_truthy(north, "north exit must exist in room")
    h.assert_truthy(north.portal,
        "north exit must use portal reference (portal architecture)")
    h.assert_eq("bedroom-hallway-door-north", north.portal,
        "north exit portal must reference the bedroom-hallway portal object")
end)

---------------------------------------------------------------------------
-- ROOM PLACEMENT
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: room placement")

test("70. Bedroom door portal referenced in start-room north exit", function()
    local north = room.exits and room.exits.north
    h.assert_truthy(north and north.portal,
        "start-room north exit must reference the portal")
    h.assert_eq("bedroom-hallway-door-north", north.portal,
        "portal reference must match door id")
end)

test("71. Portal instances exist in start-room", function()
    local found = false
    for _, inst in ipairs(room.instances or {}) do
        if inst.id == "bedroom-hallway-door-north" or
           (inst.type_id and inst.type_id == door.guid:gsub("[{}]", "")) then
            found = true; break
        end
    end
    h.assert_truthy(found, "bedroom-hallway-door-north instance must exist in start-room")
end)

test("72. Portal is not portable (anchored in room)", function()
    h.assert_eq(false, door.portable, "portal must not be portable")
end)

---------------------------------------------------------------------------
-- CATEGORIES
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: categories")

test("73. Categories include 'architecture'", function()
    local found = false
    for _, c in ipairs(door.categories) do
        if c == "architecture" then found = true; break end
    end
    h.assert_truthy(found, "must include 'architecture'")
end)

test("74. Categories include 'portal'", function()
    local found = false
    for _, c in ipairs(door.categories) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "must include 'portal'")
end)

---------------------------------------------------------------------------
-- DESCRIPTION CONTENT
---------------------------------------------------------------------------
suite("BEDROOM DOOR OBJECT: description content")

test("75. Description matches spec text", function()
    h.assert_eq("A heavy oak door with iron bands. It appears to be barred from the other side.",
        door.description, "description must match spec")
end)

test("76. Name is 'a heavy oak door'", function()
    h.assert_eq("a heavy oak door", door.name, "name")
end)

test("77. on_listen mentions bar or creak", function()
    h.assert_truthy(door.on_listen:lower():find("bar") or door.on_listen:lower():find("creak"),
        "on_listen must mention the bar mechanism")
end)

test("78. on_knock mentions thud or knock", function()
    h.assert_truthy(door.on_knock:lower():find("thud") or door.on_knock:lower():find("knock"),
        "on_knock must describe the sound")
end)

test("79. on_push mentions bar or budge", function()
    h.assert_truthy(door.on_push:lower():find("bar") or door.on_push:lower():find("budge"),
        "on_push must reference the bar holding it")
end)

test("80. on_examine mentions no keyhole", function()
    h.assert_truthy(door.on_examine:lower():find("no keyhole"),
        "on_examine must mention there is no keyhole")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
