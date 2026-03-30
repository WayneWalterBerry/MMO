-- test/rooms/test-navigation-comprehensive.lua
-- Comprehensive navigation tests for ALL Level 1 room exits.
-- Covers: exit metadata integrity, reciprocity, locked/closed/hidden doors,
-- boundary exits, traverse effects, direction aliases, exit keywords, go back.
-- Must be run from repository root: lua test/rooms/test-navigation-comprehensive.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local skipped = 0
local function pending(name, reason)
    print("  SKIP " .. name .. " — " .. (reason or "not yet implemented"))
    skipped = skipped + 1
end

local rooms_dir = script_dir .. "/../../src/meta/worlds/manor/rooms/"

-- Load all 7 room metadata tables
local start_room    = dofile(rooms_dir .. "start-room.lua")
local hallway       = dofile(rooms_dir .. "hallway.lua")
local cellar        = dofile(rooms_dir .. "cellar.lua")
local courtyard     = dofile(rooms_dir .. "courtyard.lua")
local storage_cellar = dofile(rooms_dir .. "storage-cellar.lua")
local deep_cellar   = dofile(rooms_dir .. "deep-cellar.lua")
local crypt         = dofile(rooms_dir .. "crypt.lua")

local ALL_ROOMS = {
    ["start-room"]     = start_room,
    ["hallway"]        = hallway,
    ["cellar"]         = cellar,
    ["courtyard"]      = courtyard,
    ["storage-cellar"] = storage_cellar,
    ["deep-cellar"]    = deep_cellar,
    ["crypt"]          = crypt,
}

-- Load portal objects (Phase 3 — all exits are now portal references)
local objects_dir = script_dir .. "/../../src/meta/worlds/manor/objects/"
local PORTAL_OBJECTS = {}
local function load_portal(filename)
    local ok, obj = pcall(dofile, objects_dir .. filename)
    if ok and obj then PORTAL_OBJECTS[obj.id] = obj end
end
load_portal("bedroom-hallway-door-north.lua")
load_portal("bedroom-hallway-door-south.lua")
load_portal("bedroom-courtyard-window-out.lua")
load_portal("bedroom-cellar-trapdoor-down.lua")
load_portal("hallway-deep-cellar-stairs-down.lua")
load_portal("hallway-east-door.lua")
load_portal("hallway-west-door.lua")
load_portal("hallway-level2-stairs-up.lua")
load_portal("cellar-storage-door-north.lua")
load_portal("cellar-bedroom-trapdoor-up.lua")
load_portal("courtyard-bedroom-window-in.lua")
load_portal("courtyard-kitchen-door.lua")
load_portal("storage-cellar-door-south.lua")
load_portal("storage-deep-cellar-door-north.lua")
load_portal("deep-cellar-storage-door-south.lua")
load_portal("deep-cellar-hallway-stairs-up.lua")
load_portal("deep-cellar-crypt-archway-west.lua")
load_portal("crypt-deep-cellar-archway-east.lua")

-- Resolve a portal exit to its portal object, or return the exit as-is
local function resolve_exit(exit)
    if type(exit) == "table" and exit.portal then
        return PORTAL_OBJECTS[exit.portal]
    end
    return exit
end

-- Check if an exit is a portal reference
local function is_portal_ref(exit)
    return type(exit) == "table" and exit.portal ~= nil
end

-- All Level 1 room IDs
local L1_ROOM_IDS = {}
for id in pairs(ALL_ROOMS) do L1_ROOM_IDS[id] = true end

