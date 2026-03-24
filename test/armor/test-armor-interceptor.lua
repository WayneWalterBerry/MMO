-- test/armor/test-armor-interceptor.lua
-- TDD regression tests for the armor interceptor system (Phase A3).
-- These tests define the CONTRACT for the armor system.
-- They should FAIL today (armor not implemented) and PASS once built.
--
-- Covers:
--   1. Baseline — no armor = full damage
--   2. Basic protection — wearing armor reduces injury damage
--   3. Material differences — iron > leather > wool
--   4. Location targeting — head armor only protects head, not torso
--   5. Material degradation — ceramic cracks, shattered = zero protection
--   6. Layer stacking — inner + outer layers both contribute
--   7. Fit quality — makeshift < fitted < masterwork
--   8. Edge cases — minimum damage floor, missing material, etc.
--
-- Usage: lua test/armor/test-armor-interceptor.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

---------------------------------------------------------------------------
-- Load real modules
---------------------------------------------------------------------------
local h       = require("test-helpers")
local effects = require("engine.effects")
local injuries = require("engine.injuries")
local materials = require("engine.materials")

-- Try to load the armor module (will fail until implementation exists)
local armor_ok, armor = pcall(require, "engine.armor")

---------------------------------------------------------------------------
-- Test injury definition (simple bruise for controlled damage testing)
---------------------------------------------------------------------------
local test_injury_def = {
    id = "test-bruise",
    name = "Test Bruise",
    category = "impact",
    damage_type = "instant",
    initial_state = "active",
    on_inflict = {
        initial_damage = 0,  -- we override via effect.damage
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

local function make_armor(overrides)
    local item = {
        id       = "test-armor",
        name     = "test armor",
        material = "iron",
        covers   = { "head" },
        fit      = "fitted",
        _state   = "intact",
        layer    = "outer",
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
        source      = "test-source",
        location    = "head",
        damage      = 10,
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
    -- Register armor interceptor if available
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
-- Suite 1: Baseline — No Armor (validates test infrastructure)
---------------------------------------------------------------------------
h.suite("Baseline — No Armor = Full Damage")

h.test("no armor: full damage passes through", function()
    setup()
    local player = fresh_player()
    player.worn = {}  -- explicitly no armor
    process_effect(player, { damage = 10, location = "head" })
    h.assert_eq(10, get_injury_damage(player),
        "injury damage should equal effect damage when no armor worn")
end)

h.test("no armor: injury is created with correct type", function()
    setup()
    local player = fresh_player()
    player.worn = {}
    process_effect(player, { damage = 15, location = "torso" })
    h.assert_eq("test-bruise", player.injuries[1].type,
        "injury type should match effect")
end)

h.test("no armor: health decreases by full damage amount", function()
    setup()
    local player = fresh_player()
    player.worn = {}
    process_effect(player, { damage = 20, location = "head" })
    local health = injuries.compute_health(player)
    h.assert_eq(80, health, "health should be max - full damage")
end)

---------------------------------------------------------------------------
-- Suite 2: Basic Protection — Armor Reduces Damage
---------------------------------------------------------------------------
h.suite("Basic Protection — Armor Reduces Damage")

h.test("iron helmet reduces head injury damage", function()
    setup()
    local player = fresh_player()
    local helmet = make_armor({
        id = "iron-helmet", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    })
    player.worn = { helmet }
    process_effect(player, { damage = 10, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg, "injury should still be inflicted")
    h.assert_truthy(dmg < 10,
        "iron helmet should reduce damage below 10, got " .. tostring(dmg))
end)

h.test("leather vest reduces torso injury damage", function()
    setup()
    local player = fresh_player()
    local vest = make_armor({
        id = "leather-vest", material = "leather",
        covers = { "torso" }, fit = "fitted", _state = "intact",
    })
    player.worn = { vest }
    process_effect(player, { damage = 10, location = "torso" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg, "injury should still be inflicted")
    h.assert_truthy(dmg < 10,
        "leather vest should reduce damage below 10, got " .. tostring(dmg))
end)

h.test("armor reduces damage but injury still occurs", function()
    setup()
    local player = fresh_player()
    local helmet = make_armor({
        id = "steel-helm", material = "steel",
        covers = { "head" }, fit = "fitted", _state = "intact",
    })
    player.worn = { helmet }
    process_effect(player, { damage = 10, location = "head" })
    h.assert_eq(1, #player.injuries, "injury should still be created")
end)

---------------------------------------------------------------------------
-- Suite 3: Material Differences
---------------------------------------------------------------------------
h.suite("Material Differences — Different Materials, Different Protection")

h.test("iron protects more than leather", function()
    setup()
    -- Iron: hardness 8
    local player_iron = fresh_player()
    player_iron.worn = { make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player_iron, { damage = 20, location = "head" })
    local iron_dmg = get_injury_damage(player_iron)

    -- Leather: hardness 3
    setup()
    local player_leather = fresh_player()
    player_leather.worn = { make_armor({
        id = "leather-cap", material = "leather",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player_leather, { damage = 20, location = "head" })
    local leather_dmg = get_injury_damage(player_leather)

    h.assert_truthy(iron_dmg and leather_dmg,
        "both should inflict injuries")
    h.assert_truthy(iron_dmg < leather_dmg,
        "iron (hardness 8) should absorb more than leather (hardness 3)"
        .. " — iron_dmg=" .. tostring(iron_dmg)
        .. " leather_dmg=" .. tostring(leather_dmg))
end)

h.test("steel protects more than wool", function()
    setup()
    -- Steel: hardness 9
    local player_steel = fresh_player()
    player_steel.worn = { make_armor({
        id = "steel-helm", material = "steel",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player_steel, { damage = 20, location = "head" })
    local steel_dmg = get_injury_damage(player_steel)

    -- Wool: hardness 1
    setup()
    local player_wool = fresh_player()
    player_wool.worn = { make_armor({
        id = "wool-cap", material = "wool",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player_wool, { damage = 20, location = "head" })
    local wool_dmg = get_injury_damage(player_wool)

    h.assert_truthy(steel_dmg and wool_dmg,
        "both should inflict injuries")
    h.assert_truthy(steel_dmg < wool_dmg,
        "steel (hardness 9) should absorb more than wool (hardness 1)"
        .. " — steel_dmg=" .. tostring(steel_dmg)
        .. " wool_dmg=" .. tostring(wool_dmg))
end)

h.test("wool still provides some protection vs no armor", function()
    setup()
    local player_wool = fresh_player()
    player_wool.worn = { make_armor({
        id = "wool-cap", material = "wool",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player_wool, { damage = 20, location = "head" })
    local wool_dmg = get_injury_damage(player_wool)

    setup()
    local player_bare = fresh_player()
    player_bare.worn = {}
    process_effect(player_bare, { damage = 20, location = "head" })
    local bare_dmg = get_injury_damage(player_bare)

    h.assert_truthy(wool_dmg < bare_dmg,
        "even wool should reduce damage vs bare skin"
        .. " — wool=" .. tostring(wool_dmg) .. " bare=" .. tostring(bare_dmg))
end)

---------------------------------------------------------------------------
-- Suite 4: Location Targeting
---------------------------------------------------------------------------
h.suite("Location Targeting — Armor Only Protects Covered Areas")

h.test("head armor does NOT protect against torso injuries", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "iron-helmet", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "torso" })
    h.assert_eq(10, get_injury_damage(player),
        "head armor should not reduce torso damage")
end)

h.test("torso armor does NOT protect against head injuries", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "iron-vest", material = "iron",
        covers = { "torso" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "head" })
    h.assert_eq(10, get_injury_damage(player),
        "torso armor should not reduce head damage")
end)

h.test("head armor protects head injuries", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "iron-helmet", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg < 10,
        "head armor should reduce head damage, got " .. tostring(dmg))
end)

h.test("torso armor protects torso injuries", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "iron-vest", material = "iron",
        covers = { "torso" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "torso" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg < 10,
        "torso armor should reduce torso damage, got " .. tostring(dmg))
end)

h.test("armor covering multiple locations protects both", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "full-mail", material = "iron",
        covers = { "head", "torso" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "head" })
    local head_dmg = get_injury_damage(player)

    setup()
    local player2 = fresh_player()
    player2.worn = { make_armor({
        id = "full-mail", material = "iron",
        covers = { "head", "torso" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player2, { damage = 10, location = "torso" })
    local torso_dmg = get_injury_damage(player2)

    h.assert_truthy(head_dmg < 10,
        "full mail should protect head, got " .. tostring(head_dmg))
    h.assert_truthy(torso_dmg < 10,
        "full mail should protect torso, got " .. tostring(torso_dmg))
end)

---------------------------------------------------------------------------
-- Suite 5: Material Degradation
---------------------------------------------------------------------------
h.suite("Material Degradation — Armor Wears Out")

h.test("ceramic armor cracks after absorbing a hit", function()
    setup()
    local player = fresh_player()
    local pot = make_armor({
        id = "ceramic-pot", material = "ceramic",
        covers = { "head" }, fit = "makeshift", _state = "intact",
    })
    player.worn = { pot }

    -- Ceramic has fragility 0.7 — high-damage hit should crack it
    -- Mock math.random so degradation is deterministic
    local old_random = math.random
    math.random = function() return 0.0 end  -- always below fragility threshold
    process_effect(player, { damage = 15, location = "head" })
    math.random = old_random

    h.assert_eq("cracked", pot._state,
        "ceramic armor should crack after absorbing a heavy hit")
end)

h.test("cracked armor still provides some protection", function()
    setup()
    local player = fresh_player()
    local pot = make_armor({
        id = "ceramic-pot", material = "ceramic",
        covers = { "head" }, fit = "fitted", _state = "cracked",
    })
    player.worn = { pot }
    process_effect(player, { damage = 10, location = "head" })
    local cracked_dmg = get_injury_damage(player)

    -- Compare to intact
    setup()
    local player2 = fresh_player()
    local pot2 = make_armor({
        id = "ceramic-pot2", material = "ceramic",
        covers = { "head" }, fit = "fitted", _state = "intact",
    })
    player2.worn = { pot2 }

    -- Force no degradation for this comparison
    local old_random = math.random
    math.random = function() return 1.0 end  -- always above threshold
    process_effect(player2, { damage = 10, location = "head" })
    math.random = old_random

    local intact_dmg = get_injury_damage(player2)

    h.assert_truthy(cracked_dmg and intact_dmg,
        "both should inflict injuries")
    h.assert_truthy(cracked_dmg > intact_dmg,
        "cracked armor should protect less than intact"
        .. " — cracked=" .. tostring(cracked_dmg)
        .. " intact=" .. tostring(intact_dmg))
end)

h.test("shattered armor provides zero protection", function()
    setup()
    local player = fresh_player()
    local pot = make_armor({
        id = "ceramic-pot", material = "ceramic",
        covers = { "head" }, fit = "fitted", _state = "shattered",
    })
    player.worn = { pot }
    process_effect(player, { damage = 10, location = "head" })
    h.assert_eq(10, get_injury_damage(player),
        "shattered armor should provide zero protection — full damage")
end)

h.test("iron armor resists degradation (low fragility)", function()
    setup()
    local player = fresh_player()
    local helm = make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    })
    player.worn = { helm }

    -- Iron has fragility 0.1 — moderate hit should NOT crack it
    local old_random = math.random
    math.random = function() return 0.5 end  -- above iron's fragility threshold
    process_effect(player, { damage = 10, location = "head" })
    math.random = old_random

    h.assert_eq("intact", helm._state,
        "iron armor should resist degradation on moderate hits")
end)

---------------------------------------------------------------------------
-- Suite 6: Layer Stacking
---------------------------------------------------------------------------
h.suite("Layer Stacking — Inner + Outer Both Contribute")

h.test("two layers reduce damage more than one", function()
    setup()
    -- Single layer
    local player_single = fresh_player()
    player_single.worn = { make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
        layer = "outer",
    }) }

    -- Force no degradation
    local old_random = math.random
    math.random = function() return 1.0 end

    process_effect(player_single, { damage = 20, location = "head" })
    local single_dmg = get_injury_damage(player_single)

    -- Double layer
    setup()
    local player_double = fresh_player()
    player_double.worn = {
        make_armor({
            id = "wool-coif", material = "wool",
            covers = { "head" }, fit = "fitted", _state = "intact",
            layer = "inner",
        }),
        make_armor({
            id = "iron-helm", material = "iron",
            covers = { "head" }, fit = "fitted", _state = "intact",
            layer = "outer",
        }),
    }
    process_effect(player_double, { damage = 20, location = "head" })
    local double_dmg = get_injury_damage(player_double)

    math.random = old_random

    h.assert_truthy(single_dmg and double_dmg,
        "both should inflict injuries")
    h.assert_truthy(double_dmg < single_dmg,
        "two layers should reduce more than one"
        .. " — double=" .. tostring(double_dmg)
        .. " single=" .. tostring(single_dmg))
end)

h.test("inner layer alone still provides protection", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "wool-coif", material = "wool",
        covers = { "head" }, fit = "fitted", _state = "intact",
        layer = "inner",
    }) }
    process_effect(player, { damage = 15, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg < 15,
        "inner layer alone should still reduce damage, got " .. tostring(dmg))
end)

h.test("stacking only applies to matching location", function()
    setup()
    local player = fresh_player()
    player.worn = {
        make_armor({
            id = "wool-coif", material = "wool",
            covers = { "head" }, fit = "fitted", _state = "intact",
            layer = "inner",
        }),
        make_armor({
            id = "iron-vest", material = "iron",
            covers = { "torso" }, fit = "fitted", _state = "intact",
            layer = "outer",
        }),
    }
    process_effect(player, { damage = 10, location = "head" })
    local head_dmg = get_injury_damage(player)

    -- Only wool coif covers head — iron vest should not help
    -- Compare to wool coif alone
    setup()
    local player2 = fresh_player()
    player2.worn = { make_armor({
        id = "wool-coif", material = "wool",
        covers = { "head" }, fit = "fitted", _state = "intact",
        layer = "inner",
    }) }
    process_effect(player2, { damage = 10, location = "head" })
    local coif_only_dmg = get_injury_damage(player2)

    h.assert_eq(coif_only_dmg, head_dmg,
        "torso armor should not stack with head armor for head hits")
end)

---------------------------------------------------------------------------
-- Suite 7: Fit Quality Multipliers
---------------------------------------------------------------------------
h.suite("Fit Quality — Makeshift vs Fitted vs Masterwork")

h.test("fitted provides more protection than makeshift", function()
    setup()
    -- Makeshift
    local player_makeshift = fresh_player()
    player_makeshift.worn = { make_armor({
        id = "pot-helm", material = "iron",
        covers = { "head" }, fit = "makeshift", _state = "intact",
    }) }
    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player_makeshift, { damage = 20, location = "head" })
    local makeshift_dmg = get_injury_damage(player_makeshift)

    -- Fitted
    setup()
    local player_fitted = fresh_player()
    player_fitted.worn = { make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player_fitted, { damage = 20, location = "head" })
    local fitted_dmg = get_injury_damage(player_fitted)
    math.random = old_random

    h.assert_truthy(makeshift_dmg and fitted_dmg,
        "both should inflict injuries")
    h.assert_truthy(fitted_dmg < makeshift_dmg,
        "fitted should protect more than makeshift"
        .. " — fitted=" .. tostring(fitted_dmg)
        .. " makeshift=" .. tostring(makeshift_dmg))
end)

h.test("masterwork provides more protection than fitted", function()
    setup()
    -- Fitted
    local player_fitted = fresh_player()
    player_fitted.worn = { make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player_fitted, { damage = 20, location = "head" })
    local fitted_dmg = get_injury_damage(player_fitted)

    -- Masterwork
    setup()
    local player_master = fresh_player()
    player_master.worn = { make_armor({
        id = "master-helm", material = "iron",
        covers = { "head" }, fit = "masterwork", _state = "intact",
    }) }
    process_effect(player_master, { damage = 20, location = "head" })
    local master_dmg = get_injury_damage(player_master)
    math.random = old_random

    h.assert_truthy(master_dmg and fitted_dmg,
        "both should inflict injuries")
    h.assert_truthy(master_dmg < fitted_dmg,
        "masterwork should protect more than fitted"
        .. " — masterwork=" .. tostring(master_dmg)
        .. " fitted=" .. tostring(fitted_dmg))
end)

h.test("makeshift still provides some protection vs no armor", function()
    setup()
    local player_makeshift = fresh_player()
    player_makeshift.worn = { make_armor({
        id = "pot-helm", material = "iron",
        covers = { "head" }, fit = "makeshift", _state = "intact",
    }) }
    process_effect(player_makeshift, { damage = 20, location = "head" })
    local makeshift_dmg = get_injury_damage(player_makeshift)

    setup()
    local player_bare = fresh_player()
    player_bare.worn = {}
    process_effect(player_bare, { damage = 20, location = "head" })
    local bare_dmg = get_injury_damage(player_bare)

    h.assert_truthy(makeshift_dmg < bare_dmg,
        "even makeshift armor should reduce damage vs none"
        .. " — makeshift=" .. tostring(makeshift_dmg)
        .. " bare=" .. tostring(bare_dmg))
end)

---------------------------------------------------------------------------
-- Suite 8: Edge Cases & Minimum Damage
---------------------------------------------------------------------------
h.suite("Edge Cases — Minimum Damage Floor & Boundary Conditions")

h.test("armor never reduces damage below 1 (minimum damage floor)", function()
    setup()
    local player = fresh_player()
    -- Masterwork steel on a tiny 2-damage hit
    player.worn = { make_armor({
        id = "master-steel-helm", material = "steel",
        covers = { "head" }, fit = "masterwork", _state = "intact",
    }) }
    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player, { damage = 2, location = "head" })
    math.random = old_random

    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg, "injury should still be created")
    h.assert_truthy(dmg >= 1,
        "damage should never go below 1, got " .. tostring(dmg))
end)

h.test("worn item with no material field provides no protection", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "mystery-hat", material = nil,
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "head" })
    h.assert_eq(10, get_injury_damage(player),
        "item with no material should provide no protection")
end)

h.test("worn item with unknown material provides no protection", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "unobtainium-hat", material = "unobtainium",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = "head" })
    h.assert_eq(10, get_injury_damage(player),
        "item with unregistered material should provide no protection")
