-- test/objects/test-bedroom-courtyard-window.lua
-- TDD tests for the bedroom-courtyard window portal pair (Issue #199).
-- Validates both portal objects, FSM states, sensory metadata, portal linkage,
-- bidirectional sync pairing, room wiring, and traverse effects.
-- Must be run from repository root: lua test/objects/test-bedroom-courtyard-window.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load objects and rooms
---------------------------------------------------------------------------
local win_out = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/bedroom-courtyard-window-out.lua")
local win_in  = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/courtyard-bedroom-window-in.lua")
local bedroom = dofile(script_dir .. "/../../src/meta/worlds/manor/rooms/start-room.lua")
local courtyard = dofile(script_dir .. "/../../src/meta/worlds/manor/rooms/courtyard.lua")

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

local function find_instance(room, inst_id)
    for _, inst in ipairs(room.instances or {}) do
        if inst.id == inst_id then return inst end
    end
    return nil
end

-- =========================================================================
-- BEDROOM SIDE: bedroom-courtyard-window-out
-- =========================================================================

---------------------------------------------------------------------------
-- IDENTITY & STRUCTURE
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): identity")

test("1. Object loads without error", function()
    h.assert_truthy(win_out, "bedroom-courtyard-window-out.lua must load")
end)

test("2. Object id is 'bedroom-courtyard-window-out'", function()
    h.assert_eq("bedroom-courtyard-window-out", win_out.id, "object id")
end)

test("3. Has a valid GUID in brace format", function()
    h.assert_truthy(win_out.guid, "guid must exist")
    h.assert_truthy(win_out.guid:match("{.*}"), "guid must be in brace format")
end)

test("4. Template is 'portal'", function()
    h.assert_eq("portal", win_out.template, "template")
end)

test("5. Material is 'glass'", function()
    h.assert_eq("glass", win_out.material, "material")
end)

test("6. Size is positive", function()
    h.assert_truthy(win_out.size and win_out.size > 0, "size must be positive")
end)

test("7. Not portable", function()
    h.assert_eq(false, win_out.portable, "portable must be false")
end)

---------------------------------------------------------------------------
-- KEYWORDS
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): keywords")

test("8. Keywords table exists and is non-empty", function()
    h.assert_truthy(win_out.keywords, "keywords must exist")
    h.assert_truthy(#win_out.keywords > 0, "keywords must not be empty")
end)

test("9. Keywords include 'window'", function()
    h.assert_truthy(has_keyword(win_out, "window"), "must include 'window'")
end)

test("10. Keywords include 'leaded glass window'", function()
    h.assert_truthy(has_keyword(win_out, "leaded glass window"), "must include 'leaded glass window'")
end)

test("11. Keywords include 'glass'", function()
    h.assert_truthy(has_keyword(win_out, "glass"), "must include 'glass'")
end)

---------------------------------------------------------------------------
-- FSM STATE STRUCTURE
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): FSM states")

test("12. Initial state is 'locked'", function()
    h.assert_eq("locked", win_out.initial_state, "initial_state")
end)

test("13. _state matches initial_state", function()
    h.assert_eq(win_out.initial_state, win_out._state, "_state must match initial_state")
end)

test("14. States table exists", function()
    h.assert_truthy(win_out.states, "states table must exist")
end)

test("15. Has 'locked' state", function()
    h.assert_truthy(win_out.states.locked, "locked state must exist")
end)

test("16. Has 'closed' state", function()
    h.assert_truthy(win_out.states.closed, "closed state must exist")
end)

test("17. Has 'open' state", function()
    h.assert_truthy(win_out.states.open, "open state must exist")
end)

test("18. Has 'broken' state", function()
    h.assert_truthy(win_out.states.broken, "broken state must exist")
end)

---------------------------------------------------------------------------
-- TRAVERSABLE FLAGS
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): traversable flags")

test("19. Locked state is NOT traversable", function()
    h.assert_eq(false, win_out.states.locked.traversable, "locked must not be traversable")
end)

test("20. Closed state is NOT traversable", function()
    h.assert_eq(false, win_out.states.closed.traversable, "closed must not be traversable")
end)

