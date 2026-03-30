-- test/creatures/test-wolf-combat-balance.lua
-- Regression tests for #352: Wolf combat balance + targeting + max_health.
-- TDD: Tests must FAIL before fix, PASS after.
-- Must be run from repository root: lua test/creatures/test-wolf-combat-balance.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load the wolf object
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "creatures" .. SEP .. "wolf.lua"
local ok, wolf = pcall(dofile, wolf_path)
if not ok then
    print("WARNING: wolf.lua not found — " .. tostring(wolf))
    wolf = nil
end

---------------------------------------------------------------------------
-- Load morale module
---------------------------------------------------------------------------
local morale_ok, morale = pcall(require, "engine.creatures.morale")
if not morale_ok then
    print("WARNING: morale module not loadable — " .. tostring(morale))
    morale = nil
end

---------------------------------------------------------------------------
-- Load combat init for select_npc_target
---------------------------------------------------------------------------
local combat_ok, combat = pcall(require, "engine.combat")
if not combat_ok then
    print("WARNING: combat module not loadable — " .. tostring(combat))
    combat = nil
end

---------------------------------------------------------------------------
-- TESTS: Wolf combat stats are survivable (#352)
---------------------------------------------------------------------------
suite("WOLF BALANCE: bite force must be survivable (#352)")

test("1. wolf bite force <= 5 (was 8, too lethal)", function()
    h.assert_truthy(wolf, "wolf not loaded")
    local bite = wolf.combat.natural_weapons[1]
    h.assert_truthy(bite, "wolf must have bite weapon")
    h.assert_eq("bite", bite.id, "first weapon must be bite")
    h.assert_truthy(bite.force <= 5,
        "bite force must be <= 5 for survivable combat, got " .. tostring(bite.force))
end)

test("2. wolf claw force <= 3 (was 4, slightly too strong)", function()
    h.assert_truthy(wolf, "wolf not loaded")
    local claw = wolf.combat.natural_weapons[2]
    h.assert_truthy(claw, "wolf must have claw weapon")
    h.assert_eq("claw", claw.id, "second weapon must be claw")
    h.assert_truthy(claw.force <= 3,
        "claw force must be <= 3 for balance, got " .. tostring(claw.force))
end)

test("3. wolf combat speed <= 5 (was 7, outspeeds everything)", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.combat.speed <= 5,
        "combat speed must be <= 5, got " .. tostring(wolf.combat.speed))
end)

test("4. wolf health <= 25 (was 40, too tanky for basic weapons)", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.health <= 25,
        "wolf health must be <= 25, got " .. tostring(wolf.health))
    h.assert_truthy(wolf.max_health <= 25,
        "wolf max_health must be <= 25, got " .. tostring(wolf.max_health))
    h.assert_eq(wolf.health, wolf.max_health,
        "health and max_health must match at start")
end)

---------------------------------------------------------------------------
-- TESTS: Wolf targets player (#324)
---------------------------------------------------------------------------
suite("WOLF TARGETING: player must be in prey list (#324)")

test("5. wolf behavior.prey includes 'player'", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.behavior, "wolf must have behavior")
    h.assert_truthy(wolf.behavior.prey, "wolf must have prey list")

    local has_player = false
    for _, prey_id in ipairs(wolf.behavior.prey) do
        if prey_id == "player" then has_player = true; break end
    end
    h.assert_truthy(has_player,
        "wolf behavior.prey must include 'player' for wolf to attack")
end)

test("6. select_npc_target picks player when player in prey list", function()
    if not combat or not combat.select_npc_target then
        h.assert_truthy(false, "combat.select_npc_target not available")
        return
    end
    h.assert_truthy(wolf, "wolf not loaded")

    local player = { id = "player", _state = "alive", animate = true,
                     combat = { size = "medium" } }
    local wolf_copy = {
        id = "wolf", _state = "alive-aggressive", animate = true,
        behavior = wolf.behavior,
        combat = wolf.combat,
    }
    local combatants = { wolf_copy, player }

    local target = combat.select_npc_target(wolf_copy, combatants)
    h.assert_truthy(target, "wolf must pick a target")
    h.assert_eq("player", target.id, "wolf must target the player")
end)

---------------------------------------------------------------------------
-- TESTS: max_health not nil → morale flee works (#319)
---------------------------------------------------------------------------
suite("WOLF MORALE: max_health lookup must not be nil (#319)")

test("7. wolf has max_health at top level", function()
    h.assert_truthy(wolf, "wolf not loaded")
    h.assert_truthy(wolf.max_health, "wolf.max_health must exist")
    h.assert_eq("number", type(wolf.max_health), "max_health must be a number")
    h.assert_truthy(wolf.max_health > 0, "max_health must be positive")
end)

test("8. morale.check triggers flee when health < threshold", function()
    if not morale or not morale.check then
        h.assert_truthy(false, "morale module not available")
        return
    end
    h.assert_truthy(wolf, "wolf not loaded")

    -- Create a damaged wolf at 10% health (below flee_threshold=0.2)
    local damaged_wolf = {
        id = "wolf", _state = "alive-aggressive", animate = true,
        health = 2, max_health = wolf.max_health,
        behavior = wolf.behavior,
        combat = wolf.combat,
    }

    local mock_helpers = {
        get_location = function() return "test-room" end,
        get_valid_exits = function() return {{ target = "other-room", direction = "north" }} end,
        get_player_room_id = function() return "test-room" end,
        move_creature = function(_, creature, target)
            creature.location = target
        end,
    }

    local result = morale.check({registry = {}}, damaged_wolf, nil, mock_helpers)
    h.assert_truthy(result == "flee" or result == "cornered",
        "morale.check must return 'flee' or 'cornered' when health < threshold, got: " .. tostring(result))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
