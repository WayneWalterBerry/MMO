-- test/creatures/test-pack-tactics.lua
-- WAVE-5 TDD: Pack tactics — alpha selection, staggered attacks, single wolf
-- bypass, defensive retreat. Other agents building engine in parallel.
-- Q4 resolved: alpha = highest health wolf.
-- Must be run from repository root: lua test/creatures/test-pack-tactics.lua

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
-- Load engine modules (pcall-guarded — TDD: may not exist yet)
---------------------------------------------------------------------------
local creatures_ok, creatures = pcall(require, "engine.creatures")
if not creatures_ok then
    print("WARNING: engine.creatures not loadable — " .. tostring(creatures))
    creatures = nil
end

local pack_ok, pack_tactics = pcall(require, "engine.creatures.pack-tactics")
if not pack_ok then
    print("WARNING: engine.creatures.pack-tactics not loadable — " .. tostring(pack_tactics))
    pack_tactics = nil
end

---------------------------------------------------------------------------
-- Load wolf definition
---------------------------------------------------------------------------
local wolf_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "creatures" .. SEP .. "wolf.lua"
local ok_wolf, wolf_def = pcall(dofile, wolf_path)
if not ok_wolf then
    print("WARNING: wolf.lua not found — tests will fail (TDD: expected)")
    wolf_def = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local guid_counter = 0
local function next_guid()
    guid_counter = guid_counter + 1
    return "{test-pack-" .. guid_counter .. "}"
end

local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deep_copy(v) end
    return copy
end

local function make_wolf(overrides)
    local base = wolf_def and deep_copy(wolf_def) or {
        template = "creature",
        id = "wolf",
        name = "a grey wolf",
        animate = true,
        alive = true,
        health = 25,
        max_health = 25,
        size = "medium",
        initial_state = "alive-idle",
        _state = "alive-idle",
        behavior = {
            default = "idle",
            aggression = 70,
            flee_threshold = 20,
            territorial = true,
            territory = "hallway",
            pack_animal = true,
        },
        combat = {
            natural_weapons = {
                { type = "bite", material = "tooth-enamel", force = 8 },
            },
        },
        drives = {
            hunger = { value = 50, decay_rate = 1, max = 100, min = 0 },
            fear   = { value = 0, decay_rate = -5, max = 100, min = 0 },
        },
    }
    base.guid = next_guid()
    if overrides then
        for k, v in pairs(overrides) do base[k] = v end
    end
    return base
end

local function make_room(id, contents, exits)
    return {
        guid = "{room-" .. id .. "}",
        id = id,
        template = "room",
        name = id,
        description = "A test room.",
        contents = contents or {},
        exits = exits or {},
    }
end

local function make_mock_registry(objects)
    local reg = { _objects = {} }
    for _, obj in ipairs(objects) do
        reg._objects[obj.guid] = obj
        if obj.id then reg._objects[obj.id] = obj end
    end
    function reg:get(id) return self._objects[id] end
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
    function reg:add(obj)
        self._objects[obj.guid] = obj
        if obj.id then self._objects[obj.id] = obj end
    end
    return reg
end

local function make_context(reg, room)
    return {
        registry = reg,
        rooms = { [room.id] = room },
        current_room = room,
        player = { location = room.id, health = 50, max_health = 50, hands = { nil, nil } },
        game_time = 100,
        headless = true,
        print = function() end,
    }
end

---------------------------------------------------------------------------
-- TESTS: Pack Tactics — Alpha Selection (Q4: highest health)
---------------------------------------------------------------------------
suite("PACK TACTICS: alpha selection + coordination (WAVE-5 TDD)")

test("1. alpha selection — highest-health wolf becomes alpha", function()
    -- Q4 resolved: alpha = highest health wolf
    local pack_mod = pack_tactics or (creatures and creatures.pack_tactics)
        or (creatures and creatures._test and creatures._test.pack_tactics)
    h.assert_truthy(pack_mod, "pack tactics module must be loadable (TDD red phase)")

    local select_alpha = pack_mod.select_alpha
        or pack_mod.choose_alpha
        or pack_mod.get_alpha
    h.assert_truthy(select_alpha, "select_alpha function must exist")

    local wolf_strong = make_wolf({ health = 25, max_health = 25 })
    local wolf_weak   = make_wolf({ health = 12, max_health = 25 })
    wolf_strong.location = "hallway"
    wolf_weak.location   = "hallway"

    local room = make_room("hallway", { wolf_strong.guid, wolf_weak.guid })
    local reg  = make_mock_registry({ wolf_strong, wolf_weak, room })
    local ctx  = make_context(reg, room)

    local pack = { wolf_strong, wolf_weak }
    local alpha = select_alpha(pack, ctx)

    h.assert_truthy(alpha, "select_alpha must return a wolf")
    h.assert_eq(wolf_strong.guid, alpha.guid,
        "wolf with higher health (25) must be alpha, not the weaker wolf (12)")
end)

