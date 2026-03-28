-- test/rooms/test-portal-storage-deep-cellar.lua
-- TDD tests for the storage ↔ deep-cellar iron door portal pair (#202).
-- Validates: paired portal objects, FSM (locked/closed/open), lock/unlock
-- with iron-key, bidirectional sync, room wiring, movement, sensory.
--
-- Usage: lua test/rooms/test-portal-storage-deep-cellar.lua
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

local north_ok, portal_north_def = pcall(dofile, obj_dir .. "storage-deep-cellar-door-north.lua")
local south_ok, portal_south_def = pcall(dofile, obj_dir .. "deep-cellar-storage-door-south.lua")
local storage_room_ok, storage_room_def = pcall(dofile, room_dir .. "storage-cellar.lua")
local deep_room_ok, deep_room_def = pcall(dofile, room_dir .. "deep-cellar.lua")

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

-- Build a game context with the actual storage-deep-cellar portal pair
local function make_storage_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()

    local pn = deep_copy(portal_north_def)
    local ps = deep_copy(portal_south_def)

    if opts.north_state then pn._state = opts.north_state end
    if opts.south_state then ps._state = opts.south_state end

    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    -- Register extra objects (e.g. iron key)
    if opts.extra_objects then
        for _, obj in ipairs(opts.extra_objects) do
            reg:register(obj.id, obj)
        end
    end

    local storage = {
        id = "storage-cellar",
        name = "The Storage Cellar",
        description = "A long, narrow vault.",
        contents = { pn.id },
        exits = { north = { portal = "storage-deep-cellar-door-north" } },
    }

    local deep = {
        id = "deep-cellar",
        name = "The Deep Cellar",
        description = "A vaulted limestone chamber.",
        contents = { ps.id },
        exits = { south = { portal = "deep-cellar-storage-door-south" } },
    }

    local rooms = {
        ["storage-cellar"] = storage,
        ["deep-cellar"] = deep,
    }

    local start = opts.start_location or "storage-cellar"

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
    }, pn, ps
end

-- Iron key mock
local function make_iron_key()
    return {
        id = "iron-key",
        name = "an iron key",
        keywords = {"key", "iron key", "iron-key"},
        portable = true,
        size = 1,
        weight = 1,
        on_feel = "A heavy iron key.",
        capabilities = { "iron-key" },
        tool_id = "iron-key",
    }
end

---------------------------------------------------------------------------
-- 1. PORTAL OBJECT FILES LOAD
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: file loading")

test("north portal file loads without error", function()
    h.assert_truthy(north_ok, "storage-deep-cellar-door-north.lua must load: " .. tostring(portal_north_def))
end)

test("south portal file loads without error", function()
    h.assert_truthy(south_ok, "deep-cellar-storage-door-south.lua must load: " .. tostring(portal_south_def))
end)

test("storage-cellar room file loads without error", function()
    h.assert_truthy(storage_room_ok, "storage-cellar.lua must load: " .. tostring(storage_room_def))
end)

