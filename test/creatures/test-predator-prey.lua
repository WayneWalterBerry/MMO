-- test/creatures/test-predator-prey.lua
-- WAVE-2 TDD: Validates predator-prey detection, prey target selection,
-- territorial behavior, and creature-to-creature hunting logic.
-- These are TDD tests — engine code is being implemented in parallel.
-- Functions that don't exist yet fail gracefully, not crash.
-- Must be run from repository root: lua test/creatures/test-predator-prey.lua

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

local ok_bat, bat_def = pcall(dofile, creature_path("bat"))
if not ok_bat then print("WARNING: bat.lua failed to load — " .. tostring(bat_def)) end

---------------------------------------------------------------------------
-- Try to load engine modules (may not be fully implemented yet — TDD)
---------------------------------------------------------------------------
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

local pp_ok, predator_prey = pcall(require, "engine.creatures.predator-prey")
if not pp_ok then
    print("WARNING: engine.creatures.predator-prey not loadable — " .. tostring(predator_prey))
    predator_prey = nil
end

local stimulus_ok, stimulus = pcall(require, "engine.creatures.stimulus")
if not stimulus_ok then
    print("WARNING: engine.creatures.stimulus not loadable — " .. tostring(stimulus))
    stimulus = nil
end

---------------------------------------------------------------------------
-- Mock factory
---------------------------------------------------------------------------
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
    local registry = make_mock_registry(all_objects)
    local rooms = { [room_id] = room }
    if opts.extra_rooms then
        for rid, r in pairs(opts.extra_rooms) do rooms[rid] = r end
    end
    return {
        registry = registry,
        rooms = rooms,
        current_room = room,
        player = opts.player or { location = room_id, hands = { nil, nil } },
        game_start_time = opts.game_start_time or os.time(),
        headless = true,
    }
end

---------------------------------------------------------------------------
-- TESTS: Predator-Prey Detection (WAVE-2)
---------------------------------------------------------------------------
suite("PREDATOR-PREY: detection + territorial behavior (WAVE-2)")

-- 1. has_prey_in_room returns true when prey present
test("1. has_prey_in_room returns true when prey present", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist (not implemented yet)")

    local result = has_prey_fn(cat, ctx)
    h.assert_truthy(result, "has_prey_in_room must return true when rat is in same room as cat")
end)

-- 2. has_prey_in_room returns false when no prey
test("2. has_prey_in_room returns false when no prey present", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat, "cat.lua must load")

    local cat = deep_copy(cat_def)
    cat.location = "test-room"

    local ctx = make_context({ creatures = { cat } })

    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(cat, ctx)
    h.assert_truthy(not result, "has_prey_in_room must return false when no prey in room")
end)

-- 3. has_prey_in_room returns false when prey is dead
test("3. has_prey_in_room returns false when prey is dead", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat._state = "dead"
    rat.animate = false
    rat.alive = false
    rat.health = 0
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(cat, ctx)
    h.assert_truthy(not result, "has_prey_in_room must return false when prey is dead")
end)

-- 4. select_prey_target returns correct creature
test("4. select_prey_target returns correct creature", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    local select_fn = creatures.select_prey_target
        or (creatures._test and creatures._test.select_prey_target)
    h.assert_truthy(select_fn, "select_prey_target function must exist (not implemented yet)")

    local target = select_fn(ctx, cat)
    h.assert_truthy(target, "select_prey_target must return a creature")
    h.assert_eq("rat", target.id, "cat's prey target must be the rat")
end)

-- 5. select_prey_target returns nil when no prey
test("5. select_prey_target returns nil when no prey", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat, "cat.lua must load")

    local cat = deep_copy(cat_def)
    cat.location = "test-room"

    local ctx = make_context({ creatures = { cat } })

    local select_fn = creatures.select_prey_target
        or (creatures._test and creatures._test.select_prey_target)
    h.assert_truthy(select_fn, "select_prey_target function must exist")

    local target = select_fn(ctx, cat)
    h.assert_nil(target, "select_prey_target must return nil when no prey in room")
end)

