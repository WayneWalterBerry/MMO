-- test/rooms/test-portal-hallway-west.lua
-- TDD tests for the hallway → manor-west boundary door portal (#206).
-- Validates: portal object structure, locked FSM state, boundary message,
-- room wiring, movement blocking, sensory properties.
--
-- Usage: lua test/rooms/test-portal-hallway-west.lua
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

local door_ok, door_def = pcall(dofile, obj_dir .. "hallway-west-door.lua")
local hallway_ok, hallway_def = pcall(dofile, room_dir .. "hallway.lua")

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

    local hallway = {
        id = "hallway",
        name = "The Manor Hallway",
        description = "A warm, torchlit corridor.",
        contents = { door.id },
        exits = { west = { portal = "hallway-west-door" } },
    }

    local rooms = {
        hallway = hallway,
    }

    local player = {
        location = "hallway",
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        max_health = 100,
        visited_rooms = { hallway = true },
    }

    return {
        registry = reg,
        current_room = hallway,
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

---------------------------------------------------------------------------
-- 1. FILE LOADING
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: file loading")

test("west door portal file loads without error", function()
    h.assert_truthy(door_ok,
        "hallway-west-door.lua must load: " .. tostring(door_def))
end)

test("hallway room file loads without error", function()
    h.assert_truthy(hallway_ok,
        "hallway.lua must load: " .. tostring(hallway_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: object structure")

test("west door has template = 'portal'", function()
    eq("portal", door_def.template, "door template")
end)

test("west door has correct id", function()
    eq("hallway-west-door", door_def.id, "door id")
end)

test("west door has guid", function()
    h.assert_truthy(door_def.guid, "door must have a guid")
    h.assert_truthy(#door_def.guid > 0, "guid must not be empty")
end)

test("west door has 'portal' category", function()
    local found = false
    for _, c in ipairs(door_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'portal' category")
end)

test("west door is not portable", function()
    eq(false, door_def.portable, "door must not be portable")
end)

test("west door has material", function()
    h.assert_truthy(door_def.material, "door must have a material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: portal metadata")

test("west door has portal table", function()
    h.assert_truthy(type(door_def.portal) == "table",
        "door must have portal metadata table")
end)

test("west door portal target is 'manor-west'", function()
    eq("manor-west", door_def.portal.target, "door portal target")
end)

test("west door direction_hint is 'west'", function()
    eq("west", door_def.portal.direction_hint, "door direction hint")
end)

test("boundary portal has nil bidirectional_id", function()
    eq(nil, door_def.portal.bidirectional_id,
        "boundary portal must have nil bidirectional_id (no paired portal)")
end)

---------------------------------------------------------------------------
-- 4. FSM STATE — locked (boundary portal)
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: FSM state")

test("west door initial_state is 'locked'", function()
    eq("locked", door_def.initial_state, "door initial_state")
end)

test("west door _state is 'locked'", function()
    eq("locked", door_def._state, "door _state")
end)

test("west door has 'locked' state definition", function()
    h.assert_truthy(door_def.states, "door must have states table")
    h.assert_truthy(door_def.states.locked, "door must have 'locked' state")
end)

test("locked state is not traversable", function()
    eq(false, door_def.states.locked.traversable,
        "locked state must not be traversable")
end)

test("locked state has blocked_message", function()
    h.assert_truthy(door_def.states.locked.blocked_message,
        "locked state must have blocked_message")
    h.assert_truthy(#door_def.states.locked.blocked_message > 0,
        "blocked_message must not be empty")
end)

test("blocked_message mentions impassability", function()
    local msg = door_def.states.locked.blocked_message:lower()
    h.assert_truthy(
        msg:find("lock") or msg:find("cannot") or msg:find("can't")
        or msg:find("no key") or msg:find("firmly") or msg:find("won't"),
        "blocked_message should describe why passage is blocked — got: " .. msg)
end)

test("west door has no transitions (boundary — no unlock in Level 1)", function()
    local trans = door_def.transitions or {}
    eq(0, #trans,
        "boundary portal should have no transitions (manor-west doesn't exist yet)")
end)

---------------------------------------------------------------------------
-- 5. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: sensory properties")

test("west door has on_feel (P6 required)", function()
    h.assert_truthy(door_def.on_feel, "door must have on_feel")
    h.assert_truthy(#door_def.on_feel > 0, "on_feel must not be empty")
end)

test("west door has on_smell", function()
    h.assert_truthy(door_def.on_smell, "door should have on_smell")
end)

test("west door has on_listen", function()
    h.assert_truthy(door_def.on_listen, "door should have on_listen")
end)

test("west door has on_taste", function()
    h.assert_truthy(door_def.on_taste, "door should have on_taste")
end)

test("west door has on_examine", function()
    h.assert_truthy(door_def.on_examine, "door should have on_examine")
end)

test("locked state has on_feel (darkness sense per state)", function()
    h.assert_truthy(door_def.states.locked.on_feel,
        "locked state should have on_feel for darkness navigation")
end)

test("locked state has on_examine", function()
    h.assert_truthy(door_def.states.locked.on_examine,
        "locked state should have on_examine")
end)

test("locked state has description", function()
    h.assert_truthy(door_def.states.locked.description,
        "locked state should have description")
end)

test("locked state has room_presence", function()
    h.assert_truthy(door_def.states.locked.room_presence,
        "locked state should have room_presence")
end)

---------------------------------------------------------------------------
-- 6. MOVEMENT — boundary blocking
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: movement blocking")

test("'go west' from hallway is blocked by boundary portal", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["go"](ctx, "west") end)
    eq("hallway", ctx.player.location,
        "player should stay in hallway (locked boundary)")
end)

test("'west' direction handler is blocked", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["west"](ctx, "") end)
    eq("hallway", ctx.player.location,
        "'west' shorthand should be blocked by boundary portal")
end)

test("blocked message is shown when attempting passage", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["west"](ctx, "") end)
    h.assert_truthy(out:lower():find("lock") or out:lower():find("no key")
        or out:lower():find("cannot") or out:lower():find("can't")
        or out:lower():find("firmly") or out:lower():find("won't"),
        "should show blocking message — got: " .. out)
end)

test("'go door' via keyword is blocked", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["go"](ctx, "door") end)
    eq("hallway", ctx.player.location,
        "'go door' should be blocked by boundary portal")
end)

test("portal target room 'manor-west' does not exist", function()
    local ctx = make_door_ctx()
    eq(nil, ctx.rooms["manor-west"],
        "manor-west room should not exist (boundary portal)")
end)

---------------------------------------------------------------------------
-- 7. ROOM WIRING — exits reference portal object
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: room wiring")

test("hallway exits.west uses portal reference", function()
    h.assert_truthy(hallway_def.exits, "hallway must have exits")
    h.assert_truthy(hallway_def.exits.west, "hallway must have a 'west' exit")
    eq("hallway-west-door", hallway_def.exits.west.portal,
        "hallway west exit must reference hallway-west-door portal")
end)

test("hallway instances include west door portal", function()
    local found = false
    for _, inst in ipairs(hallway_def.instances or {}) do
        if inst.id == "hallway-west-door" then found = true; break end
    end
    h.assert_truthy(found,
        "hallway instances must include hallway-west-door")
end)

test("hallway has no legacy inline west exit", function()
    local exit = hallway_def.exits.west
    h.assert_truthy(exit.portal, "west exit must use portal reference")
    eq(nil, exit.target,
        "west exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 8. KEYWORDS — door discoverable by multiple names
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: keywords")

test("west door has 'door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'door' keyword")
end)

test("west door has 'west door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "west door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'west door' keyword")
end)

test("west door has 'oak door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "oak door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'oak door' keyword")
end)

test("west door has 'locked door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "locked door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'locked door' keyword")
end)

---------------------------------------------------------------------------
-- 9. DESCRIPTIONS — atmospheric boundary content
---------------------------------------------------------------------------
suite("HALLWAY-WEST DOOR: descriptions")

test("west door has name", function()
    h.assert_truthy(door_def.name, "door must have a name")
    h.assert_truthy(#door_def.name > 0, "name must not be empty")
end)

test("west door has description", function()
    h.assert_truthy(door_def.description, "door must have a description")
    h.assert_truthy(#door_def.description > 0, "description must not be empty")
end)

test("west door has room_presence", function()
    h.assert_truthy(door_def.room_presence, "door must have room_presence")
    h.assert_truthy(#door_def.room_presence > 0, "room_presence must not be empty")
end)

test("description mentions locked state", function()
    local desc = door_def.description:lower()
    h.assert_truthy(desc:find("lock") or desc:find("closed") or desc:find("shut"),
        "description should mention door being locked/closed — got: " .. desc)
end)

test("description hints at what lies beyond", function()
    local desc = door_def.description:lower()
    h.assert_truthy(desc:find("bookshel") or desc:find("study") or desc:find("room")
        or desc:find("beyond") or desc:find("keyhole"),
        "description should hint at what lies beyond the door — got: " .. desc)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code)
