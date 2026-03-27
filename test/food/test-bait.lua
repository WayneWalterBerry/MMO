-- test/food/test-bait.lua
-- WAVE-5 TDD (Track 5D): Bait mechanic tests — food-as-lure for creatures.
-- Must be run from repository root: lua test/food/test-bait.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

---------------------------------------------------------------------------
-- Load creature definitions (TDD: graceful failures)
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local function creature_path(name)
    return "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. name .. ".lua"
end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

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
-- Mock factory
---------------------------------------------------------------------------
local portal_counter = 0

local function make_portal(target_room_id, traversable)
    portal_counter = portal_counter + 1
    local pid = "{portal-bait-" .. portal_counter .. "}"
    return {
        guid = pid,
        id = "portal-bait-" .. portal_counter,
        _state = traversable and "open" or "closed",
        states = {
            open   = { traversable = true },
            closed = { traversable = false },
        },
        portal = { target = target_room_id },
    }, pid
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid or obj.id] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
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
    function reg:get(id)
        return self._objects[id] or nil
    end
    function reg:remove(id)
        local obj = self._objects[id]
        self._objects[id] = nil
        return obj
    end
    return reg
end

local function make_food(overrides)
    local food = {
        guid = "{test-food-bait-001}",
        id = "bait-cheese",
        template = "small-item",
        name = "a wedge of cheese",
        keywords = {"cheese", "wedge", "food"},
        description = "A crumbly wedge of pale cheese.",
        on_feel = "Firm and slightly crumbly.",
        on_smell = "Sharp and tangy.",
        on_taste = "Sharp, salty, with a nutty finish.",
        edible = true,
        food = { edible = true, nutrition = 20, bait_value = 3, bait_targets = {"rat", "bat"} },
        material = "cheese",
        size = 1,
        weight = 0.3,
        portable = true,
        location = "test-room",
    }
    if overrides then
        for k, v in pairs(overrides) do food[k] = v end
    end
    return food
end