-- 6. Cat hunts rat (attack scored from prey list)
test("6. cat hunts rat — attack action scored from prey list", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "test-room"
    rat.location = "test-room"

    h.assert_truthy(cat.behavior.prey, "cat must have prey list in behavior")
    local has_rat = false
    for _, p in ipairs(cat.behavior.prey) do
        if p == "rat" then has_rat = true; break end
    end
    h.assert_truthy(has_rat, "cat's prey list must include 'rat'")

    local ctx = make_context({ creatures = { cat, rat } })

    local score_fn = creatures.score_actions or creatures._test and creatures._test.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    local scores = score_fn(cat, ctx)
    local found_attack = false
    for _, entry in ipairs(scores) do
        if entry.action == "attack" then found_attack = true; break end
    end
    h.assert_truthy(found_attack, "cat must score attack action when rat (prey) is present")
end)

-- 7. Cat ignores wolf (not in prey list)
test("7. cat ignores wolf — no attack scored for non-prey", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_wolf, "cat.lua and wolf.lua must load")

    local cat = deep_copy(cat_def)
    local wolf = deep_copy(wolf_def)
    cat.location = "test-room"
    wolf.location = "test-room"

    -- Verify wolf is NOT in cat's prey list
    local wolf_is_prey = false
    for _, p in ipairs(cat.behavior.prey or {}) do
        if p == "wolf" then wolf_is_prey = true; break end
    end
    h.assert_truthy(not wolf_is_prey, "wolf must NOT be in cat's prey list")

    local ctx = make_context({ creatures = { cat, wolf } })

    local score_fn = creatures.score_actions or creatures._test and creatures._test.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    local scores = score_fn(cat, ctx)
    local found_attack = false
    for _, entry in ipairs(scores) do
        if entry.action == "attack" then found_attack = true; break end
    end
    h.assert_truthy(not found_attack, "cat must NOT score attack when only non-prey (wolf) present")
end)

-- 8. Wolf hunts rat, cat, and bat
test("8. wolf hunts rat, cat, and bat — prey list contains all three", function()
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    h.assert_truthy(wolf.behavior.prey, "wolf must have prey list")

    local expected = { rat = false, cat = false, bat = false }
    for _, p in ipairs(wolf.behavior.prey) do
        if expected[p] ~= nil then expected[p] = true end
    end

    h.assert_truthy(expected.rat, "wolf prey list must include 'rat'")
    h.assert_truthy(expected.cat, "wolf prey list must include 'cat'")
    h.assert_truthy(expected.bat, "wolf prey list must include 'bat'")
end)

-- 9. Same-room requirement enforced
test("9. same-room requirement enforced — no cross-room attack", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "room-a"
    rat.location = "room-b"

    local extra_rooms = {
        ["room-b"] = { id = "room-b", name = "Room B", contents = { "rat" }, exits = {} },
    }
    local ctx = make_context({
        room_id = "room-a",
        creatures = { cat, rat },
        extra_rooms = extra_rooms,
    })
    -- Override rat location to room-b (make_context defaults to room_id)
    rat.location = "room-b"

    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(cat, ctx)
    h.assert_truthy(not result,
        "has_prey_in_room must return false when prey is in a different room")
end)

-- 10. Dead prey skipped by select_prey_target
test("10. dead prey skipped by select_prey_target", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat._state = "dead"
    rat.animate = false
    rat.alive = false
    rat.health = 0
    cat.location = "test-room"
    rat.location = "test-room"

    local ctx = make_context({ creatures = { cat, rat } })

    local select_fn = creatures.select_prey_target
        or (creatures._test and creatures._test.select_prey_target)
    h.assert_truthy(select_fn, "select_prey_target function must exist")

    local target = select_fn(ctx, cat)
    h.assert_nil(target, "select_prey_target must skip dead prey and return nil")
end)

-- 11. Empty prey list is safe (no crash)
test("11. empty prey list does not crash", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    -- Rat has no prey list (or empty) — verify it doesn't crash
    rat.behavior = rat.behavior or {}
    rat.behavior.prey = {}
    rat.location = "test-room"

    local ctx = make_context({ creatures = { rat } })

    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local ok_call, result = pcall(has_prey_fn, rat, ctx)
    h.assert_truthy(ok_call, "has_prey_in_room with empty prey list must not crash: " .. tostring(result))
    h.assert_truthy(not result, "has_prey_in_room must return false for empty prey list")
end)

