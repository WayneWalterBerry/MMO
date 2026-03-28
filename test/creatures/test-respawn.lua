-- test/creatures/test-respawn.lua
-- WAVE-5 TDD: Validates creature respawn system — timer tracking, population
-- caps, player-presence gating, fresh instance creation, and home room placement.
-- Tests the real engine/creatures/respawn.lua module contract.
-- Must be run from repository root: lua test/creatures/test-respawn.lua

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

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_wolf, wolf_def = pcall(dofile, creature_path("wolf"))
if not ok_wolf then print("WARNING: wolf.lua failed to load — " .. tostring(wolf_def)) end

local ok_spider, spider_def = pcall(dofile, creature_path("spider"))
if not ok_spider then print("WARNING: spider.lua failed to load — " .. tostring(spider_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

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
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-respawn-" .. guid_counter .. "}"
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

local function make_live_creature(def, guid_override)
    local inst = deep_copy(def)
    inst.guid = guid_override or next_guid()
    inst.template = inst.template or "creature"
    inst.animate = true
    inst.alive = true
    inst.health = inst.health or inst.max_health or 10
    inst.max_health = inst.max_health or 10
    inst.behavior = inst.behavior or { default = "idle" }
    inst.drives = inst.drives or { hunger = { value = 50 } }
    return inst
end

local function make_room(id, contents)
    return {
        id = id,
        name = "Test Room " .. id,
        template = "room",
        contents = contents or {},
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
-- Real module: register(creature), clear(), tick(ctx, list_fn, get_room_fn, player_room_id)
-- get_pending() returns the internal pending table
---------------------------------------------------------------------------
local function list_fn(registry) return registry:list() end
local function get_room_fn(context, room_id)
    return context.rooms and context.rooms[room_id] or nil
end

-- Wrap tick to also collect newly spawned creatures by diffing registry
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
-- TESTS: Respawn System (WAVE-5)
---------------------------------------------------------------------------
suite("RESPAWN SYSTEM: timer, population, player-gating (WAVE-5)")

-- 1. Creature with respawn metadata: timer starts on death
test("1. respawn timer starts when creature with respawn metadata dies", function()
    respawn.clear()
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = make_live_creature(rat_def)
    h.assert_truthy(rat.respawn, "rat must have respawn metadata")
    h.assert_truthy(rat.respawn.timer, "rat.respawn must have timer")

    local result = respawn.register(rat)
    h.assert_truthy(result, "register must return truthy on success")

    local pending = respawn.get_pending()
    local has_pending = false
    for _, entry in pairs(pending) do
        if entry.type_id == rat.id then has_pending = true; break end
    end
    h.assert_truthy(has_pending, "respawn timer must be pending after register")
end)

-- 2. Timer expires + player NOT in room → creature respawns
test("2. timer expires + player NOT in room → creature respawns", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    rat.location = "cellar"
    respawn.register(rat)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    local spawned = {}
    for i = 1, rat.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "creature must respawn after timer expires when player not in room")
end)

-- 3. Timer expires + player IN room → no respawn (waits)
test("3. timer expires + player IN room → no respawn", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    rat.location = "cellar"
    respawn.register(rat)

    local ctx = make_context({
        player_room = "cellar",
        rooms = { ["cellar"] = make_room("cellar") },
        creatures = {},
    })

    local spawned = {}
    for i = 1, rat.respawn.timer + 5 do
        spawned = tick_and_collect(ctx)
    end

    h.assert_eq(0, #spawned, "creature must NOT respawn while player is in home room")

    -- Verify still pending (not discarded)
    local pending = respawn.get_pending()
    local still_pending = false
    for _, entry in pairs(pending) do
        if entry.type_id == rat.id then still_pending = true; break end
    end
    h.assert_truthy(still_pending, "respawn entry must remain pending (not discarded) when player blocks it")
end)

-- 4. Population cap: max_population reached → no respawn
test("4. population cap reached → no respawn", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    rat.location = "cellar"
    respawn.register(rat)

    -- Fill cellar to max_population (rat max = 3)
    local existing_rats = {}
    for i = 1, rat.respawn.max_population do
        local r = make_live_creature(rat_def)
        r.location = "cellar"
        existing_rats[#existing_rats + 1] = r
    end

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = existing_rats,
    })

    for i = 1, rat.respawn.timer + 5 do
        tick_and_collect(ctx)
    end

    local registered = ctx.registry:get_registered()
    h.assert_eq(0, #registered, "no new creature should spawn when population cap is reached")
end)

-- 5. Population cap: below max → respawn succeeds
test("5. population below max → respawn succeeds", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    rat.location = "cellar"
    respawn.register(rat)

    -- Only 1 rat alive in cellar (max_population = 3)
    local existing_rat = make_live_creature(rat_def)
    existing_rat.location = "cellar"

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = { existing_rat },
    })

    local spawned = {}
    for i = 1, rat.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "creature must respawn when below population cap")
