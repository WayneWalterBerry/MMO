-- test/armor/test-armor-degradation.lua
-- TDD tests for armor degradation auto-unequip behavior.
--
-- Validates:
--   1. Wearing intact armor works normally
--   2. Armor degrades intact → cracked (protection drops to 70%)
--   3. Armor degrades cracked → shattered (protection drops to 0%)
--   4. KEY: Shattered armor auto-unequips from player
--   5. KEY: Player can't wear shattered armor
--   6. KEY: Non-wearable FSM states cause auto-unequip on transition
--
-- Usage: lua test/armor/test-armor-degradation.lua
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
local captured_output = {}

local function capture_print(fn)
    local old_print = _G.print
    captured_output = {}
    _G.print = function(...)
        local args = {...}
        local line = ""
        for i, v in ipairs(args) do
            if i > 1 then line = line .. "\t" end
            line = line .. tostring(v)
        end
        captured_output[#captured_output + 1] = line
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
    return captured_output
end

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

local function make_armor_item(overrides)
    local item = {
        id         = "iron-breastplate",
        name       = "an iron breastplate",
        material   = "iron",
        covers     = { "torso" },
        fit        = "fitted",
        _state     = "intact",
        wear       = {
            slot     = "torso",
            layer    = "outer",
            coverage = 1.0,
            fit      = "fitted",
        },
        wearable   = true,
    }
    if overrides then
        for k, v in pairs(overrides) do item[k] = v end
    end
    return item
end

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
        wearable   = true,
    }
    if overrides then
        for k, v in pairs(overrides) do item[k] = v end
    end
    return item
end