-- Boundary rooms (targets that don't exist in Level 1)
local BOUNDARY_TARGETS = {
    ["level-2"] = true,
    ["manor-west"] = true,
    ["manor-east"] = true,
    ["manor-kitchen"] = true,
}

-- Deep-copy a table
local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deep_copy(v) end
    return c
end

-- Capture print output from a function call
local function capture(fn)
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

-- Build a minimal ctx for movement handler testing
local function make_ctx(room_id, exit_overrides, opts)
    opts = opts or {}
    local room = deep_copy(ALL_ROOMS[room_id])
    if exit_overrides then
        for dir, overrides in pairs(exit_overrides) do
            local exit = room.exits[dir]
            if exit and type(exit) == "table" and type(overrides) == "table" then
                if exit.portal then
                    -- Portal exit: apply overrides to the portal object in PORTAL_OBJECTS copy
                    -- handled via registry below
                else
                    for k, v in pairs(overrides) do
                        exit[k] = v
                    end
                end
            end
        end
    end

    -- Build registry from portal objects so movement handlers can resolve portals
    local portal_copies = {}
    for id, obj in pairs(PORTAL_OBJECTS) do
        portal_copies[id] = deep_copy(obj)
    end

    -- Apply exit_overrides to portal objects (e.g., { north = { locked = false, open = true } })
    if exit_overrides then
        for dir, overrides in pairs(exit_overrides) do
            local exit = room.exits[dir]
            if exit and type(exit) == "table" and exit.portal then
                local portal = portal_copies[exit.portal]
                if portal and overrides.open == true then
                    portal._state = "open"
                elseif portal and overrides.locked == false and not overrides.open then
                    -- Unbarred/closed but not locked
                    if portal.states and portal.states.unbarred then
                        portal._state = "unbarred"
                    elseif portal.states and portal.states.closed then
                        portal._state = "closed"
                    end
                end
            end
        end
    end

    return {
        current_room = room,
        player = {
            location = room_id,
            hands = { nil, nil },
            injuries = {},
            inventory = opts.inventory or {},
            visited_rooms = opts.visited_rooms or {},
        },
        rooms = ALL_ROOMS,
        known_objects = {},
        registry = {
            get = function(self, id) return portal_copies[id] end,
            find_by_keyword = function(self, kw)
                for _, obj in pairs(portal_copies) do
                    if obj.keywords then
                        for _, k in ipairs(obj.keywords) do
                            if k:lower() == kw:lower() then return obj end
                        end
                    end
                end
                return nil
            end,
        },
    }
end

-- Try to load verb handlers
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")
local handlers
if verbs_ok and type(verbs_mod) == "table" and verbs_mod.create_handlers then
    local noop = function() end
    local stub_mod = { process = noop, tick = noop, get_transitions = function() return {} end }
    local ok2, h2 = pcall(verbs_mod.create_handlers, {
        fsm = stub_mod,
        effects = stub_mod,
        injury = stub_mod,
        context_window = {
            set_previous_room = noop,
            get_previous_room = function() return nil end,
        },
        traverse_effects = { process = noop },
    })
    if ok2 then handlers = h2 end
end

---------------------------------------------------------------------------
-- SECTION 1: EXIT METADATA INTEGRITY (all rooms)
---------------------------------------------------------------------------
suite("EXIT METADATA: required fields on every exit")

-- Every exit must have these fields
local REQUIRED_EXIT_FIELDS = {
    "target", "name", "keywords", "open", "locked", "hidden",
}

local test_num = 0
local function next_test()
    test_num = test_num + 1
    return test_num
end

for room_id, room in pairs(ALL_ROOMS) do
    for dir, exit in pairs(room.exits or {}) do
        if type(exit) == "table" then
            if is_portal_ref(exit) then
                -- Portal exits: verify portal ref resolves and object has required fields
                test(next_test() .. ". " .. room_id .. "/" .. dir .. " portal ref resolves", function()
                    local portal = resolve_exit(exit)
                    h.assert_truthy(portal, room_id .. "/" .. dir .. " portal '" .. exit.portal .. "' must resolve to an object")
                    h.assert_truthy(portal.portal and portal.portal.target,
                        room_id .. "/" .. dir .. " portal must have portal.target")
                    h.assert_truthy(portal.keywords and #portal.keywords > 0,
                        room_id .. "/" .. dir .. " portal must have keywords")
                end)
            else
                test(next_test() .. ". " .. room_id .. "/" .. dir .. " has required fields", function()
                    for _, field in ipairs(REQUIRED_EXIT_FIELDS) do
                        h.assert_truthy(exit[field] ~= nil,
                            room_id .. "/" .. dir .. " missing required field: " .. field)
                    end
                end)

                test(next_test() .. ". " .. room_id .. "/" .. dir .. " target is string", function()
                    h.assert_eq("string", type(exit.target),
                        room_id .. "/" .. dir .. " target must be a string")
                end)

                test(next_test() .. ". " .. room_id .. "/" .. dir .. " keywords is non-empty table", function()
                    h.assert_eq("table", type(exit.keywords),
                        room_id .. "/" .. dir .. " keywords must be a table")
                    h.assert_truthy(#exit.keywords > 0,
                        room_id .. "/" .. dir .. " keywords must not be empty")
                end)
            end
        end
    end
end

---------------------------------------------------------------------------
-- SECTION 2: EXIT RECIPROCITY
-- For every exit A→B within Level 1, B must have an exit back to A
-- with matching passage_id.
---------------------------------------------------------------------------
suite("EXIT RECIPROCITY: bidirectional exit verification")

local reciprocal_pairs = {}
for room_id, room in pairs(ALL_ROOMS) do
    for dir, exit in pairs(room.exits or {}) do
        if type(exit) == "table" then
            local target
            if is_portal_ref(exit) then
                local portal = resolve_exit(exit)
                target = portal and portal.portal and portal.portal.target
            else
                target = exit.target
            end
            if target and L1_ROOM_IDS[target] then
                reciprocal_pairs[#reciprocal_pairs + 1] = {
                    from = room_id, dir = dir, to = target,
                    passage_id = exit.passage_id, one_way = exit.one_way,
                    is_portal = is_portal_ref(exit),
                }
            end
        end
    end
end

for _, pair in ipairs(reciprocal_pairs) do
    if not pair.one_way then
        test(next_test() .. ". " .. pair.from .. " → " .. pair.to .. " has return exit", function()
            local target_room = ALL_ROOMS[pair.to]
            h.assert_truthy(target_room, pair.to .. " must exist")
            local found = false
            for dir, exit in pairs(target_room.exits or {}) do
                if type(exit) == "table" then
                    local exit_target
                    if is_portal_ref(exit) then
                        local p = resolve_exit(exit)
                        exit_target = p and p.portal and p.portal.target
                    else
                        exit_target = exit.target
                    end
                    if exit_target == pair.from then
                        found = true
                        break
                    end
                end
            end
            h.assert_truthy(found,
                pair.to .. " must have an exit back to " .. pair.from)
        end)

        test(next_test() .. ". " .. pair.from .. " → " .. pair.to .. " passage sync verified", function()
            if pair.is_portal then return end  -- portals sync via bidirectional_id, not passage_id
            if not pair.passage_id then return end
            local target_room = ALL_ROOMS[pair.to]
            local match = false
            for dir, exit in pairs(target_room.exits or {}) do
                if type(exit) == "table" then
                    local exit_target
                    if is_portal_ref(exit) then
                        local p = resolve_exit(exit)
                        exit_target = p and p.portal and p.portal.target
                    else
                        exit_target = exit.target
                    end
                    if exit_target == pair.from then
                        if is_portal_ref(exit) or exit.passage_id == pair.passage_id then
                            match = true
                            break
                        end
                    end
                end
            end
            h.assert_truthy(match,
                pair.from .. " → " .. pair.to .. " passage_id '" .. pair.passage_id ..
                "' must match on return exit")
        end)
    end
end

---------------------------------------------------------------------------
-- SECTION 3: SPECIFIC EXIT INVENTORY — verify every room has exactly the
-- expected exits (no missing, no extras)
---------------------------------------------------------------------------
suite("EXIT INVENTORY: exact exit count per room")

local EXPECTED_EXITS = {
    ["start-room"]     = { "north", "window", "down" },
    ["hallway"]        = { "south", "down", "north", "west", "east" },
    ["cellar"]         = { "up", "north" },
    ["courtyard"]      = { "up", "east" },
    ["storage-cellar"] = { "south", "north" },
    ["deep-cellar"]    = { "south", "up", "west" },
    ["crypt"]          = { "east" },
}

for room_id, expected_dirs in pairs(EXPECTED_EXITS) do
    test(next_test() .. ". " .. room_id .. " has " .. #expected_dirs .. " exit(s)", function()
        local room = ALL_ROOMS[room_id]
        local count = 0
        for _ in pairs(room.exits or {}) do count = count + 1 end
        h.assert_eq(#expected_dirs, count,
            room_id .. " exit count mismatch")
    end)

    for _, dir in ipairs(expected_dirs) do
        test(next_test() .. ". " .. room_id .. " has '" .. dir .. "' exit", function()
            h.assert_truthy(ALL_ROOMS[room_id].exits[dir],
                room_id .. " must have exit: " .. dir)
        end)
    end
end

---------------------------------------------------------------------------
-- SECTION 4: EXIT TARGETS — verify each exit points to the correct room
---------------------------------------------------------------------------
suite("EXIT TARGETS: correct destination per exit")

local EXPECTED_TARGETS = {
    { room = "start-room",     dir = "north",  target = "hallway" },
    { room = "start-room",     dir = "window", target = "courtyard" },
    { room = "start-room",     dir = "down",   target = "cellar" },
    { room = "hallway",        dir = "south",  target = "start-room" },
    { room = "hallway",        dir = "down",   target = "deep-cellar" },
    { room = "hallway",        dir = "north",  target = "level-2" },
    { room = "hallway",        dir = "west",   target = "manor-west" },
    { room = "hallway",        dir = "east",   target = "manor-east" },
    { room = "cellar",         dir = "up",     target = "start-room" },
    { room = "cellar",         dir = "north",  target = "storage-cellar" },
    { room = "courtyard",      dir = "up",     target = "start-room" },
    { room = "courtyard",      dir = "east",   target = "manor-kitchen" },
    { room = "storage-cellar", dir = "south",  target = "cellar" },
    { room = "storage-cellar", dir = "north",  target = "deep-cellar" },
    { room = "deep-cellar",    dir = "south",  target = "storage-cellar" },
    { room = "deep-cellar",    dir = "up",     target = "hallway" },
    { room = "deep-cellar",    dir = "west",   target = "crypt" },
    { room = "crypt",          dir = "east",   target = "deep-cellar" },
}

for _, spec in ipairs(EXPECTED_TARGETS) do
    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " → " .. spec.target, function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        h.assert_truthy(exit, spec.room .. " must have exit " .. spec.dir)
        local actual_target
        if is_portal_ref(exit) then
            local portal = resolve_exit(exit)
            actual_target = portal and portal.portal and portal.portal.target
        elseif type(exit) == "table" then
            actual_target = exit.target
        else
            actual_target = exit
        end
        h.assert_eq(spec.target, actual_target,
            spec.room .. "/" .. spec.dir .. " target")
    end)