test("2. stagger attacks — alpha attacks first, others wait 1 turn", function()
    local pack_mod = pack_tactics or (creatures and creatures.pack_tactics)
        or (creatures and creatures._test and creatures._test.pack_tactics)
    h.assert_truthy(pack_mod, "pack tactics module must be loadable (TDD red phase)")

    local plan_attack = pack_mod.plan_attack
        or pack_mod.stagger_attacks
        or pack_mod.coordinate_attack
    h.assert_truthy(plan_attack, "plan_attack/stagger_attacks function must exist")

    local wolf_alpha = make_wolf({ health = 25 })
    local wolf_beta  = make_wolf({ health = 20 })
    wolf_alpha.location = "hallway"
    wolf_beta.location  = "hallway"

    local room = make_room("hallway", { wolf_alpha.guid, wolf_beta.guid })
    local reg  = make_mock_registry({ wolf_alpha, wolf_beta, room })
    local ctx  = make_context(reg, room)

    local pack = { wolf_alpha, wolf_beta }
    local attack_plan = plan_attack(pack, ctx)

    h.assert_truthy(attack_plan, "plan_attack must return an attack plan")
    h.assert_eq("table", type(attack_plan), "attack plan must be a table")

    -- Alpha attacks on turn 0, beta on turn 1
    local alpha_entry, beta_entry
    for _, entry in ipairs(attack_plan) do
        if entry.creature and entry.creature.guid == wolf_alpha.guid then
            alpha_entry = entry
        end
        if entry.creature and entry.creature.guid == wolf_beta.guid then
            beta_entry = entry
        end
        -- Alternative key: attacker
        if entry.attacker and entry.attacker == wolf_alpha.guid then
            alpha_entry = entry
        end
        if entry.attacker and entry.attacker == wolf_beta.guid then
            beta_entry = entry
        end
    end

    h.assert_truthy(alpha_entry, "attack plan must include alpha wolf")
    h.assert_truthy(beta_entry, "attack plan must include beta wolf")

    local alpha_delay = alpha_entry.delay or alpha_entry.turn or 0
    local beta_delay  = beta_entry.delay or beta_entry.turn or 0
    h.assert_truthy(alpha_delay < beta_delay,
        "alpha must attack before beta (alpha delay=" .. alpha_delay
        .. " beta delay=" .. beta_delay .. ")")
end)

test("3. single wolf — no pack stagger, attacks normally", function()
    local pack_mod = pack_tactics or (creatures and creatures.pack_tactics)
        or (creatures and creatures._test and creatures._test.pack_tactics)
    h.assert_truthy(pack_mod, "pack tactics module must be loadable (TDD red phase)")

    local plan_attack = pack_mod.plan_attack
        or pack_mod.stagger_attacks
        or pack_mod.coordinate_attack
    h.assert_truthy(plan_attack, "plan_attack function must exist")

    local lone_wolf = make_wolf({ health = 25 })
    lone_wolf.location = "hallway"

    local room = make_room("hallway", { lone_wolf.guid })
    local reg  = make_mock_registry({ lone_wolf, room })
    local ctx  = make_context(reg, room)

    local pack = { lone_wolf }
    local attack_plan = plan_attack(pack, ctx)

    h.assert_truthy(attack_plan, "plan_attack must return plan even for lone wolf")

    -- Lone wolf should attack immediately (delay 0) with no stagger
    local entry = attack_plan[1]
    h.assert_truthy(entry, "attack plan must have at least one entry")
    local delay = entry.delay or entry.turn or 0
    h.assert_eq(0, delay,
        "lone wolf attacks immediately (no stagger), got delay=" .. delay)
end)

test("4. defensive retreat — wolf at <20% health attempts to flee", function()
    local pack_mod = pack_tactics or (creatures and creatures.pack_tactics)
        or (creatures and creatures._test and creatures._test.pack_tactics)
    h.assert_truthy(pack_mod, "pack tactics module must be loadable (TDD red phase)")

    local should_retreat = pack_mod.should_retreat
        or pack_mod.check_retreat
        or pack_mod.evaluate_retreat
    h.assert_truthy(should_retreat, "should_retreat/check_retreat function must exist")

    -- Wolf at 4/25 health = 16% → below 20% threshold → should retreat
    local wounded_wolf = make_wolf({ health = 4, max_health = 25 })
    wounded_wolf.location = "hallway"

    local room = make_room("hallway", { wounded_wolf.guid },
        { north = { target = "cellar" } })
    local reg  = make_mock_registry({ wounded_wolf, room })
    local ctx  = make_context(reg, room)

    local retreat = should_retreat(wounded_wolf, ctx)
    h.assert_truthy(retreat,
        "wolf at 16% health (4/25) must attempt retreat (threshold <20%)")

    -- Wolf at 20/25 = 80% → healthy, should NOT retreat
    local healthy_wolf = make_wolf({ health = 20, max_health = 25 })
    healthy_wolf.location = "hallway"
    local reg2 = make_mock_registry({ healthy_wolf, room })
    local ctx2 = make_context(reg2, room)

    local no_retreat = should_retreat(healthy_wolf, ctx2)
    h.assert_truthy(not no_retreat,
        "wolf at 80% health (20/25) must NOT retreat")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
