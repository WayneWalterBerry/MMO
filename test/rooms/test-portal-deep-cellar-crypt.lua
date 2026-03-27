-- test/rooms/test-portal-deep-cellar-crypt.lua
-- TDD tests for the deep cellar ↔ crypt archway portal pair (#204).
-- Validates: paired portal objects, FSM (locked/closed/open), silver-key
-- lock/unlock mechanic, bidirectional sync, room wiring, movement, sensory.
--
-- Usage: lua test/rooms/test-portal-deep-cellar-crypt.lua
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

local west_ok, portal_west_def = pcall(dofile, obj_dir .. "deep-cellar-crypt-archway-west.lua")
local east_ok, portal_east_def = pcall(dofile, obj_dir .. "crypt-deep-cellar-archway-east.lua")
local deep_cellar_ok, deep_cellar_def = pcall(dofile, room_dir .. "deep-cellar.lua")
local crypt_ok, crypt_def = pcall(dofile, room_dir .. "crypt.lua")

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

local function make_silver_key()
    return {
        id = "silver-key",
        name = "a silver key",
        keywords = {"key", "silver key"},
        material = "silver",
        size = 1,
        weight = 0.1,
        portable = true,
        categories = {"metal", "key"},
        capabilities = { unlock = true },
    }
end

local function make_archway_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()

    local pw = deep_copy(portal_west_def)
    local pe = deep_copy(portal_east_def)

    if opts.west_state then pw._state = opts.west_state end
    if opts.east_state then pe._state = opts.east_state end

    reg:register(pw.id, pw)
    reg:register(pe.id, pe)

    if opts.extra_objects then
        for _, obj in ipairs(opts.extra_objects) do
            reg:register(obj.id, obj)
        end
    end

    local deep_cellar = {
        id = "deep-cellar",
        name = "The Deep Cellar",
        description = "A vaulted limestone chamber.",
        contents = opts.deep_cellar_contents or { pw.id },
        exits = { west = { portal = "deep-cellar-crypt-archway-west" } },
    }

    local crypt = {
        id = "crypt",
        name = "The Crypt",
        description = "A silent vault of stone coffins.",
        contents = opts.crypt_contents or { pe.id },
        exits = { east = { portal = "crypt-deep-cellar-archway-east" } },
    }

    local rooms = {
        ["deep-cellar"] = deep_cellar,
        ["crypt"] = crypt,
    }

    local start = opts.start_location or "deep-cellar"

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
    }, pw, pe
end

---------------------------------------------------------------------------
-- 1. PORTAL OBJECT FILES LOAD
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: file loading")

test("west portal file loads without error", function()
    h.assert_truthy(west_ok, "deep-cellar-crypt-archway-west.lua must load: " .. tostring(portal_west_def))
end)

test("east portal file loads without error", function()
    h.assert_truthy(east_ok, "crypt-deep-cellar-archway-east.lua must load: " .. tostring(portal_east_def))
end)

test("deep-cellar room file loads without error", function()
    h.assert_truthy(deep_cellar_ok, "deep-cellar.lua must load: " .. tostring(deep_cellar_def))
end)

