-- test/rooms/test-portal-bedroom-cellar.lua
-- TDD tests for the bedroom ↔ cellar trapdoor portal pair (#200).
-- Validates: paired portal objects, FSM (hidden/closed/open), hidden→reveal
-- mechanic, bidirectional sync, room wiring, movement, sensory.
--
-- Usage: lua test/rooms/test-portal-bedroom-cellar.lua
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

local down_ok, portal_down_def = pcall(dofile, obj_dir .. "bedroom-cellar-trapdoor-down.lua")
local up_ok, portal_up_def = pcall(dofile, obj_dir .. "cellar-bedroom-trapdoor-up.lua")
local bedroom_ok, bedroom_def = pcall(dofile, room_dir .. "start-room.lua")
local cellar_ok, cellar_def = pcall(dofile, room_dir .. "cellar.lua")

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

-- Build a game context with the actual bedroom-cellar trapdoor portal pair
local function make_trapdoor_ctx(opts)
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

    local bedroom = {
        id = "start-room",
        name = "The Bedroom",
        description = "A dim bedchamber.",
        contents = opts.bedroom_contents or { pd.id },
        exits = { down = { portal = "bedroom-cellar-trapdoor-down" } },
    }

    local cellar = {
        id = "cellar",
        name = "The Cellar",
        description = "A cold, damp cellar.",
        contents = opts.cellar_contents or { pu.id },
        exits = { up = { portal = "cellar-bedroom-trapdoor-up" } },
    }

    local rooms = {
        ["start-room"] = bedroom,
        ["cellar"] = cellar,
    }

    local start = opts.start_location or "start-room"

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
suite("BEDROOM-CELLAR TRAPDOOR: file loading")

test("down portal file loads without error", function()
    h.assert_truthy(down_ok, "bedroom-cellar-trapdoor-down.lua must load: " .. tostring(portal_down_def))
end)

test("up portal file loads without error", function()
    h.assert_truthy(up_ok, "cellar-bedroom-trapdoor-up.lua must load: " .. tostring(portal_up_def))
end)

test("start-room (bedroom) file loads without error", function()
    h.assert_truthy(bedroom_ok, "start-room.lua must load: " .. tostring(bedroom_def))
end)

test("cellar room file loads without error", function()
    h.assert_truthy(cellar_ok, "cellar.lua must load: " .. tostring(cellar_def))
end)

---------------------------------------------------------------------------
-- 2. PORTAL OBJECT STRUCTURE
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: object structure")

test("down portal has template = 'portal'", function()
    eq("portal", portal_down_def.template, "down portal template")
end)

test("up portal has template = 'portal'", function()
    eq("portal", portal_up_def.template, "up portal template")
end)

test("down portal has correct id", function()
    eq("bedroom-cellar-trapdoor-down", portal_down_def.id, "down portal id")
end)

test("up portal has correct id", function()
    eq("cellar-bedroom-trapdoor-up", portal_up_def.id, "up portal id")
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

test("both portals have material = 'wood'", function()
    eq("wood", portal_down_def.material, "down portal material")
    eq("wood", portal_up_def.material, "up portal material")
end)

---------------------------------------------------------------------------
-- 3. PORTAL METADATA (target, bidirectional_id, direction_hint)
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: portal metadata")

test("down portal targets cellar", function()
    eq("cellar", portal_down_def.portal.target, "down portal target")
end)

test("up portal targets start-room", function()
    eq("start-room", portal_up_def.portal.target, "up portal target")
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
-- 4. FSM STATES — hidden / closed / open
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: FSM states")

test("down portal initial_state is 'hidden'", function()
    eq("hidden", portal_down_def.initial_state, "down initial_state")
end)

test("down portal _state is 'hidden'", function()
    eq("hidden", portal_down_def._state, "down _state")
end)

test("up portal initial_state is 'hidden'", function()
    eq("hidden", portal_up_def.initial_state, "up initial_state")
end)

test("up portal _state is 'hidden'", function()
    eq("hidden", portal_up_def._state, "up _state")
end)

test("down portal has 3 states: hidden, closed, open", function()
    h.assert_truthy(portal_down_def.states.hidden, "down must have hidden state")
    h.assert_truthy(portal_down_def.states.closed, "down must have closed state")
    h.assert_truthy(portal_down_def.states.open, "down must have open state")
end)

test("up portal has 3 states: hidden, closed, open", function()
    h.assert_truthy(portal_up_def.states.hidden, "up must have hidden state")
    h.assert_truthy(portal_up_def.states.closed, "up must have closed state")
    h.assert_truthy(portal_up_def.states.open, "up must have open state")
end)

-- Traversable flags
test("hidden state: traversable = false (both sides)", function()
    eq(false, portal_down_def.states.hidden.traversable, "down hidden traversable")
    eq(false, portal_up_def.states.hidden.traversable, "up hidden traversable")
end)

test("closed state: traversable = false (both sides)", function()
    eq(false, portal_down_def.states.closed.traversable, "down closed traversable")
    eq(false, portal_up_def.states.closed.traversable, "up closed traversable")
end)

test("open state: traversable = true (both sides)", function()
    eq(true, portal_down_def.states.open.traversable, "down open traversable")
    eq(true, portal_up_def.states.open.traversable, "up open traversable")
end)

-- Hidden flag
test("hidden state has hidden = true (both sides)", function()
    eq(true, portal_down_def.states.hidden.hidden, "down hidden state must be hidden")
    eq(true, portal_up_def.states.hidden.hidden, "up hidden state must be hidden")
end)

---------------------------------------------------------------------------
-- 5. FSM TRANSITIONS
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: FSM transitions")

test("down portal: hidden → closed via 'reveal'", function()
    local reg = registry_mod.new()
    local pd = deep_copy(portal_down_def)
    reg:register(pd.id, pd)
    local trans, err = fsm_mod.transition(reg, pd.id, "closed", nil, "reveal")
    h.assert_truthy(trans, "hidden→closed transition must succeed: " .. tostring(err))
    eq("closed", pd._state, "down portal should be in closed state after reveal")
end)

test("down portal: closed → open via 'open'", function()
    local reg = registry_mod.new()
    local pd = deep_copy(portal_down_def)
    pd._state = "closed"
    reg:register(pd.id, pd)
    local trans, err = fsm_mod.transition(reg, pd.id, "open", nil, "open")
    h.assert_truthy(trans, "closed→open transition must succeed: " .. tostring(err))
    eq("open", pd._state, "down portal should be in open state")
end)

test("down portal: open → closed via 'close'", function()
    local reg = registry_mod.new()
    local pd = deep_copy(portal_down_def)
    pd._state = "open"
    reg:register(pd.id, pd)
    local trans, err = fsm_mod.transition(reg, pd.id, "closed", nil, "close")
    h.assert_truthy(trans, "open→closed transition must succeed: " .. tostring(err))
    eq("closed", pd._state, "down portal should be in closed state after close")
end)

test("up portal: hidden → closed via 'reveal'", function()
    local reg = registry_mod.new()
    local pu = deep_copy(portal_up_def)
    reg:register(pu.id, pu)
    local trans, err = fsm_mod.transition(reg, pu.id, "closed", nil, "reveal")
    h.assert_truthy(trans, "hidden→closed transition must succeed: " .. tostring(err))
    eq("closed", pu._state, "up portal should be in closed state after reveal")
end)

test("up portal: closed → open via 'open'", function()
    local reg = registry_mod.new()
    local pu = deep_copy(portal_up_def)
    pu._state = "closed"
    reg:register(pu.id, pu)
    local trans, err = fsm_mod.transition(reg, pu.id, "open", nil, "open")
    h.assert_truthy(trans, "closed→open transition must succeed: " .. tostring(err))
    eq("open", pu._state, "up portal should be in open state")
end)

test("up portal: open → closed via 'close'", function()
    local reg = registry_mod.new()
    local pu = deep_copy(portal_up_def)
    pu._state = "open"
    reg:register(pu.id, pu)
    local trans, err = fsm_mod.transition(reg, pu.id, "closed", nil, "close")
    h.assert_truthy(trans, "open→closed transition must succeed: " .. tostring(err))
    eq("closed", pu._state, "up portal should be in closed state after close")
end)

test("down portal: cannot skip hidden → open directly", function()
    local reg = registry_mod.new()
    local pd = deep_copy(portal_down_def)
    reg:register(pd.id, pd)
    local trans = fsm_mod.transition(reg, pd.id, "open", nil, "open")
    eq(nil, trans, "should not jump from hidden to open (must reveal first)")
    eq("hidden", pd._state, "state should remain hidden")
end)

---------------------------------------------------------------------------
-- 6. SENSORY PROPERTIES (P6 — darkness support)
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: sensory properties")

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

test("closed state has on_feel (darkness sense per state)", function()
    h.assert_truthy(portal_down_def.states.closed.on_feel,
        "closed state should have on_feel for darkness navigation")
end)

test("open state has on_feel (darkness sense per state)", function()
    h.assert_truthy(portal_down_def.states.open.on_feel,
        "open state should have on_feel for darkness navigation")
end)

---------------------------------------------------------------------------
-- 7. MOVEMENT THROUGH TRAPDOOR PORTAL
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: movement")

test("'go down' through open trapdoor moves to cellar", function()
    local ctx = make_trapdoor_ctx({ down_state = "open", up_state = "open" })
    capture_output(function() handlers["go"](ctx, "down") end)
    eq("cellar", ctx.player.location, "player should move to cellar via open trapdoor")
end)

test("'down' direction handler moves to cellar", function()
    local ctx = make_trapdoor_ctx({ down_state = "open", up_state = "open" })
    capture_output(function() handlers["down"](ctx, "") end)
    eq("cellar", ctx.player.location, "'down' shorthand should move to cellar")
end)

test("'go down' through hidden trapdoor is blocked", function()
    local ctx = make_trapdoor_ctx({ down_state = "hidden" })
    local out = capture_output(function() handlers["go"](ctx, "down") end)
    eq("start-room", ctx.player.location, "player should stay in bedroom")
end)

test("'go down' through closed trapdoor is blocked", function()
    local ctx = make_trapdoor_ctx({ down_state = "closed" })
    local out = capture_output(function() handlers["go"](ctx, "down") end)
    eq("start-room", ctx.player.location, "player should stay in bedroom (closed)")
    h.assert_truthy(out:lower():find("closed") or out:lower():find("block")
        or out:lower():find("can't") or out:lower():find("shut"),
        "should print closed/blocked message — got: " .. out)
end)

test("'go up' from cellar through open trapdoor returns to bedroom", function()
    local ctx = make_trapdoor_ctx({
        start_location = "cellar",
        down_state = "open",
        up_state = "open",
    })
    capture_output(function() handlers["go"](ctx, "up") end)
    eq("start-room", ctx.player.location,
        "player should move from cellar back to bedroom via open trapdoor")
end)

test("'up' direction handler returns to bedroom", function()
    local ctx = make_trapdoor_ctx({
        start_location = "cellar",
        down_state = "open",
        up_state = "open",
    })
    capture_output(function() handlers["up"](ctx, "") end)
    eq("start-room", ctx.player.location,
        "'up' shorthand should move from cellar to bedroom")
end)

test("'go up' from cellar through closed trapdoor is blocked", function()
    local ctx = make_trapdoor_ctx({
        start_location = "cellar",
        up_state = "closed",
    })
    local out = capture_output(function() handlers["go"](ctx, "up") end)
    eq("cellar", ctx.player.location, "player should stay in cellar")
    h.assert_truthy(out:lower():find("closed") or out:lower():find("block")
        or out:lower():find("can't") or out:lower():find("shut"),
        "should print closed/blocked message — got: " .. out)
end)

---------------------------------------------------------------------------
-- 8. BIDIRECTIONAL SYNC
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: bidirectional sync")

test("opening down portal syncs up portal to open", function()
    local ctx, pd, pu = make_trapdoor_ctx({ down_state = "closed", up_state = "closed" })
    local helpers = require("engine.verbs.helpers")
    pd._state = "open"
    helpers.sync_bidirectional_portal(ctx, pd)
    eq("open", pu._state, "up portal should sync to open")
end)

test("closing down portal syncs up portal to closed", function()
    local ctx, pd, pu = make_trapdoor_ctx({ down_state = "open", up_state = "open" })
    local helpers = require("engine.verbs.helpers")
    pd._state = "closed"
    helpers.sync_bidirectional_portal(ctx, pd)
    eq("closed", pu._state, "up portal should sync to closed")
end)

test("revealing down portal syncs up portal to closed", function()
    local ctx, pd, pu = make_trapdoor_ctx({ down_state = "hidden", up_state = "hidden" })
    local helpers = require("engine.verbs.helpers")
    pd._state = "closed"
    helpers.sync_bidirectional_portal(ctx, pd)
    eq("closed", pu._state, "up portal should sync to closed after reveal")
end)

test("sync does nothing without bidirectional_id", function()
    local ctx, pd, pu = make_trapdoor_ctx({ down_state = "closed", up_state = "closed" })
    local helpers = require("engine.verbs.helpers")
    pd.portal.bidirectional_id = nil
    pd._state = "open"
    helpers.sync_bidirectional_portal(ctx, pd)
    eq("closed", pu._state, "unlinked portal should not change")
end)

---------------------------------------------------------------------------
-- 9. ROOM WIRING — exits reference portal objects
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: room wiring")

test("start-room exits.down uses portal reference", function()
    h.assert_truthy(bedroom_def.exits, "start-room must have exits")
    h.assert_truthy(bedroom_def.exits.down, "start-room must have a 'down' exit")
    eq("bedroom-cellar-trapdoor-down", bedroom_def.exits.down.portal,
        "start-room down exit must reference bedroom-cellar-trapdoor-down portal")
end)

test("cellar exits.up uses portal reference", function()
    h.assert_truthy(cellar_def.exits, "cellar must have exits")
    h.assert_truthy(cellar_def.exits.up, "cellar must have an 'up' exit")
    eq("cellar-bedroom-trapdoor-up", cellar_def.exits.up.portal,
        "cellar up exit must reference cellar-bedroom-trapdoor-up portal")
end)

test("start-room instances include down portal", function()
    local found = false
    for _, inst in ipairs(bedroom_def.instances or {}) do
        if inst.id == "bedroom-cellar-trapdoor-down" then found = true; break end
    end
    h.assert_truthy(found, "start-room instances must include bedroom-cellar-trapdoor-down")
end)

test("cellar instances include up portal", function()
    local found = false
    for _, inst in ipairs(cellar_def.instances or {}) do
        if inst.id == "cellar-bedroom-trapdoor-up" then found = true; break end
    end
    h.assert_truthy(found, "cellar instances must include cellar-bedroom-trapdoor-up")
end)

test("start-room has no legacy inline down exit", function()
    local exit = bedroom_def.exits.down
    -- A legacy inline exit would have a 'target' field directly on the exit table
    h.assert_truthy(exit.portal, "down exit must use portal reference, not inline target")
    eq(nil, exit.target, "down exit must NOT have legacy inline 'target' field")
end)

test("cellar has no legacy inline up exit", function()
    local exit = cellar_def.exits.up
    h.assert_truthy(exit.portal, "up exit must use portal reference, not inline target")
    eq(nil, exit.target, "up exit must NOT have legacy inline 'target' field")
end)

---------------------------------------------------------------------------
-- 10. KEYWORDS — trapdoor discoverable by multiple names
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: keywords")

test("down portal has 'trap door' keyword", function()
    local found = false
    for _, kw in ipairs(portal_down_def.keywords or {}) do
        if kw:lower() == "trap door" then found = true; break end
    end
    h.assert_truthy(found, "down portal must have 'trap door' keyword")
end)

test("down portal has 'trapdoor' keyword", function()
    local found = false
    for _, kw in ipairs(portal_down_def.keywords or {}) do
        if kw:lower() == "trapdoor" then found = true; break end
    end
    h.assert_truthy(found, "down portal must have 'trapdoor' keyword")
end)

test("down portal has 'iron ring' keyword", function()
    local found = false
    for _, kw in ipairs(portal_down_def.keywords or {}) do
        if kw:lower():find("iron ring") then found = true; break end
    end
    h.assert_truthy(found, "down portal must have 'iron ring' keyword for handle")
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

---------------------------------------------------------------------------
-- 11. PASSAGE CONSTRAINTS
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: passage constraints")

test("down portal has max_carry_size", function()
    h.assert_truthy(portal_down_def.max_carry_size,
        "trapdoor should have max_carry_size (narrow passage)")
    h.assert_truthy(portal_down_def.max_carry_size <= 4,
        "trapdoor max_carry_size should be narrow (≤4)")
end)

test("up portal has matching max_carry_size", function()
    eq(portal_down_def.max_carry_size, portal_up_def.max_carry_size,
        "paired portals should have matching passage constraints")
end)

---------------------------------------------------------------------------
-- 12. TRANSITION MESSAGES — reveal and open produce player-facing text
---------------------------------------------------------------------------
suite("BEDROOM-CELLAR TRAPDOOR: transition messages")

test("reveal transition has a message", function()
    local reveal_trans = nil
    for _, t in ipairs(portal_down_def.transitions) do
        if t.from == "hidden" and t.to == "closed" then reveal_trans = t; break end
    end
    h.assert_truthy(reveal_trans, "hidden→closed transition must exist")
    h.assert_truthy(reveal_trans.message, "reveal transition must have a message")
    h.assert_truthy(#reveal_trans.message > 0, "reveal message must not be empty")
end)

test("open transition has a message", function()
    local open_trans = nil
    for _, t in ipairs(portal_down_def.transitions) do
        if t.from == "closed" and t.to == "open" then open_trans = t; break end
    end
    h.assert_truthy(open_trans, "closed→open transition must exist")
    h.assert_truthy(open_trans.message, "open transition must have a message")
    h.assert_truthy(#open_trans.message > 0, "open message must not be empty")
end)

test("close transition has a message", function()
    local close_trans = nil
    for _, t in ipairs(portal_down_def.transitions) do
        if t.from == "open" and t.to == "closed" then close_trans = t; break end
    end
    h.assert_truthy(close_trans, "open→closed transition must exist")
    h.assert_truthy(close_trans.message, "close transition must have a message")
    h.assert_truthy(#close_trans.message > 0, "close message must not be empty")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
os.exit(exit_code)
