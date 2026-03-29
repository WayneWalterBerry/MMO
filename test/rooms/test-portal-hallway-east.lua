-- test/rooms/test-portal-hallway-east.lua
-- TDD tests for the hallway → manor-east boundary door portal (#207).
-- Validates: portal object structure, locked/unlatched FSM states, pry transition,
-- boundary blocking in ALL states, room wiring, sensory properties.
--
-- Usage: lua test/rooms/test-portal-hallway-east.lua
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
local obj_dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP
local room_dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "rooms" .. SEP

local door_ok, door_def = pcall(dofile, obj_dir .. "hallway-east-door.lua")
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
        exits = { east = { portal = "hallway-east-door" } },
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
suite("HALLWAY-EAST DOOR: file loading")

test("east door portal file loads without error", function()
    h.assert_truthy(door_ok,
        "hallway-east-door.lua must load: " .. tostring(door_def))
end)

test("hallway room file loads without error", function()
    h.assert_truthy(hallway_ok,
        "hallway.lua must load: " .. tostring(hallway_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: object structure")

test("east door has template = 'portal'", function()
    eq("portal", door_def.template, "door template")
end)

test("east door has correct id", function()
    eq("hallway-east-door", door_def.id, "door id")
end)

test("east door has guid", function()
    h.assert_truthy(door_def.guid, "door must have a guid")
    h.assert_truthy(#door_def.guid > 0, "guid must not be empty")
end)

test("east door has 'portal' category", function()
    local found = false
    for _, c in ipairs(door_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'portal' category")
end)

test("east door is not portable", function()
    eq(false, door_def.portable, "door must not be portable")
end)

test("east door has material", function()
    h.assert_truthy(door_def.material, "door must have a material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: portal metadata")

test("east door has portal table", function()
    h.assert_truthy(type(door_def.portal) == "table",
        "door must have portal metadata table")
end)

test("east door portal target is 'manor-east'", function()
    eq("manor-east", door_def.portal.target, "door portal target")
end)

test("east door direction_hint is 'east'", function()
    eq("east", door_def.portal.direction_hint, "door direction hint")
end)

test("boundary portal has nil bidirectional_id", function()
    eq(nil, door_def.portal.bidirectional_id,
        "boundary portal must have nil bidirectional_id (no paired portal)")
end)

---------------------------------------------------------------------------
-- 4. FSM STATE — locked + unlatched (boundary portal)
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: FSM states")

test("east door initial_state is 'locked'", function()
    eq("locked", door_def.initial_state, "door initial_state")
end)

test("east door _state is 'locked'", function()
    eq("locked", door_def._state, "door _state")
end)

test("east door has 'locked' state definition", function()
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

test("locked blocked_message hints at mechanism", function()
    local msg = door_def.states.locked.blocked_message:lower()
    h.assert_truthy(
        msg:find("latch") or msg:find("inside") or msg:find("bar")
        or msg:find("blade") or msg:find("gap") or msg:find("slide"),
        "locked blocked_message should hint at the latch mechanism — got: " .. msg)
end)

test("east door has 'unlatched' state definition", function()
    h.assert_truthy(door_def.states.unlatched, "door must have 'unlatched' state")
end)

test("unlatched state is not traversable (boundary)", function()
    eq(false, door_def.states.unlatched.traversable,
        "unlatched state must not be traversable (manor-east doesn't exist)")
end)

test("unlatched state has blocked_message", function()
    h.assert_truthy(door_def.states.unlatched.blocked_message,
        "unlatched state must have blocked_message")
    h.assert_truthy(#door_def.states.unlatched.blocked_message > 0,
        "blocked_message must not be empty")
end)

test("unlatched blocked_message mentions collapse/rubble", function()
    local msg = door_def.states.unlatched.blocked_message:lower()
    h.assert_truthy(
        msg:find("collapse") or msg:find("rubble") or msg:find("block")
        or msg:find("cannot") or msg:find("masonry"),
        "unlatched blocked_message should explain physical blockage — got: " .. msg)
end)

---------------------------------------------------------------------------
-- 5. FSM TRANSITIONS — pry mechanic
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: FSM transitions")

test("east door has at least one transition", function()
    h.assert_truthy(door_def.transitions, "transitions table must exist")
    h.assert_truthy(#door_def.transitions > 0,
        "door must have at least one transition")
end)

test("locked → unlatched transition exists", function()
    local found = false
    for _, t in ipairs(door_def.transitions or {}) do
        if t.from == "locked" and t.to == "unlatched" then found = true; break end
    end
    h.assert_truthy(found, "must have locked → unlatched transition")
end)

test("locked → unlatched uses 'pry' verb", function()
    for _, t in ipairs(door_def.transitions or {}) do
        if t.from == "locked" and t.to == "unlatched" then
            eq("pry", t.verb, "transition verb must be 'pry'")
            break
        end
    end
end)

test("locked → unlatched requires cutting_edge tool", function()
    for _, t in ipairs(door_def.transitions or {}) do
        if t.from == "locked" and t.to == "unlatched" then
            eq("cutting_edge", t.requires_tool,
                "transition must require cutting_edge tool")
            break
        end
    end
end)

test("locked → unlatched has a message", function()
    for _, t in ipairs(door_def.transitions or {}) do
        if t.from == "locked" and t.to == "unlatched" then
            h.assert_truthy(t.message,
                "transition must have a message describing the action")
            h.assert_truthy(#t.message > 0, "message must not be empty")
            break
        end
    end
end)

---------------------------------------------------------------------------
-- 6. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: sensory properties")

test("east door has on_feel (P6 required)", function()
    h.assert_truthy(door_def.on_feel, "door must have on_feel")
    h.assert_truthy(#door_def.on_feel > 0, "on_feel must not be empty")
end)

test("east door has on_smell", function()
    h.assert_truthy(door_def.on_smell, "door should have on_smell")
end)

test("east door has on_listen", function()
    h.assert_truthy(door_def.on_listen, "door should have on_listen")
end)

test("east door has on_taste", function()
    h.assert_truthy(door_def.on_taste, "door should have on_taste")
end)

test("east door has on_examine", function()
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

test("unlatched state has on_feel", function()
    h.assert_truthy(door_def.states.unlatched.on_feel,
        "unlatched state should have on_feel")
end)

test("unlatched state has on_examine", function()
    h.assert_truthy(door_def.states.unlatched.on_examine,
        "unlatched state should have on_examine")
end)

test("unlatched state has description", function()
    h.assert_truthy(door_def.states.unlatched.description,
        "unlatched state should have description")
end)

test("unlatched state has room_presence", function()
    h.assert_truthy(door_def.states.unlatched.room_presence,
        "unlatched state should have room_presence")
end)

---------------------------------------------------------------------------
-- 7. MOVEMENT — boundary blocking (BOTH states)
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: movement blocking (locked)")

test("'go east' from hallway is blocked in locked state", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("hallway", ctx.player.location,
        "player should stay in hallway (locked boundary)")
end)

test("'east' direction handler is blocked in locked state", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["east"](ctx, "") end)
    eq("hallway", ctx.player.location,
        "'east' shorthand should be blocked by boundary portal")
end)

test("locked blocked message is shown when attempting passage", function()
    local ctx = make_door_ctx()
    local out = capture_output(function() handlers["east"](ctx, "") end)
    h.assert_truthy(out:lower():find("latch") or out:lower():find("lock")
        or out:lower():find("inside") or out:lower():find("bar")
        or out:lower():find("cannot") or out:lower():find("blade"),
        "should show latch-related blocking message — got: " .. out)
end)

suite("HALLWAY-EAST DOOR: movement blocking (unlatched)")

test("'go east' from hallway is blocked in unlatched state", function()
    local ctx = make_door_ctx({ door_state = "unlatched" })
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("hallway", ctx.player.location,
        "player should stay in hallway (unlatched but collapsed)")
end)

test("'east' direction is blocked in unlatched state", function()
    local ctx = make_door_ctx({ door_state = "unlatched" })
    local out = capture_output(function() handlers["east"](ctx, "") end)
    eq("hallway", ctx.player.location,
        "'east' should be blocked by rubble even when unlatched")
end)

test("unlatched blocked message mentions collapse", function()
    local ctx = make_door_ctx({ door_state = "unlatched" })
    local out = capture_output(function() handlers["east"](ctx, "") end)
    h.assert_truthy(out:lower():find("collapse") or out:lower():find("rubble")
        or out:lower():find("block") or out:lower():find("masonry"),
        "should show collapse message when unlatched — got: " .. out)
end)

test("portal target room 'manor-east' does not exist", function()
    local ctx = make_door_ctx()
    eq(nil, ctx.rooms["manor-east"],
        "manor-east room should not exist (boundary portal)")
end)

---------------------------------------------------------------------------
-- 8. ROOM WIRING — exits reference portal object
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: room wiring")

test("hallway exits.east uses portal reference", function()
    h.assert_truthy(hallway_def.exits, "hallway must have exits")
    h.assert_truthy(hallway_def.exits.east, "hallway must have an 'east' exit")
    eq("hallway-east-door", hallway_def.exits.east.portal,
        "hallway east exit must reference hallway-east-door portal")
end)

test("hallway instances include east door portal", function()
    local found = false
    for _, inst in ipairs(hallway_def.instances or {}) do
        if inst.id == "hallway-east-door" then found = true; break end
    end
    h.assert_truthy(found,
        "hallway instances must include hallway-east-door")
end)

test("hallway has no legacy inline east exit", function()
    local exit = hallway_def.exits.east
    h.assert_truthy(exit.portal, "east exit must use portal reference")
    eq(nil, exit.target,
        "east exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 9. KEYWORDS — door discoverable by multiple names
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: keywords")

test("east door has 'door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'door' keyword")
end)

test("east door has 'east door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "east door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'east door' keyword")
end)

test("east door has 'kitchen door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "kitchen door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'kitchen door' keyword")
end)

test("east door has 'oak door' keyword", function()
    local found = false
    for _, kw in ipairs(door_def.keywords or {}) do
        if kw:lower() == "oak door" then found = true; break end
    end
    h.assert_truthy(found, "door must have 'oak door' keyword")
end)

---------------------------------------------------------------------------
-- 10. DESCRIPTIONS — atmospheric boundary content
---------------------------------------------------------------------------
suite("HALLWAY-EAST DOOR: descriptions")

test("east door has name", function()
    h.assert_truthy(door_def.name, "door must have a name")
    h.assert_truthy(#door_def.name > 0, "name must not be empty")
end)

test("east door has description", function()
    h.assert_truthy(door_def.description, "door must have a description")
    h.assert_truthy(#door_def.description > 0, "description must not be empty")
end)

test("east door has room_presence", function()
    h.assert_truthy(door_def.room_presence, "door must have room_presence")
    h.assert_truthy(#door_def.room_presence > 0, "room_presence must not be empty")
end)

test("description mentions cooking/kitchen smells", function()
    local desc = door_def.description:lower()
    h.assert_truthy(desc:find("cook") or desc:find("kitchen") or desc:find("grease")
        or desc:find("herb") or desc:find("smoke"),
        "description should mention kitchen-related smells — got: " .. desc)
end)

test("on_smell is rich with kitchen atmosphere", function()
    local smell = door_def.on_smell:lower()
    h.assert_truthy(smell:find("cook") or smell:find("grease") or smell:find("herb")
        or smell:find("fat") or smell:find("smoke"),
        "on_smell should evoke kitchen atmosphere — got: " .. smell)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code)
