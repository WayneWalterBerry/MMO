-- test/armor/test-ceramic-degradation.lua
-- TDD tests for Issue #155: ceramic pot never cracks after 8+ self-hits while worn.
--
-- Root cause: covers_location() only checks item.covers, but real wearable
-- objects use wear.slot / wear_slot instead. The armor interceptor never
-- matches worn items → never runs check_degradation.
--
-- These tests validate:
--   1. covers_location fallback to wear.slot / wear_slot
--   2. Ceramic pot degrades (intact → cracked → shattered) when hit
--   3. Cracked ceramic provides reduced protection
--   4. Shattered ceramic provides zero protection
--   5. Hit verb triggers armor degradation on worn items
--
-- Usage: lua test/armor/test-ceramic-degradation.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------
local h         = require("test-helpers")
local test      = h.test
local suite     = h.suite
local effects   = require("engine.effects")
local injuries  = require("engine.injuries")
local materials = require("engine.materials")
local armor_ok, armor = pcall(require, "engine.armor")

---------------------------------------------------------------------------
-- Injury definition for testing
---------------------------------------------------------------------------
local test_injury_def = {
    id = "test-bruise",
    name = "Test Bruise",
    category = "impact",
    damage_type = "instant",
    initial_state = "active",
    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "",
    },
    states = {
        active = {
            name = "bruise",
            symptom = "A painful bruise.",
            description = "Bruised.",
            damage_per_tick = 0,
        },
        healed = {
            name = "healed bruise",
            description = "The bruise has faded.",
            terminal = true,
        },
    },
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function suppress_print(fn)
    local old_print = _G.print
    _G.print = function() end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
end

local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        state = {},
    }
end

--- Make a ceramic pot item matching chamber-pot.lua's actual structure.
-- NO explicit covers field — uses wear.slot like real objects.
local function make_ceramic_pot(overrides)
    local item = {
        id         = "chamber-pot",
        name       = "a ceramic chamber pot",
        material   = "ceramic",
        wear_slot  = "head",
        is_helmet  = true,
        _state     = "intact",
        wear = {
            slot     = "head",
            layer    = "outer",
            coverage = 0.8,
            fit      = "makeshift",
        },
    }
    if overrides then
        for k, v in pairs(overrides) do item[k] = v end
    end
    return item
end

local function make_effect(overrides)
    local eff = {
        type        = "inflict_injury",
        injury_type = "test-bruise",
        source      = "self-inflicted",
        location    = "head",
        damage      = 10,
        damage_type = "blunt",
    }
    if overrides then
        for k, v in pairs(overrides) do eff[k] = v end
    end
    return eff
end

local function setup()
    injuries.clear_cache()
    injuries.reset_id_counter()
    injuries.register_definition("test-bruise", test_injury_def)
    effects.clear_interceptors()
    if armor_ok and armor and armor.register then
        armor.register(effects)
    end
end

local function process_effect(player, effect_override)
    local eff = make_effect(effect_override)
    local ctx = { player = player, source_id = eff.source }
    suppress_print(function()
        effects.process(eff, ctx)
    end)
    return player, ctx
end

local function get_injury_damage(player)
    if not player.injuries or #player.injuries == 0 then return nil end
    return player.injuries[1].damage
end

---------------------------------------------------------------------------
-- Suite 1: covers_location fallback to wear.slot
---------------------------------------------------------------------------
suite("#155 — Armor intercepts items using wear.slot (no explicit covers)")

test("ceramic pot (wear.slot=head) reduces head damage", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }
    process_effect(player, { damage = 10, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg, "injury must be inflicted")
    h.assert_truthy(dmg < 10,
        "ceramic pot with wear.slot=head should reduce head damage, got " .. tostring(dmg))
end)

test("ceramic pot does NOT reduce torso damage (only covers head)", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }
    process_effect(player, { damage = 10, location = "torso" })
    local dmg = get_injury_damage(player)
    h.assert_eq(10, dmg, "head armor should not reduce torso damage")
end)

