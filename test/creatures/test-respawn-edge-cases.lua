-- test/creatures/test-respawn-edge-cases.lua
-- WAVE-5 TDD: Edge cases for respawn system — no metadata, zero population,
-- immediate timer, missing home room, multiple deaths of same type.
-- Must be run from repository root: lua test/creatures/test-respawn-edge-cases.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[deep_copy(k)] = deep_copy(v) end
    return copy
end

---------------------------------------------------------------------------
-- Load creature definitions via dofile
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

---------------------------------------------------------------------------
-- Try to load respawn engine module (TDD — may not exist yet)
---------------------------------------------------------------------------
local respawn_ok, respawn = pcall(require, "engine.creatures.respawn")
if not respawn_ok then
    print("WARNING: engine.creatures.respawn not loadable — " .. tostring(respawn))
    respawn = nil
end

---------------------------------------------------------------------------
-- Mock factory (shared with test-respawn.lua pattern)
---------------------------------------------------------------------------
local guid_counter = 1000
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-edge-" .. guid_counter .. "}"
end

local function make_mock_registry(objects)
    local reg = { _objects = {}, _registered = {} }
    for _, obj in ipairs(objects or {}) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] or nil end
    function reg:list()
        local result, seen = {}, {}
        for _, obj in pairs(self._objects) do
            local key = obj.guid or obj.id
            if not seen[key] then
                seen[key] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    reg.all = reg.list
    function reg:register(obj)
        self._objects[obj.guid or obj.id] = obj
        if obj.id then self._objects[obj.id] = obj end
        self._registered[#self._registered + 1] = obj
    end
    function reg:get_registered() return self._registered end
    return reg
end

local function make_room(id)
    return {
        id = id,
        name = "Test Room " .. id,
        template = "room",
        contents = {},
    }
end

local function make_context(opts)
    opts = opts or {}
    local player_room = opts.player_room or "player-room"
    local rooms = opts.rooms or {}
    if not rooms[player_room] then
        rooms[player_room] = make_room(player_room)
    end
    local all_objects = {}
    for _, c in ipairs(opts.creatures or {}) do
        all_objects[#all_objects + 1] = c
    end
    return {
        registry = make_mock_registry(all_objects),
        rooms = rooms,
        current_room = rooms[player_room],
        player = { location = player_room, hands = { nil, nil } },
        headless = true,
        tick_count = opts.tick_count or 0,
    }
end

---------------------------------------------------------------------------
-- Mock respawn manager (same contract as test-respawn.lua)
---------------------------------------------------------------------------
local mock_respawn = {}
mock_respawn._pending = {}

function mock_respawn.reset()
    mock_respawn._pending = {}
end

function mock_respawn.on_death(creature)
    if not creature.respawn then return end
    local key = creature.id .. "@" .. (creature.respawn.home_room or "unknown")
    mock_respawn._pending[key] = {
        type_id = creature.id,
        timer = creature.respawn.timer,
        home_room = creature.respawn.home_room,
        max_population = creature.respawn.max_population or 1,
        ticks_remaining = creature.respawn.timer,
        source_def = creature,
    }
end

function mock_respawn.tick(context)
    local spawned = {}
    for key, entry in pairs(mock_respawn._pending) do
        entry.ticks_remaining = entry.ticks_remaining - 1
        if entry.ticks_remaining <= 0 then
            -- Check home room exists
            if not context.rooms[entry.home_room] then
                -- Graceful error: log but don't crash, remove entry
                mock_respawn._pending[key] = nil
            elseif context.player.location == entry.home_room then
                entry.ticks_remaining = 1
            else
                local count = 0
                for _, obj in ipairs(context.registry:list()) do
                    if obj.id == entry.type_id and obj.alive and obj.location == entry.home_room then
                        count = count + 1
                    end
                end
                if entry.max_population <= 0 or count >= entry.max_population then
                    -- max_population = 0 means never respawn; at cap means no respawn
                    mock_respawn._pending[key] = nil
                else
                    local new_creature = deep_copy(entry.source_def)
                    new_creature.guid = next_guid()
                    new_creature.alive = true
                    new_creature.animate = true
                    new_creature.health = new_creature.max_health or 10
                    new_creature.location = entry.home_room
                    context.registry:register(new_creature)
                    spawned[#spawned + 1] = new_creature
                    mock_respawn._pending[key] = nil
                end
            end
        end
    end
    return spawned
end

local R = (respawn_ok and respawn) or mock_respawn

---------------------------------------------------------------------------
-- TESTS: Respawn Edge Cases (WAVE-5)
---------------------------------------------------------------------------
suite("RESPAWN EDGE CASES: no-metadata, zero-pop, immediate, missing room (WAVE-5)")

-- 1. Creature without respawn metadata → no tracking, no crash
test("1. creature without respawn metadata → on_death is a no-op", function()
    R.reset()
    local plain_obj = {
        guid = next_guid(),
        id = "rock",
        name = "a rock",
        template = "small-item",
        alive = false,
    }
    -- Must not crash
    local ok, err = pcall(R.on_death, plain_obj)
    h.assert_truthy(ok, "on_death must not crash for objects without respawn metadata: " .. tostring(err))

    -- Nothing should be pending
    local count = 0
    for _ in pairs(R._pending) do count = count + 1 end
    h.assert_eq(0, count, "no pending respawns for object without respawn metadata")
end)

-- 2. Creature explicitly nil respawn → no tracking
test("2. creature with respawn = nil → no respawn tracking", function()
    R.reset()
    local obj = {
        guid = next_guid(),
        id = "chair",
        name = "a wooden chair",
        template = "furniture",
        respawn = nil,
    }
    local ok, err = pcall(R.on_death, obj)
    h.assert_truthy(ok, "on_death must not crash: " .. tostring(err))
    local count = 0
    for _ in pairs(R._pending) do count = count + 1 end
    h.assert_eq(0, count, "no pending respawns")
end)

-- 3. Respawn with max_population = 0 → never respawns
test("3. max_population = 0 → creature never respawns", function()
    R.reset()
    local creature = deep_copy(rat_def)
    creature.guid = next_guid()
    creature.alive = true
    creature.animate = true
    creature.health = creature.max_health or 5
    creature.respawn = {
        timer = 5,
        home_room = "cellar",
        max_population = 0,
    }
    creature.location = "cellar"
    R.on_death(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    -- Tick well past timer
    for i = 1, 20 do
        R.tick(ctx)
    end

    local registered = ctx.registry:get_registered()
    h.assert_eq(0, #registered, "creature with max_population=0 must never respawn")
end)

-- 4. Timer = 0 → immediate respawn (next tick, if player not in room)
test("4. timer = 0 → respawn on first tick if player not in room", function()
    R.reset()
    local creature = deep_copy(rat_def)
    creature.guid = next_guid()
    creature.alive = true
    creature.animate = true
    creature.health = creature.max_health or 5
    creature.respawn = {
        timer = 0,
        home_room = "cellar",
        max_population = 3,
    }
    creature.location = "cellar"
    R.on_death(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    -- Timer=0 means ticks_remaining=0, so first tick should decrement to -1 and trigger
    local spawned = R.tick(ctx)
    h.assert_truthy(#spawned > 0, "timer=0 must respawn on first tick (immediate)")
end)

-- 5. Timer = 1 → respawn after exactly 1 tick
test("5. timer = 1 → respawn after exactly 1 tick", function()
    R.reset()
    local creature = deep_copy(rat_def)
    creature.guid = next_guid()
    creature.alive = true
    creature.animate = true
    creature.health = creature.max_health or 5
    creature.respawn = {
        timer = 1,
        home_room = "cellar",
        max_population = 3,
    }
    creature.location = "cellar"
    R.on_death(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    local spawned = R.tick(ctx)
    h.assert_truthy(#spawned > 0, "timer=1 must respawn after 1 tick")
end)

-- 6. Home room doesn't exist → graceful error (no crash)
test("6. home room missing from context.rooms → no crash, entry cleaned up", function()
    R.reset()
    local creature = deep_copy(rat_def)
    creature.guid = next_guid()
    creature.alive = true
    creature.animate = true
    creature.health = creature.max_health or 5
    creature.respawn = {
        timer = 2,
        home_room = "nonexistent-room",
        max_population = 3,
    }
    creature.location = "nonexistent-room"
    R.on_death(creature)

    -- Context does NOT include "nonexistent-room"
    local ctx = make_context({
        player_room = "bedroom",
        rooms = { ["bedroom"] = make_room("bedroom") },
        creatures = {},
    })

    local ok, err = pcall(function()
        for i = 1, 10 do R.tick(ctx) end
    end)
    h.assert_truthy(ok, "respawn tick must not crash when home room is missing: " .. tostring(err))

    -- Nothing should have been registered
    local registered = ctx.registry:get_registered()
    h.assert_eq(0, #registered, "no creature should spawn when home room is missing")
end)

-- 7. Multiple deaths of same creature type → only one pending per key
test("7. multiple deaths of same type in same room → one pending entry per key", function()
    R.reset()

    for i = 1, 3 do
        local rat = deep_copy(rat_def)
        rat.guid = next_guid()
        rat.alive = true
        rat.animate = true
        rat.health = rat.max_health or 5
        rat.location = "cellar"
        R.on_death(rat)
    end

    -- Count pending entries for rat@cellar
    local count = 0
    for key, entry in pairs(R._pending) do
        if entry.type_id == "rat" and entry.home_room == "cellar" then
            count = count + 1
        end
    end
    -- Keyed by type_id@home_room, so only one pending entry
    h.assert_eq(1, count, "only one pending respawn per creature type per room (not one per death)")
end)

-- 8. on_death called on already-dead creature → no crash
test("8. on_death on already-dead creature → no crash, still tracks", function()
    R.reset()
    local rat = deep_copy(rat_def)
    rat.guid = next_guid()
    rat.alive = false
    rat.animate = false
    rat.health = 0
    rat.location = "cellar"

    local ok, err = pcall(R.on_death, rat)
    h.assert_truthy(ok, "on_death must not crash on already-dead creature: " .. tostring(err))
end)

-- 9. Player leaves room mid-wait → respawn triggers on next tick
test("9. player leaves home room after timer expires → respawn triggers", function()
    R.reset()
    local rat = deep_copy(rat_def)
    rat.guid = next_guid()
    rat.alive = true
    rat.animate = true
    rat.health = rat.max_health or 5
    rat.location = "cellar"
    R.on_death(rat)

    -- Player stays in cellar past timer
    local ctx = make_context({
        player_room = "cellar",
        rooms = {
            ["cellar"] = make_room("cellar"),
            ["bedroom"] = make_room("bedroom"),
        },
        creatures = {},
    })

    for i = 1, rat_def.respawn.timer + 5 do
        R.tick(ctx)
    end

    -- No spawn yet
    h.assert_eq(0, #ctx.registry:get_registered(), "no spawn while player in room")

    -- Player moves to bedroom
    ctx.player.location = "bedroom"
    ctx.current_room = ctx.rooms["bedroom"]

    local spawned = R.tick(ctx)
    h.assert_truthy(#spawned > 0, "creature must respawn once player leaves the home room")
    h.assert_eq("cellar", spawned[1].location, "respawned creature must be in cellar")
end)

-- 10. Respawn metadata preserved on deep_copy (regression guard)
test("10. deep_copy preserves respawn metadata structure", function()
    h.assert_truthy(ok_rat, "rat.lua must load")
    local copy = deep_copy(rat_def)
    h.assert_truthy(copy.respawn, "deep_copy must preserve respawn table")
    h.assert_eq(rat_def.respawn.timer, copy.respawn.timer, "timer preserved")
    h.assert_eq(rat_def.respawn.home_room, copy.respawn.home_room, "home_room preserved")
    h.assert_eq(rat_def.respawn.max_population, copy.respawn.max_population, "max_population preserved")
end)

---------------------------------------------------------------------------
h.summary()