end)

h.test("effect with no location is not intercepted by armor", function()
    setup()
    local player = fresh_player()
    player.worn = { make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    process_effect(player, { damage = 10, location = nil })
    h.assert_eq(10, get_injury_damage(player),
        "unlocated effect should bypass armor entirely")
end)

h.test("non-injury effects are not intercepted by armor", function()
    setup()
    local player = fresh_player()
    player.state = {}
    player.worn = { make_armor({
        id = "iron-helm", material = "iron",
        covers = { "head" }, fit = "fitted", _state = "intact",
    }) }
    local status_effect = {
        type = "add_status", status = "dizzy", duration = 3,
    }
    local ctx = { player = player }
    suppress_print(function()
        effects.process(status_effect, ctx)
    end)
    h.assert_truthy(player.state.dizzy,
        "status effects should still apply normally with armor equipped")
end)

h.test("armor interceptor loaded successfully", function()
    h.assert_truthy(armor_ok,
        "engine.armor module should load — got error: " .. tostring(armor))
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("")
print("=== ARMOR MODULE STATUS ===")
if armor_ok then
    print("  engine.armor: LOADED")
else
    print("  engine.armor: NOT FOUND (expected for TDD phase)")
    print("  Error: " .. tostring(armor))
end
print("")

local exit_code = h.summary()
os.exit(exit_code)
