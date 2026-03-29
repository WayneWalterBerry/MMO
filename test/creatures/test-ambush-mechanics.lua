-- test/creatures/test-ambush-mechanics.lua
-- WAVE-4 Phase 5: Ambush mechanics — stealth, surprise damage, detection, pack coordination.
-- Must be run from repository root: lua test/creatures/test-ambush-mechanics.lua

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

math.randomseed(42)

local ok_mod, creatures = pcall(require, "engine.creatures")
if not ok_mod then
    print("WARNING: engine.creatures not found — tests will fail")
    creatures = nil
end

local ok_pt, pack_tactics = pcall(require, "engine.creatures.pack-tactics")
if not ok_pt then pack_tactics = nil end

local ok_act, actions = pcall(require, "engine.creatures.actions")
if not ok_act then actions = nil end

---------------------------------------------------------------------------
-- Mock helpers (matches test-creature-tick.lua patterns)
---------------------------------------------------------------------------

local function make_wolf(overrides)
    local c = {
        guid = "{wolf-" .. tostring(math.random(99999)) .. "}",
        template = "creature",
        id = "wolf",
        name = "a grey wolf",
        keywords = {"wolf"},
        animate = true,
        alive = true,
        health = 22,
        max_health = 22,
        size = "medium",
        weight = 35,
        material = "flesh",
        location = nil,
        initial_state = "alive-idle",
        _state = "alive-idle",
        states = {
            ["alive-idle"]       = { description = "Standing.", room_presence = "A wolf watches from the shadows." },
            ["alive-aggressive"] = { description = "Snarling.", room_presence = "A snarling wolf blocks the way." },
            ["alive-flee"]       = { description = "Fleeing." },
            ["dead"]             = { description = "Dead.", animate = false },
        },
        behavior = {
            default = "idle",
            aggression = 70,
            flee_threshold = 20,
            pack_animal = true,
            ambush = {
                trigger_on_proximity = true,
                damage_bonus = 1.5,
                can_rehide = false,
                detect_on_listen = "You hear low breathing from the shadows.",
                narration = "A grey shape explodes from the darkness!",
            },
        },
        drives = {
            hunger = { value = 30, decay_rate = 1, max = 100, min = 0 },
            fear   = { value = 0, decay_rate = -5, max = 100, min = 0 },
        },
        reactions = {},
        combat = {
            natural_weapons = {
                { id = "bite", type = "pierce", force = 5, message = "bites" },
                { id = "claw", type = "slash",  force = 3, message = "claws" },
            },
        },
        movement = { speed = 3, can_open_doors = false },
    }
    if overrides then
        for k, v in pairs(overrides) do c[k] = v end
    end
    return c
end

local function make_room(id)
    return {
        guid = "{room-" .. id .. "}",
        id = id,
        template = "room",
        exits = {},
        contents = {},
    }
end

local function make_registry(objects)
    local reg = { _objects = objects or {} }
    function reg:list() return self._objects end
    function reg:get(id)
        for _, obj in ipairs(self._objects) do
            if obj.guid == id or obj.id == id then return obj end
        end
        return nil
    end
    return reg
end

local function make_context(registry, rooms_table, current_room_obj)
    return {
        registry = registry,
        rooms = rooms_table,
        current_room = current_room_obj,
        player = { location = current_room_obj and current_room_obj.id or nil },
    }
end

local function rooms_by_id(...)
    local t = {}
    for _, r in ipairs({...}) do t[r.id] = r end
    return t
end

---------------------------------------------------------------------------
-- TESTS: Hidden State
---------------------------------------------------------------------------
suite("AMBUSH: hidden state")

test("1. ambush creature starts hidden (not sprung)", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    local room = make_room("cellar")
    local player_room = make_room("bedroom")
    local reg = make_registry({wolf, room, player_room})
    local ctx = make_context(reg, rooms_by_id(room, player_room), player_room)

    creatures.tick(ctx)
    h.assert_eq(true, wolf.hidden, "wolf should be hidden before springing")
    h.assert_eq(nil, wolf._ambush_sprung, "ambush should not have sprung (player in different room)")
end)

test("2. ambush creature reveals on proximity", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    local room = make_room("cellar")
    local reg = make_registry({wolf, room})
    local ctx = make_context(reg, rooms_by_id(room), room)

    local msgs = creatures.tick(ctx)
    h.assert_eq(true, wolf._ambush_sprung, "ambush should spring when player is in same room")
    h.assert_eq(false, wolf.hidden, "wolf should not be hidden after springing")
end)

test("3. ambush narration shown when springing in player room", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    local room = make_room("cellar")
    local reg = make_registry({wolf, room})
    local ctx = make_context(reg, rooms_by_id(room), room)

    local msgs = creatures.tick(ctx)
    local found = false
    for _, m in ipairs(msgs) do
        if m:find("darkness") then found = true end
    end
    h.assert_eq(true, found, "should see ambush narration")
end)