end)

-- 6. Respawned creature is a fresh instance (new GUID, full health)
test("6. respawned creature has new GUID and full health", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    local original_guid = rat.guid
    rat.location = "cellar"
    respawn.register(rat)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    local spawned = {}
    for i = 1, rat.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "creature must respawn")
    local new_creature = spawned[1]
    h.assert_truthy(new_creature.guid ~= original_guid,
        "respawned creature must have a NEW guid (got " .. tostring(new_creature.guid)
        .. " vs original " .. tostring(original_guid) .. ")")
    h.assert_truthy(new_creature.alive, "respawned creature must be alive")
    h.assert_truthy(new_creature.animate, "respawned creature must be animate")
end)

-- 7. Respawned creature appears in home_room
test("7. respawned creature location is home_room", function()
    respawn.clear()
    local cat = make_live_creature(cat_def)
    cat.location = "courtyard"
    respawn.register(cat)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["courtyard"] = make_room("courtyard"),
        },
        creatures = {},
    })

    local spawned = {}
    for i = 1, cat.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "cat must respawn")
    h.assert_eq("courtyard", spawned[1].location, "respawned creature must be in home_room")
end)

-- 8. Respawn timer resets correctly for chain kills
test("8. chain kill: second death starts a fresh respawn timer", function()
    respawn.clear()
    local rat1 = make_live_creature(rat_def)
    rat1.location = "cellar"
    respawn.register(rat1)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    -- Let first respawn complete
    local spawned = {}
    for i = 1, rat1.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end
    h.assert_truthy(#spawned > 0, "first respawn must complete")

    -- Kill the respawned creature — register it for respawn
    local rat2 = spawned[1]
    rat2.respawn = rat1.respawn  -- ensure respawn metadata carried over
    respawn.register(rat2)

    -- Verify new pending timer exists
    local pending = respawn.get_pending()
    local has_pending = false
    for _, entry in pairs(pending) do
        if entry.type_id == rat2.id or entry.type_id == "rat" then
            has_pending = true; break
        end
    end
    h.assert_truthy(has_pending, "second death must create a new pending respawn timer")
end)

-- 9. Multiple creature types can have independent respawn timers
test("9. independent respawn timers for different creature types", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    rat.location = "cellar"
    local cat = make_live_creature(cat_def)
    cat.location = "courtyard"

    respawn.register(rat)
    respawn.register(cat)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
            ["courtyard"] = make_room("courtyard"),
        },
        creatures = {},
    })

    -- Rat timer = 60, cat timer = 120
    local rat_spawned = false
    local cat_spawned = false
    for i = 1, rat.respawn.timer + 1 do
        local spawned = tick_and_collect(ctx)
        for _, s in ipairs(spawned) do
            local sid = s._original_type_id or s.type_id or s.id
            if sid == "rat" then rat_spawned = true end
            if sid == "cat" then cat_spawned = true end
        end
    end
    h.assert_truthy(rat_spawned, "rat must respawn after its timer (60)")
    h.assert_truthy(not cat_spawned, "cat must NOT respawn yet (timer=120, only 61 ticks elapsed)")

    -- Continue ticking to cat timer
    for i = 1, cat.respawn.timer - rat.respawn.timer + 1 do
        local spawned = tick_and_collect(ctx)
        for _, s in ipairs(spawned) do
            local sid = s._original_type_id or s.type_id or s.id
            if sid == "cat" then cat_spawned = true end
        end
    end
    h.assert_truthy(cat_spawned, "cat must respawn after its own timer (120)")
end)

-- 10. All 5 creatures have respawn metadata
test("10. all 5 creature definitions have respawn metadata", function()
    local defs = {
        { name = "rat",    ok = ok_rat,    def = rat_def },
        { name = "cat",    ok = ok_cat,    def = cat_def },
        { name = "wolf",   ok = ok_wolf,   def = wolf_def },
        { name = "spider", ok = ok_spider, def = spider_def },
        { name = "bat",    ok = ok_bat,    def = bat_def },
    }
    for _, entry in ipairs(defs) do
        h.assert_truthy(entry.ok, entry.name .. ".lua must load")
        h.assert_truthy(entry.def.respawn, entry.name .. " must have respawn table")
        h.assert_truthy(entry.def.respawn.timer, entry.name .. ".respawn must have timer")
        h.assert_truthy(entry.def.respawn.home_room, entry.name .. ".respawn must have home_room")
        h.assert_truthy(entry.def.respawn.max_population, entry.name .. ".respawn must have max_population")
    end
end)

