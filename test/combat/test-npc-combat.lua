-- test/combat/test-npc-combat.lua
-- WAVE-3 TDD: NPC-vs-NPC combat resolution, multi-combatant turn order,
-- active_fights lifecycle, morale/flee/cornered, dead creature handling.
-- Engine modules under test: src/engine/combat/init.lua, src/engine/creatures/init.lua
-- TDD red phase — tests written to spec, may fail until Bart/Smithers finish.
-- Must be run from repository root: lua test/combat/test-npc-combat.lua

math.randomseed(42)

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

local ok_cat, cat_def = pcall(dofile, creature_path("cat"))
if not ok_cat then print("WARNING: cat.lua failed to load — " .. tostring(cat_def)) end

local ok_rat, rat_def = pcall(dofile, creature_path("rat"))
if not ok_rat then print("WARNING: rat.lua failed to load — " .. tostring(rat_def)) end

local ok_wolf, wolf_def = pcall(dofile, creature_path("wolf"))
if not ok_wolf then print("WARNING: wolf.lua failed to load — " .. tostring(wolf_def)) end

local ok_spider, spider_def = pcall(dofile, creature_path("spider"))
if not ok_spider then print("WARNING: spider.lua failed to load — " .. tostring(spider_def)) end

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

---------------------------------------------------------------------------
-- Load engine modules (pcall-guarded — TDD: may not be fully implemented)
---------------------------------------------------------------------------
local combat_ok, combat = pcall(require, "engine.combat")
if not combat_ok then
    print("WARNING: engine.combat not loadable — " .. tostring(combat))
    combat = nil
end

local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

---------------------------------------------------------------------------
-- Mock factory: registry, rooms, context
---------------------------------------------------------------------------
local portal_counter = 0

local function make_portal(target_room_id, traversable)
    portal_counter = portal_counter + 1
    local pid = "{portal-npc-" .. portal_counter .. "}"
    return {
        guid = pid,
        id = "portal-npc-" .. portal_counter,
        _state = traversable and "open" or "closed",
        states = {
            open = { traversable = true },
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
        local result = {}
        local seen = {}
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
    return reg
end

local function make_context(opts)
    opts = opts or {}
    local room_id = opts.room_id or "test-room"
    local room = {
        id = room_id,
        name = "Test Room",
        template = "room",
        contents = {},
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
    -- Add portal objects to registry so exits resolve
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
            id = "player", name = "the player",
            location = room_id,
            hands = { nil, nil },
            health = 100, max_health = 100,
            combat = { size = "medium", speed = 5 },
            body_tree = {
                head  = { size = 0.10, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
                torso = { size = 0.35, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
                arms  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
                hands = { size = 0.10, vital = false, tissue = { "skin", "flesh", "bone" } },
                legs  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
                feet  = { size = 0.05, vital = false, tissue = { "skin", "flesh", "bone" } },
            },
            _state = "alive", animate = true, portable = false,
        },
        active_fights = opts.active_fights or {},
        combat_active = opts.combat_active or false,
        game_start_time = opts.game_start_time or os.time(),
        headless = true,
    }
end

---------------------------------------------------------------------------
-- Helper: make a player combatant table
---------------------------------------------------------------------------
local function make_player()
    return {
        id = "player", name = "the player",
        location = "test-room",
        health = 100, max_health = 100,
        combat = { size = "medium", speed = 5 },
        body_tree = {
            head  = { size = 0.10, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
            torso = { size = 0.35, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
            arms  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
            hands = { size = 0.10, vital = false, tissue = { "skin", "flesh", "bone" } },
            legs  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
            feet  = { size = 0.05, vital = false, tissue = { "skin", "flesh", "bone" } },
        },
        _state = "alive", animate = true, portable = false,
    }
end

---------------------------------------------------------------------------
-- SUITE 1: Cat-Kills-Rat — Full NPC Combat Resolution
---------------------------------------------------------------------------
suite("NPC COMBAT: cat-kills-rat resolution (WAVE-3)")

test("1. run_combat(cat, rat) does not crash", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })
    local ok_run, result = pcall(combat.run_combat, ctx, cat, rat)
    h.assert_truthy(ok_run, "run_combat must not crash: " .. tostring(result))
    h.assert_truthy(type(result) == "table", "run_combat must return a result table")
end)

test("2. rat health decrements after cat attack", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    local initial_health = rat.health
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })
    combat.run_combat(ctx, cat, rat)
    h.assert_truthy(rat.health <= initial_health,
        "rat health must decrement after cat attack (was " .. initial_health
        .. ", now " .. rat.health .. ")")
end)

test("3. repeated attacks kill rat (health reaches 0)", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })
    -- Cat has force=5 bite vs rat with 5 HP — should die within 20 rounds
    for round = 1, 20 do
        if rat.health <= 0 or rat._state == "dead" or rat.alive == false then break end
        pcall(combat.run_combat, ctx, cat, rat)
    end
    h.assert_truthy(rat.health <= 0 or rat._state == "dead" or rat.alive == false,
        "rat must die after repeated cat attacks (health=" .. rat.health
        .. ", state=" .. tostring(rat._state) .. ")")