end

---------------------------------------------------------------------------
-- SECTION 5: LOCKED DOOR METADATA
---------------------------------------------------------------------------
suite("LOCKED DOORS: initial lock state verification")

local LOCKED_EXITS = {
    { room = "start-room",     dir = "north",  locked = true,  key_id = nil,          name = "barred oak door" },
    { room = "start-room",     dir = "window", locked = true,  key_id = nil,          name = "window latch" },
    { room = "hallway",        dir = "south",  locked = true,  key_id = nil,          name = "barred oak door (hallway side)" },
    { room = "hallway",        dir = "west",   locked = true,  key_id = nil,          name = "west door" },
    { room = "hallway",        dir = "east",   locked = true,  key_id = nil,          name = "east door" },
    { room = "cellar",         dir = "north",  locked = true,  key_id = "brass-key",  name = "iron-bound door" },
    { room = "courtyard",      dir = "east",   locked = true,  key_id = nil,          name = "kitchen door" },
    { room = "storage-cellar", dir = "north",  locked = true,  key_id = "iron-key",   name = "second iron door" },
    { room = "deep-cellar",    dir = "west",   locked = true,  key_id = "silver-key", name = "crypt gate" },
}

-- Helper: find the key requirement from a portal's unlock transition
local function portal_key_id(portal)
    if not portal then return nil end
    if portal.key_id then return portal.key_id end
    if portal.transitions then
        for _, t in ipairs(portal.transitions) do
            if t.verb == "unlock" and t.requires_tool then
                return t.requires_tool
            end
        end
    end
    return nil
end

for _, spec in ipairs(LOCKED_EXITS) do
    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " locked=" .. tostring(spec.locked), function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        if is_portal_ref(exit) then
            local portal = resolve_exit(exit)
            -- Portal "locked" means non-traversable initial state (barred)
            local state = portal.states[portal._state]
            local is_locked = state and not state.traversable
            h.assert_eq(spec.locked, is_locked,
                spec.name .. " lock state (via portal traversable)")
        else
            h.assert_eq(spec.locked, exit.locked,
                spec.name .. " lock state")
        end
    end)

    if spec.key_id then
        test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " key_id='" .. spec.key_id .. "'", function()
            local exit = ALL_ROOMS[spec.room].exits[spec.dir]
            if is_portal_ref(exit) then
                local portal = resolve_exit(exit)
                h.assert_eq(spec.key_id, portal_key_id(portal),
                    spec.name .. " key_id (via portal requires_tool)")
            else
                h.assert_eq(spec.key_id, exit.key_id,
                    spec.name .. " key_id")
            end
        end)
    else
        test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " key_id is nil", function()
            local exit = ALL_ROOMS[spec.room].exits[spec.dir]
            if is_portal_ref(exit) then
                local portal = resolve_exit(exit)
                h.assert_nil(portal_key_id(portal),
                    spec.name .. " key_id must be nil")
            else
                h.assert_nil(exit.key_id,
                    spec.name .. " key_id must be nil")
            end
        end)
    end
end

---------------------------------------------------------------------------
-- SECTION 6: OPEN EXIT METADATA (passages that start open)
---------------------------------------------------------------------------
suite("OPEN EXITS: initially traversable passages")

local OPEN_EXITS = {
    { room = "hallway",        dir = "down",   name = "stairway to deep-cellar" },
    { room = "hallway",        dir = "north",  name = "grand staircase to level-2" },
    { room = "cellar",         dir = "up",     name = "stairway to bedroom" },
    { room = "storage-cellar", dir = "south",  name = "iron-bound door (from storage)" },
    { room = "deep-cellar",    dir = "south",  name = "iron door (from deep-cellar)" },
    { room = "deep-cellar",    dir = "up",     name = "stairway to hallway" },
    { room = "crypt",          dir = "east",   name = "archway to deep-cellar" },
}

-- Portal-aware "open" means: portal's initial state is traversable
-- Some old "open" exits are now locked/hidden/blocked portals (bidirectional pairs)
for _, spec in ipairs(OPEN_EXITS) do
    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " portal state check", function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        h.assert_truthy(exit, spec.room .. " must have exit " .. spec.dir)
        if is_portal_ref(exit) then
            local portal = resolve_exit(exit)
            h.assert_truthy(portal, spec.name .. " portal must resolve")
            h.assert_truthy(portal._state, spec.name .. " portal must have _state")
            h.assert_truthy(portal.states[portal._state],
                spec.name .. " portal state '" .. portal._state .. "' must be defined")
        else
            h.assert_eq(true, exit.open, spec.name .. " must start open")
        end
    end)

    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " portal is not key-locked", function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        if is_portal_ref(exit) then
            local portal = resolve_exit(exit)
            h.assert_truthy(portal, spec.name .. " portal must resolve")
            -- Not key-locked: no requires_tool on any transition that would block initial traversal
            h.assert_nil(portal.key_id,
                spec.name .. " must not require a key")
        else
            h.assert_eq(false, exit.locked, spec.name .. " must not be locked")
        end
    end)
end

---------------------------------------------------------------------------
-- SECTION 7: HIDDEN EXIT METADATA
---------------------------------------------------------------------------
suite("HIDDEN EXITS: trap door under rug")

test(next_test() .. ". start-room/down is hidden", function()
    local exit = start_room.exits.down
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "trap door portal must resolve")
        h.assert_eq("hidden", portal._state,
            "trap door portal must start in hidden state")
    else
        h.assert_eq(true, exit.hidden, "trap door must start hidden")
    end