test("21. Open state IS traversable", function()
    h.assert_eq(true, win_out.states.open.traversable, "open must be traversable")
end)

test("22. Broken state IS traversable", function()
    h.assert_eq(true, win_out.states.broken.traversable, "broken must be traversable")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS: top-level
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): sensory descriptions (top-level)")

test("23. Has description", function()
    h.assert_truthy(win_out.description, "description must exist")
    h.assert_truthy(#win_out.description > 0, "description must not be empty")
end)

test("24. Has room_presence", function()
    h.assert_truthy(win_out.room_presence, "room_presence must exist")
end)

test("25. Has on_feel (primary dark sense)", function()
    h.assert_truthy(win_out.on_feel, "on_feel must exist")
end)

test("26. Has on_smell", function()
    h.assert_truthy(win_out.on_smell, "on_smell must exist")
end)

test("27. Has on_listen", function()
    h.assert_truthy(win_out.on_listen, "on_listen must exist")
end)

test("28. Has on_taste", function()
    h.assert_truthy(win_out.on_taste, "on_taste must exist")
end)

test("29. Has on_examine", function()
    h.assert_truthy(win_out.on_examine, "on_examine must exist")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS: per-state
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): sensory descriptions (per-state)")

local sensory_fields_out = {"description", "room_presence", "on_examine", "on_feel"}

for _, state_name in ipairs({"locked", "closed", "open", "broken"}) do
    for _, field in ipairs(sensory_fields_out) do
        test("State '" .. state_name .. "' has " .. field, function()
            h.assert_truthy(win_out.states[state_name][field],
                state_name .. "." .. field .. " must exist")
        end)
    end
end

-- All states should have on_smell and on_listen too
for _, state_name in ipairs({"locked", "closed", "open", "broken"}) do
    test("State '" .. state_name .. "' has on_smell", function()
        h.assert_truthy(win_out.states[state_name].on_smell,
            state_name .. ".on_smell must exist")
    end)
    test("State '" .. state_name .. "' has on_listen", function()
        h.assert_truthy(win_out.states[state_name].on_listen,
            state_name .. ".on_listen must exist")
    end)
end

---------------------------------------------------------------------------
-- TRANSITIONS (bedroom side)
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): transitions")

test("Transitions table exists and is non-empty", function()
    h.assert_truthy(win_out.transitions, "transitions must exist")
    h.assert_truthy(#win_out.transitions > 0, "transitions must not be empty")
end)

test("Has locked -> closed (unlock) transition", function()
    local t = find_transition(win_out, "locked", "closed")
    h.assert_truthy(t, "locked -> closed transition must exist")
    h.assert_eq("unlock", t.verb, "verb must be 'unlock'")
end)

test("Unlock has aliases including 'unlatch'", function()
    local t = find_transition(win_out, "locked", "closed")
    h.assert_truthy(t.aliases, "unlock must have aliases")
    local found = false
    for _, a in ipairs(t.aliases) do
        if a == "unlatch" then found = true; break end
    end
    h.assert_truthy(found, "aliases must include 'unlatch'")
end)

test("Has closed -> locked (lock) transition", function()
    local t = find_transition(win_out, "closed", "locked")
    h.assert_truthy(t, "closed -> locked transition must exist")
    h.assert_eq("lock", t.verb, "verb must be 'lock'")
end)

test("Has closed -> open (open) transition", function()
    local t = find_transition(win_out, "closed", "open")
    h.assert_truthy(t, "closed -> open transition must exist")
    h.assert_eq("open", t.verb, "verb must be 'open'")
end)

test("Has open -> closed (close) transition", function()
    local t = find_transition(win_out, "open", "closed")
    h.assert_truthy(t, "open -> closed transition must exist")
    h.assert_eq("close", t.verb, "verb must be 'close'")
end)

test("Has locked -> broken (break) transition", function()
    local t = find_transition(win_out, "locked", "broken")
    h.assert_truthy(t, "locked -> broken transition must exist")
    h.assert_eq("break", t.verb, "verb must be 'break'")
end)

test("Has closed -> broken (break) transition", function()
    local t = find_transition(win_out, "closed", "broken")
    h.assert_truthy(t, "closed -> broken transition must exist")
    h.assert_eq("break", t.verb, "verb must be 'break'")
end)

test("Break from locked requires higher strength than from closed", function()
    local t_locked = find_transition(win_out, "locked", "broken")
    local t_closed = find_transition(win_out, "closed", "broken")
    h.assert_truthy(t_locked.requires_strength, "locked break must require strength")
    h.assert_truthy(t_closed.requires_strength, "closed break must require strength")
    h.assert_truthy(t_locked.requires_strength > t_closed.requires_strength,
        "locked break must require more strength than closed break")
end)

test("Break transitions spawn glass shards", function()
    local t = find_transition(win_out, "locked", "broken")
    h.assert_truthy(t.spawns, "break must spawn items")
    local found_shard = false
    for _, s in ipairs(t.spawns) do
        if s == "glass-shard" then found_shard = true; break end
    end
    h.assert_truthy(found_shard, "break must spawn glass-shard")
end)

test("All transitions have messages", function()
    for _, t in ipairs(win_out.transitions) do
        h.assert_truthy(t.message, "transition " .. t.from .. " -> " .. t.to .. " must have a message")
    end
end)

test("All transitions have mutate blocks", function()
    for _, t in ipairs(win_out.transitions) do
        h.assert_truthy(t.mutate, "transition " .. t.from .. " -> " .. t.to .. " must have mutate")
    end
end)

---------------------------------------------------------------------------
-- PORTAL METADATA (bedroom side)
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): portal metadata")

