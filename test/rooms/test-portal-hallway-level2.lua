-- test/rooms/test-portal-hallway-level2.lua
-- TDD tests for the hallway → level 2 boundary staircase portal (#205).
-- Validates: portal object structure, blocked FSM state, boundary message,
-- room wiring, movement blocking, sensory properties.
--
-- Usage: lua test/rooms/test-portal-hallway-level2.lua
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

local stair_ok, stair_def = pcall(dofile, obj_dir .. "hallway-level2-stairs-up.lua")
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

local function make_stair_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()

    local stair = deep_copy(stair_def)
    if opts.stair_state then stair._state = opts.stair_state end

    reg:register(stair.id, stair)

    if opts.extra_objects then
        for _, obj in ipairs(opts.extra_objects) do
            reg:register(obj.id, obj)
        end
    end

    local hallway = {
        id = "hallway",
        name = "The Manor Hallway",
        description = "A warm, torchlit corridor.",
        contents = { stair.id },
        exits = { north = { portal = "hallway-level2-stairs-up" } },
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
    }, stair
end

---------------------------------------------------------------------------
-- 1. FILE LOADING
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: file loading")

test("staircase portal file loads without error", function()
    h.assert_truthy(stair_ok,
        "hallway-level2-stairs-up.lua must load: " .. tostring(stair_def))
end)

test("hallway room file loads without error", function()
    h.assert_truthy(hallway_ok,
        "hallway.lua must load: " .. tostring(hallway_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: object structure")

test("staircase has template = 'portal'", function()
    eq("portal", stair_def.template, "staircase template")
end)

test("staircase has correct id", function()
    eq("hallway-level2-stairs-up", stair_def.id, "staircase id")
end)

test("staircase has guid", function()
    h.assert_truthy(stair_def.guid, "staircase must have a guid")
    h.assert_truthy(#stair_def.guid > 0, "guid must not be empty")
end)

test("staircase has 'portal' category", function()
    local found = false
    for _, c in ipairs(stair_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "staircase must have 'portal' category")
end)

test("staircase is not portable", function()
    eq(false, stair_def.portable, "staircase must not be portable")
end)

test("staircase has material", function()
    h.assert_truthy(stair_def.material, "staircase must have a material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: portal metadata")

test("staircase has portal table", function()
    h.assert_truthy(type(stair_def.portal) == "table",
        "staircase must have portal metadata table")
end)

test("staircase portal target is 'level-2'", function()
    eq("level-2", stair_def.portal.target, "staircase portal target")
end)

test("staircase direction_hint is 'up'", function()
    eq("up", stair_def.portal.direction_hint, "staircase direction hint")
end)

test("boundary portal has nil bidirectional_id", function()
    eq(nil, stair_def.portal.bidirectional_id,
        "boundary portal must have nil bidirectional_id (no paired portal)")
end)

---------------------------------------------------------------------------
-- 4. FSM STATE — blocked (boundary portal)
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: FSM state")

test("staircase initial_state is 'blocked'", function()
    eq("blocked", stair_def.initial_state, "staircase initial_state")
end)

test("staircase _state is 'blocked'", function()
    eq("blocked", stair_def._state, "staircase _state")
end)

test("staircase has 'blocked' state definition", function()
    h.assert_truthy(stair_def.states, "staircase must have states table")
    h.assert_truthy(stair_def.states.blocked, "staircase must have 'blocked' state")
end)

test("blocked state is not traversable", function()
    eq(false, stair_def.states.blocked.traversable,
        "blocked state must not be traversable")
end)

test("blocked state has blocked_message", function()
    h.assert_truthy(stair_def.states.blocked.blocked_message,
        "blocked state must have blocked_message")
    h.assert_truthy(#stair_def.states.blocked.blocked_message > 0,
        "blocked_message must not be empty")
end)

test("blocked_message mentions impassability", function()
    local msg = stair_def.states.blocked.blocked_message:lower()
    h.assert_truthy(
        msg:find("block") or msg:find("cannot") or msg:find("can't")
        or msg:find("impassable") or msg:find("rubble") or msg:find("cannot pass"),
        "blocked_message should describe why passage is blocked — got: " .. msg)
end)

test("staircase has no transitions (boundary — no state changes)", function()
    local trans = stair_def.transitions or {}
    eq(0, #trans,
        "boundary portal should have no transitions (level 2 doesn't exist yet)")
end)

---------------------------------------------------------------------------
-- 5. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: sensory properties")

test("staircase has on_feel (P6 required)", function()
    h.assert_truthy(stair_def.on_feel, "staircase must have on_feel")
    h.assert_truthy(#stair_def.on_feel > 0, "on_feel must not be empty")
end)

test("staircase has on_smell", function()
    h.assert_truthy(stair_def.on_smell, "staircase should have on_smell")
end)

test("staircase has on_listen", function()
    h.assert_truthy(stair_def.on_listen, "staircase should have on_listen")
end)

test("staircase has on_taste", function()
    h.assert_truthy(stair_def.on_taste, "staircase should have on_taste")
end)

test("staircase has on_examine", function()
    h.assert_truthy(stair_def.on_examine, "staircase should have on_examine")
end)

test("blocked state has on_feel (darkness sense per state)", function()
    h.assert_truthy(stair_def.states.blocked.on_feel,
        "blocked state should have on_feel for darkness navigation")
end)

test("blocked state has on_examine", function()
    h.assert_truthy(stair_def.states.blocked.on_examine,
        "blocked state should have on_examine")
end)

test("blocked state has description", function()
    h.assert_truthy(stair_def.states.blocked.description,
        "blocked state should have description")
end)

test("blocked state has room_presence", function()
    h.assert_truthy(stair_def.states.blocked.room_presence,
        "blocked state should have room_presence")
end)

---------------------------------------------------------------------------
-- 6. MOVEMENT — boundary blocking
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: movement blocking")

test("'go north' from hallway is blocked by boundary portal", function()
    local ctx = make_stair_ctx()
    local out = capture_output(function() handlers["go"](ctx, "north") end)
    eq("hallway", ctx.player.location,
        "player should stay in hallway (blocked boundary)")
end)

test("'north' direction handler is blocked", function()
    local ctx = make_stair_ctx()
    local out = capture_output(function() handlers["north"](ctx, "") end)
    eq("hallway", ctx.player.location,
        "'north' shorthand should be blocked by boundary portal")
end)

test("blocked message is shown when attempting passage", function()
    local ctx = make_stair_ctx()
    local out = capture_output(function() handlers["north"](ctx, "") end)
    h.assert_truthy(out:lower():find("block") or out:lower():find("rubble")
        or out:lower():find("cannot") or out:lower():find("can't")
        or out:lower():find("impassable") or out:lower():find("cannot pass"),
        "should show blocking message — got: " .. out)
end)

test("'go staircase' via keyword is blocked", function()
    local ctx = make_stair_ctx()
    local out = capture_output(function() handlers["go"](ctx, "staircase") end)
    eq("hallway", ctx.player.location,
        "'go staircase' should be blocked by boundary portal")
end)

test("'go stairs' via keyword is blocked", function()
    local ctx = make_stair_ctx()
    local out = capture_output(function() handlers["go"](ctx, "stairs") end)
    eq("hallway", ctx.player.location,
        "'go stairs' should be blocked by boundary portal")
end)

test("portal target room 'level-2' does not exist", function()
    local ctx = make_stair_ctx()
    eq(nil, ctx.rooms["level-2"],
        "level-2 room should not exist (boundary portal)")
end)

---------------------------------------------------------------------------
-- 7. ROOM WIRING — exits reference portal object
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: room wiring")

test("hallway exits.north uses portal reference", function()
    h.assert_truthy(hallway_def.exits, "hallway must have exits")
    h.assert_truthy(hallway_def.exits.north, "hallway must have a 'north' exit")
    eq("hallway-level2-stairs-up", hallway_def.exits.north.portal,
        "hallway north exit must reference hallway-level2-stairs-up portal")
end)

test("hallway instances include staircase portal", function()
    local found = false
    for _, inst in ipairs(hallway_def.instances or {}) do
        if inst.id == "hallway-level2-stairs-up" then found = true; break end
    end
    h.assert_truthy(found,
        "hallway instances must include hallway-level2-stairs-up")
end)

test("hallway has no legacy inline north exit", function()
    local exit = hallway_def.exits.north
    h.assert_truthy(exit.portal, "north exit must use portal reference")
    eq(nil, exit.target,
        "north exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 8. KEYWORDS — staircase discoverable by multiple names
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: keywords")

test("staircase has 'staircase' keyword", function()
    local found = false
    for _, kw in ipairs(stair_def.keywords or {}) do
        if kw:lower() == "staircase" then found = true; break end
    end
    h.assert_truthy(found, "staircase must have 'staircase' keyword")
end)

test("staircase has 'stairs' keyword", function()
    local found = false
    for _, kw in ipairs(stair_def.keywords or {}) do
        if kw:lower() == "stairs" then found = true; break end
    end
    h.assert_truthy(found, "staircase must have 'stairs' keyword")
end)

test("staircase has 'grand staircase' keyword", function()
    local found = false
    for _, kw in ipairs(stair_def.keywords or {}) do
        if kw:lower() == "grand staircase" then found = true; break end
    end
    h.assert_truthy(found, "staircase must have 'grand staircase' keyword")
end)

test("staircase has 'up' keyword", function()
    local found = false
    for _, kw in ipairs(stair_def.keywords or {}) do
        if kw:lower() == "up" then found = true; break end
    end
    h.assert_truthy(found, "staircase must have 'up' keyword")
end)

---------------------------------------------------------------------------
-- 9. DESCRIPTIONS — atmospheric boundary content
---------------------------------------------------------------------------
suite("HALLWAY-LEVEL2 STAIRCASE: descriptions")

test("staircase has name", function()
    h.assert_truthy(stair_def.name, "staircase must have a name")
    h.assert_truthy(#stair_def.name > 0, "name must not be empty")
end)

test("staircase has description", function()
    h.assert_truthy(stair_def.description, "staircase must have a description")
    h.assert_truthy(#stair_def.description > 0, "description must not be empty")
end)

test("staircase has room_presence", function()
    h.assert_truthy(stair_def.room_presence, "staircase must have room_presence")
    h.assert_truthy(#stair_def.room_presence > 0, "room_presence must not be empty")
end)

test("description mentions the staircase going up", function()
    local desc = stair_def.description:lower()
    h.assert_truthy(desc:find("ascend") or desc:find("up") or desc:find("upper"),
        "description should mention ascending — got: " .. desc)
end)

test("description hints at blockage", function()
    local desc = stair_def.description:lower()
    h.assert_truthy(desc:find("rubble") or desc:find("block") or desc:find("collapse")
        or desc:find("impassable") or desc:find("choke"),
        "description should hint at why passage is blocked — got: " .. desc)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
h.summary()