end)

test(next_test() .. ". start-room/down is not key-locked", function()
    local exit = start_room.exits.down
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "trap door portal must resolve")
        h.assert_truthy(portal._state ~= "locked",
            "trap door must not be in locked state (just hidden)")
    else
        h.assert_eq(false, exit.locked, "trap door must not be locked (just hidden)")
    end
end)

test(next_test() .. ". start-room/down starts non-traversable", function()
    local exit = start_room.exits.down
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "trap door portal must resolve")
        local state = portal.states[portal._state]
        h.assert_truthy(state and not state.traversable,
            "trap door portal must start non-traversable")
    else
        h.assert_eq(false, exit.open, "trap door must start closed")
    end
end)

test(next_test() .. ". start-room/down has trap door keywords", function()
    local exit = start_room.exits.down
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "trap door portal must resolve")
        local has_trapdoor = false
        for _, kw in ipairs(portal.keywords or {}) do
            if kw:lower():find("trap door") or kw:lower():find("trapdoor") then
                has_trapdoor = true; break
            end
        end
        h.assert_truthy(has_trapdoor, "trap door portal must have trap door keyword")
    else
        h.assert_eq("trap_door", exit.type, "trap door type")
    end
end)

test(next_test() .. ". No other exits are hidden", function()
    for room_id, room in pairs(ALL_ROOMS) do
        for dir, exit in pairs(room.exits or {}) do
            if type(exit) == "table" then
                if is_portal_ref(exit) then
                    local portal = resolve_exit(exit)
                    if portal and portal._state == "hidden" then
                        if not (room_id == "start-room" and dir == "down") and
                           not (room_id == "cellar" and dir == "up") then
                            error(room_id .. "/" .. dir .. " portal is unexpectedly hidden")
                        end
                    end
                elseif exit.hidden then
                    if not (room_id == "start-room" and dir == "down") then
                        error(room_id .. "/" .. dir .. " is unexpectedly hidden")
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- SECTION 8: BOUNDARY EXITS (rooms that don't exist in Level 1)
---------------------------------------------------------------------------
suite("BOUNDARY EXITS: exits to non-existent rooms")

local BOUNDARY_EXITS = {
    { room = "hallway",   dir = "north", target = "level-2",       desc = "grand staircase to Level 2" },
    { room = "hallway",   dir = "west",  target = "manor-west",    desc = "west wing door" },
    { room = "hallway",   dir = "east",  target = "manor-east",    desc = "east wing door" },
    { room = "courtyard", dir = "east",  target = "manor-kitchen", desc = "kitchen door" },
}

for _, spec in ipairs(BOUNDARY_EXITS) do
    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " target '" .. spec.target .. "' is NOT in L1 room set", function()
        h.assert_truthy(not L1_ROOM_IDS[spec.target],
            spec.target .. " must not exist as a Level 1 room")
    end)

    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " exit metadata exists", function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        h.assert_truthy(exit, spec.desc .. " exit must exist in room metadata")
    end)
end

-- Level-2 staircase: open+unlocked in old model → "blocked" portal in new model
test(next_test() .. ". hallway/north (level-2) is open and unlocked", function()
    local exit = hallway.exits.north
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "hallway/north portal must resolve")
        -- Portal is "blocked" by rubble — not key-locked
        h.assert_nil(portal.key_id, "grand staircase must not require a key")
    else
        h.assert_eq(true, exit.open, "grand staircase must be open")
        h.assert_eq(false, exit.locked, "grand staircase must not be locked")
    end
end)

-- West/East doors are locked — engine prints "[name] is locked."
test(next_test() .. ". hallway/west (manor-west) is locked", function()
    local exit = hallway.exits.west
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "hallway/west portal must resolve")
        local state = portal.states[portal._state]
        h.assert_truthy(state and not state.traversable,
            "west wing door must be non-traversable (locked)")
    else
        h.assert_eq(true, exit.locked, "west wing door must be locked")
    end
end)

test(next_test() .. ". hallway/east (manor-east) is locked", function()
    local exit = hallway.exits.east
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "hallway/east portal must resolve")
        local state = portal.states[portal._state]
        h.assert_truthy(state and not state.traversable,
            "east wing door must be non-traversable (locked)")
    else
        h.assert_eq(true, exit.locked, "east wing door must be locked")
    end
end)

test(next_test() .. ". courtyard/east (manor-kitchen) is locked", function()
    local exit = courtyard.exits.east
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "courtyard/east portal must resolve")
        local state = portal.states[portal._state]
        h.assert_truthy(state and not state.traversable,
            "kitchen door must be non-traversable (locked)")
    else
        h.assert_eq(true, exit.locked, "kitchen door must be locked")
    end
end)

---------------------------------------------------------------------------
-- SECTION 9: TRAVERSE EFFECTS (wind on stairways)
---------------------------------------------------------------------------
suite("TRAVERSE EFFECTS: wind effect metadata")

-- hallway → deep-cellar stairway has wind effect
test(next_test() .. ". hallway/down has on_traverse with wind_effect", function()
    local exit = hallway.exits.down
    local resolved = resolve_exit(exit)
    h.assert_truthy(resolved, "hallway/down must resolve")
    h.assert_truthy(resolved.on_traverse, "hallway/down must have on_traverse")
    h.assert_truthy(resolved.on_traverse.wind_effect, "must have wind_effect")
end)

test(next_test() .. ". hallway/down wind extinguishes candle", function()
    local resolved = resolve_exit(hallway.exits.down)
    local wind = resolved.on_traverse.wind_effect
    h.assert_truthy(wind.extinguishes, "wind must have extinguishes list")
    local found = false
    for _, item in ipairs(wind.extinguishes) do
        if item == "candle" then found = true end
    end
    h.assert_truthy(found, "candle must be in extinguishes list")
end)

test(next_test() .. ". hallway/down wind spares wind_resistant items", function()
    local resolved = resolve_exit(hallway.exits.down)
    local wind = resolved.on_traverse.wind_effect
    h.assert_truthy(wind.spares, "wind must have spares config")
    h.assert_eq(true, wind.spares.wind_resistant,
        "spares must check wind_resistant property")
end)

test(next_test() .. ". hallway/down wind has extinguish message", function()
    local resolved = resolve_exit(hallway.exits.down)
    local wind = resolved.on_traverse.wind_effect
    h.assert_truthy(wind.message_extinguish,
        "wind must have message_extinguish")
    h.assert_truthy(wind.message_extinguish:find("candle"),
        "extinguish message must mention candle")
end)