--- A generic wearable with FSM states that include a non-wearable terminal state.
local function make_degradable_cloak(overrides)
    local item = {
        id         = "wool-cloak",
        name       = "a wool cloak",
        material   = "wool",
        _state     = "intact",
        wear       = {
            slot     = "torso",
            layer    = "outer",
        },
        wearable   = true,
        initial_state = "intact",
        states = {
            intact = {
                description = "A warm wool cloak.",
                wearable = true,
            },
            torn = {
                description = "A badly torn cloak.",
                wearable = true,
            },
            shredded = {
                description = "Nothing but rags.",
                wearable = false,
            },
        },
        transitions = {
            { from = "intact", to = "torn", verb = "cut" },
            { from = "torn", to = "shredded", verb = "cut" },
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
        location    = "torso",
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

--- Check if an item is in the player's worn list.
local function is_worn(player, item_id)
    for _, worn in ipairs(player.worn or {}) do
        local wid = type(worn) == "table" and worn.id or worn
        if wid == item_id then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Suite 1: Wearing intact armor works
---------------------------------------------------------------------------
suite("Armor degradation — wearing intact armor works")

test("intact armor provides protection (baseline)", function()
    setup()
    local player = fresh_player()
    local armor_item = make_ceramic_pot()
    player.worn = { armor_item }

    -- Suppress degradation
    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player, { damage = 10, location = "head" })
    math.random = old_random

    local dmg = get_injury_damage(player)
    h.assert_truthy(dmg, "injury must be inflicted")
    h.assert_truthy(dmg < 10,
        "intact armor should reduce damage, got " .. tostring(dmg))
end)

test("intact armor stays in worn list after absorbing hit", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player, { damage = 10, location = "head" })
    math.random = old_random

    h.assert_eq(1, #player.worn, "intact armor should remain worn")
end)

---------------------------------------------------------------------------
-- Suite 2: Degradation path (intact → cracked → shattered)
---------------------------------------------------------------------------
suite("Armor degradation — state transitions")

test("armor degrades from intact to cracked", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot()
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    process_effect(player, { damage = 10, location = "head", damage_type = "blunt" })
    math.random = old_random

    h.assert_eq("cracked", pot._state,
        "ceramic should crack on deterministic hit")
end)

test("cracked armor provides reduced protection (70%)", function()
    setup()
    -- Intact pot
    local player1 = fresh_player()
    player1.worn = { make_ceramic_pot({ _state = "intact" }) }
    local old_random = math.random
    math.random = function() return 1.0 end
    process_effect(player1, { damage = 20, location = "head" })
    local intact_dmg = get_injury_damage(player1)

    -- Cracked pot
    setup()
    local player2 = fresh_player()
    player2.worn = { make_ceramic_pot({ _state = "cracked" }) }
    math.random = function() return 1.0 end
    process_effect(player2, { damage = 20, location = "head" })
    math.random = old_random
    local cracked_dmg = get_injury_damage(player2)

    h.assert_truthy(intact_dmg and cracked_dmg, "both must inflict injuries")
    h.assert_truthy(cracked_dmg > intact_dmg,
        "cracked armor should allow more damage through"
        .. " — intact=" .. tostring(intact_dmg) .. " cracked=" .. tostring(cracked_dmg))
end)

test("armor degrades from cracked to shattered", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot({ _state = "cracked" })
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    process_effect(player, { damage = 10, location = "head", damage_type = "blunt" })
    math.random = old_random

    h.assert_eq("shattered", pot._state,
        "cracked ceramic should shatter on deterministic hit")
end)

test("shattered armor provides zero protection", function()
    setup()
    local player = fresh_player()
    player.worn = { make_ceramic_pot({ _state = "shattered" }) }
    process_effect(player, { damage = 10, location = "head" })
    local dmg = get_injury_damage(player)
    h.assert_eq(10, dmg,
        "shattered armor should provide zero protection, got " .. tostring(dmg))
end)

---------------------------------------------------------------------------
-- Suite 3: KEY — Shattered armor auto-unequips
---------------------------------------------------------------------------
suite("Armor degradation — shattered armor auto-unequips")

test("armor that shatters is removed from player.worn", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot({ _state = "cracked" })
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    process_effect(player, { damage = 10, location = "head", damage_type = "blunt" })
    math.random = old_random

    h.assert_eq("shattered", pot._state,
        "pot must shatter first")
    h.assert_eq(0, #player.worn,
        "shattered armor must be auto-removed from player.worn, still has " .. #player.worn)
end)

test("auto-unequip prints 'shatters and falls away' message", function()
    setup()
    local player = fresh_player()
    local pot = make_ceramic_pot({ _state = "cracked" })
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    local output = capture_print(function()
        local eff = make_effect({ damage = 10, location = "head", damage_type = "blunt" })
        local ctx = { player = player, source_id = eff.source }
        effects.process(eff, ctx)
    end)
    math.random = old_random

    local found_msg = false
    for _, line in ipairs(output) do
        if line:find("shatters") and line:find("falls away") then
            found_msg = true
            break
        end
    end
    h.assert_truthy(found_msg,
        "should print 'shatters and falls away' message on auto-unequip")
end)

test("auto-unequip via degrade_covering_armor removes from worn", function()
    local player = fresh_player()
    local pot = make_ceramic_pot({ _state = "cracked" })
    player.worn = { pot }

    local old_random = math.random
    math.random = function() return 0.0 end
    suppress_print(function()
        armor.degrade_covering_armor(player, "head", 10, "blunt")
    end)
    math.random = old_random

    h.assert_eq("shattered", pot._state, "pot must shatter")
    h.assert_eq(0, #player.worn,
        "degrade_covering_armor must also auto-unequip shattered armor")
end)

---------------------------------------------------------------------------
-- Suite 4: KEY — Player can't wear shattered armor
---------------------------------------------------------------------------
suite("Armor degradation — can't wear shattered items")

test("wearing shattered armor is rejected", function()
    -- This tests the equipment.lua wear handler
    -- We simulate what the wear handler should check
    local item = make_ceramic_pot({ _state = "shattered" })

    -- Check: armor module should report shattered items as non-wearable
    h.assert_truthy(armor.is_wearable_state,
        "armor module must export is_wearable_state function")

    local can_wear = armor.is_wearable_state(item)
    h.assert_eq(false, can_wear,
        "shattered armor should not be wearable")
end)

test("intact armor is wearable", function()
    local item = make_ceramic_pot({ _state = "intact" })
    h.assert_truthy(armor.is_wearable_state,
        "armor module must export is_wearable_state function")
    local can_wear = armor.is_wearable_state(item)
    h.assert_eq(true, can_wear,
        "intact armor should be wearable")
end)

test("cracked armor is still wearable", function()
    local item = make_ceramic_pot({ _state = "cracked" })
    local can_wear = armor.is_wearable_state(item)
    h.assert_eq(true, can_wear,
        "cracked armor should still be wearable")
end)

---------------------------------------------------------------------------
-- Suite 5: KEY — Non-wearable FSM states cause auto-unequip
---------------------------------------------------------------------------
suite("Armor degradation — generalized non-wearable state auto-unequip")

test("item with FSM state wearable=false is detected as non-wearable", function()
    local cloak = make_degradable_cloak({ _state = "shredded" })
    h.assert_truthy(armor.is_wearable_state,
        "armor module must export is_wearable_state function")
    local can_wear = armor.is_wearable_state(cloak)
    h.assert_eq(false, can_wear,
        "item in FSM state with wearable=false should not be wearable")
end)

test("item with FSM state wearable=true is detected as wearable", function()
    local cloak = make_degradable_cloak({ _state = "intact" })
    local can_wear = armor.is_wearable_state(cloak)
    h.assert_eq(true, can_wear,
        "item in FSM state with wearable=true should be wearable")
end)

test("auto_unequip_check removes worn item in non-wearable state", function()
    h.assert_truthy(armor.auto_unequip_check,
        "armor module must export auto_unequip_check function")

    local player = fresh_player()
    local cloak = make_degradable_cloak({ _state = "shredded" })
    player.worn = { cloak }

    local removed, msg = false, nil
    suppress_print(function()
        removed, msg = armor.auto_unequip_check(player, cloak)
    end)

    h.assert_eq(true, removed,
        "auto_unequip_check should return true for non-wearable state")
    h.assert_eq(0, #player.worn,
        "auto_unequip_check should remove item from worn list")
end)

test("auto_unequip_check does nothing for wearable state", function()
    local player = fresh_player()
    local cloak = make_degradable_cloak({ _state = "intact" })
    player.worn = { cloak }

    local removed = false
    suppress_print(function()
        removed = armor.auto_unequip_check(player, cloak)
    end)

    h.assert_eq(false, removed,
        "auto_unequip_check should return false for wearable state")
    h.assert_eq(1, #player.worn,
        "wearable item should remain in worn list")
end)

test("item without FSM states is always wearable (backward compat)", function()
    local item = { id = "plain-hat", name = "a hat", wearable = true }
    local can_wear = armor.is_wearable_state(item)
    h.assert_eq(true, can_wear,
        "item without FSM states should be wearable by default")
end)

---------------------------------------------------------------------------
-- Done
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