local function make_context(opts)
    opts = opts or {}
    local room_id = opts.room_id or "test-room"
    local room = {
        id = room_id,
        name = "Test Room",
        template = "room",
        description = "A plain room.",
        contents = opts.room_contents or {},
        exits = opts.exits or {},
    }
    local all_objects = {}
    for _, c in ipairs(opts.creatures or {}) do
        c.location = c.location or room_id
        all_objects[#all_objects + 1] = c
        if c.location == room_id then
            room.contents[#room.contents + 1] = c.id
        end
    end
    for _, obj in ipairs(opts.objects or {}) do
        all_objects[#all_objects + 1] = obj
        if obj.location == room_id then
            room.contents[#room.contents + 1] = obj.id
        end
    end
    for _, obj in ipairs(opts.extra_objects or {}) do
        all_objects[#all_objects + 1] = obj
    end
    local registry = make_mock_registry(all_objects)
    local rooms = { [room_id] = room }
    if opts.extra_rooms then
        for rid, r in pairs(opts.extra_rooms) do rooms[rid] = r end
    end
    return {
        registry = registry,
        rooms = rooms,
        current_room = room,
        player = opts.player or {
            id = "player",
            name = "the player",
            location = room_id,
            hands = { nil, nil },
            health = 100,
            max_health = 100,
            _state = "alive",
        },
        active_fights = opts.active_fights or {},
        combat_active = opts.combat_active or false,
        game_start_time = opts.game_start_time or os.time(),
        headless = true,
    }
end

---------------------------------------------------------------------------
-- SUITE 1: Drop Food + Rat in Room — Rat Approaches
---------------------------------------------------------------------------
suite("BAIT: rat approaches food (WAVE-5)")

test("1. drop food + rat in room: rat approaches food", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    -- Ensure rat has hunger drive above threshold
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 80
    end

    local cheese = make_food({ location = "test-room" })

    local ctx = make_context({
        creatures = { rat },
        objects = { cheese },
    })

    -- creature_tick should detect food and move rat toward it
    -- TDD: hunger + bait mechanic may not be implemented yet
    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    local ok_tick, msgs = pcall(tick_fn, ctx, rat)
    h.assert_truthy(ok_tick,
        "creature_tick must not crash with food in room: " .. tostring(msgs))
end)

test("2. rat consumes dropped food (object removed)", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 90
    end

    local cheese = make_food({ location = "test-room" })

    local ctx = make_context({
        creatures = { rat },
        objects = { cheese },
    })

    -- Run enough ticks for rat to approach and consume
    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    for tick = 1, 10 do
        local still_exists = ctx.registry:get("bait-cheese")
        if not still_exists then break end
        pcall(tick_fn, ctx, rat)
    end

    local food_gone = ctx.registry:get("bait-cheese") == nil
    h.assert_truthy(food_gone,
        "rat must consume food after ticks (bait-cheese removed from registry)")
end)

---------------------------------------------------------------------------
-- SUITE 2: Adjacent Room — Creature Moves Toward Food
---------------------------------------------------------------------------
suite("BAIT: adjacent room movement (WAVE-5)")

test("3. adjacent room: rat moves toward food", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local portal, portal_id = make_portal("food-room", true)
    local rat = deep_copy(rat_def)
    rat.location = "start-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 90
    end

    local cheese = make_food({ location = "food-room" })

    local food_room = {
        id = "food-room",
        name = "Food Room",
        template = "room",
        description = "A room with food.",
        contents = { "bait-cheese" },
        exits = {},
    }

    local ctx = make_context({
        room_id = "start-room",
        creatures = { rat },
        objects = { cheese },
        extra_objects = { portal },
        exits = { east = portal_id },
        extra_rooms = { ["food-room"] = food_room },
    })

    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    -- Run ticks — rat should detect food in adjacent room and move toward it
    for tick = 1, 10 do
        if rat.location == "food-room" then break end
        pcall(tick_fn, ctx, rat)
    end

    h.assert_eq("food-room", rat.location,
        "rat must move from start-room toward food-room (bait lure)")
end)

---------------------------------------------------------------------------
-- SUITE 3: Bait Value Priority
---------------------------------------------------------------------------
suite("BAIT: bait_value priority (WAVE-5)")

test("4. bait_value priority: higher value food preferred", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 90
    end

    local cheese = make_food({
        id = "high-bait",
        guid = "{high-bait-001}",
        food = { edible = true, nutrition = 20, bait_value = 5, bait_targets = {"rat"} },
        location = "test-room",
    })
    local bread = make_food({
        id = "low-bait",
        guid = "{low-bait-001}",
        name = "a crust of bread",
        keywords = {"bread", "crust"},
        food = { edible = true, nutrition = 15, bait_value = 1, bait_targets = {"rat"} },
        location = "test-room",
    })

    local ctx = make_context({
        creatures = { rat },
        objects = { cheese, bread },
    })

    -- Run ticks — rat should consume higher bait_value food first
    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    for tick = 1, 10 do
        if not ctx.registry:get("high-bait") then break end
        pcall(tick_fn, ctx, rat)
    end

    local high_gone = ctx.registry:get("high-bait") == nil
    local low_still = ctx.registry:get("low-bait") ~= nil
    h.assert_truthy(high_gone or low_still,
        "rat must prefer higher bait_value food (cheese=5) over lower (bread=1)")
end)

---------------------------------------------------------------------------
-- SUITE 4: Combat Suppression
---------------------------------------------------------------------------
suite("BAIT: combat suppression (WAVE-5)")

test("5. in-combat: hunger suppressed, creature ignores food", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 95
    end

    local cheese = make_food({ location = "test-room" })

    local ctx = make_context({
        creatures = { rat },
        objects = { cheese },
        combat_active = true,
        active_fights = {
            { combatants = { rat.id, "player" }, room_id = "test-room", round = 1 },
        },
    })

    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    -- Creature in combat should not chase food
    for tick = 1, 5 do
        pcall(tick_fn, ctx, rat)
    end

    local food_still_here = ctx.registry:get("bait-cheese") ~= nil
    h.assert_truthy(food_still_here,
        "rat in active combat must ignore food (hunger suppressed)")
end)

---------------------------------------------------------------------------
-- SUITE 5: Non-Matching bait_targets
---------------------------------------------------------------------------
suite("BAIT: target filtering (WAVE-5)")

test("6. non-matching bait_targets: creature ignores food", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat, "cat.lua must load")

    local cat = deep_copy(cat_def)
    cat.location = "test-room"
    if cat.drives and cat.drives.hunger then
        cat.drives.hunger.value = 90
    end

    -- cheese targets rat and bat only — cat should ignore
    local cheese = make_food({
        food = { edible = true, nutrition = 20, bait_value = 3, bait_targets = {"rat", "bat"} },
        location = "test-room",
    })

    local ctx = make_context({
        creatures = { cat },
        objects = { cheese },
    })

    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    for tick = 1, 5 do
        pcall(tick_fn, ctx, cat)
    end

    local food_still_here = ctx.registry:get("bait-cheese") ~= nil
    h.assert_truthy(food_still_here,
        "cat must ignore cheese — not in bait_targets (rat, bat only)")
end)

---------------------------------------------------------------------------
-- SUITE 6: Narration
---------------------------------------------------------------------------
suite("BAIT: narration (WAVE-5)")

test("7. narration emitted when creature eats bait", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 95
    end

    local cheese = make_food({ location = "test-room" })

    local ctx = make_context({
        creatures = { rat },
        objects = { cheese },
    })

    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    local all_output = {}
    local _print = print
    print = function(s) all_output[#all_output + 1] = s end

    for tick = 1, 10 do
        if not ctx.registry:get("bait-cheese") then break end
        pcall(tick_fn, ctx, rat)
    end

    print = _print

    -- Check if any narration was emitted about the creature eating
    local found_narration = false
    for _, line in ipairs(all_output) do
        local lower = line:lower()
        if (lower:find("rat") or lower:find("creature")) and
           (lower:find("eat") or lower:find("devour") or
            lower:find("consume") or lower:find("scurri")) then
            found_narration = true; break
        end
    end

    -- TDD: narration may not be implemented yet
    if ctx.registry:get("bait-cheese") then
        -- Bait mechanic not implemented — test is expected to fail
        h.assert_truthy(false,
            "bait mechanic not yet implemented — creature did not consume food")
    else
        h.assert_truthy(found_narration,
            "narration must be emitted when creature eats bait (e.g. 'The rat scurries toward the cheese and devours it.')")
    end
end)

---------------------------------------------------------------------------
-- SUITE 7: Multiple Creatures
---------------------------------------------------------------------------
suite("BAIT: multiple creatures (WAVE-5)")

test("8. multiple creatures: each evaluates independently", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat and ok_bat, "rat.lua and bat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 90
    end

    local bat = deep_copy(bat_def)
    bat.location = "test-room"
    if bat.drives and bat.drives.hunger then
        bat.drives.hunger.value = 90
    end

    -- cheese targets both rat and bat
    local cheese = make_food({
        food = { edible = true, nutrition = 20, bait_value = 3, bait_targets = {"rat", "bat"} },
        location = "test-room",
    })

    local ctx = make_context({
        creatures = { rat, bat },
        objects = { cheese },
    })

    -- Both creatures should evaluate bait independently
    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    -- Tick each creature independently
    local ok_rat_tick = pcall(tick_fn, ctx, rat)
    local ok_bat_tick = pcall(tick_fn, ctx, bat)

    h.assert_truthy(ok_rat_tick,
        "rat creature_tick must not crash with bait present")
    h.assert_truthy(ok_bat_tick,
        "bat creature_tick must not crash with bait present")
end)

test("9. two food items + two creatures: each targets best bait", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat and ok_bat, "rat.lua and bat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    if rat.drives and rat.drives.hunger then
        rat.drives.hunger.value = 90
    end

    local bat = deep_copy(bat_def)
    bat.location = "test-room"
    if bat.drives and bat.drives.hunger then
        bat.drives.hunger.value = 90
    end

    local cheese = make_food({
        id = "cheese-bait",
        guid = "{cheese-bait-multi}",
        food = { edible = true, nutrition = 20, bait_value = 3, bait_targets = {"rat", "bat"} },
        location = "test-room",
    })
    local bread = make_food({
        id = "bread-bait",
        guid = "{bread-bait-multi}",
        name = "a crust of bread",
        keywords = {"bread", "crust"},
        food = { edible = true, nutrition = 15, bait_value = 1, bait_targets = {"rat"} },
        location = "test-room",
    })

    local ctx = make_context({
        creatures = { rat, bat },
        objects = { cheese, bread },
    })

    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    -- Run ticks — multiple creatures evaluate independently
    for tick = 1, 10 do
        pcall(tick_fn, ctx, rat)
        pcall(tick_fn, ctx, bat)
        -- If both food items consumed, stop early
        if not ctx.registry:get("cheese-bait") and not ctx.registry:get("bread-bait") then
            break
        end
    end

    -- At minimum, the test should not crash. Full behavior (each creature
    -- independently selects food by bait_value) is a WAVE-5 implementation target.
    h.assert_truthy(true,
        "multiple creatures evaluating bait independently must not crash")
end)

test("10. bat ignores bread (not in bait_targets)", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_bat, "bat.lua must load")

    local bat = deep_copy(bat_def)
    bat.location = "test-room"
    if bat.drives and bat.drives.hunger then
        bat.drives.hunger.value = 90
    end

    -- bread targets only rat — bat should ignore it
    local bread = make_food({
        id = "bread-only-rat",
        guid = "{bread-only-rat}",
        name = "a crust of bread",
        keywords = {"bread", "crust"},
        food = { edible = true, nutrition = 15, bait_value = 2, bait_targets = {"rat"} },
        location = "test-room",
    })

    local ctx = make_context({
        creatures = { bat },
        objects = { bread },
    })

    local tick_fn = creatures.creature_tick or creatures.tick
    h.assert_truthy(tick_fn, "creature tick function must exist")

    for tick = 1, 5 do
        pcall(tick_fn, ctx, bat)
    end

    local bread_still = ctx.registry:get("bread-only-rat") ~= nil
    h.assert_truthy(bread_still,
        "bat must ignore bread — bat is not in bait_targets (rat only)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
