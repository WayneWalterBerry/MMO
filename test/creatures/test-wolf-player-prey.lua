-- test/creatures/test-wolf-player-prey.lua
-- TDD regression tests for #324: Wolf never attacks player — player not in prey list.
-- Root cause: predator-prey.has_prey_in_room() only scans the registry via
-- get_creatures_in_room(), but the player lives at context.player and is NOT
-- registered. So the wolf's prey list includes "player" but the engine never
-- finds it.
--
-- Tests must FAIL before fix, PASS after.
-- Run from repo root: lua test/creatures/test-wolf-player-prey.lua

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
-- Load wolf definition
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "wolf.lua"
local ok_wolf, wolf_def = pcall(dofile, wolf_path)
if not ok_wolf then
    print("WARNING: wolf.lua not found — " .. tostring(wolf_def))
    wolf_def = nil
end

---------------------------------------------------------------------------
-- Load engine modules
---------------------------------------------------------------------------
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

local pp_ok, predator_prey = pcall(require, "engine.creatures.predator-prey")
if not pp_ok then
    print("WARNING: predator-prey not loadable — " .. tostring(predator_prey))
    predator_prey = nil
end

---------------------------------------------------------------------------
-- Mock factory (mirrors test-predator-prey.lua pattern)
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
        player = opts.player or { location = room_id, hands = { nil, nil }, health = 100, max_health = 100 },
        game_start_time = opts.game_start_time or os.time(),
        headless = true,
    }
end

---------------------------------------------------------------------------
-- TESTS: Wolf detects player as prey (#324)
---------------------------------------------------------------------------
suite("BUG #324: Wolf must detect player as prey")

test("1. has_prey_in_room returns true when player is in same room as wolf", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    wolf.location = "test-room"

    local player = { location = "test-room", hands = { nil, nil }, health = 100, max_health = 100 }
    local ctx = make_context({ creatures = { wolf }, player = player })

    local has_prey_fn = creatures.has_prey_in_room
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(wolf, ctx)
    h.assert_truthy(result, "has_prey_in_room must return true when player is in same room as wolf")
end)

test("2. select_prey_target returns player when player is in same room", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    wolf.location = "test-room"

    local player = { location = "test-room", hands = { nil, nil }, health = 100, max_health = 100 }
    local ctx = make_context({ creatures = { wolf }, player = player })

    local select_fn = creatures.select_prey_target
    h.assert_truthy(select_fn, "select_prey_target function must exist")

    local target = select_fn(ctx, wolf)
    h.assert_truthy(target, "select_prey_target must return the player")
    h.assert_eq(player, target, "target must be the player object")
end)

test("3. wolf scores attack action when player is prey in room", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    wolf.location = "test-room"

    local player = { location = "test-room", hands = { nil, nil }, health = 100, max_health = 100 }
    local ctx = make_context({ creatures = { wolf }, player = player })

    local score_fn = creatures.score_actions
    h.assert_truthy(score_fn, "score_actions function must exist")

    local scores = score_fn(wolf, ctx)
    local found_attack = false
    for _, entry in ipairs(scores) do
        if entry.action == "attack" then found_attack = true; break end
    end
    h.assert_truthy(found_attack, "wolf must score attack action when player (prey) is present")
end)

test("4. has_prey_in_room returns false when player is in different room", function()
    h.assert_truthy(creatures, "engine.creatures module required")
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    wolf.location = "room-a"

    local player = { location = "room-b", hands = { nil, nil }, health = 100, max_health = 100 }
    local ctx = make_context({ room_id = "room-a", creatures = { wolf }, player = player })

    local has_prey_fn = creatures.has_prey_in_room
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(wolf, ctx)
    h.assert_truthy(not result, "has_prey_in_room must return false when player is in a different room")
end)

test("5. predator-prey ignores player when 'player' not in prey list", function()
    h.assert_truthy(creatures, "engine.creatures module required")

    -- Create a creature with no "player" in prey list
    local cat_like = {
        id = "test-cat",
        guid = "{test-cat-guid}",
        animate = true,
        _state = "alive-idle",
        location = "test-room",
        behavior = { prey = {"rat"}, aggression = 40 },
        drives = { hunger = { value = 30, max = 100 }, fear = { value = 0, max = 100, min = 0 } },
    }

    local player = { location = "test-room", hands = { nil, nil }, health = 100, max_health = 100 }
    local ctx = make_context({ creatures = { cat_like }, player = player })

    local has_prey_fn = creatures.has_prey_in_room
    h.assert_truthy(has_prey_fn, "has_prey_in_room function must exist")

    local result = has_prey_fn(cat_like, ctx)
    h.assert_truthy(not result, "has_prey_in_room must return false when 'player' is not in prey list")
end)

test("6. player is highest-priority prey (first in wolf prey list)", function()
    h.assert_truthy(ok_wolf, "wolf.lua must load")

    local wolf = deep_copy(wolf_def)
    h.assert_truthy(wolf.behavior.prey, "wolf must have prey list")
    h.assert_eq("player", wolf.behavior.prey[1],
        "player must be first in wolf prey list (highest priority)")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
