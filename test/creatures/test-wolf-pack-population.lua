-- test/creatures/test-wolf-pack-population.lua
-- Issue #315 TDD: Wolf max_population must allow pack tactics (>= 2).
-- Must be run from repository root: lua test/creatures/test-wolf-pack-population.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "wolf.lua"
local ok_wolf, wolf_def = pcall(dofile, wolf_path)
if not ok_wolf then
    print("WARNING: wolf.lua not found — " .. tostring(wolf_def))
    wolf_def = nil
end

local respawn_ok, respawn = pcall(require, "engine.creatures.respawn")
if not respawn_ok then
    print("WARNING: engine.creatures.respawn not loadable — " .. tostring(respawn))
    respawn = nil
end

local pack_ok, pack_tactics = pcall(require, "engine.creatures.pack-tactics")
if not pack_ok then
    print("WARNING: engine.creatures.pack-tactics not loadable — " .. tostring(pack_tactics))
    pack_tactics = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-pop-" .. guid_counter .. "}"
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

local function make_wolf(overrides)
    local base = wolf_def and deep_copy(wolf_def) or {
        id = "wolf", animate = true, alive = true,
        health = 22, max_health = 22,
        behavior = { aggression = 70 },
        respawn = { timer = 200, home_room = "hallway", max_population = 1 },
    }
    base.guid = next_guid()
    if overrides then
        for k, v in pairs(overrides) do base[k] = v end
    end
    return base
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:list()
        local seen, result = {}, {}
        for _, obj in pairs(self._objects) do
            if not seen[obj.guid] then
                seen[obj.guid] = true
                result[#result + 1] = obj
            end
        end
        return result
    end
    function reg:get(id) return self._objects[id] end
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:register(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    function reg:set_location(guid, loc)
        local obj = self._objects[guid]
        if obj then obj.location = loc end
    end
    return reg
end

---------------------------------------------------------------------------
-- TESTS: Wolf Population for Pack Tactics (Issue #315)
---------------------------------------------------------------------------
suite("WOLF POPULATION: max_population enables pack tactics (Issue #315 TDD)")

test("1. wolf max_population must be >= 2 for pack tactics", function()
    h.assert_truthy(wolf_def, "wolf.lua must load")
    h.assert_truthy(wolf_def.respawn, "wolf must have respawn metadata")
    h.assert_truthy(wolf_def.respawn.max_population >= 2,
        "wolf max_population must be >= 2, got " .. tostring(wolf_def.respawn.max_population))
end)

test("2. respawn allows second wolf when population < max", function()
    h.assert_truthy(respawn, "respawn module must load")
    respawn.clear()

    local wolf1 = make_wolf({ location = "hallway" })
    wolf1._original_type_id = "wolf"
    wolf1.type_id = "wolf"

    local room = { guid = "{room-hallway}", id = "hallway", template = "room",
                   name = "hallway", contents = {} }
    local reg = make_mock_registry({ wolf1, room })

    -- Kill wolf1 and register for respawn
    wolf1.alive = false
    wolf1._state = "dead"
    wolf1.animate = false
    respawn.register(wolf1)

    -- Spawn a new living wolf1 replacement
    wolf1.alive = true
    wolf1.animate = true
    wolf1._state = "alive-idle"

    local ctx = {
        registry = reg,
        rooms = { hallway = room },
    }
    local list_fn = function(r) return r:list() end
    local get_room_fn = function(c, id) return c.rooms[id] end

    -- Tick down to spawn
    for i = 1, 201 do
        respawn.tick(ctx, list_fn, get_room_fn, "some-other-room")
    end

    -- Count wolves in hallway
    local wolf_count = 0
    for _, obj in ipairs(reg:list()) do
        if obj.id == "wolf" and obj.location == "hallway" and obj.alive ~= false then
            wolf_count = wolf_count + 1
        end
    end

    h.assert_truthy(wolf_count >= 2,
        "Respawn should allow 2 wolves in hallway, found " .. wolf_count)
end)

test("3. pack tactics work with 2 wolves — staggered attack plan", function()
    h.assert_truthy(pack_tactics, "pack-tactics module must load")

    local wolf1 = make_wolf({ health = 22, location = "hallway" })
    local wolf2 = make_wolf({ health = 20, location = "hallway" })
    local reg = make_mock_registry({ wolf1, wolf2 })

    local pack = pack_tactics.get_pack_in_room(reg, "hallway", wolf1)
    h.assert_truthy(#pack >= 2,
        "get_pack_in_room must find 2 wolves, found " .. #pack)

    local plan = pack_tactics.plan_attack(pack)
    h.assert_eq(2, #plan,
        "attack plan for 2-wolf pack must have 2 entries")

    -- Alpha attacks delay=0, beta delay=1
    local delays = {}
    for _, entry in ipairs(plan) do
        delays[#delays + 1] = entry.delay
    end
    table.sort(delays)
    h.assert_eq(0, delays[1], "alpha must attack at delay 0")
    h.assert_eq(1, delays[2], "beta must attack at delay 1")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