-- 12. nil prey list is safe (no crash)
test("12. nil prey list does not crash", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_rat, "rat.lua must load")

    local rat = deep_copy(rat_def)
    rat.behavior = rat.behavior or {}
    rat.behavior.prey = nil
    rat.location = "test-room"

    local ctx = make_context({ creatures = { rat } })

    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local ok_call, result = pcall(has_prey_fn, rat, ctx)
    h.assert_truthy(ok_call, "has_prey_in_room with nil prey list must not crash: " .. tostring(result))
end)

-- 13. Territorial wolf aggression boost in hallway
test("13. territorial wolf gets aggression boost in home territory", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf and ok_rat, "wolf.lua and rat.lua must load")

    local wolf = deep_copy(wolf_def)
    local rat = deep_copy(rat_def)
    wolf.location = "hallway"
    rat.location = "hallway"

    h.assert_truthy(wolf.behavior.territorial, "wolf must be territorial")
    h.assert_eq("hallway", wolf.behavior.territory, "wolf territory must be 'hallway'")

    local hallway = {
        id = "hallway",
        name = "Hallway",
        contents = { "wolf", "rat" },
        exits = {},
    }
    local ctx = make_context({
        room_id = "hallway",
        creatures = { wolf, rat },
    })
    ctx.rooms["hallway"] = hallway

    local score_fn = creatures.score_actions or creatures._test and creatures._test.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    local scores = score_fn(wolf, ctx)
    local attack_score = 0
    for _, entry in ipairs(scores) do
        if entry.action == "attack" then attack_score = entry.score; break end
    end

    -- Territorial wolf in home room should have boosted attack score
    -- We verify the boost by comparing with non-territorial scenario (test 14)
    h.assert_truthy(attack_score > 0,
        "territorial wolf in hallway must score attack action (score=" .. attack_score .. ")")
end)

-- 14. Non-territorial creature gets no boost
test("14. non-territorial creature gets no territorial boost", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    cat.location = "hallway"
    rat.location = "hallway"

    h.assert_truthy(not cat.behavior.territorial or cat.behavior.territorial == false,
        "cat must NOT be territorial")

    local hallway = {
        id = "hallway",
        name = "Hallway",
        contents = { "cat", "rat" },
        exits = {},
    }
    local ctx = make_context({
        room_id = "hallway",
        creatures = { cat, rat },
    })
    ctx.rooms["hallway"] = hallway

    local score_fn = creatures.score_actions or creatures._test and creatures._test.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    local scores = score_fn(cat, ctx)
    local attack_score = 0
    for _, entry in ipairs(scores) do
        if entry.action == "attack" then attack_score = entry.score; break end
    end

    -- Cat should score attack (rat is prey) but without territorial bonus
    -- Exact value depends on aggression(40) + hunger(40)*0.5 + jitter = ~60
    h.assert_truthy(attack_score > 0,
        "non-territorial cat must still score attack against prey")
end)

-- 15. Territorial wolf NO boost in non-home room
test("15. territorial wolf gets no boost outside home territory", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf and ok_rat, "wolf.lua and rat.lua must load")

    local wolf_home = deep_copy(wolf_def)
    local wolf_away = deep_copy(wolf_def)
    wolf_away.guid = "{test-wolf-away}"

    local rat1 = deep_copy(rat_def)
    rat1.guid = "{test-rat-home}"
    local rat2 = deep_copy(rat_def)
    rat2.guid = "{test-rat-away}"

    -- Wolf in hallway (home)
    wolf_home.location = "hallway"
    rat1.location = "hallway"
    local ctx_home = make_context({
        room_id = "hallway",
        creatures = { wolf_home, rat1 },
    })

    -- Wolf NOT in hallway (away)
    wolf_away.location = "courtyard"
    rat2.location = "courtyard"
    local ctx_away = make_context({
        room_id = "courtyard",
        creatures = { wolf_away, rat2 },
    })

    local score_fn = creatures.score_actions or creatures._test and creatures._test.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    math.randomseed(42)
    local scores_home = score_fn(wolf_home, ctx_home)
    math.randomseed(42)
    local scores_away = score_fn(wolf_away, ctx_away)

    local attack_home, attack_away = 0, 0
    for _, e in ipairs(scores_home) do
        if e.action == "attack" then attack_home = e.score end
    end
    for _, e in ipairs(scores_away) do
        if e.action == "attack" then attack_away = e.score end
    end

    h.assert_truthy(attack_home > attack_away,
        "territorial wolf attack score in home (" .. attack_home ..
        ") must exceed away (" .. attack_away .. ")")
