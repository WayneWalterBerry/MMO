-- test/rooms/test-portal-deep-cellar-hallway.lua
-- TDD tests for the deep cellar ↔ hallway stairway portal pair (#203).
-- Validates: paired portal objects, always-open stairway, bidirectional sync,
-- wind traverse effects, room wiring, movement, sensory.
--
-- Usage: lua test/rooms/test-portal-deep-cellar-hallway.lua
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
local fsm_mod = require("engine.fsm")

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
-- Load actual portal object files
---------------------------------------------------------------------------
local obj_dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP
local room_dir = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "rooms" .. SEP

local down_ok, portal_down_def = pcall(dofile, obj_dir .. "hallway-deep-cellar-stairs-down.lua")
local up_ok, portal_up_def = pcall(dofile, obj_dir .. "deep-cellar-hallway-stairs-up.lua")
local hallway_ok, hallway_def = pcall(dofile, room_dir .. "hallway.lua")
local deep_cellar_ok, deep_cellar_def = pcall(dofile, room_dir .. "deep-cellar.lua")

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

local function make_stairway_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()

    local pd = deep_copy(portal_down_def)
    local pu = deep_copy(portal_up_def)

    if opts.down_state then pd._state = opts.down_state end
    if opts.up_state then pu._state = opts.up_state end

    reg:register(pd.id, pd)
    reg:register(pu.id, pu)

    if opts.extra_objects then
        for _, obj in ipairs(opts.extra_objects) do
            reg:register(obj.id, obj)
        end
    end

    local hallway = {
        id = "hallway",
        name = "The Manor Hallway",
        description = "A warm, torchlit corridor.",
        contents = opts.hallway_contents or { pd.id },
        exits = { down = { portal = "hallway-deep-cellar-stairs-down" } },
    }

    local deep_cellar = {
        id = "deep-cellar",
        name = "The Deep Cellar",
        description = "A vaulted limestone chamber.",
        contents = opts.deep_cellar_contents or { pu.id },
        exits = { up = { portal = "deep-cellar-hallway-stairs-up" } },
    }

    local rooms = {
        ["hallway"] = hallway,
        ["deep-cellar"] = deep_cellar,
    }

    local start = opts.start_location or "hallway"

    local player = {
        location = start,
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = {},
        max_health = 100,
        visited_rooms = { [start] = true },
    }

    return {
        registry = reg,
        current_room = rooms[start],
        rooms = rooms,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "go",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }, pd, pu
end

---------------------------------------------------------------------------
-- 1. PORTAL OBJECT FILES LOAD
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: file loading")

test("down portal file loads without error", function()
    h.assert_truthy(down_ok, "hallway-deep-cellar-stairs-down.lua must load: " .. tostring(portal_down_def))
end)

test("up portal file loads without error", function()
    h.assert_truthy(up_ok, "deep-cellar-hallway-stairs-up.lua must load: " .. tostring(portal_up_def))
end)

test("hallway room file loads without error", function()
    h.assert_truthy(hallway_ok, "hallway.lua must load: " .. tostring(hallway_def))
end)

test("deep-cellar room file loads without error", function()
    h.assert_truthy(deep_cellar_ok, "deep-cellar.lua must load: " .. tostring(deep_cellar_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: object structure")

test("down portal has template = 'portal'", function()
    eq("portal", portal_down_def.template, "down portal template")
end)

test("up portal has template = 'portal'", function()
    eq("portal", portal_up_def.template, "up portal template")
end)

test("down portal has correct id", function()
    eq("hallway-deep-cellar-stairs-down", portal_down_def.id, "down portal id")
end)

test("up portal has correct id", function()
    eq("deep-cellar-hallway-stairs-up", portal_up_def.id, "up portal id")
end)

test("down portal has guid", function()
    h.assert_truthy(portal_down_def.guid, "down portal must have a guid")
    h.assert_truthy(#portal_down_def.guid > 0, "guid must not be empty")
end)

test("up portal has guid", function()
    h.assert_truthy(portal_up_def.guid, "up portal must have a guid")
    h.assert_truthy(#portal_up_def.guid > 0, "guid must not be empty")
end)

test("down and up guids differ", function()
    h.assert_truthy(portal_down_def.guid ~= portal_up_def.guid,
        "paired portals must have different guids")
end)

test("down portal has 'portal' category", function()
    local found = false
    for _, c in ipairs(portal_down_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "down portal must have 'portal' category")
end)

test("up portal has 'portal' category", function()
    local found = false
    for _, c in ipairs(portal_up_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "up portal must have 'portal' category")
end)

test("both portals are not portable", function()
    eq(false, portal_down_def.portable, "down portal must not be portable")
    eq(false, portal_up_def.portable, "up portal must not be portable")
end)

test("both portals have material = 'stone'", function()
    eq("stone", portal_down_def.material, "down portal material")
    eq("stone", portal_up_def.material, "up portal material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA (target, bidirectional_id, direction_hint)
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: portal metadata")

test("down portal targets deep-cellar", function()
    eq("deep-cellar", portal_down_def.portal.target, "down portal target")
end)

test("up portal targets hallway", function()
    eq("hallway", portal_up_def.portal.target, "up portal target")
end)

test("down direction_hint is 'down'", function()
    eq("down", portal_down_def.portal.direction_hint, "down direction hint")
end)

test("up direction_hint is 'up'", function()
    eq("up", portal_up_def.portal.direction_hint, "up direction hint")
end)

test("paired portals share bidirectional_id", function()
    h.assert_truthy(portal_down_def.portal.bidirectional_id,
        "down portal must have bidirectional_id")
    h.assert_truthy(portal_up_def.portal.bidirectional_id,
        "up portal must have bidirectional_id")
    eq(portal_down_def.portal.bidirectional_id,
       portal_up_def.portal.bidirectional_id,
       "paired portals must share bidirectional_id")
end)

test("bidirectional_id is a GUID string", function()
    local bid = portal_down_def.portal.bidirectional_id
    h.assert_truthy(type(bid) == "string" and #bid > 0,
        "bidirectional_id must be a non-empty string")
end)

---------------------------------------------------------------------------
-- 4. FSM STATES — always open (no locked/closed)
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: FSM states")

test("down portal initial_state is 'open'", function()
    eq("open", portal_down_def.initial_state, "down initial_state")
end)

test("down portal _state is 'open'", function()
    eq("open", portal_down_def._state, "down _state")
end)

test("up portal initial_state is 'open'", function()
    eq("open", portal_up_def.initial_state, "up initial_state")
end)

test("up portal _state is 'open'", function()
    eq("open", portal_up_def._state, "up _state")
end)

test("down portal has open state", function()
    h.assert_truthy(portal_down_def.states.open, "down must have open state")
end)

test("up portal has open state", function()
    h.assert_truthy(portal_up_def.states.open, "up must have open state")
end)

test("down portal open state: traversable = true", function()
    eq(true, portal_down_def.states.open.traversable, "down open traversable")
end)

test("up portal open state: traversable = true", function()
    eq(true, portal_up_def.states.open.traversable, "up open traversable")
end)

test("stairway has no transitions (always open)", function()
    eq(0, #(portal_down_def.transitions or {}), "down portal should have no transitions")
    eq(0, #(portal_up_def.transitions or {}), "up portal should have no transitions")
end)

---------------------------------------------------------------------------
-- 5. WIND TRAVERSE EFFECTS
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: traverse effects")

test("down portal has on_traverse.wind_effect", function()
    h.assert_truthy(portal_down_def.on_traverse, "down portal must have on_traverse")
    h.assert_truthy(portal_down_def.on_traverse.wind_effect, "down portal must have wind_effect")
end)

test("up portal has on_traverse.wind_effect", function()
    h.assert_truthy(portal_up_def.on_traverse, "up portal must have on_traverse")
    h.assert_truthy(portal_up_def.on_traverse.wind_effect, "up portal must have wind_effect")
end)

test("down wind_effect extinguishes candles", function()
    local ext = portal_down_def.on_traverse.wind_effect.extinguishes
    h.assert_truthy(ext, "wind_effect must have extinguishes list")
    local found = false
    for _, item in ipairs(ext) do
        if item == "candle" then found = true; break end
    end
    h.assert_truthy(found, "wind_effect must extinguish candles")
end)

test("up wind_effect extinguishes candles", function()
    local ext = portal_up_def.on_traverse.wind_effect.extinguishes
    h.assert_truthy(ext, "wind_effect must have extinguishes list")
    local found = false
    for _, item in ipairs(ext) do
        if item == "candle" then found = true; break end
    end
    h.assert_truthy(found, "wind_effect must extinguish candles")
end)

test("wind_effect spares wind_resistant items", function()
    local spares = portal_down_def.on_traverse.wind_effect.spares
    h.assert_truthy(spares, "wind_effect must have spares table")
    eq(true, spares.wind_resistant, "wind_resistant items should be spared")
end)

test("down wind_effect has extinguish message", function()
    h.assert_truthy(portal_down_def.on_traverse.wind_effect.message_extinguish,
        "wind_effect must have message_extinguish")
    h.assert_truthy(#portal_down_def.on_traverse.wind_effect.message_extinguish > 0,
        "message_extinguish must not be empty")
end)

test("down wind_effect has spared message", function()
    h.assert_truthy(portal_down_def.on_traverse.wind_effect.message_spared,
        "wind_effect must have message_spared")
end)

---------------------------------------------------------------------------
-- 6. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: sensory properties")

test("down portal has on_feel (P6 required)", function()
    h.assert_truthy(portal_down_def.on_feel, "down portal must have on_feel")
    h.assert_truthy(#portal_down_def.on_feel > 0, "on_feel must not be empty")
end)

test("up portal has on_feel (P6 required)", function()
    h.assert_truthy(portal_up_def.on_feel, "up portal must have on_feel")
    h.assert_truthy(#portal_up_def.on_feel > 0, "on_feel must not be empty")
end)

test("down portal has on_smell", function()
    h.assert_truthy(portal_down_def.on_smell, "down portal should have on_smell")
end)

test("down portal has on_listen", function()
    h.assert_truthy(portal_down_def.on_listen, "down portal should have on_listen")
end)

test("down portal has on_taste", function()
    h.assert_truthy(portal_down_def.on_taste, "down portal should have on_taste")
end)

test("up portal has on_smell", function()
    h.assert_truthy(portal_up_def.on_smell, "up portal should have on_smell")
end)

test("up portal has on_listen", function()
    h.assert_truthy(portal_up_def.on_listen, "up portal should have on_listen")
end)

test("up portal has on_taste", function()
    h.assert_truthy(portal_up_def.on_taste, "up portal should have on_taste")
end)

test("open state has on_feel (darkness sense per state)", function()
    h.assert_truthy(portal_down_def.states.open.on_feel,
        "open state should have on_feel for darkness navigation")
end)

---------------------------------------------------------------------------
-- 7. MOVEMENT THROUGH STAIRWAY
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: movement")

test("'go down' from hallway moves to deep-cellar", function()
    local ctx = make_stairway_ctx()
    capture_output(function() handlers["go"](ctx, "down") end)
    eq("deep-cellar", ctx.player.location, "player should move to deep-cellar via open stairway")
end)

test("'down' direction handler moves to deep-cellar", function()
    local ctx = make_stairway_ctx()
    capture_output(function() handlers["down"](ctx, "") end)
    eq("deep-cellar", ctx.player.location, "'down' shorthand should move to deep-cellar")
end)

test("'go up' from deep-cellar moves to hallway", function()
    local ctx = make_stairway_ctx({ start_location = "deep-cellar" })
    capture_output(function() handlers["go"](ctx, "up") end)
    eq("hallway", ctx.player.location, "player should move to hallway via open stairway")
end)

test("'up' direction handler moves to hallway", function()
    local ctx = make_stairway_ctx({ start_location = "deep-cellar" })
    capture_output(function() handlers["up"](ctx, "") end)
    eq("hallway", ctx.player.location, "'up' shorthand should move to hallway")
end)

---------------------------------------------------------------------------
-- 8. BIDIRECTIONAL SYNC
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: bidirectional sync")

test("sync does not error on always-open portal pair", function()
    local ctx, pd, pu = make_stairway_ctx()
    local helpers = require("engine.verbs.helpers")
    local ok, err = pcall(helpers.sync_bidirectional_portal, ctx, pd)
    h.assert_truthy(ok, "sync should not error on open stairway: " .. tostring(err))
    eq("open", pu._state, "up portal should remain open after sync")
end)

---------------------------------------------------------------------------
-- 9. ROOM WIRING — exits reference portal objects
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: room wiring")

test("hallway exits.down uses portal reference", function()
    h.assert_truthy(hallway_def.exits, "hallway must have exits")
    h.assert_truthy(hallway_def.exits.down, "hallway must have a 'down' exit")
    eq("hallway-deep-cellar-stairs-down", hallway_def.exits.down.portal,
        "hallway down exit must reference hallway-deep-cellar-stairs-down portal")
end)

test("deep-cellar exits.up uses portal reference", function()
    h.assert_truthy(deep_cellar_def.exits, "deep-cellar must have exits")
    h.assert_truthy(deep_cellar_def.exits.up, "deep-cellar must have an 'up' exit")
    eq("deep-cellar-hallway-stairs-up", deep_cellar_def.exits.up.portal,
        "deep-cellar up exit must reference deep-cellar-hallway-stairs-up portal")
end)

test("hallway instances include down portal", function()
    local found = false
    for _, inst in ipairs(hallway_def.instances or {}) do
        if inst.id == "hallway-deep-cellar-stairs-down" then found = true; break end
    end
    h.assert_truthy(found, "hallway instances must include hallway-deep-cellar-stairs-down")
end)

test("deep-cellar instances include up portal", function()
    local found = false
    for _, inst in ipairs(deep_cellar_def.instances or {}) do
        if inst.id == "deep-cellar-hallway-stairs-up" then found = true; break end
    end
    h.assert_truthy(found, "deep-cellar instances must include deep-cellar-hallway-stairs-up")
end)

test("hallway has no legacy inline down exit", function()
    local exit = hallway_def.exits.down
    h.assert_truthy(exit.portal, "down exit must use portal reference, not inline target")
    eq(nil, exit.target, "down exit must NOT have legacy inline 'target' field")
end)

test("deep-cellar has no legacy inline up exit", function()
    local exit = deep_cellar_def.exits.up
    h.assert_truthy(exit.portal, "up exit must use portal reference, not inline target")
    eq(nil, exit.target, "up exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 10. KEYWORDS — stairway discoverable by multiple names
---------------------------------------------------------------------------
suite("DEEP-CELLAR-HALLWAY STAIRWAY: keywords")

test("down portal has 'stairs' keyword", function()
    local found = false
    for _, kw in ipairs(portal_down_def.keywords or {}) do
        if kw:lower() == "stairs" then found = true; break end
    end
    h.assert_truthy(found, "down portal must have 'stairs' keyword")
end)

test("down portal has 'stairway' keyword", function()
    local found = false
    for _, kw in ipairs(portal_down_def.keywords or {}) do
        if kw:lower() == "stairway" then found = true; break end
    end
    h.assert_truthy(found, "down portal must have 'stairway' keyword")
end)

test("up portal has 'stairs' keyword", function()
    local found = false
    for _, kw in ipairs(portal_up_def.keywords or {}) do
        if kw:lower() == "stairs" then found = true; break end
    end
    h.assert_truthy(found, "up portal must have 'stairs' keyword")
end)

test("up portal has 'stairway' keyword", function()
    local found = false
    for _, kw in ipairs(portal_up_def.keywords or {}) do
        if kw:lower() == "stairway" then found = true; break end
    end
    h.assert_truthy(found, "up portal must have 'stairway' keyword")
end)

h.summary()