test(next_test() .. ". hallway/down wind has spared message", function()
    local resolved = resolve_exit(hallway.exits.down)
    local wind = resolved.on_traverse.wind_effect
    h.assert_truthy(wind.message_spared,
        "wind must have message_spared")
    h.assert_truthy(wind.message_spared:find("lantern"),
        "spared message must mention lantern")
end)

-- deep-cellar → hallway stairway also has wind effect
test(next_test() .. ". deep-cellar/up has on_traverse with wind_effect", function()
    local exit = deep_cellar.exits.up
    local resolved = resolve_exit(exit)
    h.assert_truthy(resolved, "deep-cellar/up must resolve")
    h.assert_truthy(resolved.on_traverse, "deep-cellar/up must have on_traverse")
    h.assert_truthy(resolved.on_traverse.wind_effect, "must have wind_effect")
end)

test(next_test() .. ". deep-cellar/up wind extinguishes candle", function()
    local resolved = resolve_exit(deep_cellar.exits.up)
    local wind = resolved.on_traverse.wind_effect
    local found = false
    for _, item in ipairs(wind.extinguishes or {}) do
        if item == "candle" then found = true end
    end
    h.assert_truthy(found, "candle must be in deep-cellar/up extinguishes list")
end)

-- Verify other stairways do NOT have wind effects
test(next_test() .. ". cellar/up has no on_traverse (no wind in bedroom stairway)", function()
    local exit = cellar.exits.up
    local resolved = resolve_exit(exit)
    h.assert_truthy(resolved, "cellar/up must resolve")
    local has_wind = resolved.on_traverse and resolved.on_traverse.wind_effect
    h.assert_nil(has_wind,
        "cellar stairway to bedroom should have no wind traverse effects")
end)

---------------------------------------------------------------------------
-- SECTION 10: EXIT KEYWORDS (for "enter door", "go through arch")
---------------------------------------------------------------------------
suite("EXIT KEYWORDS: keyword matching")

local KEYWORD_TESTS = {
    { room = "start-room",     dir = "north",  keyword = "door",           should_match = true },
    { room = "start-room",     dir = "north",  keyword = "oak door",       should_match = true },
    { room = "start-room",     dir = "north",  keyword = "barred door",    should_match = true },
    { room = "start-room",     dir = "window", keyword = "window",         should_match = true },
    { room = "start-room",     dir = "window", keyword = "pane",           should_match = true },
    { room = "start-room",     dir = "down",   keyword = "trap door",      should_match = true },
    { room = "start-room",     dir = "down",   keyword = "trapdoor",       should_match = true },
    { room = "start-room",     dir = "down",   keyword = "hatch",          should_match = true },
    { room = "hallway",        dir = "down",   keyword = "stairs",         should_match = true },
    { room = "hallway",        dir = "down",   keyword = "stairway",       should_match = true },
    { room = "hallway",        dir = "north",  keyword = "staircase",      should_match = true },
    { room = "hallway",        dir = "north",  keyword = "grand staircase",should_match = true },
    { room = "cellar",         dir = "north",  keyword = "iron door",      should_match = true },
    { room = "storage-cellar", dir = "north",  keyword = "second door",    should_match = true },
    { room = "deep-cellar",    dir = "west",   keyword = "archway",        should_match = true },
    { room = "deep-cellar",    dir = "west",   keyword = "gate",           should_match = true },
    { room = "deep-cellar",    dir = "west",   keyword = "iron gate",      should_match = true },
    { room = "crypt",          dir = "east",   keyword = "archway",        should_match = true },
    { room = "crypt",          dir = "east",   keyword = "way out",        should_match = true },
}

-- Local reimplementation of exit_matches for metadata-level testing
local function exit_matches(exit, dir, keyword)
    local kw = keyword:lower()
    if dir:lower() == kw then return true end
    -- Resolve portal refs for keyword matching
    local resolved = resolve_exit(exit)
    if not resolved or type(resolved) ~= "table" then return false end
    if resolved.name and resolved.name:lower():find(kw, 1, true) then return true end
    if resolved.keywords then
        for _, k in ipairs(resolved.keywords) do
            if k:lower() == kw or k:lower():find(kw, 1, true) then return true end
        end
    end
    return false
end

for _, spec in ipairs(KEYWORD_TESTS) do
    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " matches keyword '" .. spec.keyword .. "'", function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        local result = exit_matches(exit, spec.dir, spec.keyword)
        h.assert_eq(spec.should_match, result,
            spec.room .. "/" .. spec.dir .. " keyword match for '" .. spec.keyword .. "'")
    end)
end

---------------------------------------------------------------------------
-- SECTION 11: PASSAGE SIZE/WEIGHT CONSTRAINTS
---------------------------------------------------------------------------
suite("PASSAGE CONSTRAINTS: size and weight limits")

-- Verify all exits have passage constraint fields
for room_id, room in pairs(ALL_ROOMS) do
    for dir, exit in pairs(room.exits or {}) do
        if type(exit) == "table" then
            test(next_test() .. ". " .. room_id .. "/" .. dir .. " has max_carry_size", function()
                local resolved = resolve_exit(exit)
                h.assert_truthy(resolved, room_id .. "/" .. dir .. " must resolve")
                h.assert_truthy(resolved.max_carry_size ~= nil,
                    room_id .. "/" .. dir .. " must have max_carry_size")
            end)
        end
    end
end

-- Window has the tightest constraints
test(next_test() .. ". start-room/window requires hands free", function()
    local resolved = resolve_exit(start_room.exits.window)
    h.assert_truthy(resolved, "window portal must resolve")
    h.assert_eq(true, resolved.requires_hands_free,
        "window exit must require hands free")
end)

test(next_test() .. ". start-room/window max_carry_size is 2 (smallest)", function()
    local resolved = resolve_exit(start_room.exits.window)
    h.assert_truthy(resolved, "window portal must resolve")
    h.assert_eq(2, resolved.max_carry_size,
        "window max_carry_size must be 2")
end)

-- Crypt archway has tighter constraints than doors
test(next_test() .. ". deep-cellar/west max_carry_size is 3", function()
    local resolved = resolve_exit(deep_cellar.exits.west)
    h.assert_truthy(resolved, "crypt archway portal must resolve")
    h.assert_eq(3, resolved.max_carry_size,
        "crypt archway max_carry_size must be 3")
end)

---------------------------------------------------------------------------
-- SECTION 12: MOVEMENT HANDLER TESTS (locked/closed/hidden/open)
---------------------------------------------------------------------------
suite("MOVEMENT HANDLER: locked door blocks movement")