-- 11. Respawn metadata values match spec
test("11. respawn metadata values match WAVE-5 spec", function()
    local expected = {
        { def = rat_def,    id = "rat",    timer = 60,  room = "cellar",      max = 3 },
        { def = cat_def,    id = "cat",    timer = 120, room = "courtyard",   max = 1 },
        { def = wolf_def,   id = "wolf",   timer = 200, room = "hallway",     max = 3 },
        { def = spider_def, id = "spider", timer = 80,  room = "deep-cellar", max = 2 },
        { def = bat_def,    id = "bat",    timer = 60,  room = "crypt",       max = 3 },
    }
    for _, e in ipairs(expected) do
        h.assert_eq(e.timer, e.def.respawn.timer, e.id .. " timer")
        h.assert_eq(e.room, e.def.respawn.home_room, e.id .. " home_room")
        h.assert_eq(e.max, e.def.respawn.max_population, e.id .. " max_population")
    end
end)

-- 12. Pending respawn is cleared after successful respawn
test("12. pending respawn entry cleared after successful respawn", function()
    respawn.clear()
    local rat = make_live_creature(rat_def)
    rat.location = "cellar"
    respawn.register(rat)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["cellar"] = make_room("cellar"),
        },
        creatures = {},
    })

    for i = 1, rat.respawn.timer + 1 do
        tick_and_collect(ctx)
    end

    -- After respawn, no pending entry for this rat
    local pending = respawn.get_pending()
    local still_pending = false
    for _, entry in pairs(pending) do
        if entry.type_id == "rat" then still_pending = true; break end
    end
    h.assert_truthy(not still_pending, "pending respawn entry must be cleared after successful respawn")
end)

-- 13. Respawned creature retains species identity
test("13. respawned creature retains species identity (id, type_id, template)", function()
    respawn.clear()
    local wolf = make_live_creature(wolf_def)
    wolf.location = "hallway"
    respawn.register(wolf)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["hallway"] = make_room("hallway"),
        },
        creatures = {},
    })

    local spawned = {}
    for i = 1, wolf.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "wolf must respawn")
    local new_wolf = spawned[1]
    local new_type = new_wolf._original_type_id or new_wolf.type_id or new_wolf.id
    h.assert_eq("wolf", new_type, "respawned creature must retain wolf type identity")
    h.assert_truthy(new_wolf.animate, "respawned creature must be animate")
    h.assert_truthy(new_wolf.alive, "respawned creature must be alive")
end)

-- 14. Spider respawns in deep-cellar (verifies non-default room)
test("14. spider respawns in deep-cellar", function()
    respawn.clear()
    local spider = make_live_creature(spider_def)
    spider.location = "deep-cellar"
    respawn.register(spider)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["deep-cellar"] = make_room("deep-cellar"),
        },
        creatures = {},
    })

    local spawned = {}
    for i = 1, spider.respawn.timer + 1 do
        spawned = tick_and_collect(ctx)
        if #spawned > 0 then break end
    end

    h.assert_truthy(#spawned > 0, "spider must respawn")
    h.assert_eq("deep-cellar", spawned[1].location, "spider must respawn in deep-cellar")
end)

-- 15. Bat respawn blocked when crypt already at max population
test("15. bat respawn blocked when crypt already at max population (3)", function()
    respawn.clear()

    -- Pre-populate crypt with 3 live bats (= max_population)
    local existing_bats = {}
    for i = 1, bat_def.respawn.max_population do
        local b = make_live_creature(bat_def)
        b.location = "crypt"
        existing_bats[#existing_bats + 1] = b
    end

    -- Kill one more bat and try to respawn it
    local dead_bat = make_live_creature(bat_def)
    dead_bat.location = "crypt"
    respawn.register(dead_bat)

    local ctx = make_context({
        player_room = "bedroom",
        rooms = {
            ["bedroom"] = make_room("bedroom"),
            ["crypt"] = make_room("crypt"),
        },
        creatures = existing_bats,
    })

    -- Tick past timer
    for i = 1, bat_def.respawn.timer + 5 do
        tick_and_collect(ctx)
    end

    -- No new bats should have spawned (already at cap)
    h.assert_eq(0, #ctx.registry:get_registered(),
        "no bat should respawn when crypt already has " .. bat_def.respawn.max_population .. " bats")
end)

---------------------------------------------------------------------------
h.summary()