test("crypt room file loads without error", function()
    h.assert_truthy(crypt_ok, "crypt.lua must load: " .. tostring(crypt_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: object structure")

test("west portal has template = 'portal'", function()
    eq("portal", portal_west_def.template, "west portal template")
end)

test("east portal has template = 'portal'", function()
    eq("portal", portal_east_def.template, "east portal template")
end)

test("west portal has correct id", function()
    eq("deep-cellar-crypt-archway-west", portal_west_def.id, "west portal id")
end)

test("east portal has correct id", function()
    eq("crypt-deep-cellar-archway-east", portal_east_def.id, "east portal id")
end)

test("west portal has guid", function()
    h.assert_truthy(portal_west_def.guid, "west portal must have a guid")
    h.assert_truthy(#portal_west_def.guid > 0, "guid must not be empty")
end)

test("east portal has guid", function()
    h.assert_truthy(portal_east_def.guid, "east portal must have a guid")
    h.assert_truthy(#portal_east_def.guid > 0, "guid must not be empty")
end)

test("west and east guids differ", function()
    h.assert_truthy(portal_west_def.guid ~= portal_east_def.guid,
        "paired portals must have different guids")
end)

test("west portal has 'portal' category", function()
    local found = false
    for _, c in ipairs(portal_west_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "west portal must have 'portal' category")
end)

test("east portal has 'portal' category", function()
    local found = false
    for _, c in ipairs(portal_east_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "east portal must have 'portal' category")
end)

test("both portals are not portable", function()
    eq(false, portal_west_def.portable, "west portal must not be portable")
    eq(false, portal_east_def.portable, "east portal must not be portable")
end)

test("both portals have material = 'iron'", function()
    eq("iron", portal_west_def.material, "west portal material")
    eq("iron", portal_east_def.material, "east portal material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA (target, bidirectional_id, direction_hint)
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: portal metadata")

test("west portal targets crypt", function()
    eq("crypt", portal_west_def.portal.target, "west portal target")
end)

test("east portal targets deep-cellar", function()
    eq("deep-cellar", portal_east_def.portal.target, "east portal target")
end)

test("west direction_hint is 'west'", function()
    eq("west", portal_west_def.portal.direction_hint, "west direction hint")
end)

test("east direction_hint is 'east'", function()
    eq("east", portal_east_def.portal.direction_hint, "east direction hint")
end)

test("paired portals share bidirectional_id", function()
    h.assert_truthy(portal_west_def.portal.bidirectional_id,
        "west portal must have bidirectional_id")
    h.assert_truthy(portal_east_def.portal.bidirectional_id,
        "east portal must have bidirectional_id")
    eq(portal_west_def.portal.bidirectional_id,
       portal_east_def.portal.bidirectional_id,
       "paired portals must share bidirectional_id")
end)

test("bidirectional_id is a GUID string", function()
    local bid = portal_west_def.portal.bidirectional_id
    h.assert_truthy(type(bid) == "string" and #bid > 0,
        "bidirectional_id must be a non-empty string")
end)

---------------------------------------------------------------------------
-- 4. FSM STATES — locked / closed / open
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: FSM states")

test("west portal initial_state is 'locked'", function()
    eq("locked", portal_west_def.initial_state, "west initial_state")
end)

test("west portal _state is 'locked'", function()
    eq("locked", portal_west_def._state, "west _state")
end)

test("east portal initial_state is 'locked'", function()
    eq("locked", portal_east_def.initial_state, "east initial_state")
end)

test("east portal _state is 'locked'", function()
    eq("locked", portal_east_def._state, "east _state")
end)

test("west portal has 3 states: locked, closed, open", function()
    h.assert_truthy(portal_west_def.states.locked, "west must have locked state")
    h.assert_truthy(portal_west_def.states.closed, "west must have closed state")
    h.assert_truthy(portal_west_def.states.open, "west must have open state")
end)

test("east portal has 3 states: locked, closed, open", function()
    h.assert_truthy(portal_east_def.states.locked, "east must have locked state")
    h.assert_truthy(portal_east_def.states.closed, "east must have closed state")
    h.assert_truthy(portal_east_def.states.open, "east must have open state")
end)

-- Traversable flags
test("locked state: traversable = false (both sides)", function()
    eq(false, portal_west_def.states.locked.traversable, "west locked traversable")
    eq(false, portal_east_def.states.locked.traversable, "east locked traversable")
end)

test("closed state: traversable = false (both sides)", function()
    eq(false, portal_west_def.states.closed.traversable, "west closed traversable")
    eq(false, portal_east_def.states.closed.traversable, "east closed traversable")
end)

test("open state: traversable = true (both sides)", function()
    eq(true, portal_west_def.states.open.traversable, "west open traversable")
    eq(true, portal_east_def.states.open.traversable, "east open traversable")
end)

---------------------------------------------------------------------------
-- 5. FSM TRANSITIONS — lock/unlock/open/close with silver key
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: FSM transitions")

test("west portal: locked → closed via 'unlock'", function()
    local reg = registry_mod.new()
    local pw = deep_copy(portal_west_def)
    local key = make_silver_key()
    reg:register(pw.id, pw)
    reg:register(key.id, key)
    local trans, err = fsm_mod.transition(reg, pw.id, "closed", key, "unlock")
    h.assert_truthy(trans, "locked→closed transition must succeed: " .. tostring(err))
    eq("closed", pw._state, "west portal should be in closed state after unlock")
end)

test("west portal: closed → open via 'open'", function()
    local reg = registry_mod.new()
    local pw = deep_copy(portal_west_def)
    pw._state = "closed"
    reg:register(pw.id, pw)
    local trans, err = fsm_mod.transition(reg, pw.id, "open", nil, "open")
    h.assert_truthy(trans, "closed→open transition must succeed: " .. tostring(err))
    eq("open", pw._state, "west portal should be in open state")
end)

test("west portal: open → closed via 'close'", function()
    local reg = registry_mod.new()
    local pw = deep_copy(portal_west_def)
    pw._state = "open"
    reg:register(pw.id, pw)
    local trans, err = fsm_mod.transition(reg, pw.id, "closed", nil, "close")
    h.assert_truthy(trans, "open→closed transition must succeed: " .. tostring(err))
    eq("closed", pw._state, "west portal should be in closed state after close")
end)

test("west portal: closed → locked via 'lock'", function()
    local reg = registry_mod.new()
    local pw = deep_copy(portal_west_def)
    pw._state = "closed"
    local key = make_silver_key()
    reg:register(pw.id, pw)
    reg:register(key.id, key)
    local trans, err = fsm_mod.transition(reg, pw.id, "locked", key, "lock")
    h.assert_truthy(trans, "closed→locked transition must succeed: " .. tostring(err))
    eq("locked", pw._state, "west portal should be in locked state after lock")
end)

test("east portal: locked → closed via 'unlock'", function()
    local reg = registry_mod.new()
    local pe = deep_copy(portal_east_def)
    local key = make_silver_key()
    reg:register(pe.id, pe)
    reg:register(key.id, key)
    local trans, err = fsm_mod.transition(reg, pe.id, "closed", key, "unlock")
    h.assert_truthy(trans, "locked→closed transition must succeed: " .. tostring(err))
    eq("closed", pe._state, "east portal should be in closed state after unlock")
end)

test("east portal: closed → open via 'open'", function()
    local reg = registry_mod.new()
    local pe = deep_copy(portal_east_def)
    pe._state = "closed"
    reg:register(pe.id, pe)
    local trans, err = fsm_mod.transition(reg, pe.id, "open", nil, "open")
    h.assert_truthy(trans, "closed→open transition must succeed: " .. tostring(err))
    eq("open", pe._state, "east portal should be in open state")
end)

test("east portal: open → closed via 'close'", function()
    local reg = registry_mod.new()
    local pe = deep_copy(portal_east_def)
    pe._state = "open"
    reg:register(pe.id, pe)
    local trans, err = fsm_mod.transition(reg, pe.id, "closed", nil, "close")
    h.assert_truthy(trans, "open→closed transition must succeed: " .. tostring(err))
    eq("closed", pe._state, "east portal should be in closed state after close")
end)

test("east portal: closed → locked via 'lock'", function()
    local reg = registry_mod.new()
    local pe = deep_copy(portal_east_def)
    pe._state = "closed"
    local key = make_silver_key()
    reg:register(pe.id, pe)
    reg:register(key.id, key)
    local trans, err = fsm_mod.transition(reg, pe.id, "locked", key, "lock")
    h.assert_truthy(trans, "closed→locked transition must succeed: " .. tostring(err))
    eq("locked", pe._state, "east portal should be in locked state after lock")
end)

test("west portal: cannot skip locked → open directly", function()
    local reg = registry_mod.new()
    local pw = deep_copy(portal_west_def)
    reg:register(pw.id, pw)
    local trans = fsm_mod.transition(reg, pw.id, "open", nil, "open")
    eq(nil, trans, "should not jump from locked to open (must unlock first)")
    eq("locked", pw._state, "state should remain locked")
end)

test("unlock requires silver-key tool", function()
    local pw = deep_copy(portal_west_def)
    local found_unlock = false
    for _, t in ipairs(pw.transitions or {}) do
        if t.from == "locked" and t.to == "closed" and t.verb == "unlock" then
            found_unlock = true
            eq("silver-key", t.requires_tool, "unlock transition must require silver-key")
        end
    end
    h.assert_truthy(found_unlock, "must have a locked→closed unlock transition")
end)

---------------------------------------------------------------------------
-- 6. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: sensory properties")

test("west portal has on_feel (P6 required)", function()
    h.assert_truthy(portal_west_def.on_feel, "west portal must have on_feel")
    h.assert_truthy(#portal_west_def.on_feel > 0, "on_feel must not be empty")
end)

test("east portal has on_feel (P6 required)", function()
    h.assert_truthy(portal_east_def.on_feel, "east portal must have on_feel")
    h.assert_truthy(#portal_east_def.on_feel > 0, "on_feel must not be empty")
end)

test("west portal has on_smell", function()
    h.assert_truthy(portal_west_def.on_smell, "west portal should have on_smell")
end)

test("west portal has on_listen", function()
    h.assert_truthy(portal_west_def.on_listen, "west portal should have on_listen")
end)

test("west portal has on_taste", function()
    h.assert_truthy(portal_west_def.on_taste, "west portal should have on_taste")
end)

test("east portal has on_smell", function()
    h.assert_truthy(portal_east_def.on_smell, "east portal should have on_smell")
end)

test("east portal has on_listen", function()
    h.assert_truthy(portal_east_def.on_listen, "east portal should have on_listen")
end)

test("east portal has on_taste", function()
    h.assert_truthy(portal_east_def.on_taste, "east portal should have on_taste")
end)

test("locked state has on_feel (darkness sense per state)", function()
    h.assert_truthy(portal_west_def.states.locked.on_feel,
        "locked state should have on_feel for darkness navigation")
end)

test("closed state has on_feel (darkness sense per state)", function()
    h.assert_truthy(portal_west_def.states.closed.on_feel,
        "closed state should have on_feel for darkness navigation")
end)

test("open state has on_feel (darkness sense per state)", function()
    h.assert_truthy(portal_west_def.states.open.on_feel,
        "open state should have on_feel for darkness navigation")
end)

---------------------------------------------------------------------------
-- 7. MOVEMENT THROUGH ARCHWAY
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: movement")

test("'go west' through open archway moves to crypt", function()
    local ctx = make_archway_ctx({ west_state = "open", east_state = "open" })
    capture_output(function() handlers["go"](ctx, "west") end)
    eq("crypt", ctx.player.location, "player should move to crypt via open archway")
end)

test("'west' direction handler moves to crypt", function()
    local ctx = make_archway_ctx({ west_state = "open", east_state = "open" })
    capture_output(function() handlers["west"](ctx, "") end)
    eq("crypt", ctx.player.location, "'west' shorthand should move to crypt")
end)

test("'go west' through locked archway is blocked", function()
    local ctx = make_archway_ctx({ west_state = "locked" })
    local out = capture_output(function() handlers["go"](ctx, "west") end)
    eq("deep-cellar", ctx.player.location, "player should stay in deep-cellar (locked)")
    h.assert_truthy(out:lower():find("lock") or out:lower():find("block")
        or out:lower():find("can't") or out:lower():find("shut"),
        "should print locked/blocked message — got: " .. out)
end)

test("'go west' through closed archway is blocked", function()
    local ctx = make_archway_ctx({ west_state = "closed" })
    local out = capture_output(function() handlers["go"](ctx, "west") end)
    eq("deep-cellar", ctx.player.location, "player should stay in deep-cellar (closed)")
    h.assert_truthy(out:lower():find("closed") or out:lower():find("block")
        or out:lower():find("can't") or out:lower():find("shut")
        or out:lower():find("push"),
        "should print closed/blocked message — got: " .. out)
end)

test("'go east' from crypt through open archway returns to deep-cellar", function()
    local ctx = make_archway_ctx({
        start_location = "crypt",
        west_state = "open",
        east_state = "open",
    })
    capture_output(function() handlers["go"](ctx, "east") end)
    eq("deep-cellar", ctx.player.location,
        "player should move from crypt back to deep-cellar via open archway")
end)

test("'east' direction handler returns to deep-cellar", function()
    local ctx = make_archway_ctx({
        start_location = "crypt",
        west_state = "open",
        east_state = "open",
    })
    capture_output(function() handlers["east"](ctx, "") end)
    eq("deep-cellar", ctx.player.location,
        "'east' shorthand should move from crypt to deep-cellar")
end)

test("'go east' from crypt through locked archway is blocked", function()
    local ctx = make_archway_ctx({
        start_location = "crypt",
        east_state = "locked",
    })
    local out = capture_output(function() handlers["go"](ctx, "east") end)
    eq("crypt", ctx.player.location, "player should stay in crypt")
    h.assert_truthy(out:lower():find("lock") or out:lower():find("block")
        or out:lower():find("can't") or out:lower():find("shut"),
        "should print locked/blocked message — got: " .. out)
end)

---------------------------------------------------------------------------
-- 8. BIDIRECTIONAL SYNC
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: bidirectional sync")

test("opening west portal syncs east portal to open", function()
    local ctx, pw, pe = make_archway_ctx({ west_state = "closed", east_state = "closed" })
    local helpers = require("engine.verbs.helpers")
    pw._state = "open"
    helpers.sync_bidirectional_portal(ctx, pw)
    eq("open", pe._state, "east portal should sync to open")
end)

test("closing west portal syncs east portal to closed", function()
    local ctx, pw, pe = make_archway_ctx({ west_state = "open", east_state = "open" })
    local helpers = require("engine.verbs.helpers")
    pw._state = "closed"
    helpers.sync_bidirectional_portal(ctx, pw)
    eq("closed", pe._state, "east portal should sync to closed")
end)

test("unlocking west portal syncs east portal to closed", function()
    local ctx, pw, pe = make_archway_ctx({ west_state = "locked", east_state = "locked" })
    local helpers = require("engine.verbs.helpers")
    pw._state = "closed"
    helpers.sync_bidirectional_portal(ctx, pw)
    eq("closed", pe._state, "east portal should sync to closed after unlock")
end)

test("locking west portal syncs east portal to locked", function()
    local ctx, pw, pe = make_archway_ctx({ west_state = "closed", east_state = "closed" })
    local helpers = require("engine.verbs.helpers")
    pw._state = "locked"
    helpers.sync_bidirectional_portal(ctx, pw)
    eq("locked", pe._state, "east portal should sync to locked")
end)

test("sync does nothing without bidirectional_id", function()
    local ctx, pw, pe = make_archway_ctx({ west_state = "closed", east_state = "closed" })
    local helpers = require("engine.verbs.helpers")
    pw.portal.bidirectional_id = nil
    pw._state = "open"
    helpers.sync_bidirectional_portal(ctx, pw)
    eq("closed", pe._state, "unlinked portal should not change")
end)

---------------------------------------------------------------------------
-- 9. ROOM WIRING — exits reference portal objects
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: room wiring")

test("deep-cellar exits.west uses portal reference", function()
    h.assert_truthy(deep_cellar_def.exits, "deep-cellar must have exits")
    h.assert_truthy(deep_cellar_def.exits.west, "deep-cellar must have a 'west' exit")
    eq("deep-cellar-crypt-archway-west", deep_cellar_def.exits.west.portal,
        "deep-cellar west exit must reference deep-cellar-crypt-archway-west portal")
end)

test("crypt exits.east uses portal reference", function()
    h.assert_truthy(crypt_def.exits, "crypt must have exits")
    h.assert_truthy(crypt_def.exits.east, "crypt must have an 'east' exit")
    eq("crypt-deep-cellar-archway-east", crypt_def.exits.east.portal,
        "crypt east exit must reference crypt-deep-cellar-archway-east portal")
end)

test("deep-cellar instances include west portal", function()
    local found = false
    for _, inst in ipairs(deep_cellar_def.instances or {}) do
        if inst.id == "deep-cellar-crypt-archway-west" then found = true; break end
    end
    h.assert_truthy(found, "deep-cellar instances must include deep-cellar-crypt-archway-west")
end)

test("crypt instances include east portal", function()
    local found = false
    for _, inst in ipairs(crypt_def.instances or {}) do
        if inst.id == "crypt-deep-cellar-archway-east" then found = true; break end
    end
    h.assert_truthy(found, "crypt instances must include crypt-deep-cellar-archway-east")
end)

test("deep-cellar has no legacy inline west exit", function()
    local exit = deep_cellar_def.exits.west
    h.assert_truthy(exit.portal, "west exit must use portal reference, not inline target")
    eq(nil, exit.target, "west exit must NOT have legacy inline 'target' field")
end)

test("crypt has no legacy inline east exit", function()
    local exit = crypt_def.exits.east
    h.assert_truthy(exit.portal, "east exit must use portal reference, not inline target")
    eq(nil, exit.target, "east exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 10. KEYWORDS — archway discoverable by multiple names
---------------------------------------------------------------------------
suite("DEEP-CELLAR-CRYPT ARCHWAY: keywords")

test("west portal has 'archway' keyword", function()
    local found = false
    for _, kw in ipairs(portal_west_def.keywords or {}) do
        if kw:lower() == "archway" then found = true; break end
    end
    h.assert_truthy(found, "west portal must have 'archway' keyword")
end)

test("west portal has 'gate' keyword", function()
    local found = false
    for _, kw in ipairs(portal_west_def.keywords or {}) do
        if kw:lower() == "gate" then found = true; break end
    end
    h.assert_truthy(found, "west portal must have 'gate' keyword")
end)

test("west portal has 'iron gate' keyword", function()
    local found = false
    for _, kw in ipairs(portal_west_def.keywords or {}) do
        if kw:lower() == "iron gate" then found = true; break end
    end
    h.assert_truthy(found, "west portal must have 'iron gate' keyword")
end)

test("east portal has 'archway' keyword", function()
    local found = false
    for _, kw in ipairs(portal_east_def.keywords or {}) do
        if kw:lower() == "archway" then found = true; break end
    end
    h.assert_truthy(found, "east portal must have 'archway' keyword")
end)

test("east portal has 'gate' keyword", function()
    local found = false
    for _, kw in ipairs(portal_east_def.keywords or {}) do
        if kw:lower() == "gate" then found = true; break end
    end
    h.assert_truthy(found, "east portal must have 'gate' keyword")
end)

test("east portal has 'iron gate' keyword", function()
    local found = false
    for _, kw in ipairs(portal_east_def.keywords or {}) do
        if kw:lower() == "iron gate" then found = true; break end
    end
    h.assert_truthy(found, "east portal must have 'iron gate' keyword")
end)

h.summary()