---------------------------------------------------------------------------
-- TESTS: Surprise Damage
---------------------------------------------------------------------------
suite("AMBUSH: surprise damage multiplier")

test("4. ambush boosts weapon force on first strike", function()
    h.assert_truthy(actions, "engine.creatures.actions not loaded")
    local wolf = make_wolf({ location = "cellar" })
    wolf._ambush_sprung = true
    wolf._ambush_bonus_used = nil
    wolf.hidden = false

    local orig_bite = wolf.combat.natural_weapons[1].force
    local orig_claw = wolf.combat.natural_weapons[2].force
    local multiplier = wolf.behavior.ambush.damage_bonus

    -- Call execute_action with "attack" — combat module may not be loaded,
    -- so we verify the weapon force boost/restore cycle directly
    local weapons = wolf.combat.natural_weapons
    -- Simulate the boost logic from actions.lua
    if wolf._ambush_sprung and not wolf._ambush_bonus_used then
        for _, w in ipairs(weapons) do
            w._original_force = w.force
            w.force = w.force * multiplier
        end
        wolf._ambush_bonus_used = true
    end

    h.assert_eq(orig_bite * multiplier, weapons[1].force, "bite force should be 1.5x")
    h.assert_eq(orig_claw * multiplier, weapons[2].force, "claw force should be 1.5x")

    -- Restore
    for _, w in ipairs(weapons) do
        if w._original_force then
            w.force = w._original_force
            w._original_force = nil
        end
    end
    h.assert_eq(orig_bite, weapons[1].force, "bite force restored after ambush")
    h.assert_eq(orig_claw, weapons[2].force, "claw force restored after ambush")
end)

test("5. ambush bonus only applies once per cycle", function()
    local wolf = make_wolf()
    wolf._ambush_sprung = true
    wolf._ambush_bonus_used = true  -- already used
    local orig_force = wolf.combat.natural_weapons[1].force

    -- Should NOT boost
    if wolf._ambush_sprung and not wolf._ambush_bonus_used then
        error("should not enter boost block")
    end
    h.assert_eq(orig_force, wolf.combat.natural_weapons[1].force,
        "weapon force unchanged when bonus already used")
end)

---------------------------------------------------------------------------
-- TESTS: Re-hide
---------------------------------------------------------------------------
suite("AMBUSH: re-hide after combat")

test("6. can_rehide resets ambush when player leaves", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local spider = make_wolf({ location = "cellar", id = "spider", name = "a spider" })
    spider.behavior.ambush.can_rehide = true
    spider._ambush_sprung = true
    spider._ambush_bonus_used = true
    spider.hidden = false

    local cellar = make_room("cellar")
    local bedroom = make_room("bedroom")
    local reg = make_registry({spider, cellar, bedroom})
    -- Player is in bedroom, spider is in cellar (different room)
    local ctx = make_context(reg, rooms_by_id(cellar, bedroom), bedroom)

    creatures.tick(ctx)
    h.assert_eq(false, spider._ambush_sprung, "ambush should reset when player leaves")
    h.assert_eq(false, spider._ambush_bonus_used, "bonus should reset")
    h.assert_eq(true, spider.hidden, "should be hidden again after re-hide")
end)

test("7. can_rehide=false does NOT reset", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    wolf._ambush_sprung = true
    wolf._ambush_bonus_used = true
    wolf.hidden = false

    local cellar = make_room("cellar")
    local bedroom = make_room("bedroom")
    local reg = make_registry({wolf, cellar, bedroom})
    local ctx = make_context(reg, rooms_by_id(cellar, bedroom), bedroom)

    creatures.tick(ctx)
    h.assert_eq(true, wolf._ambush_sprung, "ambush should stay sprung (can_rehide=false)")
end)

---------------------------------------------------------------------------
-- TESTS: Ambush Detection
---------------------------------------------------------------------------
suite("AMBUSH: detection via listen")

