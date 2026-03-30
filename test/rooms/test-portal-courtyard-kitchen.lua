-- test/rooms/test-portal-courtyard-kitchen.lua
-- TDD tests for the courtyard → manor-kitchen boundary door portal (#208).
-- Validates: portal object structure, 4-state FSM (locked/closed/open/broken),
-- transitions (unlock, open, close, break x2), boundary blocking in ALL states,
-- room wiring, sensory properties, spawns.
--
-- Usage: lua test/rooms/test-portal-courtyard-kitchen.lua
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

-- Load verb handlers
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
-- Load actual object and room files
---------------------------------------------------------------------------
local obj_dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP
local room_dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "rooms" .. SEP

local door_ok, door_def = pcall(dofile, obj_dir .. "courtyard-kitchen-door.lua")
local courtyard_ok, courtyard_def = pcall(dofile, room_dir .. "courtyard.lua")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deep_copy(v) end
    return copy
end

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

local function make_door_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()

    local door = deep_copy(door_def)
    if opts.door_state then door._state = opts.door_state end

    reg:register(door.id, door)

    if opts.extra_objects then
        for _, obj in ipairs(opts.extra_objects) do
            reg:register(obj.id, obj)
        end
    end

    local courtyard = {
        id = "courtyard",
        name = "The Inner Courtyard",
        description = "A moonlit cobblestone courtyard.",
        contents = { door.id },
        exits = { east = { portal = "courtyard-kitchen-door" } },
    }

    local rooms = {
        courtyard = courtyard,
    }

    local player = {
        location = "courtyard",
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        max_health = 100,
        visited_rooms = { courtyard = true },
    }

    return {
        registry = reg,
        current_room = courtyard,
        rooms = rooms,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "go",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }, door
end

-- Helper: find a transition by from/to
local function find_transition(from, to)
    for _, t in ipairs(door_def.transitions or {}) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

-- Helper: find all transitions from a state
local function find_transitions_from(from)
    local result = {}
    for _, t in ipairs(door_def.transitions or {}) do
        if t.from == from then result[#result + 1] = t end
    end
    return result
end

---------------------------------------------------------------------------
-- 1. FILE LOADING
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: file loading")

test("kitchen door portal file loads without error", function()
    h.assert_truthy(door_ok,
        "courtyard-kitchen-door.lua must load: " .. tostring(door_def))
end)

test("courtyard room file loads without error", function()
    h.assert_truthy(courtyard_ok,
        "courtyard.lua must load: " .. tostring(courtyard_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: object structure")

test("kitchen door has template = 'portal'", function()
    eq("portal", door_def.template, "door template")
end)

test("kitchen door has correct id", function()
    eq("courtyard-kitchen-door", door_def.id, "door id")
end)

test("kitchen door has guid", function()
    h.assert_truthy(door_def.guid, "door must have a guid")
    h.assert_truthy(#door_def.guid > 0, "guid must not be empty")
end)

test("kitchen door has 'portal' category", function()
    local found = false
    for _, c in ipairs(door_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'portal' category")
end)

test("kitchen door is not portable", function()
    eq(false, door_def.portable, "door must not be portable")
end)

test("kitchen door has material", function()
    h.assert_truthy(door_def.material, "door must have a material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: portal metadata")

test("kitchen door has portal table", function()
    h.assert_truthy(type(door_def.portal) == "table",
        "door must have portal metadata table")
end)

test("kitchen door portal target is 'manor-kitchen'", function()
    eq("manor-kitchen", door_def.portal.target, "door portal target")
end)

test("kitchen door direction_hint is 'east'", function()
    eq("east", door_def.portal.direction_hint, "door direction hint")
end)

test("boundary portal has nil bidirectional_id", function()
    eq(nil, door_def.portal.bidirectional_id,
        "boundary portal must have nil bidirectional_id (no paired portal)")
end)

---------------------------------------------------------------------------
-- 4. FSM STATES — locked/closed/open/broken (all non-traversable boundary)
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: FSM states")

test("kitchen door initial_state is 'locked'", function()
    eq("locked", door_def.initial_state, "door initial_state")
end)

test("kitchen door _state is 'locked'", function()
    eq("locked", door_def._state, "door _state")
end)

test("door has 'locked' state", function()
    h.assert_truthy(door_def.states, "door must have states table")
    h.assert_truthy(door_def.states.locked, "door must have 'locked' state")
end)

test("door has 'closed' state", function()
    h.assert_truthy(door_def.states.closed, "door must have 'closed' state")
end)

test("door has 'open' state", function()
    h.assert_truthy(door_def.states.open, "door must have 'open' state")
end)

test("door has 'broken' state", function()
    h.assert_truthy(door_def.states.broken, "door must have 'broken' state")
end)

test("locked state is not traversable", function()
    eq(false, door_def.states.locked.traversable,
        "locked state must not be traversable")
end)

test("closed state is not traversable", function()
    eq(false, door_def.states.closed.traversable,
        "closed state must not be traversable (boundary)")
end)

test("open state is not traversable (boundary — kitchen doesn't exist)", function()
    eq(false, door_def.states.open.traversable,
        "open state must not be traversable (manor-kitchen doesn't exist yet)")
end)

test("broken state is not traversable (boundary — kitchen doesn't exist)", function()
    eq(false, door_def.states.broken.traversable,
        "broken state must not be traversable (manor-kitchen doesn't exist yet)")
end)

test("open state has blocked_message", function()
    h.assert_truthy(door_def.states.open.blocked_message,
        "open state must have blocked_message explaining rubble/collapse")
    h.assert_truthy(#door_def.states.open.blocked_message > 0,
        "blocked_message must not be empty")
end)

test("broken state has blocked_message", function()
    h.assert_truthy(door_def.states.broken.blocked_message,
        "broken state must have blocked_message explaining rubble/collapse")
    h.assert_truthy(#door_def.states.broken.blocked_message > 0,
        "blocked_message must not be empty")
end)

test("open blocked_message mentions collapse/masonry", function()
    local msg = door_def.states.open.blocked_message:lower()
    h.assert_truthy(
        msg:find("collapse") or msg:find("masonry") or msg:find("block")
        or msg:find("rubble") or msg:find("cannot"),
        "open blocked_message should explain physical blockage — got: " .. msg)
end)

test("broken blocked_message mentions collapse/masonry", function()
    local msg = door_def.states.broken.blocked_message:lower()
    h.assert_truthy(
        msg:find("collapse") or msg:find("masonry") or msg:find("block")
        or msg:find("rubble") or msg:find("cannot"),
        "broken blocked_message should explain physical blockage — got: " .. msg)
end)

---------------------------------------------------------------------------
-- 5. FSM TRANSITIONS — unlock/open/close/break mechanics
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: FSM transitions")

test("door has transitions", function()
    h.assert_truthy(door_def.transitions, "transitions table must exist")
    h.assert_truthy(#door_def.transitions > 0,
        "door must have transitions")
end)

test("locked → closed (unlock) transition exists", function()
    local t = find_transition("locked", "closed")
    h.assert_truthy(t, "must have locked → closed transition")
    eq("unlock", t.verb, "transition verb should be 'unlock'")
end)

test("locked → closed has message", function()
    local t = find_transition("locked", "closed")
    h.assert_truthy(t.message, "unlock transition must have a message")
    h.assert_truthy(#t.message > 0, "message must not be empty")
end)

test("locked → closed has mutate (keyword changes)", function()
    local t = find_transition("locked", "closed")
    h.assert_truthy(t.mutate, "unlock transition should have mutate fields")
end)

test("closed → open transition exists", function()
    local t = find_transition("closed", "open")
    h.assert_truthy(t, "must have closed → open transition")
    eq("open", t.verb, "transition verb should be 'open'")
end)

test("closed → open has message", function()
    local t = find_transition("closed", "open")
    h.assert_truthy(t.message, "open transition must have a message")
end)

test("open → closed (close) transition exists", function()
    local t = find_transition("open", "closed")
    h.assert_truthy(t, "must have open → closed transition")
    eq("close", t.verb, "transition verb should be 'close'")
end)

test("locked → broken (break) transition exists", function()
    local t = find_transition("locked", "broken")
    h.assert_truthy(t, "must have locked → broken transition")
    eq("break", t.verb, "transition verb should be 'break'")
end)

test("locked → broken requires strength", function()
    local t = find_transition("locked", "broken")
    h.assert_truthy(t.requires_strength,
        "breaking locked door should require strength")
end)

test("locked → broken spawns wood-splinters", function()
    local t = find_transition("locked", "broken")
    h.assert_truthy(t.spawns, "break transition should spawn debris")
    local found = false
    for _, s in ipairs(t.spawns or {}) do
        if s == "wood-splinters" then found = true; break end
    end
    h.assert_truthy(found, "break from locked should spawn wood-splinters")
end)

test("closed → broken (break) transition exists", function()
    local t = find_transition("closed", "broken")
    h.assert_truthy(t, "must have closed → broken transition")
    eq("break", t.verb, "transition verb should be 'break'")
end)

test("closed → broken spawns wood-splinters", function()
    local t = find_transition("closed", "broken")
    h.assert_truthy(t.spawns, "break transition should spawn debris")
    local found = false
    for _, s in ipairs(t.spawns or {}) do
        if s == "wood-splinters" then found = true; break end
    end
    h.assert_truthy(found, "break from closed should spawn wood-splinters")
end)

test("closed → broken requires less strength than locked → broken", function()
    local t_locked = find_transition("locked", "broken")
    local t_closed = find_transition("closed", "broken")
    h.assert_truthy(t_locked.requires_strength and t_closed.requires_strength,
        "both break transitions should require strength")
    h.assert_truthy(t_closed.requires_strength < t_locked.requires_strength,
        "breaking unlatched door should require less strength than locked — " ..
        "locked=" .. tostring(t_locked.requires_strength) ..
        " closed=" .. tostring(t_closed.requires_strength))
end)

---------------------------------------------------------------------------
-- 6. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: sensory properties")

test("kitchen door has on_feel (P6 required)", function()
    h.assert_truthy(door_def.on_feel, "door must have on_feel")
    h.assert_truthy(#door_def.on_feel > 0, "on_feel must not be empty")
end)

test("kitchen door has on_smell", function()
    h.assert_truthy(door_def.on_smell, "door should have on_smell")
end)

test("kitchen door has on_listen", function()
    h.assert_truthy(door_def.on_listen, "door should have on_listen")
end)

test("kitchen door has on_taste", function()
    h.assert_truthy(door_def.on_taste, "door should have on_taste")
end)

test("kitchen door has on_examine", function()
    h.assert_truthy(door_def.on_examine, "door should have on_examine")
end)

-- Verify sensory per state
test("locked state has on_feel", function()
    h.assert_truthy(door_def.states.locked.on_feel,
        "locked state should have on_feel")
end)

test("locked state has on_examine", function()
    h.assert_truthy(door_def.states.locked.on_examine,
        "locked state should have on_examine")
end)

test("closed state has on_feel", function()
    h.assert_truthy(door_def.states.closed.on_feel,
        "closed state should have on_feel")
end)

test("closed state has on_examine", function()
    h.assert_truthy(door_def.states.closed.on_examine,
        "closed state should have on_examine")
end)

test("open state has on_feel", function()
    h.assert_truthy(door_def.states.open.on_feel,
        "open state should have on_feel")
end)

test("open state has on_examine", function()
    h.assert_truthy(door_def.states.open.on_examine,
        "open state should have on_examine")
end)

test("broken state has on_feel", function()
    h.assert_truthy(door_def.states.broken.on_feel,
        "broken state should have on_feel")
end)

test("broken state has on_examine", function()
    h.assert_truthy(door_def.states.broken.on_examine,
        "broken state should have on_examine")
end)

-- State descriptions
test("locked state has description", function()
    h.assert_truthy(door_def.states.locked.description,
        "locked state should have description")
end)

test("closed state has description", function()
    h.assert_truthy(door_def.states.closed.description,
        "closed state should have description")
end)

test("open state has description", function()
    h.assert_truthy(door_def.states.open.description,
        "open state should have description")
end)

test("broken state has description", function()
    h.assert_truthy(door_def.states.broken.description,
        "broken state should have description")
end)

-- State room_presence
test("locked state has room_presence", function()
    h.assert_truthy(door_def.states.locked.room_presence,
        "locked state should have room_presence")
end)

test("closed state has room_presence", function()
    h.assert_truthy(door_def.states.closed.room_presence,
        "closed state should have room_presence")
end)

test("open state has room_presence", function()
    h.assert_truthy(door_def.states.open.room_presence,
        "open state should have room_presence")
end)

test("broken state has room_presence", function()
    h.assert_truthy(door_def.states.broken.room_presence,
        "broken state should have room_presence")
end)

---------------------------------------------------------------------------
-- 7. MOVEMENT — boundary blocking (ALL states)
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: movement blocking (locked)")

test("'go east' from courtyard is blocked in locked state", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("courtyard", ctx.player.location,
        "player should stay in courtyard (locked boundary)")
end)

test("'east' direction handler is blocked in locked state", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["east"](ctx, "") end)
    eq("courtyard", ctx.player.location,
        "'east' shorthand should be blocked by boundary portal")
end)

suite("COURTYARD-KITCHEN DOOR: movement blocking (closed)")

test("'go east' is blocked in closed state", function()
    local ctx = make_door_ctx({ door_state = "closed" })
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("courtyard", ctx.player.location,
        "player should stay in courtyard (closed, swollen shut)")
end)

suite("COURTYARD-KITCHEN DOOR: movement blocking (open)")

test("'go east' is blocked in open state (rubble)", function()
    local ctx = make_door_ctx({ door_state = "open" })
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("courtyard", ctx.player.location,
        "player should stay in courtyard (open but collapsed masonry)")
end)

test("open state shows rubble message", function()
    local ctx = make_door_ctx({ door_state = "open" })
    local out = capture_output(function() handlers["east"](ctx, "") end)
    h.assert_truthy(out:lower():find("collapse") or out:lower():find("masonry")
        or out:lower():find("block") or out:lower():find("rubble")
        or out:lower():find("cannot"),
        "should show collapse message in open state — got: " .. out)
end)

suite("COURTYARD-KITCHEN DOOR: movement blocking (broken)")

test("'go east' is blocked in broken state (rubble)", function()
    local ctx = make_door_ctx({ door_state = "broken" })
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("courtyard", ctx.player.location,
        "player should stay in courtyard (broken but collapsed masonry)")
end)

test("broken state shows rubble message", function()
    local ctx = make_door_ctx({ door_state = "broken" })
    local out = capture_output(function() handlers["east"](ctx, "") end)
    h.assert_truthy(out:lower():find("collapse") or out:lower():find("masonry")
        or out:lower():find("block") or out:lower():find("rubble")
        or out:lower():find("cannot"),
        "should show collapse message in broken state — got: " .. out)
end)

test("portal target room 'manor-kitchen' does not exist", function()
    local ctx = make_door_ctx()
    eq(nil, ctx.rooms["manor-kitchen"],
        "manor-kitchen room should not exist (boundary portal)")
end)

---------------------------------------------------------------------------
-- 8. ROOM WIRING — exits reference portal object
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: room wiring")

test("courtyard exits.east uses portal reference", function()
    h.assert_truthy(courtyard_def.exits, "courtyard must have exits")
    h.assert_truthy(courtyard_def.exits.east, "courtyard must have an 'east' exit")
    eq("courtyard-kitchen-door", courtyard_def.exits.east.portal,
        "courtyard east exit must reference courtyard-kitchen-door portal")
end)

test("courtyard instances include kitchen door portal", function()
    local found = false
    for _, inst in ipairs(courtyard_def.instances or {}) do
        if inst.id == "courtyard-kitchen-door" then found = true; break end
    end
    h.assert_truthy(found,
        "courtyard instances must include courtyard-kitchen-door")
end)

test("courtyard has no legacy inline east exit", function()
    local exit = courtyard_def.exits.east
    h.assert_truthy(exit.portal, "east exit must use portal reference")
    eq(nil, exit.target,
        "east exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 9. KEYWORDS — door discoverable by multiple names
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: keywords")

test("kitchen door has 'door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'door' keyword")
end)

test("kitchen door has 'wooden door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "wooden door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'wooden door' keyword")
end)

test("kitchen door has 'kitchen door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "kitchen door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'kitchen door' keyword")
end)

test("kitchen door has 'east door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "east door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'east door' keyword")
end)

test("kitchen door has 'warped door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "warped door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'warped door' keyword")
end)

---------------------------------------------------------------------------
-- 10. DESCRIPTIONS — atmospheric boundary content
---------------------------------------------------------------------------
suite("COURTYARD-KITCHEN DOOR: descriptions")

test("kitchen door has name", function()
    h.assert_truthy(door_def.name, "door must have a name")
    h.assert_truthy(#door_def.name > 0, "name must not be empty")
end)

test("kitchen door has description", function()
    h.assert_truthy(door_def.description, "door must have a description")
    h.assert_truthy(#door_def.description > 0, "description must not be empty")
end)

test("kitchen door has room_presence", function()
    h.assert_truthy(door_def.room_presence, "door must have room_presence")
    h.assert_truthy(#door_def.room_presence > 0, "room_presence must not be empty")
end)

test("description mentions rust/warped/damp", function()
    local desc = door_def.description:lower()
    h.assert_truthy(desc:find("rust") or desc:find("warp") or desc:find("damp")
        or desc:find("swollen"),
        "description should mention weathered/rusted condition — got: " .. desc)
end)

test("description mentions cooking smells", function()
    local desc = door_def.description:lower()
    h.assert_truthy(desc:find("cook") or desc:find("grease") or desc:find("fire"),
        "description should mention kitchen smells — got: " .. desc)
end)

test("on_smell evokes kitchen atmosphere", function()
    local smell = door_def.on_smell:lower()
    h.assert_truthy(smell:find("grease") or smell:find("cook") or smell:find("herb")
        or smell:find("ash"),
        "on_smell should evoke kitchen atmosphere — got: " .. smell)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code)