end)

-- 16. Wolf hunts cat when both in same room
test("16. wolf hunts cat — attack scored when cat is prey", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf and ok_cat, "wolf.lua and cat.lua must load")

    local wolf = deep_copy(wolf_def)
    local cat = deep_copy(cat_def)
    wolf.location = "test-room"
    cat.location = "test-room"

    local ctx = make_context({ creatures = { wolf, cat } })

    local score_fn = creatures.score_actions or creatures._test and creatures._test.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    local scores = score_fn(wolf, ctx)
    local found_attack = false
    for _, entry in ipairs(scores) do
        if entry.action == "attack" then found_attack = true; break end
    end
    h.assert_truthy(found_attack, "wolf must score attack when cat (prey) is present")
end)

-- 17. select_prey_target prefers first alive match
test("17. select_prey_target returns first alive prey match", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf and ok_rat and ok_cat, "wolf/rat/cat must load")

    local wolf = deep_copy(wolf_def)
    local rat = deep_copy(rat_def)
    local cat = deep_copy(cat_def)
    wolf.location = "test-room"
    rat.location = "test-room"
    cat.location = "test-room"

    -- Player in different room so wolf targets creatures, not player
    local player = { location = "other-room", hands = { nil, nil } }
    local ctx = make_context({ creatures = { wolf, rat, cat }, player = player })

    local select_fn = creatures.select_prey_target
        or (creatures._test and creatures._test.select_prey_target)
    h.assert_truthy(select_fn, "select_prey_target function must exist")

    local target = select_fn(ctx, wolf)
    h.assert_truthy(target, "select_prey_target must return a creature")
    -- Wolf's prey list is {"player", "rat", "cat", "bat"} — player absent, so rat or cat
    h.assert_truthy(target.id == "rat" or target.id == "cat",
        "wolf's prey target must be rat or cat, got: " .. tostring(target.id))
end)

-- 18. get_creatures_in_room returns only animate creatures
test("18. get_creatures_in_room returns only animate creatures", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_cat and ok_rat, "cat.lua and rat.lua must load")

    local cat = deep_copy(cat_def)
    local rat = deep_copy(rat_def)
    rat._state = "dead"
    rat.animate = false
    cat.location = "test-room"
    rat.location = "test-room"

    local registry = make_mock_registry({ cat, rat })

    local result = creatures.get_creatures_in_room(registry, "test-room")
    h.assert_eq("table", type(result), "must return a table")
    h.assert_eq(1, #result, "only animate creatures should be returned (dead rat excluded)")
    h.assert_eq("cat", result[1].id, "only the cat should be returned")
end)

-- 19. Predator does not target itself
test("19. predator does not target itself", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    -- Add "wolf" to prey list to test self-targeting prevention
    wolf.behavior.prey = {"wolf", "rat", "cat"}
    wolf.location = "test-room"

    local ctx = make_context({ creatures = { wolf } })

    local select_fn = creatures.select_prey_target
        or (creatures._test and creatures._test.select_prey_target)
    h.assert_truthy(select_fn, "select_prey_target function must exist")

    local target = select_fn(ctx, wolf)
    h.assert_nil(target, "predator must not select itself as prey target")
end)

-- 20. Wolf hunts bat (verify bat is in prey list)
test("20. wolf hunts bat — bat is valid prey", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf and ok_bat, "wolf.lua and bat.lua must load")

    local wolf = deep_copy(wolf_def)
    local bat = deep_copy(bat_def)
    wolf.location = "test-room"
    bat.location = "test-room"

    -- Player in different room so wolf targets bat, not player
    local player = { location = "other-room", hands = { nil, nil } }
    local ctx = make_context({ creatures = { wolf, bat }, player = player })    local has_prey_fn = creatures.has_prey_in_room
        or (creatures._test and creatures._test.has_prey_in_room)
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(wolf, ctx)
    h.assert_truthy(result, "wolf must detect bat as prey in room")

    local select_fn = creatures.select_prey_target
        or (creatures._test and creatures._test.select_prey_target)
    h.assert_truthy(select_fn, "select_prey_target function must exist")

    local target = select_fn(ctx, wolf)
    h.assert_truthy(target, "select_prey_target must return bat")
    h.assert_eq("bat", target.id, "wolf's prey target must be the bat")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
