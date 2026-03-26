-- test/objects/test-cellar-storage-door.lua
-- TDD tests for the cellar-storage iron-bound door portal pair.
-- Validates: object structure, FSM states, sensory metadata, portal linkage,
-- bidirectional pairing, room exit wiring, and transition logic.
-- Issue: #201 — Portal Unification Phase 3
-- Must be run from repository root: lua test/objects/test-cellar-storage-door.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load portal objects and room files
---------------------------------------------------------------------------
local door_north = dofile(script_dir .. "/../../src/meta/objects/cellar-storage-door-north.lua")
local door_south = dofile(script_dir .. "/../../src/meta/objects/storage-cellar-door-south.lua")
local cellar = dofile(script_dir .. "/../../src/meta/rooms/cellar.lua")
local storage = dofile(script_dir .. "/../../src/meta/rooms/storage-cellar.lua")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function has_keyword(obj, kw)
    for _, k in ipairs(obj.keywords or {}) do
        if k == kw then return true end
    end
    return false
end

local function has_category(obj, cat)
    for _, c in ipairs(obj.categories or {}) do
        if c == cat then return true end
    end
    return false
end

local function find_transition(obj, from, to)
    for _, t in ipairs(obj.transitions or {}) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

local function find_instance(room, obj_id)
    for _, inst in ipairs(room.instances or {}) do
        if inst.id == obj_id then return inst end
    end
    return nil
end

-- =========================================================================
-- NORTH DOOR (cellar side) — cellar-storage-door-north
-- =========================================================================

---------------------------------------------------------------------------
-- IDENTITY & STRUCTURE
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: identity")

test("Object loads without error", function()
    h.assert_truthy(door_north, "cellar-storage-door-north.lua must load")
end)

test("Object id is 'cellar-storage-door-north'", function()
    h.assert_eq("cellar-storage-door-north", door_north.id, "object id")
end)

test("Has a valid GUID in brace format", function()
    h.assert_truthy(door_north.guid, "guid must exist")
    h.assert_truthy(door_north.guid:match("^{.*}$"), "guid must be in brace format")
end)

test("Template is 'portal'", function()
    h.assert_eq("portal", door_north.template, "template")
end)

test("Material is 'iron'", function()
    h.assert_eq("iron", door_north.material, "material")
end)

test("Size is positive", function()
    h.assert_truthy(door_north.size and door_north.size > 0, "size must be positive")
end)

test("Not portable", function()
    h.assert_eq(false, door_north.portable, "portal must not be portable")
end)

---------------------------------------------------------------------------
-- KEYWORDS
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: keywords")