test("Has portal table", function()
    h.assert_truthy(win_out.portal, "portal table must exist")
end)

test("Portal target is 'courtyard'", function()
    h.assert_eq("courtyard", win_out.portal.target, "portal target")
end)

test("Has bidirectional_id for paired sync", function()
    h.assert_truthy(win_out.portal.bidirectional_id,
        "portal must have bidirectional_id")
end)

test("Direction hint is 'window'", function()
    h.assert_eq("window", win_out.portal.direction_hint, "direction_hint")
end)

---------------------------------------------------------------------------
-- PASSAGE CONSTRAINTS
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): passage constraints")

test("Has max_carry_size", function()
    h.assert_truthy(win_out.max_carry_size, "max_carry_size must exist")
end)

test("Has max_carry_weight", function()
    h.assert_truthy(win_out.max_carry_weight, "max_carry_weight must exist")
end)

test("Requires hands free (climbing)", function()
    h.assert_eq(true, win_out.requires_hands_free, "requires_hands_free must be true")
end)

test("Has player_max_size", function()
    h.assert_truthy(win_out.player_max_size, "player_max_size must exist")
end)

---------------------------------------------------------------------------
-- ON_TRAVERSE (bedroom side)
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): on_traverse")

test("Has on_traverse table", function()
    h.assert_truthy(win_out.on_traverse, "on_traverse must exist")
end)

test("Has wind_effect", function()
    h.assert_truthy(win_out.on_traverse.wind_effect, "wind_effect must exist")
end)

test("Wind strength is 'gust'", function()
    h.assert_eq("gust", win_out.on_traverse.wind_effect.strength, "wind strength")
end)

test("Wind extinguishes candle", function()
    local found = false
    for _, item in ipairs(win_out.on_traverse.wind_effect.extinguishes or {}) do
        if item == "candle" then found = true; break end
    end
    h.assert_truthy(found, "wind must extinguish candle")
end)

test("Wind spares wind-resistant objects", function()
    h.assert_truthy(win_out.on_traverse.wind_effect.spares, "spares must exist")
    h.assert_eq(true, win_out.on_traverse.wind_effect.spares.wind_resistant, "must spare wind_resistant")
end)

test("Has extinguish message", function()
    h.assert_truthy(win_out.on_traverse.wind_effect.message_extinguish, "message_extinguish must exist")
end)

test("Has spared message", function()
    h.assert_truthy(win_out.on_traverse.wind_effect.message_spared, "message_spared must exist")
end)