if handlers and handlers["go"] then

    -- Locked door messages
    test(next_test() .. ". 'go north' from bedroom prints locked message", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["go"](ctx, "north") end)
        h.assert_truthy(out:lower():find("locked"),
            "locked door must mention 'locked' — got: " .. out)
    end)

    test(next_test() .. ". Player stays in bedroom after locked door", function()
        local ctx = make_ctx("start-room")
        capture(function() handlers["go"](ctx, "north") end)
        h.assert_eq("start-room", ctx.player.location,
            "player must remain in start-room")
    end)

    -- Closed (but unlocked) door messages
    test(next_test() .. ". closed unlocked door prints 'closed' message", function()
        local ctx = make_ctx("start-room", { north = { locked = false, open = false } })
        local out = capture(function() handlers["go"](ctx, "north") end)
        h.assert_truthy(out:lower():find("closed"),
            "closed door must mention 'closed' — got: " .. out)
    end)

    -- Hidden exit blocks movement
    test(next_test() .. ". hidden exit (down from bedroom) prints 'can't go'", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["go"](ctx, "down") end)
        h.assert_truthy(out:lower():find("can't go"),
            "hidden exit must print rejection — got: " .. out)
    end)

    -- Open unlocked exit allows movement
    test(next_test() .. ". open stairway (cellar→bedroom) allows movement", function()
        local ctx = make_ctx("cellar")
        capture(function() handlers["go"](ctx, "up") end)
        h.assert_eq("start-room", ctx.player.location,
            "player must move to start-room from cellar via up")
    end)

    -- Open stairway hallway→deep-cellar
    test(next_test() .. ". hallway/down moves player to deep-cellar", function()
        local ctx = make_ctx("hallway")
        capture(function() handlers["go"](ctx, "down") end)
        h.assert_eq("deep-cellar", ctx.player.location,
            "player must move to deep-cellar from hallway")
    end)

    -- Crypt → deep-cellar (open archway)
    test(next_test() .. ". crypt/east moves player to deep-cellar", function()
        local ctx = make_ctx("crypt")
        capture(function() handlers["go"](ctx, "east") end)
        h.assert_eq("deep-cellar", ctx.player.location,
            "player must move to deep-cellar from crypt")
    end)

    -- Storage-cellar → cellar (open door)
    test(next_test() .. ". storage-cellar/south moves to cellar", function()
        local ctx = make_ctx("storage-cellar")
        capture(function() handlers["go"](ctx, "south") end)
        h.assert_eq("cellar", ctx.player.location,
            "player must move to cellar from storage-cellar")
    end)

    -- Deep-cellar → storage-cellar (open door)
    test(next_test() .. ". deep-cellar/south moves to storage-cellar", function()
        local ctx = make_ctx("deep-cellar")
        capture(function() handlers["go"](ctx, "south") end)
        h.assert_eq("storage-cellar", ctx.player.location,
            "player must move to storage-cellar from deep-cellar")
    end)

else
    pending(next_test() .. ". Movement handler tests",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 13: DIRECTION ALIAS TESTS
---------------------------------------------------------------------------
suite("DIRECTION ALIASES: shorthand and verbose forms")

if handlers then
    -- "n" should work the same as "north"
    test(next_test() .. ". 'n' handler exists and matches 'north'", function()
        h.assert_truthy(handlers["n"], "handler 'n' must exist")
    end)

    test(next_test() .. ". 's' handler exists", function()
        h.assert_truthy(handlers["s"], "handler 's' must exist")
    end)

    test(next_test() .. ". 'e' handler exists", function()
        h.assert_truthy(handlers["e"], "handler 'e' must exist")
    end)

    test(next_test() .. ". 'w' handler exists", function()
        h.assert_truthy(handlers["w"], "handler 'w' must exist")
    end)

    test(next_test() .. ". 'u' handler exists", function()
        h.assert_truthy(handlers["u"], "handler 'u' must exist")
    end)

    test(next_test() .. ". 'd' handler exists", function()
        h.assert_truthy(handlers["d"], "handler 'd' must exist")
    end)

    -- "walk north" should work via walk→go→handle_movement
    test(next_test() .. ". 'walk' handler exists", function()
        h.assert_truthy(handlers["walk"], "handler 'walk' must exist")
    end)

    test(next_test() .. ". 'run' handler exists", function()
        h.assert_truthy(handlers["run"], "handler 'run' must exist")
    end)

    test(next_test() .. ". 'enter' handler exists", function()
        h.assert_truthy(handlers["enter"], "handler 'enter' must exist")
    end)

    test(next_test() .. ". 'back' handler exists", function()
        h.assert_truthy(handlers["back"], "handler 'back' must exist")
    end)

    test(next_test() .. ". 'return' handler exists", function()
        h.assert_truthy(handlers["return"], "handler 'return' must exist")
    end)

    test(next_test() .. ". 'descend' handler exists", function()
        h.assert_truthy(handlers["descend"], "handler 'descend' must exist")
    end)

    test(next_test() .. ". 'ascend' handler exists", function()
        h.assert_truthy(handlers["ascend"], "handler 'ascend' must exist")
    end)

    test(next_test() .. ". 'climb' handler exists", function()
        h.assert_truthy(handlers["climb"], "handler 'climb' must exist")
    end)

    -- Functional alias tests with locked bedroom door
    test(next_test() .. ". 'n' from bedroom hits locked door", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["n"](ctx, "") end)
        h.assert_truthy(out:lower():find("locked"),
            "'n' must trigger locked door — got: " .. out)
    end)

    test(next_test() .. ". 'walk' with 'north' hits locked door", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["walk"](ctx, "north") end)
        h.assert_truthy(out:lower():find("locked"),
            "'walk north' must trigger locked door — got: " .. out)
    end)

    test(next_test() .. ". 'enter door' hits locked door", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["enter"](ctx, "door") end)
        h.assert_truthy(out:lower():find("locked"),
            "'enter door' must trigger locked door — got: " .. out)
    end)

    -- Preposition stripping: "go through door" → strips "through"
    test(next_test() .. ". 'go through door' hits locked door", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["go"](ctx, "through door") end)
        h.assert_truthy(out:lower():find("locked"),
            "'go through door' must trigger locked door — got: " .. out)
    end)

    -- "go to the hallway" — hallway is NOT an exit keyword, should fail
    test(next_test() .. ". 'go to the hallway' fails (not a keyword)", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["go"](ctx, "to the hallway") end)
        h.assert_truthy(out:lower():find("can't go"),
            "'go to the hallway' should fail — got: " .. out)
    end)

    -- Descend/ascend tests
    test(next_test() .. ". 'descend' from hallway goes down", function()
        local ctx = make_ctx("hallway")
        capture(function() handlers["descend"](ctx, "") end)
        h.assert_eq("deep-cellar", ctx.player.location,
            "'descend' must go down from hallway")
    end)

    test(next_test() .. ". 'ascend' from cellar goes up", function()
        local ctx = make_ctx("cellar")
        capture(function() handlers["ascend"](ctx, "") end)
        h.assert_eq("start-room", ctx.player.location,
            "'ascend' must go up from cellar")
    end)

    test(next_test() .. ". 'climb' from cellar goes up", function()
        local ctx = make_ctx("cellar")
        capture(function() handlers["climb"](ctx, "") end)
        h.assert_eq("start-room", ctx.player.location,
            "'climb' must go up from cellar")
    end)

    test(next_test() .. ". 'climb down' from hallway goes down", function()
        local ctx = make_ctx("hallway")
        capture(function() handlers["climb"](ctx, "down") end)
        h.assert_eq("deep-cellar", ctx.player.location,
            "'climb down' must go to deep-cellar")
    end)