test("deep-cellar room file loads without error", function()
    h.assert_truthy(deep_room_ok, "deep-cellar.lua must load: " .. tostring(deep_room_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: object structure")

test("north portal has template = 'portal'", function()
    eq("portal", portal_north_def.template, "north portal template")
end)

test("south portal has template = 'portal'", function()
    eq("portal", portal_south_def.template, "south portal template")
end)

test("north portal has correct id", function()
    eq("storage-deep-cellar-door-north", portal_north_def.id, "north portal id")
end)

test("south portal has correct id", function()
    eq("deep-cellar-storage-door-south", portal_south_def.id, "south portal id")
end)

test("north portal has guid", function()
    h.assert_truthy(portal_north_def.guid, "north portal must have a guid")
    h.assert_truthy(#portal_north_def.guid > 0, "guid must not be empty")
end)

test("south portal has guid", function()
    h.assert_truthy(portal_south_def.guid, "south portal must have a guid")
    h.assert_truthy(#portal_south_def.guid > 0, "guid must not be empty")
end)

test("north and south guids differ", function()
    h.assert_truthy(portal_north_def.guid ~= portal_south_def.guid,
        "paired portals must have different guids")
end)

test("north portal has 'portal' category", function()
    local found = false
    for _, c in ipairs(portal_north_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "north portal must have 'portal' category")
end)

test("south portal has 'portal' category", function()
    local found = false
    for _, c in ipairs(portal_south_def.categories or {}) do
        if c == "portal" then found = true; break end
    end
    h.assert_truthy(found, "south portal must have 'portal' category")
end)

test("both portals are not portable", function()
    eq(false, portal_north_def.portable, "north portal must not be portable")
    eq(false, portal_south_def.portable, "south portal must not be portable")
end)

test("both portals have material = 'iron'", function()
    eq("iron", portal_north_def.material, "north portal material")
    eq("iron", portal_south_def.material, "south portal material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA (target, bidirectional_id, direction_hint)
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: portal metadata")

test("north portal targets deep-cellar", function()
    eq("deep-cellar", portal_north_def.portal.target, "north portal target")
end)

test("south portal targets storage-cellar", function()
    eq("storage-cellar", portal_south_def.portal.target, "south portal target")
end)

test("north direction_hint is 'north'", function()
    eq("north", portal_north_def.portal.direction_hint, "north direction hint")
end)

test("south direction_hint is 'south'", function()
    eq("south", portal_south_def.portal.direction_hint, "south direction hint")
end)

test("paired portals share bidirectional_id", function()
    h.assert_truthy(portal_north_def.portal.bidirectional_id,
        "north portal must have bidirectional_id")
    h.assert_truthy(portal_south_def.portal.bidirectional_id,
        "south portal must have bidirectional_id")
    eq(portal_north_def.portal.bidirectional_id,
       portal_south_def.portal.bidirectional_id,
       "paired portals must share bidirectional_id")
end)

test("bidirectional_id is a GUID string", function()
    local bid = portal_north_def.portal.bidirectional_id
    h.assert_truthy(type(bid) == "string" and #bid > 0,
        "bidirectional_id must be a non-empty string")
end)

---------------------------------------------------------------------------
-- 4. FSM STATES — locked / closed / open
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: FSM states")

test("north portal initial_state is 'locked'", function()
    eq("locked", portal_north_def.initial_state, "north initial_state")
end)

test("north portal _state is 'locked'", function()
    eq("locked", portal_north_def._state, "north _state")
end)

test("south portal initial_state is 'locked'", function()
    eq("locked", portal_south_def.initial_state, "south initial_state")
end)

test("north portal has exactly 3 states: locked, closed, open", function()
    h.assert_truthy(portal_north_def.states.locked, "north must have locked state")
    h.assert_truthy(portal_north_def.states.closed, "north must have closed state")
    h.assert_truthy(portal_north_def.states.open, "north must have open state")
end)

test("south portal has exactly 3 states: locked, closed, open", function()
    h.assert_truthy(portal_south_def.states.locked, "south must have locked state")
    h.assert_truthy(portal_south_def.states.closed, "south must have closed state")
    h.assert_truthy(portal_south_def.states.open, "south must have open state")
end)

test("locked state: traversable = false (north)", function()
    eq(false, portal_north_def.states.locked.traversable, "locked must block traversal")
end)

test("closed state: traversable = false (north)", function()
    eq(false, portal_north_def.states.closed.traversable, "closed must block traversal")
end)

test("open state: traversable = true (north)", function()
    eq(true, portal_north_def.states.open.traversable, "open must allow traversal")
end)

test("locked state: traversable = false (south)", function()
    eq(false, portal_south_def.states.locked.traversable, "south locked must block")
end)

test("closed state: traversable = false (south)", function()
    eq(false, portal_south_def.states.closed.traversable, "south closed must block")
end)

test("open state: traversable = true (south)", function()
    eq(true, portal_south_def.states.open.traversable, "south open must allow")
end)

test("every north state has traversable flag", function()
    for state_name, state in pairs(portal_north_def.states) do
        h.assert_truthy(state.traversable ~= nil,
            "north state '" .. state_name .. "' must declare traversable")
    end
end)

test("every south state has traversable flag", function()
    for state_name, state in pairs(portal_south_def.states) do
        h.assert_truthy(state.traversable ~= nil,
            "south state '" .. state_name .. "' must declare traversable")
    end
end)

---------------------------------------------------------------------------
-- 5. FSM TRANSITIONS — unlock/open/close/lock
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: FSM transitions")

-- Find a transition by from/to
local function find_transition(obj, from, to)
    for _, t in ipairs(obj.transitions or {}) do
        if t.from == from and t.to == to then return t end
    end
    return nil
end

test("north: locked → closed via 'unlock'", function()
    local t = find_transition(portal_north_def, "locked", "closed")
    h.assert_truthy(t, "must have locked→closed transition")
    eq("unlock", t.verb, "unlock verb triggers locked→closed")
end)

test("north: unlock requires iron-key", function()
    local t = find_transition(portal_north_def, "locked", "closed")
    eq("iron-key", t.requires_tool, "unlock must require iron-key tool")
end)

test("north: closed → open via 'open'", function()
    local t = find_transition(portal_north_def, "closed", "open")
    h.assert_truthy(t, "must have closed→open transition")
    eq("open", t.verb, "open verb triggers closed→open")
end)

test("north: open → closed via 'close'", function()
    local t = find_transition(portal_north_def, "open", "closed")
    h.assert_truthy(t, "must have open→closed transition")
    eq("close", t.verb, "close verb triggers open→closed")
end)

test("north: closed → locked via 'lock'", function()
    local t = find_transition(portal_north_def, "closed", "locked")
    h.assert_truthy(t, "must have closed→locked transition")
    eq("lock", t.verb, "lock verb triggers closed→locked")
end)

test("north: lock requires iron-key", function()
    local t = find_transition(portal_north_def, "closed", "locked")
    eq("iron-key", t.requires_tool, "lock must require iron-key tool")
end)

test("every north transition has a message", function()
    for _, t in ipairs(portal_north_def.transitions) do
        h.assert_truthy(t.message and #t.message > 0,
            "transition " .. t.from .. "→" .. t.to .. " must have a message")
    end
end)

test("south: locked → closed via 'unlock'", function()
    local t = find_transition(portal_south_def, "locked", "closed")
    h.assert_truthy(t, "south must have locked→closed transition")
    eq("unlock", t.verb, "unlock verb on south side")
end)

test("south: closed → open via 'open'", function()
    local t = find_transition(portal_south_def, "closed", "open")
    h.assert_truthy(t, "south must have closed→open transition")
    eq("open", t.verb, "open verb on south side")
end)

test("south: open → closed via 'close'", function()
    local t = find_transition(portal_south_def, "open", "closed")
    h.assert_truthy(t, "south must have open→closed transition")
    eq("close", t.verb, "close verb on south side")
end)

test("south: closed → locked via 'lock'", function()
    local t = find_transition(portal_south_def, "closed", "locked")
    h.assert_truthy(t, "south must have closed→locked transition")
    eq("lock", t.verb, "lock verb on south side")
end)

test("every south transition has a message", function()
    for _, t in ipairs(portal_south_def.transitions) do
        h.assert_truthy(t.message and #t.message > 0,
            "transition " .. t.from .. "→" .. t.to .. " must have a message")
    end
end)

test("north 'open' transition allows 'push' alias", function()
    local t = find_transition(portal_north_def, "closed", "open")
    h.assert_truthy(t.aliases, "open transition should have aliases")
    local has_push = false
    for _, a in ipairs(t.aliases or {}) do
        if a == "push" then has_push = true; break end
    end
    h.assert_truthy(has_push, "open transition should accept 'push' alias")
end)

test("north 'close' transition allows 'shut' alias", function()
    local t = find_transition(portal_north_def, "open", "closed")
    h.assert_truthy(t.aliases, "close transition should have aliases")
    local has_shut = false
    for _, a in ipairs(t.aliases or {}) do
        if a == "shut" then has_shut = true; break end
    end
    h.assert_truthy(has_shut, "close transition should accept 'shut' alias")
end)

---------------------------------------------------------------------------
-- 6. FSM ENGINE TRANSITIONS
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: FSM engine transitions")

test("FSM loads north portal", function()
    local p = deep_copy(portal_north_def)
    local def = fsm_mod.load(p)
    h.assert_truthy(def, "fsm.load must recognize portal with states")
end)

test("FSM: locked → closed via unlock", function()
    local reg = registry_mod.new()
    local p = deep_copy(portal_north_def)
    p._state = "locked"
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "closed", nil, "unlock")
    h.assert_truthy(trans, "locked→closed transition should succeed: " .. tostring(err))
    eq("closed", p._state, "portal should be closed after unlock")
end)

test("FSM: closed → open via open", function()
    local reg = registry_mod.new()
    local p = deep_copy(portal_north_def)
    p._state = "closed"
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "open", nil, "open")
    h.assert_truthy(trans, "closed→open transition should succeed: " .. tostring(err))
    eq("open", p._state, "portal should be open")
end)

test("FSM: open → closed via close", function()
    local reg = registry_mod.new()
    local p = deep_copy(portal_north_def)
    p._state = "open"
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "closed", nil, "close")
    h.assert_truthy(trans, "open→closed transition should succeed: " .. tostring(err))
    eq("closed", p._state, "portal should be closed")
end)

test("FSM: closed → locked via lock", function()
    local reg = registry_mod.new()
    local p = deep_copy(portal_north_def)
    p._state = "closed"
    reg:register(p.id, p)
    local trans, err = fsm_mod.transition(reg, p.id, "locked", nil, "lock")
    h.assert_truthy(trans, "closed→locked transition should succeed: " .. tostring(err))
    eq("locked", p._state, "portal should be locked")
end)

test("FSM: full cycle locked → closed → open → closed → locked", function()
    local reg = registry_mod.new()
    local p = deep_copy(portal_north_def)
    p._state = "locked"
    reg:register(p.id, p)

    local t1 = fsm_mod.transition(reg, p.id, "closed", nil, "unlock")
    h.assert_truthy(t1, "step 1: unlock")
    eq("closed", p._state, "after unlock")

    local t2 = fsm_mod.transition(reg, p.id, "open", nil, "open")
    h.assert_truthy(t2, "step 2: open")
    eq("open", p._state, "after open")

    local t3 = fsm_mod.transition(reg, p.id, "closed", nil, "close")
    h.assert_truthy(t3, "step 3: close")
    eq("closed", p._state, "after close")

    local t4 = fsm_mod.transition(reg, p.id, "locked", nil, "lock")
    h.assert_truthy(t4, "step 4: lock")
    eq("locked", p._state, "after re-lock")
end)

---------------------------------------------------------------------------
-- 7. BIDIRECTIONAL SYNC
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: bidirectional sync")

test("registry finds paired portal by bidirectional_id", function()
    local reg = registry_mod.new()
    local pn = deep_copy(portal_north_def)
    local ps = deep_copy(portal_south_def)
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local partner = nil
    for _, obj in ipairs(reg:list()) do
        if obj.portal and obj.portal.bidirectional_id == pn.portal.bidirectional_id
           and obj.id ~= pn.id then
            partner = obj
            break
        end
    end
    h.assert_truthy(partner, "must find paired portal")
    eq(ps.id, partner.id, "partner must be south portal")
end)

test("unlock north syncs south to closed", function()
    local reg = registry_mod.new()
    local pn = deep_copy(portal_north_def)
    local ps = deep_copy(portal_south_def)
    pn._state = "locked"
    ps._state = "locked"
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local trans = fsm_mod.transition(reg, pn.id, "closed", nil, "unlock")
    if not trans then
        -- FSM transition itself works (tested above), so this is about sync
        h.assert_truthy(false, "FSM transition failed — cannot test sync")
        return
    end
    eq("closed", pn._state, "north portal unlocked")
    eq("closed", ps._state, "south portal should sync to closed via bidirectional")
end)

test("open north syncs south to open", function()
    local reg = registry_mod.new()
    local pn = deep_copy(portal_north_def)
    local ps = deep_copy(portal_south_def)
    pn._state = "closed"
    ps._state = "closed"
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local trans = fsm_mod.transition(reg, pn.id, "open", nil, "open")
    if not trans then
        h.assert_truthy(false, "FSM transition failed")
        return
    end
    eq("open", pn._state, "north portal opened")
    eq("open", ps._state, "south portal should sync to open")
end)

test("close south syncs north to closed (reverse direction)", function()
    local reg = registry_mod.new()
    local pn = deep_copy(portal_north_def)
    local ps = deep_copy(portal_south_def)
    pn._state = "open"
    ps._state = "open"
    reg:register(pn.id, pn)
    reg:register(ps.id, ps)

    local trans = fsm_mod.transition(reg, ps.id, "closed", nil, "close")
    if not trans then
        h.assert_truthy(false, "FSM transition failed on south portal")
        return
    end
    eq("closed", ps._state, "south portal closed")
    eq("closed", pn._state, "north portal should sync to closed (reverse)")
end)

---------------------------------------------------------------------------
-- 8. ROOM WIRING — thin portal references
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: room wiring")

test("storage-cellar exit north uses thin portal ref", function()
    h.assert_truthy(storage_room_def.exits, "storage-cellar must have exits")
    h.assert_truthy(storage_room_def.exits.north, "storage-cellar must have north exit")
    eq("storage-deep-cellar-door-north", storage_room_def.exits.north.portal,
        "north exit must reference portal object by id")
end)

test("storage-cellar north exit has no inline state flags", function()
    local ex = storage_room_def.exits.north
    h.assert_nil(ex.open, "no inline open flag")
    h.assert_nil(ex.locked, "no inline locked flag")
    h.assert_nil(ex.target, "no inline target (portal has it)")
end)

test("deep-cellar exit south uses thin portal ref", function()
    h.assert_truthy(deep_room_def.exits, "deep-cellar must have exits")
    h.assert_truthy(deep_room_def.exits.south, "deep-cellar must have south exit")
    eq("deep-cellar-storage-door-south", deep_room_def.exits.south.portal,
        "south exit must reference portal object by id")
end)

test("deep-cellar south exit has no inline state flags", function()
    local ex = deep_room_def.exits.south
    h.assert_nil(ex.open, "no inline open flag")
    h.assert_nil(ex.locked, "no inline locked flag")
    h.assert_nil(ex.target, "no inline target (portal has it)")
end)

test("storage-cellar instances include north portal", function()
    local found = false
    for _, inst in ipairs(storage_room_def.instances or {}) do
        if inst.id == "storage-deep-cellar-door-north" then
            found = true
            break
        end
    end
    h.assert_truthy(found, "storage-cellar instances must include north portal")
end)

test("deep-cellar instances include south portal", function()
    local found = false
    for _, inst in ipairs(deep_room_def.instances or {}) do
        if inst.id == "deep-cellar-storage-door-south" then
            found = true
            break
        end
    end
    h.assert_truthy(found, "deep-cellar instances must include south portal")
end)

test("storage-cellar portal instance type_id matches north portal guid", function()
    local inst
    for _, i in ipairs(storage_room_def.instances or {}) do
        if i.id == "storage-deep-cellar-door-north" then inst = i; break end
    end
    h.assert_truthy(inst, "portal instance must exist")
    eq(portal_north_def.guid, inst.type_id, "type_id must match portal guid")
end)

test("deep-cellar portal instance type_id matches south portal guid", function()
    local inst
    for _, i in ipairs(deep_room_def.instances or {}) do
        if i.id == "deep-cellar-storage-door-south" then inst = i; break end
    end
    h.assert_truthy(inst, "portal instance must exist")
    eq(portal_south_def.guid, inst.type_id, "type_id must match portal guid")
end)

---------------------------------------------------------------------------
-- 9. MOVEMENT THROUGH PORTAL
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: movement")

test("go north through open portal moves to deep-cellar", function()
    local ctx = make_storage_ctx({ north_state = "open" })
    capture_output(function() handlers["north"](ctx, "") end)
    eq("deep-cellar", ctx.player.location, "player should move to deep-cellar")
end)

test("go north through locked portal blocks movement", function()
    local ctx = make_storage_ctx({ north_state = "locked" })
    local out = capture_output(function() handlers["north"](ctx, "") end)
    eq("storage-cellar", ctx.player.location, "player should stay in storage-cellar")
    h.assert_truthy(out:lower():find("locked") or out:lower():find("can't")
        or out:lower():find("won't") or out:lower():find("blocked"),
        "should print blocked message — got: " .. out)
end)

test("go north through closed (unlocked) portal blocks movement", function()
    local ctx = make_storage_ctx({ north_state = "closed" })
    local out = capture_output(function() handlers["north"](ctx, "") end)
    eq("storage-cellar", ctx.player.location, "player should stay in storage-cellar")
    h.assert_truthy(out:lower():find("closed") or out:lower():find("shut")
        or out:lower():find("can't") or out:lower():find("blocked"),
        "should print closed message — got: " .. out)
end)

test("go south from deep-cellar through open portal", function()
    local ctx = make_storage_ctx({
        start_location = "deep-cellar",
        south_state = "open",
    })
    capture_output(function() handlers["south"](ctx, "") end)
    eq("storage-cellar", ctx.player.location,
        "player should move south to storage-cellar")
end)

test("go south from deep-cellar through locked portal blocks", function()
    local ctx = make_storage_ctx({
        start_location = "deep-cellar",
        south_state = "locked",
    })
    local out = capture_output(function() handlers["south"](ctx, "") end)
    eq("deep-cellar", ctx.player.location, "player should stay in deep-cellar")
end)

---------------------------------------------------------------------------
-- 10. SENSORY PROPERTIES
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: sensory properties")

test("north portal has on_feel (P6 darkness)", function()
    h.assert_truthy(portal_north_def.on_feel, "north must have on_feel")
    h.assert_truthy(#portal_north_def.on_feel > 0, "on_feel must not be empty")
end)

test("south portal has on_feel (P6 darkness)", function()
    h.assert_truthy(portal_south_def.on_feel, "south must have on_feel")
    h.assert_truthy(#portal_south_def.on_feel > 0, "on_feel must not be empty")
end)

test("north portal has on_smell", function()
    h.assert_truthy(portal_north_def.on_smell, "north must have on_smell")
end)

test("north portal has on_listen", function()
    h.assert_truthy(portal_north_def.on_listen, "north must have on_listen")
end)

test("north portal has on_taste", function()
    h.assert_truthy(portal_north_def.on_taste, "north must have on_taste")
end)

test("south portal has on_smell", function()
    h.assert_truthy(portal_south_def.on_smell, "south must have on_smell")
end)

test("south portal has on_listen", function()
    h.assert_truthy(portal_south_def.on_listen, "south must have on_listen")
end)

test("south portal has on_taste", function()
    h.assert_truthy(portal_south_def.on_taste, "south must have on_taste")
end)

test("locked state has on_feel (north)", function()
    h.assert_truthy(portal_north_def.states.locked.on_feel,
        "locked state must have on_feel for darkness navigation")
end)

test("closed state has on_feel (north)", function()
    h.assert_truthy(portal_north_def.states.closed.on_feel,
        "closed state must have on_feel")
end)

test("open state has on_feel (north)", function()
    h.assert_truthy(portal_north_def.states.open.on_feel,
        "open state must have on_feel")
end)

test("locked state has on_feel (south)", function()
    h.assert_truthy(portal_south_def.states.locked.on_feel,
        "south locked state must have on_feel")
end)

test("closed state has on_feel (south)", function()
    h.assert_truthy(portal_south_def.states.closed.on_feel,
        "south closed state must have on_feel")
end)

test("open state has on_feel (south)", function()
    h.assert_truthy(portal_south_def.states.open.on_feel,
        "south open state must have on_feel")
end)

test("locked and open on_feel differ (north)", function()
    local locked_feel = portal_north_def.states.locked.on_feel
    local open_feel = portal_north_def.states.open.on_feel
    h.assert_truthy(locked_feel ~= open_feel,
        "locked and open on_feel should differ")
end)

test("each north state has room_presence", function()
    for state_name, state in pairs(portal_north_def.states) do
        h.assert_truthy(state.room_presence,
            "north state '" .. state_name .. "' must have room_presence")
    end
end)

test("each south state has room_presence", function()
    for state_name, state in pairs(portal_south_def.states) do
        h.assert_truthy(state.room_presence,
            "south state '" .. state_name .. "' must have room_presence")
    end
end)

---------------------------------------------------------------------------
-- 11. KEYWORDS
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: keywords")

test("north portal has 'door' keyword", function()
    local found = false
    for _, k in ipairs(portal_north_def.keywords) do
        if k == "door" then found = true; break end
    end
    h.assert_truthy(found, "north portal must have 'door' keyword")
end)

test("north portal has 'black iron door' keyword", function()
    local found = false
    for _, k in ipairs(portal_north_def.keywords) do
        if k == "black iron door" then found = true; break end
    end
    h.assert_truthy(found, "north portal must have 'black iron door' keyword")
end)

test("south portal has 'door' keyword", function()
    local found = false
    for _, k in ipairs(portal_south_def.keywords) do
        if k == "door" then found = true; break end
    end
    h.assert_truthy(found, "south portal must have 'door' keyword")
end)

test("south portal has 'black iron door' keyword", function()
    local found = false
    for _, k in ipairs(portal_south_def.keywords) do
        if k == "black iron door" then found = true; break end
    end
    h.assert_truthy(found, "south portal must have 'black iron door' keyword")
end)

test("north portal found by registry keyword 'door'", function()
    local reg = registry_mod.new()
    local pn = deep_copy(portal_north_def)
    reg:register(pn.id, pn)
    local found = reg:find_by_keyword("door")
    h.assert_truthy(found, "registry must find portal by 'door'")
    eq(pn.id, found.id, "found portal should be north portal")
end)

test("north portal found by registry keyword 'black iron door'", function()
    local reg = registry_mod.new()
    local pn = deep_copy(portal_north_def)
    reg:register(pn.id, pn)
    local found = reg:find_by_keyword("black iron door")
    h.assert_truthy(found, "registry must find portal by 'black iron door'")
end)

---------------------------------------------------------------------------
-- 12. PASSAGE CONSTRAINTS
---------------------------------------------------------------------------
suite("STORAGE-DEEP CELLAR PORTAL: passage constraints")

test("north portal has max_carry_size", function()
    h.assert_truthy(portal_north_def.max_carry_size ~= nil,
        "north portal must define max_carry_size")
end)

test("north portal has max_carry_weight", function()
    h.assert_truthy(portal_north_def.max_carry_weight ~= nil,
        "north portal must define max_carry_weight")
end)

test("north portal has player_max_size", function()
    h.assert_truthy(portal_north_def.player_max_size ~= nil,
        "north portal must define player_max_size")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