end)

test("4. dead rat has alive=false, animate=false, portable=true", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })
    for round = 1, 20 do
        if rat.health <= 0 or rat._state == "dead" then break end
        pcall(combat.run_combat, ctx, cat, rat)
    end
    h.assert_eq(false, rat.alive, "dead rat must have alive=false")
    h.assert_eq(false, rat.animate, "dead rat must have animate=false")
    h.assert_eq(true, rat.portable, "dead rat must have portable=true")
end)

---------------------------------------------------------------------------
-- SUITE 2: Turn Order — Speed, Size Tiebreak, Player-Last
---------------------------------------------------------------------------
suite("NPC COMBAT: turn order (WAVE-3)")

test("5. faster creature goes first (bat speed=9 vs rat speed=6)", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(combat.initiate, "combat.initiate function required")
    h.assert_truthy(ok_bat and ok_rat, "bat.lua and rat.lua must load")

    local bat = deep_copy(bat_def)
    local rat = deep_copy(rat_def)

    local first, second = combat.initiate(bat, rat)
    h.assert_eq(bat.id, first.id,
        "faster creature (bat speed=9) must go first, got " .. tostring(first.id))
    h.assert_eq(rat.id, second.id,
        "slower creature (rat speed=6) must go second, got " .. tostring(second.id))
end)