test("Keywords table exists and is non-empty", function()
    h.assert_truthy(door_north.keywords, "keywords must exist")
    h.assert_truthy(#door_north.keywords > 0, "keywords must not be empty")
end)

test("Keywords include 'door'", function()
    h.assert_truthy(has_keyword(door_north, "door"), "must include 'door'")
end)

test("Keywords include 'iron door'", function()
    h.assert_truthy(has_keyword(door_north, "iron door"), "must include 'iron door'")
end)

test("Keywords include 'iron-bound door'", function()
    h.assert_truthy(has_keyword(door_north, "iron-bound door"), "must include 'iron-bound door'")
end)

test("Keywords include 'padlock'", function()
    h.assert_truthy(has_keyword(door_north, "padlock"), "must include 'padlock'")
end)

---------------------------------------------------------------------------
-- CATEGORIES
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: categories")

test("Categories include 'portal'", function()
    h.assert_truthy(has_category(door_north, "portal"), "must include 'portal'")
end)

test("Categories include 'architecture'", function()
    h.assert_truthy(has_category(door_north, "architecture"), "must include 'architecture'")
end)

test("Categories include 'iron'", function()
    h.assert_truthy(has_category(door_north, "iron"), "must include 'iron'")
end)

---------------------------------------------------------------------------
-- PORTAL METADATA
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: portal metadata")

test("Has portal table", function()
    h.assert_truthy(door_north.portal, "portal table must exist")
end)

test("Portal target is 'storage-cellar'", function()
    h.assert_eq("storage-cellar", door_north.portal.target, "portal target")
end)

test("Has bidirectional_id for paired sync", function()
    h.assert_truthy(door_north.portal.bidirectional_id, "must have bidirectional_id")
end)

test("Direction hint is 'north'", function()
    h.assert_eq("north", door_north.portal.direction_hint, "direction_hint")
end)

---------------------------------------------------------------------------
-- FSM STATES
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: FSM states")

test("Initial state is 'locked'", function()
    h.assert_eq("locked", door_north.initial_state, "initial_state")
end)

test("_state matches initial_state", function()
    h.assert_eq(door_north.initial_state, door_north._state, "_state must match initial_state")
end)

test("States table exists", function()
    h.assert_truthy(door_north.states, "states table must exist")
end)

test("Has 'locked' state", function()
    h.assert_truthy(door_north.states.locked, "locked state must exist")
end)

test("Has 'closed' state", function()
    h.assert_truthy(door_north.states.closed, "closed state must exist")
end)

test("Has 'open' state", function()
    h.assert_truthy(door_north.states.open, "open state must exist")
end)

test("Locked state is not traversable", function()
    h.assert_eq(false, door_north.states.locked.traversable, "locked must not be traversable")
end)

test("Closed state is not traversable", function()
    h.assert_eq(false, door_north.states.closed.traversable, "closed must not be traversable")
end)

test("Open state is traversable", function()
    h.assert_eq(true, door_north.states.open.traversable, "open must be traversable")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS: top-level
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: sensory (top-level)")

test("Has description", function()
    h.assert_truthy(door_north.description, "description must exist")
    h.assert_truthy(#door_north.description > 0, "description must not be empty")
end)

test("Has room_presence", function()
    h.assert_truthy(door_north.room_presence, "room_presence must exist")
end)

test("Has on_feel (P6 darkness)", function()
    h.assert_truthy(door_north.on_feel, "on_feel must exist")
end)

test("Has on_examine", function()
    h.assert_truthy(door_north.on_examine, "on_examine must exist")
end)

test("Has on_smell", function()
    h.assert_truthy(door_north.on_smell, "on_smell must exist")
end)

test("Has on_listen", function()
    h.assert_truthy(door_north.on_listen, "on_listen must exist")
end)

test("Has on_taste", function()
    h.assert_truthy(door_north.on_taste, "on_taste must exist")
end)

test("Description mentions padlock", function()
    h.assert_truthy(door_north.description:lower():find("padlock"),
        "description must mention padlock")
end)

test("on_feel mentions iron", function()
    h.assert_truthy(door_north.on_feel:lower():find("iron"),
        "on_feel must mention iron")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS: per-state
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: sensory (per-state)")

local sensory_fields = {"on_examine", "on_feel", "on_smell", "on_listen"}

for _, state_name in ipairs({"locked", "closed", "open"}) do
    for _, field in ipairs(sensory_fields) do
        test("State '" .. state_name .. "' has " .. field, function()
            h.assert_truthy(door_north.states[state_name][field],
                state_name .. "." .. field .. " must exist")
        end)
    end
end

---------------------------------------------------------------------------
-- TRANSITIONS
---------------------------------------------------------------------------
suite("CELLAR-STORAGE DOOR NORTH: transitions")

test("Transitions table exists and is non-empty", function()
    h.assert_truthy(door_north.transitions, "transitions must exist")
    h.assert_truthy(#door_north.transitions > 0, "transitions must not be empty")
end)

test("Has locked -> closed (unlock) transition", function()
    local t = find_transition(door_north, "locked", "closed")
    h.assert_truthy(t, "locked -> closed transition must exist")
end)

test("Unlock requires brass-key", function()
    local t = find_transition(door_north, "locked", "closed")
    h.assert_eq("brass-key", t.requires_tool, "unlock must require brass-key")
end)

test("Unlock verb is 'unlock'", function()
    local t = find_transition(door_north, "locked", "closed")
    h.assert_eq("unlock", t.verb, "unlock transition verb")
end)

test("Has closed -> open transition", function()
    local t = find_transition(door_north, "closed", "open")
    h.assert_truthy(t, "closed -> open transition must exist")
end)

test("Open verb is 'open'", function()
    local t = find_transition(door_north, "closed", "open")
    h.assert_eq("open", t.verb, "open transition verb")
end)

test("Has open -> closed (close) transition", function()
    local t = find_transition(door_north, "open", "closed")
    h.assert_truthy(t, "open -> closed transition must exist")
end)

test("Close verb is 'close'", function()
    local t = find_transition(door_north, "open", "closed")
    h.assert_eq("close", t.verb, "close transition verb")
end)

test("Has closed -> locked (lock) transition", function()
    local t = find_transition(door_north, "closed", "locked")
    h.assert_truthy(t, "closed -> locked transition must exist")
end)

test("Lock requires brass-key", function()
    local t = find_transition(door_north, "closed", "locked")
    h.assert_eq("brass-key", t.requires_tool, "lock must require brass-key")
end)

test("All transitions have messages", function()
    for _, t in ipairs(door_north.transitions) do
        h.assert_truthy(t.message, t.from .. " -> " .. t.to .. " must have a message")
    end
end)

-- =========================================================================
-- SOUTH DOOR (storage side) — storage-cellar-door-south
-- =========================================================================

---------------------------------------------------------------------------
-- IDENTITY & STRUCTURE
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: identity")

test("Object loads without error", function()
    h.assert_truthy(door_south, "storage-cellar-door-south.lua must load")
end)

test("Object id is 'storage-cellar-door-south'", function()
    h.assert_eq("storage-cellar-door-south", door_south.id, "object id")
end)

test("Has a valid GUID in brace format", function()
    h.assert_truthy(door_south.guid, "guid must exist")
    h.assert_truthy(door_south.guid:match("^{.*}$"), "guid must be in brace format")
end)

test("Template is 'portal'", function()
    h.assert_eq("portal", door_south.template, "template")
end)

test("Material is 'iron'", function()
    h.assert_eq("iron", door_south.material, "material")
end)

test("Not portable", function()
    h.assert_eq(false, door_south.portable, "portal must not be portable")
end)

---------------------------------------------------------------------------
-- KEYWORDS
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: keywords")

test("Keywords include 'door'", function()
    h.assert_truthy(has_keyword(door_south, "door"), "must include 'door'")
end)

test("Keywords include 'iron door'", function()
    h.assert_truthy(has_keyword(door_south, "iron door"), "must include 'iron door'")
end)

test("Keywords include 'iron-bound door'", function()
    h.assert_truthy(has_keyword(door_south, "iron-bound door"), "must include 'iron-bound door'")
end)

---------------------------------------------------------------------------
-- CATEGORIES
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: categories")

test("Categories include 'portal'", function()
    h.assert_truthy(has_category(door_south, "portal"), "must include 'portal'")
end)

test("Categories include 'architecture'", function()
    h.assert_truthy(has_category(door_south, "architecture"), "must include 'architecture'")
end)

---------------------------------------------------------------------------
-- PORTAL METADATA
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: portal metadata")

test("Has portal table", function()
    h.assert_truthy(door_south.portal, "portal table must exist")
end)

test("Portal target is 'cellar'", function()
    h.assert_eq("cellar", door_south.portal.target, "portal target")
end)

test("Has bidirectional_id for paired sync", function()
    h.assert_truthy(door_south.portal.bidirectional_id, "must have bidirectional_id")
end)

test("Direction hint is 'south'", function()
    h.assert_eq("south", door_south.portal.direction_hint, "direction_hint")
end)

---------------------------------------------------------------------------
-- FSM STATES
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: FSM states")

test("Initial state is 'locked'", function()
    h.assert_eq("locked", door_south.initial_state, "initial_state")
end)

test("_state matches initial_state", function()
    h.assert_eq(door_south.initial_state, door_south._state, "_state must match initial_state")
end)

test("Has 'locked' state", function()
    h.assert_truthy(door_south.states.locked, "locked state must exist")
end)

test("Has 'closed' state", function()
    h.assert_truthy(door_south.states.closed, "closed state must exist")
end)

test("Has 'open' state", function()
    h.assert_truthy(door_south.states.open, "open state must exist")
end)

test("Locked state is not traversable", function()
    h.assert_eq(false, door_south.states.locked.traversable, "locked must not be traversable")
end)

test("Closed state is not traversable", function()
    h.assert_eq(false, door_south.states.closed.traversable, "closed must not be traversable")
end)

test("Open state is traversable", function()
    h.assert_eq(true, door_south.states.open.traversable, "open must be traversable")
end)

---------------------------------------------------------------------------
-- SENSORY: top-level
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: sensory (top-level)")

test("Has description", function()
    h.assert_truthy(door_south.description, "description must exist")
end)

test("Has room_presence", function()
    h.assert_truthy(door_south.room_presence, "room_presence must exist")
end)

test("Has on_feel (P6 darkness)", function()
    h.assert_truthy(door_south.on_feel, "on_feel must exist")
end)

test("Has on_examine", function()
    h.assert_truthy(door_south.on_examine, "on_examine must exist")
end)

test("Has on_smell", function()
    h.assert_truthy(door_south.on_smell, "on_smell must exist")
end)

test("Has on_listen", function()
    h.assert_truthy(door_south.on_listen, "on_listen must exist")
end)

test("on_examine mentions no lock from storage side", function()
    h.assert_truthy(door_south.on_examine:lower():find("no lock")
        or door_south.on_examine:lower():find("cellar side"),
        "on_examine must reference the padlock being on the other side")
end)

---------------------------------------------------------------------------
-- SENSORY: per-state
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: sensory (per-state)")

for _, state_name in ipairs({"locked", "closed", "open"}) do
    for _, field in ipairs(sensory_fields) do
        test("State '" .. state_name .. "' has " .. field, function()
            h.assert_truthy(door_south.states[state_name][field],
                state_name .. "." .. field .. " must exist")
        end)
    end
end

---------------------------------------------------------------------------
-- TRANSITIONS
---------------------------------------------------------------------------
suite("STORAGE-CELLAR DOOR SOUTH: transitions")

test("Transitions table exists and is non-empty", function()
    h.assert_truthy(door_south.transitions, "transitions must exist")
    h.assert_truthy(#door_south.transitions > 0, "transitions must not be empty")
end)

test("Has locked -> closed (unlock) transition", function()
    local t = find_transition(door_south, "locked", "closed")
    h.assert_truthy(t, "locked -> closed transition must exist")
end)

test("Storage side unlock does NOT require brass-key", function()
    local t = find_transition(door_south, "locked", "closed")
    h.assert_eq(nil, t.requires_tool, "storage side unlock should not require key (padlock is on cellar face)")
end)

test("Has closed -> open transition", function()
    h.assert_truthy(find_transition(door_south, "closed", "open"), "closed -> open must exist")
end)

test("Has open -> closed transition", function()
    h.assert_truthy(find_transition(door_south, "open", "closed"), "open -> closed must exist")
end)

test("Has closed -> locked transition", function()
    h.assert_truthy(find_transition(door_south, "closed", "locked"), "closed -> locked must exist")
end)

test("Storage side lock does NOT require brass-key", function()
    local t = find_transition(door_south, "closed", "locked")
    h.assert_eq(nil, t.requires_tool, "storage side lock should not require key")
end)

test("All transitions have messages", function()
    for _, t in ipairs(door_south.transitions) do
        h.assert_truthy(t.message, t.from .. " -> " .. t.to .. " must have a message")
    end
end)

-- =========================================================================
-- BIDIRECTIONAL PAIRING
-- =========================================================================
suite("CELLAR-STORAGE DOOR: bidirectional pairing")

test("Both portals share the same bidirectional_id", function()
    h.assert_eq(door_north.portal.bidirectional_id,
        door_south.portal.bidirectional_id,
        "bidirectional_id must match between paired portals")
end)

test("North portal targets storage-cellar", function()
    h.assert_eq("storage-cellar", door_north.portal.target, "north targets storage-cellar")
end)

test("South portal targets cellar", function()
    h.assert_eq("cellar", door_south.portal.target, "south targets cellar")
end)

test("Direction hints are complementary (north/south)", function()
    h.assert_eq("north", door_north.portal.direction_hint, "north door hint")
    h.assert_eq("south", door_south.portal.direction_hint, "south door hint")
end)

test("Both portals have the same initial_state", function()
    h.assert_eq(door_north.initial_state, door_south.initial_state,
        "paired portals must start in the same state")
end)

test("Both portals have matching state sets", function()
    for state_name, _ in pairs(door_north.states) do
        h.assert_truthy(door_south.states[state_name],
            "south door must also have '" .. state_name .. "' state")
    end
    for state_name, _ in pairs(door_south.states) do
        h.assert_truthy(door_north.states[state_name],
            "north door must also have '" .. state_name .. "' state")
    end
end)

test("Traversability matches across paired states", function()
    for state_name, state in pairs(door_north.states) do
        h.assert_eq(state.traversable, door_south.states[state_name].traversable,
            "traversable must match for state '" .. state_name .. "'")
    end
end)

test("GUIDs are different (separate objects)", function()
    h.assert_truthy(door_north.guid ~= door_south.guid,
        "paired portals must have different GUIDs")
end)

test("IDs are different (separate objects)", function()
    h.assert_truthy(door_north.id ~= door_south.id,
        "paired portals must have different IDs")
end)

-- =========================================================================
-- ROOM EXIT WIRING
-- =========================================================================
suite("CELLAR-STORAGE DOOR: room exit wiring")

test("Cellar north exit uses thin portal reference", function()
    local north = cellar.exits and cellar.exits.north
    h.assert_truthy(north, "cellar must have north exit")
    h.assert_truthy(north.portal, "cellar north exit must use portal reference")
end)

test("Cellar north exit references cellar-storage-door-north", function()
    h.assert_eq("cellar-storage-door-north", cellar.exits.north.portal,
        "cellar north exit portal must reference the correct object")
end)

test("Cellar north exit has NO inline target (portal replaces it)", function()
    h.assert_eq(nil, cellar.exits.north.target,
        "cellar north exit must not have inline target")
end)

test("Storage-cellar south exit uses thin portal reference", function()
    local south = storage.exits and storage.exits.south
    h.assert_truthy(south, "storage-cellar must have south exit")
    h.assert_truthy(south.portal, "storage-cellar south exit must use portal reference")
end)

test("Storage-cellar south exit references storage-cellar-door-south", function()
    h.assert_eq("storage-cellar-door-south", storage.exits.south.portal,
        "storage-cellar south exit portal must reference the correct object")
end)

test("Storage-cellar south exit has NO inline target (portal replaces it)", function()
    h.assert_eq(nil, storage.exits.south.target,
        "storage-cellar south exit must not have inline target")
end)

-- =========================================================================
-- ROOM INSTANCES
-- =========================================================================
suite("CELLAR-STORAGE DOOR: room instances")

test("Cellar has cellar-storage-door-north instance", function()
    local inst = find_instance(cellar, "cellar-storage-door-north")
    h.assert_truthy(inst, "cellar must include cellar-storage-door-north in instances")
end)

test("Storage-cellar has storage-cellar-door-south instance", function()
    local inst = find_instance(storage, "storage-cellar-door-south")
    h.assert_truthy(inst, "storage-cellar must include storage-cellar-door-south in instances")
end)

test("Cellar instance references correct type_id (GUID)", function()
    local inst = find_instance(cellar, "cellar-storage-door-north")
    h.assert_truthy(inst.type_id, "instance must have type_id")
    h.assert_eq(door_north.guid, inst.type_id, "type_id must match door's GUID")
end)

test("Storage instance references correct type_id (GUID)", function()
    local inst = find_instance(storage, "storage-cellar-door-south")
    h.assert_truthy(inst.type_id, "instance must have type_id")
    h.assert_eq(door_south.guid, inst.type_id, "type_id must match door's GUID")
end)

-- =========================================================================
-- ASYMMETRIC KEY REQUIREMENT
-- =========================================================================
suite("CELLAR-STORAGE DOOR: asymmetric key requirement")

test("Cellar side (north) unlock requires brass-key", function()
    local t = find_transition(door_north, "locked", "closed")
    h.assert_eq("brass-key", t.requires_tool, "cellar side unlock needs brass-key")
end)

test("Cellar side (north) lock requires brass-key", function()
    local t = find_transition(door_north, "closed", "locked")
    h.assert_eq("brass-key", t.requires_tool, "cellar side lock needs brass-key")
end)

test("Storage side (south) unlock does NOT require key", function()
    local t = find_transition(door_south, "locked", "closed")
    h.assert_eq(nil, t.requires_tool, "storage side has no key requirement for unlock")
end)

test("Storage side (south) lock does NOT require key", function()
    local t = find_transition(door_south, "closed", "locked")
    h.assert_eq(nil, t.requires_tool, "storage side has no key requirement for lock")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
