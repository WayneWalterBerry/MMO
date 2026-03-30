-- test/creatures/test-respawn-edge-cases.lua
-- WAVE-5 TDD: Edge cases for respawn system — no metadata, zero population,
-- immediate timer, missing home room, multiple deaths of same type.
-- Tests the real engine/creatures/respawn.lua module contract.
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
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

---------------------------------------------------------------------------
-- Load respawn engine module
---------------------------------------------------------------------------
local respawn_ok, respawn = pcall(require, "engine.creatures.respawn")
if not respawn_ok then
    print("WARNING: engine.creatures.respawn not loadable — " .. tostring(respawn))
    respawn = nil
end
h.assert_truthy(respawn_ok and respawn, "engine.creatures.respawn module must load")

---------------------------------------------------------------------------
-- Mock factory
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
-- Adapter functions for respawn module API
---------------------------------------------------------------------------
local function list_fn(registry) return registry:list() end
local function get_room_fn(context, room_id)
    return context.rooms and context.rooms[room_id] or nil
end

local function tick_and_collect(ctx)
    local before = {}
    for _, obj in ipairs(ctx.registry:list()) do
        before[obj.guid or obj.id] = true
    end
    respawn.tick(ctx, list_fn, get_room_fn, ctx.player.location)
    local spawned = {}
    for _, obj in ipairs(ctx.registry:list()) do
        local key = obj.guid or obj.id
        if not before[key] then
            spawned[#spawned + 1] = obj
        end
    end
    return spawned
end

---------------------------------------------------------------------------
-- TESTS: Respawn Edge Cases (WAVE-5)
---------------------------------------------------------------------------
suite("RESPAWN EDGE CASES: no-metadata, zero-pop, immediate, missing room (WAVE-5)")

-- 1. Creature without respawn metadata → no tracking, no crash
test("1. creature without respawn metadata → register is a no-op", function()
    respawn.clear()
    local plain_obj = {
        guid = next_guid(),
        id = "rock",
        name = "a rock",
        template = "small-item",
        alive = false,
    }
    local ok, err = pcall(respawn.register, plain_obj)
    h.assert_truthy(ok, "register must not crash for objects without respawn metadata: " .. tostring(err))
    h.assert_eq(0, respawn.count_pending(), "no pending respawns for object without respawn metadata")
end)

-- 2. Creature explicitly nil respawn → no tracking
test("2. creature with respawn = nil → no respawn tracking", function()
    respawn.clear()
    local obj = {
        guid = next_guid(),
        id = "chair",
        name = "a wooden chair",
        template = "furniture",
        respawn = nil,
    }
    local ok, err = pcall(respawn.register, obj)
    h.assert_truthy(ok, "register must not crash: " .. tostring(err))
    h.assert_eq(0, respawn.count_pending(), "no pending respawns")
end)

-- 3. Respawn with max_population = 0 → never respawns
test("3. max_population = 0 → creature never respawns", function()
    respawn.clear()
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
    respawn.register(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    for i = 1, 20 do
        tick_and_collect(ctx)
    end

    local registered = ctx.registry:get_registered()
    h.assert_eq(0, #registered, "creature with max_population=0 must never respawn")
end)

-- 4. Timer = 0 → immediate respawn (next tick, if player not in room)
test("4. timer = 0 → respawn on first tick if player not in room", function()
    respawn.clear()
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
    respawn.register(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    local spawned = tick_and_collect(ctx)
    h.assert_truthy(#spawned > 0, "timer=0 must respawn on first tick (immediate)")
end)

-- 5. Timer = 1 → respawn after exactly 1 tick
test("5. timer = 1 → respawn after exactly 1 tick", function()
    respawn.clear()
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
    respawn.register(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    local spawned = tick_and_collect(ctx)
    h.assert_truthy(#spawned > 0, "timer=1 must respawn after 1 tick")
end)

-- 6. Home room doesn't exist → graceful error (no crash)
test("6. home room missing from context.rooms → no crash", function()
    respawn.clear()
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
    respawn.register(creature)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = { ["bedroom"] = make_room("bedroom") },
        creatures = {},
    })

    local ok, err = pcall(function()
        for i = 1, 10 do tick_and_collect(ctx) end
    end)
    h.assert_truthy(ok, "respawn tick must not crash when home room is missing: " .. tostring(err))

    local registered = ctx.registry:get_registered()
    h.assert_eq(0, #registered, "no creature should spawn when home room is missing")
end)

-- 7. Double-register same creature → second register is rejected
test("7. double-register same creature → second register returns false", function()
    respawn.clear()
    local rat = deep_copy(rat_def)
    rat.guid = next_guid()
    rat.alive = true
    rat.animate = true
    rat.location = "cellar"

    local first = respawn.register(rat)
    local second = respawn.register(rat)
    h.assert_truthy(first, "first register must succeed")
    h.assert_truthy(not second, "second register of same creature must return false (no double-register)")
    h.assert_eq(1, respawn.count_pending(), "only one pending entry for same creature")
end)

-- 8. register called on nil creature → no crash
test("8. register(nil) → returns false, no crash", function()
    respawn.clear()
    local ok, err = pcall(respawn.register, nil)
    h.assert_truthy(ok, "register(nil) must not crash: " .. tostring(err))
    h.assert_eq(0, respawn.count_pending(), "no pending after register(nil)")
end)

-- 9. Player leaves room after timer expires → respawn triggers after timer resets
test("9. player leaves home room after timer expires → respawn triggers on next cycle", function()
    respawn.clear()
    local rat = deep_copy(rat_def)
    rat.guid = next_guid()
    rat.alive = true
    rat.animate = true
    rat.health = rat.max_health or 5
    rat.location = "cellar"
    respawn.register(rat)

    local ctx = make_context({
        player_room = "cellar",
        rooms = {
            ["cellar"] = make_room("cellar"),
            ["bedroom"] = make_room("bedroom"),
        },
        creatures = {},
    })

    -- Tick past timer while player in room — timer resets
    for i = 1, rat_def.respawn.timer + 5 do
        tick_and_collect(ctx)
    end

    h.assert_eq(0, #ctx.registry:get_registered(), "no spawn while player in room")

    -- Player moves to bedroom
    ctx.player.location = "bedroom"
    ctx.current_room = ctx.rooms["bedroom"]

    -- Module resets timer to full value when player blocks — tick through reset cycle
    local spawned = {}
    for i = 1, rat_def.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "creature must respawn after player leaves and timer completes reset cycle")
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