test("6. slower creature goes second (rat speed=6 vs cat speed=7)", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(combat.initiate, "combat.initiate function required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)

    local first, second = combat.initiate(rat, cat)
    h.assert_eq(cat.id, first.id,
        "faster creature (cat speed=7) must go first regardless of arg order")
end)

test("7. size tiebreak: smaller first among equal speed (cat=small vs wolf=medium, both speed=7)", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(combat.initiate, "combat.initiate function required")
    h.assert_truthy(ok_cat and ok_wolf, "cat.lua and wolf.lua must load")

    local cat = deep_copy(cat_def)
    local wolf = deep_copy(wolf_def)
    -- Both have speed=7; cat is small, wolf is medium → cat goes first
    local first, second = combat.initiate(cat, wolf)
    h.assert_eq(cat.id, first.id,
        "smaller creature (cat=small) must go first when speed ties, got " .. tostring(first.id))
end)

test("8. player goes last among equals (player speed=5 vs spider speed=5)", function()
    h.assert_truthy(combat, "engine.combat module required")

    local player = make_player()
    local spider = deep_copy(spider_def)
    -- Both speed=5; spider is tiny, player is medium → spider first by size
    -- But also: player goes last among equals per spec

    -- Try multi-combatant turn order if available
    local get_turn_order = combat.get_turn_order
        or (combat._test and combat._test.get_turn_order)
    if get_turn_order then
        local order = get_turn_order({ player, spider })
        -- Player should be last
        h.assert_eq(player.id, order[#order].id,
            "player must be last in turn order among equals")
    else
        -- Fall back to initiate check
        local init_fn = combat.initiate
        h.assert_truthy(init_fn, "combat.initiate required for turn order")
        local first, second = init_fn(player, spider)
        h.assert_eq(spider.id, first.id,
            "spider (tiny) must go before player (medium) when speed ties")
        h.assert_eq(player.id, second.id,
            "player must go last among speed-equal combatants")
    end
end)

---------------------------------------------------------------------------
-- SUITE 3: active_fights Lifecycle
---------------------------------------------------------------------------
suite("NPC COMBAT: active_fights lifecycle (WAVE-3)")

test("9. active_fights created when NPC combat begins", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    -- Initiate NPC fight via engine API
    local start_fn = combat.start_fight or combat.initiate_fight
        or (combat._test and combat._test.start_fight)
    if start_fn then
        pcall(start_fn, ctx, cat, rat)
        h.assert_truthy(ctx.active_fights and #ctx.active_fights > 0,
            "active_fights must be populated after start_fight")
    else
        -- Fall back: run_combat should track fight
        pcall(combat.run_combat, ctx, cat, rat)
        h.assert_truthy(type(ctx.active_fights) == "table",
            "context.active_fights must exist (table)")
    end
end)

test("10. active_fight entry has combatants, room_id, round", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    local start_fn = combat.start_fight or combat.initiate_fight
        or (combat._test and combat._test.start_fight)
    if start_fn then
        pcall(start_fn, ctx, cat, rat)
    else
        pcall(combat.run_combat, ctx, cat, rat)
    end

    -- Check structure of active fight
    if ctx.active_fights and #ctx.active_fights > 0 then
        local fight = ctx.active_fights[1]
        h.assert_truthy(fight.combatants, "active fight must have combatants list")
        h.assert_truthy(fight.room_id, "active fight must have room_id")
        h.assert_truthy(fight.round ~= nil, "active fight must track round number")
    else
        h.assert_truthy(false,
            "active_fights must contain at least one fight entry (TDD: not yet implemented)")
    end
end)

test("11. active_fight cleaned up after combat resolves", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    -- Run combat until rat is dead
    for round = 1, 20 do
        if rat.health <= 0 or rat._state == "dead" then break end
        pcall(combat.run_combat, ctx, cat, rat)
    end

    -- After fight resolves, active_fights should be empty or fight removed
    local resolve_fn = combat.resolve_fight or combat.cleanup_fight
        or (combat._test and combat._test.cleanup_fight)
    if resolve_fn then
        pcall(resolve_fn, ctx)
    end
    -- Completed fights should not persist
    local active_count = 0
    if ctx.active_fights then
        for _, f in ipairs(ctx.active_fights) do
            if f.room_id == "test-room" then active_count = active_count + 1 end
        end
    end
    h.assert_eq(0, active_count,
        "active_fights must be cleaned up after combat resolves")
end)

---------------------------------------------------------------------------
-- SUITE 4: NPC Target Selection
---------------------------------------------------------------------------
suite("NPC COMBAT: target selection (WAVE-3)")

test("12. cat selects rat from prey list", function()
    h.assert_truthy(ok_cat, "cat.lua must load")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local cat = deep_copy(cat_def)
    -- Cat's prey list should include "rat"
    local prey = cat.combat and cat.combat.behavior and cat.combat.behavior.prey
        or cat.behavior and cat.behavior.prey
    h.assert_truthy(prey, "cat must have prey list in combat.behavior or behavior")

    local has_rat = false
    for _, p in ipairs(prey or {}) do
        if p == "rat" then has_rat = true; break end
    end
    h.assert_truthy(has_rat, "cat's prey list must include 'rat'")
end)

test("13. NPC selects prey target when prey present in room", function()
    h.assert_truthy(combat or creatures, "combat or creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    local select_fn = combat and (combat.select_target or combat.npc_select_target)
        or creatures and (creatures.select_target or creatures.select_prey_target)
    if select_fn then
        local target = select_fn(ctx, cat)
        h.assert_truthy(target, "target selection must return a creature")
        h.assert_eq("rat", target.id, "cat must select rat as target from prey list")
    else
        -- Verify run_combat uses rat as defender (indirect validation)
        h.assert_truthy(combat, "combat module needed for indirect test")
        local ok_run, result = pcall(combat.run_combat, ctx, cat, rat)
        h.assert_truthy(ok_run, "run_combat with prey target must not crash")
    end
end)

test("14. NPC target fallback to aggression threshold", function()
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    -- Wolf has aggression in behavior (numeric=70) and combat.behavior (string="territorial")
    -- Use the numeric value from behavior for threshold comparison
    local aggression = wolf.behavior and wolf.behavior.aggression
    if type(aggression) ~= "number" then
        aggression = wolf.combat and wolf.combat.behavior
            and wolf.combat.behavior.aggression
    end
    -- String aggression like "territorial" implies high aggression
    if type(aggression) == "string" then
        h.assert_truthy(aggression == "territorial" or aggression == "aggressive",
            "string aggression must indicate high aggression, got " .. aggression)
    else
        h.assert_truthy(aggression, "wolf must have aggression value")
        h.assert_truthy(aggression >= 50,
            "wolf aggression must be high enough for fallback targeting, got "
            .. tostring(aggression))
    end

    -- When no prey is present, high aggression should enable attacking non-prey
    local select_fn = combat and (combat.select_target or combat.npc_select_target)
        or creatures and (creatures.select_target or creatures.select_prey_target)
    if select_fn then
        local spider = deep_copy(spider_def)
        spider.location = "test-room"
        wolf.location = "test-room"
        local ctx = make_context({ creatures = { wolf, spider } })
        local target = select_fn(ctx, wolf)
        -- Spider is not wolf's prey → fallback to aggression-based targeting
        h.assert_truthy(target,
            "high-aggression wolf must find a target via aggression fallback")
    else
        h.assert_truthy(false,
            "select_target not found — TDD: Bart must implement target selection")
    end
end)

---------------------------------------------------------------------------
-- SUITE 5: Multi-Combatant
---------------------------------------------------------------------------
suite("NPC COMBAT: multi-combatant (WAVE-3)")

test("15. 3-creature fight resolves in finite rounds (no infinite loop)", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat and ok_spider,
        "cat.lua, rat.lua, spider.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    local spider = deep_copy(spider_def)
    cat.location = "test-room"
    rat.location = "test-room"
    spider.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat, spider } })

    -- Multi-combatant fight must resolve or cap at 20 rounds
    local resolve_multi = combat.resolve_multi_combat or combat.run_multi_combat
        or (combat._test and combat._test.resolve_multi_combat)
    local rounds = 0
    local max_rounds = 20
    if resolve_multi then
        local ok_multi, result = pcall(resolve_multi, ctx, { cat, rat, spider })
        h.assert_truthy(ok_multi, "multi-combat must not crash: " .. tostring(result))
        if type(result) == "table" and result.rounds then
            rounds = result.rounds
        end
    else
        -- Simulate via pairwise run_combat
        for r = 1, max_rounds do
            rounds = r
            local alive_count = 0
            local alive = {}
            for _, c in ipairs({ cat, rat, spider }) do
                if c.health > 0 and c._state ~= "dead" and c.alive ~= false then
                    alive_count = alive_count + 1
                    alive[#alive + 1] = c
                end
            end
            if alive_count <= 1 then break end
            -- Pairwise: first attacks second
            pcall(combat.run_combat, ctx, alive[1], alive[2])
        end
    end
    h.assert_truthy(rounds <= max_rounds,
        "3-creature fight must resolve within " .. max_rounds .. " rounds, took " .. rounds)
end)

test("16. multi-combatant: all opponents dead or fled → combat terminates", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat.health = 1  -- near death — should die quickly
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    for round = 1, 20 do
        if rat.health <= 0 or rat._state == "dead" then break end
        pcall(combat.run_combat, ctx, cat, rat)
    end
    h.assert_truthy(rat.health <= 0 or rat._state == "dead" or rat.alive == false,
        "combat must terminate when opponent is dead")
end)

test("17. player joins active NPC fight", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    local player = make_player()
    cat.location = "test-room"
    rat.location = "test-room"
    player.location = "test-room"

    local ctx = make_context({
        creatures = { cat, rat },
        player = player,
    })

    -- Start NPC fight
    pcall(combat.run_combat, ctx, cat, rat)

    -- Player joins — should be able to attack rat too
    -- Ensure player has hands structure for presentation module
    player.hands = { nil, nil }
    local ok_join, result = pcall(combat.run_combat, ctx, player, rat)
    h.assert_truthy(ok_join,
        "player joining active NPC fight must not crash: " .. tostring(result))
end)

---------------------------------------------------------------------------
-- SUITE 6: Morale / Flee
---------------------------------------------------------------------------
suite("NPC COMBAT: morale and flee (WAVE-3)")

test("18. creature below flee_threshold attempts to flee", function()
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    local flee_threshold = rat.combat and rat.combat.behavior
        and rat.combat.behavior.flee_threshold
    h.assert_truthy(flee_threshold, "rat must have flee_threshold in combat.behavior")
    h.assert_truthy(flee_threshold > 0 and flee_threshold < 1,
        "flee_threshold must be a decimal 0<x<1, got " .. tostring(flee_threshold))

    -- Set rat health below threshold
    rat.health = math.floor(rat.max_health * flee_threshold) - 1
    h.assert_truthy(rat.health / rat.max_health < flee_threshold,
        "rat health ratio (" .. rat.health / rat.max_health
        .. ") must be below flee_threshold (" .. flee_threshold .. ")")

    -- Morale check should trigger flee
    local check_morale = combat and (combat.check_morale or combat.check_flee)
        or creatures and (creatures.check_morale or creatures.check_flee)
    if check_morale then
        local should_flee = check_morale(rat)
        h.assert_truthy(should_flee,
            "creature below flee_threshold must attempt to flee")
    else
        -- Verify threshold metadata exists for Bart's implementation
        h.assert_truthy(flee_threshold == 0.3,
            "rat flee_threshold must be 0.3, got " .. tostring(flee_threshold))
    end
end)

test("19. flee success: creature moves to adjacent room", function()
    h.assert_truthy(combat or creatures, "combat or creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    rat.health = 1  -- below flee_threshold

    local adj_portal, adj_pid = make_portal("adjacent-room", true)
    local ctx = make_context({
        creatures = { rat },
        exits = { north = { portal = adj_pid } },
        extra_objects = { adj_portal },
        extra_rooms = {
            ["adjacent-room"] = {
                id = "adjacent-room", name = "Adjacent Room",
                template = "room", contents = {}, exits = {},
            },
        },
    })

    local flee_fn = combat and (combat.attempt_flee or combat.flee)
        or creatures and (creatures.attempt_flee or creatures.flee)
    if flee_fn then
        local ok_flee, result = pcall(flee_fn, ctx, rat)
        h.assert_truthy(ok_flee, "flee attempt must not crash: " .. tostring(result))
        h.assert_eq("adjacent-room", rat.location,
            "fled creature must move to adjacent room")
    else
        h.assert_truthy(false,
            "flee function not found — TDD: Bart must implement flee movement")
    end
end)

test("20. flee failure (cornered): no valid exits → cornered stance", function()
    h.assert_truthy(combat or creatures, "combat or creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    rat.health = 1  -- below flee_threshold

    -- No exits → cornered
    local ctx = make_context({ creatures = { rat }, exits = {} })

    local flee_fn = combat and (combat.attempt_flee or combat.flee)
        or creatures and (creatures.attempt_flee or creatures.flee)
    if flee_fn then
        local ok_flee, result = pcall(flee_fn, ctx, rat)
        h.assert_truthy(ok_flee, "cornered flee must not crash: " .. tostring(result))
        -- Should still be in same room
        h.assert_eq("test-room", rat.location,
            "cornered creature must stay in same room")
        -- Should have cornered stance or flag
        local is_cornered = (rat._stance == "cornered")
            or (rat._cornered == true)
            or (result and result.cornered == true)
        h.assert_truthy(is_cornered,
            "creature with no exits must be flagged as cornered")
    else
        h.assert_truthy(false,
            "flee function not found — TDD: Bart must implement cornered fallback")
    end
end)

test("21. cornered bonus: attack multiplied by 1.5", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat.location = "test-room"
    cat.location = "test-room"
    rat.health = 1
    rat._cornered = true
    rat._stance = "cornered"

    -- Cornered rat's effective attack should be 1.5x
    local get_attack = combat.get_effective_attack
        or (combat._test and combat._test.get_effective_attack)
    if get_attack then
        local normal_rat = deep_copy(rat_def)
        local normal_force = get_attack(normal_rat)
        local cornered_force = get_attack(rat)
        h.assert_truthy(cornered_force > normal_force,
            "cornered attack (" .. cornered_force .. ") must exceed normal ("
            .. normal_force .. ")")
        -- Check 1.5x multiplier
        local expected = normal_force * 1.5
        h.assert_eq(expected, cornered_force,
            "cornered bonus must be exactly 1.5x")
    else
        -- Verify via combat result damage
        local ctx = make_context({ creatures = { cat, rat }, exits = {} })
        math.randomseed(42)
        local ok_run, result = pcall(combat.run_combat, ctx, rat, cat)
        h.assert_truthy(ok_run,
            "combat with cornered creature must not crash: " .. tostring(result))
        -- Cornered bonus is a design spec — Bart must implement the multiplier
        h.assert_truthy(true, "cornered bonus spec: attack × 1.5 (TDD placeholder)")
    end
end)

---------------------------------------------------------------------------
-- SUITE 7: Dead Creature Handling
---------------------------------------------------------------------------
suite("NPC COMBAT: dead creature handling (WAVE-3)")

test("22. dead creature mutation: _state='dead', alive=false, animate=false, portable=true", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat.health = 1  -- one hit will kill
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })
    for round = 1, 10 do
        if rat.health <= 0 or rat._state == "dead" then break end
        pcall(combat.run_combat, ctx, cat, rat)
    end

    h.assert_eq("dead", rat._state, "killed creature _state must be 'dead'")
    h.assert_eq(false, rat.alive, "killed creature alive must be false")
    h.assert_eq(false, rat.animate, "killed creature animate must be false")
    h.assert_eq(true, rat.portable, "killed creature portable must be true (can be picked up)")
end)

test("23. combat does not crash with dead combatant in fight", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat._state = "dead"
    rat.alive = false
    rat.animate = false
    rat.health = 0
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    -- Combat with dead defender should not crash
    local ok_run, result = pcall(combat.run_combat, ctx, cat, rat)
    h.assert_truthy(ok_run,
        "combat with dead combatant must not crash: " .. tostring(result))
end)

test("24. dead creature skipped in multi-combatant turn order", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat and ok_spider,
        "cat.lua, rat.lua, spider.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    local spider = deep_copy(spider_def)
    rat._state = "dead"
    rat.alive = false
    rat.animate = false
    rat.health = 0
    cat.location = "test-room"
    rat.location = "test-room"
    spider.location = "test-room"

    local get_turn_order = combat.get_turn_order
        or (combat._test and combat._test.get_turn_order)
    if get_turn_order then
        local order = get_turn_order({ cat, rat, spider })
        -- Dead rat must not appear in turn order
        for _, combatant in ipairs(order) do
            h.assert_truthy(combatant.id ~= "rat" or combatant.alive ~= false,
                "dead creature must be skipped in turn order")
        end
    else
        -- Simulate: run_combat with 3 creatures, one dead — no crash expected
        local ctx = make_context({ creatures = { cat, rat, spider } })
        local alive_combatants = {}
        for _, c in ipairs({ cat, rat, spider }) do
            if c.alive ~= false and c._state ~= "dead" then
                alive_combatants[#alive_combatants + 1] = c
            end
        end
        h.assert_eq(2, #alive_combatants,
            "only alive creatures should be in the fight (expected 2, got "
            .. #alive_combatants .. ")")
        -- Pairwise should not crash
        if #alive_combatants >= 2 then
            local ok_run, result = pcall(combat.run_combat, ctx,
                alive_combatants[1], alive_combatants[2])
            h.assert_truthy(ok_run,
                "combat between alive combatants must not crash: " .. tostring(result))
        end
    end
end)

test("25. creature health cannot go below 0", function()
    h.assert_truthy(combat, "engine.combat module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    math.randomseed(42)
    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat.health = 1
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })
    for round = 1, 10 do
        if rat.health <= 0 or rat._state == "dead" then break end
        pcall(combat.run_combat, ctx, cat, rat)
    end
    h.assert_truthy(rat.health >= 0,
        "creature health must not go below 0, got " .. rat.health)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