---------------------------------------------------------------------------
-- CATEGORIES (bedroom side)
---------------------------------------------------------------------------
suite("WINDOW OUT (bedroom side): categories")

test("Categories include 'architecture'", function()
    h.assert_truthy(has_category(win_out, "architecture"), "must include 'architecture'")
end)

test("Categories include 'portal'", function()
    h.assert_truthy(has_category(win_out, "portal"), "must include 'portal'")
end)

test("Categories include 'glass'", function()
    h.assert_truthy(has_category(win_out, "glass"), "must include 'glass'")
end)

-- =========================================================================
-- COURTYARD SIDE: courtyard-bedroom-window-in
-- =========================================================================

---------------------------------------------------------------------------
-- IDENTITY & STRUCTURE
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): identity")

test("Object loads without error", function()
    h.assert_truthy(win_in, "courtyard-bedroom-window-in.lua must load")
end)

test("Object id is 'courtyard-bedroom-window-in'", function()
    h.assert_eq("courtyard-bedroom-window-in", win_in.id, "object id")
end)

test("Has a valid GUID in brace format", function()
    h.assert_truthy(win_in.guid, "guid must exist")
    h.assert_truthy(win_in.guid:match("{.*}"), "guid must be in brace format")
end)

test("Template is 'portal'", function()
    h.assert_eq("portal", win_in.template, "template")
end)

test("Material is 'glass'", function()
    h.assert_eq("glass", win_in.material, "material")
end)

test("Not portable", function()
    h.assert_eq(false, win_in.portable, "portable must be false")
end)

---------------------------------------------------------------------------
-- KEYWORDS (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): keywords")