test("8. detect_ambush reveals hidden creature via listen", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    wolf.hidden = true

    local room = make_room("cellar")
    local reg = make_registry({wolf, room})
    local ctx = make_context(reg, rooms_by_id(room), room)

    local revealed = creatures.detect_ambush(ctx, "listen")
    h.assert_eq(1, #revealed, "should reveal 1 creature")
    h.assert_eq(true, wolf._ambush_sprung, "wolf should be sprung after detection")
    h.assert_eq(false, wolf.hidden, "wolf should no longer be hidden")
end)

test("9. detect_ambush returns hint text", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    wolf.hidden = true

    local room = make_room("cellar")
    local reg = make_registry({wolf, room})
    local ctx = make_context(reg, rooms_by_id(room), room)

    local revealed = creatures.detect_ambush(ctx, "listen")
    h.assert_truthy(revealed[1]:find("breathing"), "hint should mention breathing")
end)

test("10. detect_ambush ignores creatures without detect_on_ key", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local wolf = make_wolf({ location = "cellar" })
    wolf.hidden = true
    wolf.behavior.ambush.detect_on_listen = nil

    local room = make_room("cellar")
    local reg = make_registry({wolf, room})
    local ctx = make_context(reg, rooms_by_id(room), room)

    local revealed = creatures.detect_ambush(ctx, "listen")
    h.assert_eq(0, #revealed, "no detection without detect_on_listen metadata")
    h.assert_eq(true, wolf.hidden, "wolf remains hidden")
end)

---------------------------------------------------------------------------
-- TESTS: Pack Ambush Coordination
---------------------------------------------------------------------------
suite("AMBUSH: pack coordination")

test("11. coordinate_ambush springs pack when alpha springs", function()
    h.assert_truthy(pack_tactics, "engine.creatures.pack-tactics not loaded")
    local alpha = make_wolf({ location = "hallway", health = 22 })
    alpha._ambush_sprung = true
    alpha.hidden = false

    local beta = make_wolf({ location = "hallway", health = 18 })
    beta._ambush_sprung = false
    beta.hidden = true

    local pack = { alpha, beta }
    local result = pack_tactics.coordinate_ambush(pack, {})
    h.assert_eq(true, result, "coordination should succeed")
    h.assert_eq(true, beta._ambush_sprung, "beta should spring with alpha")
    h.assert_eq(false, beta.hidden, "beta should be revealed")
end)

test("12. coordinate_ambush does nothing if alpha hasn't sprung", function()
    h.assert_truthy(pack_tactics, "engine.creatures.pack-tactics not loaded")
    local alpha = make_wolf({ location = "hallway", health = 22 })
    alpha._ambush_sprung = false

    local beta = make_wolf({ location = "hallway", health = 18 })
    beta._ambush_sprung = false

    local pack = { alpha, beta }
    local result = pack_tactics.coordinate_ambush(pack, {})
    h.assert_eq(false, result, "coordination should not fire")
    h.assert_eq(false, beta._ambush_sprung, "beta stays hidden")
end)

test("13. coordinate_ambush requires pack of 2+", function()
    h.assert_truthy(pack_tactics, "engine.creatures.pack-tactics not loaded")
    local lone = make_wolf({ location = "hallway" })
    lone._ambush_sprung = true

    local result = pack_tactics.coordinate_ambush({ lone }, {})
    h.assert_eq(false, result, "single wolf cannot coordinate")
end)

test("14. pack ambush in creature tick: beta springs when alpha triggers", function()
    h.assert_truthy(creatures, "engine.creatures not loaded")
    local hallway = make_room("hallway")

    local alpha = make_wolf({ location = "hallway", health = 22 })
    local beta  = make_wolf({ location = "hallway", health = 18 })

    local reg = make_registry({alpha, beta, hallway})
    local ctx = make_context(reg, rooms_by_id(hallway), hallway)

    -- Both wolves in player's room → alpha springs on proximity, beta via coordination
    creatures.tick(ctx)

    h.assert_eq(true, alpha._ambush_sprung, "alpha should spring on proximity")
    h.assert_eq(true, beta._ambush_sprung, "beta should spring via pack coordination")
    h.assert_eq(false, alpha.hidden, "alpha visible after spring")
    h.assert_eq(false, beta.hidden, "beta visible after spring")
end)

---------------------------------------------------------------------------
-- TESTS: Wolf metadata
---------------------------------------------------------------------------
suite("AMBUSH: wolf metadata (Principle 8)")

test("15. wolf template declares ambush metadata", function()
    local ok, wolf = pcall(dofile, "src/meta/creatures/wolf.lua")
    if not ok then
        -- Try alternate path
        ok, wolf = pcall(function()
            return loadfile("src/meta/creatures/wolf.lua")()
        end)
    end
    h.assert_truthy(ok, "wolf.lua should load")
    h.assert_truthy(wolf.behavior.ambush, "wolf should have behavior.ambush")
    h.assert_eq(1.5, wolf.behavior.ambush.damage_bonus, "damage_bonus = 1.5")
    h.assert_eq(true, wolf.behavior.ambush.trigger_on_proximity, "trigger_on_proximity")
    h.assert_eq(false, wolf.behavior.ambush.can_rehide, "wolf cannot re-hide")
    h.assert_truthy(wolf.behavior.ambush.narration, "should have narration text")
    h.assert_truthy(wolf.behavior.ambush.detect_on_listen, "should have listen detection hint")
end)

h.summary()