test("item with wear = { slot = 'head' } (no wear_slot) still intercepts head", function()
    setup()
    local player = fresh_player()
    -- Item only has wear.slot, not top-level wear_slot
    local item = {
        id = "test-hat", name = "hat", material = "leather",
        _state = "intact",
        wear = { slot = "head", fit = "fitted" },
    }
    player.worn = { item }
    process_effect(player, { damage = 10, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg < 10,
        "item with only wear.slot should intercept head hits, got " .. tostring(dmg))
end)

---------------------------------------------------------------------------
-- Suite 2: Ceramic degradation — intact → cracked → shattered
---------------------------------------------------------------------------
suite("#155 — Ceramic pot degrades through FSM states")

test("ceramic pot cracks after absorbing hit (deterministic)", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }

    -- Force math.random to always return 0.0 (below any threshold)
    local old_random = math.random
    math.random = function() return 0.0 end
    process_effect(player, { damage = 10, location = "head", damage_type = "blunt" })
    math.random = old_random

    h.assert_eq("cracked", pot._state,
        "ceramic pot (fragility 0.7) should crack on deterministic hit, got: " .. tostring(pot._state))
end)

test("cracked ceramic pot shatters on next deterministic hit", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot({ _state = "cracked" })
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    process_effect(player, { damage = 10, location = "head", damage_type = "blunt" })
    math.random = old_random

    h.assert_eq("shattered", pot._state,
        "cracked ceramic pot should shatter on deterministic hit")
end)

test("ceramic pot eventually cracks after repeated hits (probabilistic)", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }

    -- With fragility 0.7 and damage 10, blunt factor 1.5:
    -- break_chance = 0.7 * (10/20) * 1.5 = 0.525 per hit
    -- After 20 hits, P(never crack) = (1-0.525)^20 ≈ 0.00000085
    -- Practically guaranteed to crack.
    for i = 1, 20 do
        if pot._state ~= "intact" then break end
        setup()
        if armor_ok and armor and armor.register then
            effects.clear_interceptors()
            armor.register(effects)
        end
        process_effect(player, { damage = 10, location = "head", damage_type = "blunt" })
    end

    h.assert_truthy(pot._state ~= "intact",
        "ceramic pot should crack after 20 blunt hits (fragility 0.7)")
end)

---------------------------------------------------------------------------
-- Suite 3: Protection reduces with degradation state
---------------------------------------------------------------------------
suite("#155 — Degraded armor provides less protection")

test("cracked ceramic provides less protection than intact", function()
    -- Intact pot
    setup()
    local player1 = fresh_player()
    player1.worn = { make_ceramic_pot({ _state = "intact" }) }
    -- Suppress degradation by mocking random high
    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player1, { damage = 20, location = "head" })
    math.random = old_random
    local intact_dmg = get_injury_damage(player1)

    -- Cracked pot
    setup()
    local player2 = fresh_player()
    math.random = function() return 1.0 end
    player2.worn = { make_ceramic_pot({ _state = "cracked" }) }
    process_effect(player2, { damage = 20, location = "head" })
    math.random = old_random
    local cracked_dmg = get_injury_damage(player2)

    h.assert_truthy(intact_dmg and cracked_dmg, "both must inflict injuries")
    h.assert_truthy(cracked_dmg > intact_dmg,
        "cracked pot should let more damage through than intact"
        .. " — intact_dmg=" .. tostring(intact_dmg) .. " cracked_dmg=" .. tostring(cracked_dmg))
end)

test("shattered ceramic provides zero protection", function()
    setup()
    local player = fresh_player()
    player.worn = { make_ceramic_pot({ _state = "shattered" }) }
    process_effect(player, { damage = 10, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_eq(10, dmg,
        "shattered ceramic should provide zero protection, got " .. tostring(dmg))
end)

---------------------------------------------------------------------------
-- Suite 4: degrade_covering_armor API (exported for hit verb)
---------------------------------------------------------------------------
suite("#155 — armor.degrade_covering_armor API")

test("degrade_covering_armor function exists", function()
    h.assert_truthy(armor_ok, "armor module must load")
    h.assert_truthy(armor.degrade_covering_armor,
        "armor.degrade_covering_armor must be exported")
end)

test("degrade_covering_armor cracks ceramic pot (deterministic)", function()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    suppress_print(function()
        armor.degrade_covering_armor(player, "head", 10, "blunt")
    end)
    math.random = old_random

    h.assert_eq("cracked", pot._state,
        "degrade_covering_armor should crack ceramic pot")
end)

test("degrade_covering_armor ignores non-covering armor", function()
    local player = fresh_player()
    local pot = make_ceramic_pot()  -- covers head
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    suppress_print(function()
        armor.degrade_covering_armor(player, "torso", 10, "blunt")
    end)
    math.random = old_random

    h.assert_eq("intact", pot._state,
        "head armor should not degrade from torso hits")
end)

---------------------------------------------------------------------------
-- Done
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