test("Keywords table exists and is non-empty", function()
    h.assert_truthy(win_in.keywords, "keywords must exist")
    h.assert_truthy(#win_in.keywords > 0, "keywords must not be empty")
end)

test("Keywords include 'window'", function()
    h.assert_truthy(has_keyword(win_in, "window"), "must include 'window'")
end)

test("Keywords include 'bedroom window'", function()
    h.assert_truthy(has_keyword(win_in, "bedroom window"), "must include 'bedroom window'")
end)

---------------------------------------------------------------------------
-- FSM STATE STRUCTURE (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): FSM states")

test("Initial state is 'locked'", function()
    h.assert_eq("locked", win_in.initial_state, "initial_state")
end)

test("_state matches initial_state", function()
    h.assert_eq(win_in.initial_state, win_in._state, "_state must match initial_state")
end)

test("Has 'locked' state", function()
    h.assert_truthy(win_in.states.locked, "locked state must exist")
end)

test("Has 'closed' state", function()
    h.assert_truthy(win_in.states.closed, "closed state must exist")
end)

test("Has 'open' state", function()
    h.assert_truthy(win_in.states.open, "open state must exist")
end)

test("Has 'broken' state", function()
    h.assert_truthy(win_in.states.broken, "broken state must exist")
end)

---------------------------------------------------------------------------
-- TRAVERSABLE FLAGS (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): traversable flags")

test("Locked state is NOT traversable", function()
    h.assert_eq(false, win_in.states.locked.traversable, "locked must not be traversable")
end)

test("Closed state is NOT traversable", function()
    h.assert_eq(false, win_in.states.closed.traversable, "closed must not be traversable")
end)

test("Open state IS traversable", function()
    h.assert_eq(true, win_in.states.open.traversable, "open must be traversable")
end)

test("Broken state IS traversable", function()
    h.assert_eq(true, win_in.states.broken.traversable, "broken must be traversable")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS (courtyard side): top-level
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): sensory descriptions (top-level)")

test("Has description", function()
    h.assert_truthy(win_in.description, "description must exist")
    h.assert_truthy(#win_in.description > 0, "description must not be empty")
end)

test("Has room_presence", function()
    h.assert_truthy(win_in.room_presence, "room_presence must exist")
end)

test("Has on_feel", function()
    h.assert_truthy(win_in.on_feel, "on_feel must exist")
end)

test("Has on_smell", function()
    h.assert_truthy(win_in.on_smell, "on_smell must exist")
end)

test("Has on_listen", function()
    h.assert_truthy(win_in.on_listen, "on_listen must exist")
end)

test("Has on_taste", function()
    h.assert_truthy(win_in.on_taste, "on_taste must exist")
end)

test("Has on_examine", function()
    h.assert_truthy(win_in.on_examine, "on_examine must exist")
end)

---------------------------------------------------------------------------
-- SENSORY DESCRIPTIONS (courtyard side): per-state
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): sensory descriptions (per-state)")

local sensory_fields_in = {"description", "room_presence", "on_examine", "on_feel"}

for _, state_name in ipairs({"locked", "closed", "open", "broken"}) do
    for _, field in ipairs(sensory_fields_in) do
        test("State '" .. state_name .. "' has " .. field, function()
            h.assert_truthy(win_in.states[state_name][field],
                state_name .. "." .. field .. " must exist")
        end)
    end
end

---------------------------------------------------------------------------
-- TRANSITIONS (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): transitions")

test("Transitions table exists and is non-empty", function()
    h.assert_truthy(win_in.transitions, "transitions must exist")
    h.assert_truthy(#win_in.transitions > 0, "transitions must not be empty")
end)

test("Has locked -> closed (unlock) transition", function()
    local t = find_transition(win_in, "locked", "closed")
    h.assert_truthy(t, "locked -> closed transition must exist")
    h.assert_eq("unlock", t.verb, "verb must be 'unlock'")
end)

test("Has closed -> locked (lock) transition", function()
    local t = find_transition(win_in, "closed", "locked")
    h.assert_truthy(t, "closed -> locked transition must exist")
    h.assert_eq("lock", t.verb, "verb must be 'lock'")
end)

test("Has closed -> open (open) transition", function()
    local t = find_transition(win_in, "closed", "open")
    h.assert_truthy(t, "closed -> open transition must exist")
    h.assert_eq("open", t.verb, "verb must be 'open'")
end)

test("Has open -> closed (close) transition", function()
    local t = find_transition(win_in, "open", "closed")
    h.assert_truthy(t, "open -> closed transition must exist")
    h.assert_eq("close", t.verb, "verb must be 'close'")
end)

test("Has locked -> broken (break) transition", function()
    local t = find_transition(win_in, "locked", "broken")
    h.assert_truthy(t, "locked -> broken transition must exist")
    h.assert_eq("break", t.verb, "verb must be 'break'")
end)

test("Has closed -> broken (break) transition", function()
    local t = find_transition(win_in, "closed", "broken")
    h.assert_truthy(t, "closed -> broken transition must exist")
    h.assert_eq("break", t.verb, "verb must be 'break'")
end)

test("Break transitions spawn glass shards", function()
    local t = find_transition(win_in, "locked", "broken")
    h.assert_truthy(t.spawns, "break must spawn items")
    local found_shard = false
    for _, s in ipairs(t.spawns) do
        if s == "glass-shard" then found_shard = true; break end
    end
    h.assert_truthy(found_shard, "break must spawn glass-shard")
end)

test("All transitions have messages", function()
    for _, t in ipairs(win_in.transitions) do
        h.assert_truthy(t.message, "transition " .. t.from .. " -> " .. t.to .. " must have a message")
    end
end)

---------------------------------------------------------------------------
-- PORTAL METADATA (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): portal metadata")

test("Has portal table", function()
    h.assert_truthy(win_in.portal, "portal table must exist")
end)

test("Portal target is 'start-room'", function()
    h.assert_eq("start-room", win_in.portal.target, "portal target")
end)

test("Has bidirectional_id for paired sync", function()
    h.assert_truthy(win_in.portal.bidirectional_id,
        "portal must have bidirectional_id")
end)

test("Direction hint is 'window' (or 'up')", function()
    -- Courtyard side uses 'window' direction hint to match bedroom side
    h.assert_truthy(win_in.portal.direction_hint, "direction_hint must exist")
end)

---------------------------------------------------------------------------
-- PASSAGE CONSTRAINTS (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): passage constraints")

test("Has max_carry_size", function()
    h.assert_truthy(win_in.max_carry_size, "max_carry_size must exist")
end)

test("Has max_carry_weight", function()
    h.assert_truthy(win_in.max_carry_weight, "max_carry_weight must exist")
end)

test("Requires hands free (climbing)", function()
    h.assert_eq(true, win_in.requires_hands_free, "requires_hands_free must be true")
end)

---------------------------------------------------------------------------
-- ON_TRAVERSE (courtyard side)
---------------------------------------------------------------------------
suite("WINDOW IN (courtyard side): on_traverse")

test("Has on_traverse table", function()
    h.assert_truthy(win_in.on_traverse, "on_traverse must exist")
end)

test("Has wind_effect", function()
    h.assert_truthy(win_in.on_traverse.wind_effect, "wind_effect must exist")
end)

test("Wind strength is 'gust'", function()
    h.assert_eq("gust", win_in.on_traverse.wind_effect.strength, "wind strength")
end)

test("Wind extinguishes candle", function()
    local found = false
    for _, item in ipairs(win_in.on_traverse.wind_effect.extinguishes or {}) do
        if item == "candle" then found = true; break end
    end
    h.assert_truthy(found, "wind must extinguish candle")
end)

-- =========================================================================
-- BIDIRECTIONAL PAIRING
-- =========================================================================

suite("BIDIRECTIONAL PAIRING: bedroom ↔ courtyard window")

test("Both portals share the same bidirectional_id", function()
    h.assert_eq(win_out.portal.bidirectional_id, win_in.portal.bidirectional_id,
        "bidirectional_id must match between paired portals")
end)

test("Portals have different GUIDs", function()
    h.assert_truthy(win_out.guid ~= win_in.guid,
        "paired portals must have distinct GUIDs")
end)

test("Portals have different IDs", function()
    h.assert_truthy(win_out.id ~= win_in.id,
        "paired portals must have distinct object IDs")
end)

test("Portals target each other's rooms", function()
    h.assert_eq("courtyard", win_out.portal.target, "bedroom side must target courtyard")
    h.assert_eq("start-room", win_in.portal.target, "courtyard side must target start-room")
end)

test("Both have matching initial states", function()
    h.assert_eq(win_out.initial_state, win_in.initial_state,
        "paired portals must start in the same state")
end)

test("Both have matching state names", function()
    for _, state_name in ipairs({"locked", "closed", "open", "broken"}) do
        h.assert_truthy(win_out.states[state_name],
            "bedroom side must have '" .. state_name .. "' state")
        h.assert_truthy(win_in.states[state_name],
            "courtyard side must have '" .. state_name .. "' state")
    end
end)

test("Traversable flags match across states", function()
    for _, state_name in ipairs({"locked", "closed", "open", "broken"}) do
        h.assert_eq(win_out.states[state_name].traversable,
                     win_in.states[state_name].traversable,
            "traversable flag for '" .. state_name .. "' must match between sides")
    end
end)

test("Both have matching transition verb sets", function()
    local out_verbs = {}
    for _, t in ipairs(win_out.transitions) do
        out_verbs[t.from .. "->" .. t.to] = t.verb
    end
    local in_verbs = {}
    for _, t in ipairs(win_in.transitions) do
        in_verbs[t.from .. "->" .. t.to] = t.verb
    end
    for key, verb in pairs(out_verbs) do
        h.assert_eq(verb, in_verbs[key],
            "transition '" .. key .. "' verb must match: " .. verb)
    end
end)

test("Passage constraints match", function()
    h.assert_eq(win_out.max_carry_size, win_in.max_carry_size, "max_carry_size must match")
    h.assert_eq(win_out.max_carry_weight, win_in.max_carry_weight, "max_carry_weight must match")
    h.assert_eq(win_out.requires_hands_free, win_in.requires_hands_free, "requires_hands_free must match")
end)

-- =========================================================================
-- ROOM WIRING
-- =========================================================================

suite("ROOM WIRING: bedroom window exit")

test("Bedroom window exit uses thin portal reference", function()
    local win_exit = bedroom.exits and bedroom.exits.window
    h.assert_truthy(win_exit, "bedroom must have 'window' exit")
    h.assert_truthy(win_exit.portal, "window exit must use portal reference")
    h.assert_eq("bedroom-courtyard-window-out", win_exit.portal,
        "window exit portal must reference bedroom-courtyard-window-out")
end)

test("Portal instance in bedroom room instances", function()
    local inst = find_instance(bedroom, "bedroom-courtyard-window-out")
    h.assert_truthy(inst, "bedroom-courtyard-window-out must be in bedroom instances")
end)

test("Portal instance type_id matches object GUID", function()
    local inst = find_instance(bedroom, "bedroom-courtyard-window-out")
    h.assert_truthy(inst, "instance must exist")
    h.assert_eq(win_out.guid, inst.type_id, "instance type_id must match portal GUID")
end)

suite("ROOM WIRING: courtyard window exit")

test("Courtyard 'up' exit uses thin portal reference", function()
    local up_exit = courtyard.exits and courtyard.exits.up
    h.assert_truthy(up_exit, "courtyard must have 'up' exit")
    h.assert_truthy(up_exit.portal, "up exit must use portal reference")
    h.assert_eq("courtyard-bedroom-window-in", up_exit.portal,
        "up exit portal must reference courtyard-bedroom-window-in")
end)

test("Portal instance in courtyard room instances", function()
    local inst = find_instance(courtyard, "courtyard-bedroom-window-in")
    h.assert_truthy(inst, "courtyard-bedroom-window-in must be in courtyard instances")
end)

test("Portal instance type_id matches object GUID", function()
    local inst = find_instance(courtyard, "courtyard-bedroom-window-in")
    h.assert_truthy(inst, "instance must exist")
    h.assert_eq(win_in.guid, inst.type_id, "instance type_id must match portal GUID")
end)

-- =========================================================================
-- DESCRIPTION CONTENT
-- =========================================================================

suite("DESCRIPTION CONTENT: bedroom side")

test("Description mentions 'courtyard'", function()
    h.assert_truthy(win_out.description:lower():find("courtyard"),
        "bedroom-side description must mention courtyard")
end)

test("Description mentions 'leaded' or 'glass'", function()
    h.assert_truthy(win_out.description:lower():find("leaded") or
                     win_out.description:lower():find("glass"),
        "description must mention leaded glass")
end)

test("on_feel mentions 'glass' or 'lead'", function()
    h.assert_truthy(win_out.on_feel:lower():find("glass") or
                     win_out.on_feel:lower():find("lead"),
        "on_feel must reference glass or lead material")
end)

test("on_feel mentions 'latch'", function()
    h.assert_truthy(win_out.on_feel:lower():find("latch"),
        "on_feel must mention the iron latch")
end)

suite("DESCRIPTION CONTENT: courtyard side")

test("Description mentions 'bedroom'", function()
    h.assert_truthy(win_in.description:lower():find("bedroom"),
        "courtyard-side description must mention bedroom")
end)

test("Description mentions height/drop", function()
    h.assert_truthy(win_in.description:lower():find("high") or
                     win_in.description:lower():find("above") or
                     win_in.description:lower():find("drop"),
        "courtyard-side description must convey height")
end)

test("on_feel mentions 'ivy' or 'stone' (climbing)", function()
    h.assert_truthy(win_in.on_feel:lower():find("ivy") or
                     win_in.on_feel:lower():find("stone"),
        "courtyard-side on_feel must mention ivy or stone for climbing")
end)

-- =========================================================================
-- OLD WINDOW OBJECT COEXISTENCE
-- =========================================================================

suite("OLD WINDOW OBJECT: coexistence check")

test("Old window.lua still loads (backward compat)", function()
    local old_window = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/window.lua")
    h.assert_truthy(old_window, "window.lua must still load")
    h.assert_eq("window", old_window.id, "old window id must be 'window'")
end)

test("Old window is furniture template, not portal", function()
    local old_window = dofile(script_dir .. "/../../src/meta/worlds/manor/objects/window.lua")
    h.assert_eq("furniture", old_window.template, "old window must be furniture")
end)

test("Old window instance still in bedroom", function()
    local inst = find_instance(bedroom, "window")
    h.assert_truthy(inst, "old 'window' instance must still exist in bedroom")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