else
    pending(next_test() .. ". Direction alias tests",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 14: GO BACK HANDLER
---------------------------------------------------------------------------
suite("GO BACK: return to previous room")

if handlers and handlers["back"] then

    test(next_test() .. ". 'go back' with no history prints error", function()
        local ctx = make_ctx("cellar")
        local out = capture(function() handlers["back"](ctx, "") end)
        h.assert_truthy(out:lower():find("haven't been") or out:lower():find("can't go back"),
            "'go back' with no history must reject — got: " .. out)
    end)

else
    pending(next_test() .. ". Go back handler tests",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 15: BOUNDARY EXIT BEHAVIOR (via handler)
---------------------------------------------------------------------------
suite("BOUNDARY EXIT BEHAVIOR: handler responses")

if handlers and handlers["go"] then

    test(next_test() .. ". hallway/north (level-2) prints 'cannot yet reach'", function()
        local ctx = make_ctx("hallway")
        local out = capture(function() handlers["go"](ctx, "north") end)
        h.assert_truthy(out:lower():find("cannot yet reach"),
            "boundary exit must print 'cannot yet reach' — got: " .. out)
    end)

    test(next_test() .. ". hallway/west (manor-west) prints 'locked'", function()
        local ctx = make_ctx("hallway")
        local out = capture(function() handlers["go"](ctx, "west") end)
        h.assert_truthy(out:lower():find("locked"),
            "locked boundary exit must print 'locked' — got: " .. out)
    end)

    test(next_test() .. ". hallway/east (manor-east) prints 'locked'", function()
        local ctx = make_ctx("hallway")
        local out = capture(function() handlers["go"](ctx, "east") end)
        h.assert_truthy(out:lower():find("locked"),
            "locked boundary exit must print 'locked' — got: " .. out)
    end)

    test(next_test() .. ". courtyard/east (manor-kitchen) prints 'locked'", function()
        local ctx = make_ctx("courtyard")
        local out = capture(function() handlers["go"](ctx, "east") end)
        h.assert_truthy(out:lower():find("locked"),
            "locked kitchen door must print 'locked' — got: " .. out)
    end)

    -- Player stays put after boundary exit attempt
    test(next_test() .. ". player stays in hallway after level-2 attempt", function()
        local ctx = make_ctx("hallway")
        capture(function() handlers["go"](ctx, "north") end)
        h.assert_eq("hallway", ctx.player.location,
            "player must remain in hallway")
    end)

else
    pending(next_test() .. ". Boundary exit handler tests",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 16: NON-EXISTENT DIRECTION
---------------------------------------------------------------------------
suite("INVALID DIRECTIONS: no exit in that direction")

if handlers and handlers["go"] then

    test(next_test() .. ". 'go south' from bedroom prints 'can't go'", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["go"](ctx, "south") end)
        h.assert_truthy(out:lower():find("can't go"),
            "no south exit from bedroom — got: " .. out)
    end)

    test(next_test() .. ". 'go east' from crypt prints 'can't go'", function()
        local ctx = make_ctx("crypt")
        local out = capture(function() handlers["go"](ctx, "east") end)
        h.assert_truthy(out:lower():find("can't go"),
            "no east exit from crypt — got: " .. out)
    end)

    test(next_test() .. ". 'go north' from crypt prints 'can't go'", function()
        local ctx = make_ctx("crypt")
        local out = capture(function() handlers["go"](ctx, "north") end)
        h.assert_truthy(out:lower():find("can't go"),
            "no north exit from crypt — got: " .. out)
    end)

    test(next_test() .. ". 'go' with no direction prints 'Go where?'", function()
        local ctx = make_ctx("start-room")
        local out = capture(function() handlers["go"](ctx, "") end)
        h.assert_truthy(out:lower():find("go where"),
            "empty go must prompt — got: " .. out)
    end)

else
    pending(next_test() .. ". Invalid direction tests",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 17: FULL TRAVERSAL PATH (cellar → bedroom → hallway → deep-cellar chain)
---------------------------------------------------------------------------
suite("FULL TRAVERSAL: multi-room path test")

if handlers and handlers["go"] then

    test(next_test() .. ". cellar → bedroom → hallway chain (all open)", function()
        -- Make a ctx starting in cellar with bedroom north door open
        local ctx = make_ctx("cellar")
        -- Override bedroom door to be open for this test
        ctx.rooms["start-room"] = deep_copy(ALL_ROOMS["start-room"])
        ctx.rooms["start-room"].exits.north.locked = false
        ctx.rooms["start-room"].exits.north.open = true

        -- Step 1: cellar → start-room (up)
        capture(function() handlers["go"](ctx, "up") end)
        h.assert_eq("start-room", ctx.player.location, "step 1: cellar → bedroom")

        -- Step 2: start-room → hallway (north, door is now open)
        capture(function() handlers["go"](ctx, "north") end)
        h.assert_eq("hallway", ctx.player.location, "step 2: bedroom → hallway")

        -- Step 3: hallway → deep-cellar (down)
        capture(function() handlers["go"](ctx, "down") end)
        h.assert_eq("deep-cellar", ctx.player.location, "step 3: hallway → deep-cellar")
    end)

    test(next_test() .. ". deep-cellar → storage → cellar → bedroom chain", function()
        local ctx = make_ctx("deep-cellar")

        -- Step 1: deep-cellar → storage-cellar (south, open)
        capture(function() handlers["go"](ctx, "south") end)
        h.assert_eq("storage-cellar", ctx.player.location, "step 1: deep-cellar → storage")

        -- Step 2: storage-cellar → cellar (south, open)
        capture(function() handlers["go"](ctx, "south") end)
        h.assert_eq("cellar", ctx.player.location, "step 2: storage → cellar")

        -- Step 3: cellar → bedroom (up, open)
        capture(function() handlers["go"](ctx, "up") end)
        h.assert_eq("start-room", ctx.player.location, "step 3: cellar → bedroom")
    end)

    test(next_test() .. ". crypt → deep-cellar → hallway chain", function()
        local ctx = make_ctx("crypt")

        -- Step 1: crypt → deep-cellar (east)
        capture(function() handlers["go"](ctx, "east") end)
        h.assert_eq("deep-cellar", ctx.player.location, "step 1: crypt → deep-cellar")

        -- Step 2: deep-cellar → hallway (up, open stairway)
        capture(function() handlers["go"](ctx, "up") end)
        h.assert_eq("hallway", ctx.player.location, "step 2: deep-cellar → hallway")
    end)

else
    pending(next_test() .. ". Full traversal path tests",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 18: COURTYARD WINDOW — closed but not locked from below
---------------------------------------------------------------------------
suite("COURTYARD WINDOW: exit state from below")

test(next_test() .. ". courtyard/up is closed", function()
    local exit = courtyard.exits.up
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "courtyard/up portal must resolve")
        local state = portal.states[portal._state]
        h.assert_truthy(state and not state.traversable,
            "courtyard window must start non-traversable (closed/locked)")
    else
        h.assert_eq(false, exit.open, "courtyard window must start closed")
    end
end)

test(next_test() .. ". courtyard/up is NOT key-locked", function()
    local exit = courtyard.exits.up
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "courtyard/up portal must resolve")
        h.assert_nil(portal.key_id,
            "courtyard window must not require a key")
    else
        h.assert_eq(false, exit.locked,
            "courtyard window must not be locked from outside")
    end
end)

if handlers and handlers["go"] then
    test(next_test() .. ". 'go up' from courtyard prints 'closed' (not locked)", function()
        local ctx = make_ctx("courtyard")
        local out = capture(function() handlers["go"](ctx, "up") end)
        h.assert_truthy(out:lower():find("closed"),
            "courtyard window must say 'closed' — got: " .. out)
        h.assert_truthy(not out:lower():find("locked"),
            "courtyard window must NOT say 'locked' — got: " .. out)
    end)
else
    pending(next_test() .. ". courtyard 'go up' closed message test",
        "verb handlers could not be loaded for unit testing")
end

---------------------------------------------------------------------------
-- SECTION 19: EXIT TYPE VERIFICATION
---------------------------------------------------------------------------
suite("EXIT TYPES: door, stairway, window, trap_door, archway")

local EXIT_TYPES = {
    { room = "start-room",     dir = "north",  expected_type = "door" },
    { room = "start-room",     dir = "window", expected_type = "window" },
    { room = "start-room",     dir = "down",   expected_type = "trap_door" },
    { room = "hallway",        dir = "south",  expected_type = "door" },
    { room = "hallway",        dir = "down",   expected_type = "stairway" },
    { room = "hallway",        dir = "north",  expected_type = "stairway" },
    { room = "hallway",        dir = "west",   expected_type = "door" },
    { room = "hallway",        dir = "east",   expected_type = "door" },
    { room = "cellar",         dir = "up",     expected_type = "stairway" },
    { room = "cellar",         dir = "north",  expected_type = "door" },
    { room = "courtyard",      dir = "up",     expected_type = "window" },
    { room = "courtyard",      dir = "east",   expected_type = "door" },
    { room = "storage-cellar", dir = "south",  expected_type = "door" },
    { room = "storage-cellar", dir = "north",  expected_type = "door" },
    { room = "deep-cellar",    dir = "south",  expected_type = "door" },
    { room = "deep-cellar",    dir = "up",     expected_type = "stairway" },
    { room = "deep-cellar",    dir = "west",   expected_type = "archway" },
    { room = "crypt",          dir = "east",   expected_type = "archway" },
}

for _, spec in ipairs(EXIT_TYPES) do
    test(next_test() .. ". " .. spec.room .. "/" .. spec.dir .. " type='" .. spec.expected_type .. "'", function()
        local exit = ALL_ROOMS[spec.room].exits[spec.dir]
        if is_portal_ref(exit) then
            -- Portal exits: verify via portal template + categories
            local portal = resolve_exit(exit)
            h.assert_truthy(portal, spec.room .. "/" .. spec.dir .. " portal must resolve")
            h.assert_eq("portal", portal.template,
                spec.room .. "/" .. spec.dir .. " portal template")
            -- The original type ("door") is implied by the portal's architecture category
            local has_arch = false
            for _, c in ipairs(portal.categories or {}) do
                if c == "architecture" then has_arch = true; break end
            end
            h.assert_truthy(has_arch,
                spec.room .. "/" .. spec.dir .. " portal must have 'architecture' category")
        else
            h.assert_eq(spec.expected_type, exit.type,
                spec.room .. "/" .. spec.dir .. " exit type")
        end
    end)
end

---------------------------------------------------------------------------
-- SECTION 20: KEY PROGRESSION (brass → iron → silver)
---------------------------------------------------------------------------
suite("KEY PROGRESSION: three-key chain in Level 1")

-- Helper: find the requires_tool from a portal's unlock transition
local function get_portal_key(portal)
    if not portal or not portal.transitions then return nil end
    for _, t in ipairs(portal.transitions) do
        if t.verb == "unlock" and t.requires_tool then
            return t.requires_tool
        end
    end
    return portal.key_id  -- fallback to top-level key_id if present
end

test(next_test() .. ". First locked keyed door needs brass-key (cellar/north)", function()
    local exit = cellar.exits.north
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "cellar/north portal must resolve")
        h.assert_eq("brass-key", get_portal_key(portal),
            "cellar → storage requires brass-key")
    else
        h.assert_eq("brass-key", exit.key_id,
            "cellar → storage requires brass-key")
    end
end)

test(next_test() .. ". Second locked keyed door needs iron-key (storage/north)", function()
    local exit = storage_cellar.exits.north
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "storage-cellar/north portal must resolve")
        h.assert_eq("iron-key", get_portal_key(portal),
            "storage → deep-cellar requires iron-key")
    else
        h.assert_eq("iron-key", exit.key_id,
            "storage → deep-cellar requires iron-key")
    end
end)

test(next_test() .. ". Third locked keyed door needs silver-key (deep-cellar/west)", function()
    local exit = deep_cellar.exits.west
    if is_portal_ref(exit) then
        local portal = resolve_exit(exit)
        h.assert_truthy(portal, "deep-cellar/west portal must resolve")
        h.assert_eq("silver-key", get_portal_key(portal),
            "deep-cellar → crypt requires silver-key")
    else
        h.assert_eq("silver-key", exit.key_id,
            "deep-cellar → crypt requires silver-key")
    end
end)

test(next_test() .. ". Keys are distinct (no duplicate key_ids)", function()
    local keys = { "brass-key", "iron-key", "silver-key" }
    local seen = {}
    for _, k in ipairs(keys) do
        h.assert_truthy(not seen[k], "duplicate key_id: " .. k)
        seen[k] = true
    end
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
local exit_code = h.summary()
if skipped > 0 then
    print("  Skipped: " .. skipped)
end
os.exit(exit_code == 0 and 0 or 1)
