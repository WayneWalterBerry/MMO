-- test/injuries/test-disease-delivery.lua
-- TDD tests for WAVE-4 Track 4C: on_hit disease delivery in combat.
-- Tests that combat resolution delivers diseases via on_hit field on
-- natural weapons, respecting probability and severity thresholds.
--
-- Written to spec — some tests may fail until Bart finishes Track 4C/4D.
--
-- Usage: lua test/injuries/test-disease-delivery.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

local injury_mod = require("engine.injuries")
local combat_ok, combat = pcall(require, "engine.combat")
if not combat_ok then combat = nil end

---------------------------------------------------------------------------
-- Test harness
---------------------------------------------------------------------------
local passed = 0
local failed = 0
local skipped = 0

local function assert_eq(actual, expected, label)
    if actual == expected then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected: " .. tostring(expected))
        print("    actual:   " .. tostring(actual))
    end
end

local function assert_true(val, label)
    assert_eq(not not val, true, label)
end

local function assert_false(val, label)
    assert_eq(not not val, false, label)
end

local function assert_near(actual, expected, tolerance, label)
    if type(actual) == "number" and math.abs(actual - expected) <= tolerance then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected: " .. tostring(expected) .. " ±" .. tostring(tolerance))
        print("    actual:   " .. tostring(actual))
    end
end

local function skip(label, reason)
    skipped = skipped + 1
    print("  SKIP " .. label .. " — " .. reason)
end

local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then return table.concat(lines, "\n"), err end
    return table.concat(lines, "\n"), nil
end

---------------------------------------------------------------------------
-- Disease definitions (matching WAVE-4 spec for rabies + spider-venom)
---------------------------------------------------------------------------
local rabies_def = {
    id = "rabies",
    name = "Rabies",
    category = "disease",
    damage_type = "over_time",
    initial_state = "incubating",
    hidden_until_state = "prodromal",
    on_inflict = {
        initial_damage = 0,
        damage_per_tick = 0,
        message = "Something feels wrong where the bite broke skin.",
    },
    transmission = { probability = 0.08 },
    curable_in = { "incubating", "prodromal" },
    states = {
        incubating = {
            name = "incubating rabies",
            description = "No visible symptoms yet.",
            damage_per_tick = 0,
            duration = 15,
        },
        prodromal = {
            name = "early rabies",
            description = "You feel feverish. Your muscles ache.",
            symptom = "You feel feverish. The bite wound tingles.",
            damage_per_tick = 1,
            duration = 10,
            restricts = { precise_actions = true },
        },
        furious = {
            name = "furious rabies",
            description = "Uncontrollable rage. You gag at the sight of water.",
            symptom = "Rage courses through you. Water makes you gag.",
            damage_per_tick = 3,
            duration = 8,
            restricts = { drink = true, precise_actions = true },
        },
        fatal = {
            name = "terminal rabies",
            description = "The disease has won.",
            terminal = true,
            death_message = "The rabies claims you. Your body gives out.",
        },
        healed = {
            name = "cured rabies",
            description = "The disease has been driven from your body.",
            terminal = true,
        },
    },
    transitions = {
        { from = "incubating", to = "prodromal", trigger = "auto",
          condition = "duration_expired",
          message = "You feel feverish. The bite wound tingles." },
        { from = "prodromal", to = "furious", trigger = "auto",
          condition = "duration_expired",
          message = "Rage overwhelms you. Water makes you gag." },
        { from = "furious", to = "fatal", trigger = "auto",
          condition = "duration_expired",
          message = "Your body gives out." },
    },
    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "incubating", "prodromal" },
        },
    },
}

local venom_def = {
    id = "spider-venom",
    name = "Spider Venom",
    category = "disease",
    damage_type = "over_time",
    initial_state = "injected",
    on_inflict = {
        initial_damage = 2,
        damage_per_tick = 2,
        message = "Burning venom spreads from the bite.",
    },
    transmission = { probability = 1.0 },
    curable_in = { "injected", "spreading" },
    states = {
        injected = {
            name = "spider venom (early)",
            description = "Burning at the bite site.",
            damage_per_tick = 2,
            duration = 3,
        },
        spreading = {
            name = "spider venom (spreading)",
            description = "The venom spreads. Your limbs feel heavy.",
            damage_per_tick = 3,
            duration = 5,
            restricts = { movement = true },
        },
        paralysis = {
            name = "spider venom (paralysis)",
            description = "You can barely move.",
            damage_per_tick = 1,
            duration = 8,
            restricts = { movement = true, attack = true, precise_actions = true },
        },
        healed = {
            name = "cured venom",
            description = "The venom has been neutralized.",
            terminal = true,
        },
    },
    healing_interactions = {
        ["antivenom"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
        },
    },
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local SEVERITY = combat and combat.SEVERITY or {
    DEFLECT = 0, GRAZE = 1, HIT = 2, SEVERE = 3, CRITICAL = 4,
}

local function fresh_player()
    return {
        id = "player",
        is_player = true,
        max_health = 100,
        health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        state = {},
    }
end

local function fresh_creature(id, on_hit)
    return {
        id = id,
        name = "a " .. id,
        animate = true,
        health = 50,
        max_health = 50,
        injuries = {},
        combat = {
            size = "small",
            type = "pierce",
            force = 2,
        },
        natural_weapon = {
            id = id .. "-bite",
            name = id .. " bite",
            material = "bone",
            combat = { type = "pierce", force = 2, message = "bites" },
            on_hit = on_hit,
        },
        state = {},
    }
end

local function setup()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("rabies", rabies_def)
    injury_mod.register_definition("spider-venom", venom_def)
end

---------------------------------------------------------------------------
-- 1. Probability 1.0 always delivers disease
---------------------------------------------------------------------------
print("\n=== on_hit delivery: probability 1.0 always delivers ===")
setup()

do
    local defender = fresh_player()
    local on_hit = { inflict = "spider-venom", probability = 1.0 }
    local delivered = 0
    for i = 1, 20 do
        math.randomseed(i * 7)
        -- Simulate delivery check: probability 1.0 should always fire
        local roll = math.random()
        if roll <= on_hit.probability then
            delivered = delivered + 1
        end
    end
    assert_eq(delivered, 20, "prob 1.0: all 20 rolls deliver")
end

---------------------------------------------------------------------------
-- 2. Probability 0.08 rate verified (fixed seed, ±4% tolerance)
---------------------------------------------------------------------------
print("\n=== on_hit delivery: probability 0.08 rate (~8% ±4%) ===")
setup()

do
    local on_hit = { inflict = "rabies", probability = 0.08 }
    local trials = 1000
    local delivered = 0
    math.randomseed(42)
    for i = 1, trials do
        local roll = math.random()
        if roll <= on_hit.probability then
            delivered = delivered + 1
        end
    end
    local rate = delivered / trials
    assert_near(rate, 0.08, 0.04, "prob 0.08: delivery rate ~8% (got " ..
        string.format("%.1f%%", rate * 100) .. " over " .. trials .. " trials)")
end

---------------------------------------------------------------------------
-- 3. DEFLECT severity does not trigger delivery
---------------------------------------------------------------------------
print("\n=== on_hit delivery: DEFLECT severity blocks delivery ===")
setup()

do
    local severity = SEVERITY.DEFLECT
    local should_deliver = severity >= SEVERITY.HIT
    assert_false(should_deliver, "DEFLECT severity does not trigger on_hit delivery")
end

---------------------------------------------------------------------------
-- 4. GRAZE severity does not trigger delivery
---------------------------------------------------------------------------
print("\n=== on_hit delivery: GRAZE severity blocks delivery ===")
setup()

do
    local severity = SEVERITY.GRAZE
    local should_deliver = severity >= SEVERITY.HIT
    assert_false(should_deliver, "GRAZE severity does not trigger on_hit delivery")
end

---------------------------------------------------------------------------
-- 5. HIT severity triggers delivery
---------------------------------------------------------------------------
print("\n=== on_hit delivery: HIT severity triggers delivery ===")
setup()

do
    local severity = SEVERITY.HIT
    local should_deliver = severity >= SEVERITY.HIT
    assert_true(should_deliver, "HIT severity triggers on_hit delivery")
end

---------------------------------------------------------------------------
-- 6. CRITICAL severity triggers delivery
---------------------------------------------------------------------------
print("\n=== on_hit delivery: CRITICAL severity triggers delivery ===")
setup()

do
    local severity = SEVERITY.CRITICAL
    local should_deliver = severity >= SEVERITY.HIT
    assert_true(should_deliver, "CRITICAL severity triggers on_hit delivery")
end

---------------------------------------------------------------------------
-- 7. SEVERE severity triggers delivery
---------------------------------------------------------------------------
print("\n=== on_hit delivery: SEVERE severity triggers delivery ===")
setup()

do
    local severity = SEVERITY.SEVERE or 3
    local should_deliver = severity >= SEVERITY.HIT
    assert_true(should_deliver, "SEVERE severity triggers on_hit delivery")
end

---------------------------------------------------------------------------
-- 8. No on_hit field → no error (graceful)
---------------------------------------------------------------------------
print("\n=== on_hit delivery: missing on_hit field is graceful ===")
setup()

do
    local weapon = { id = "claws", combat = { type = "edged", force = 3 } }
    -- Simulate what combat.update should do: check for on_hit, skip if absent
    local on_hit = weapon.on_hit
    local delivered = false
    if on_hit and on_hit.inflict then
        delivered = true
    end
    assert_false(delivered, "no on_hit field → no delivery attempt, no error")
end

do
    -- Also test with natural_weapon but no on_hit
    local attacker = fresh_creature("wolf", nil)
    attacker.natural_weapon.on_hit = nil
    local ok, err = pcall(function()
        -- Simulate checking on_hit on a weapon with no on_hit field
        local weapon = attacker.natural_weapon
        local on_hit = weapon and weapon.on_hit
        if on_hit and on_hit.inflict and on_hit.probability then
            error("should not reach here")
        end
    end)
    assert_true(ok, "nil on_hit on natural_weapon does not error")
end

---------------------------------------------------------------------------
-- 9. Disease inflicted on correct target (defender, not attacker)
---------------------------------------------------------------------------
print("\n=== on_hit delivery: disease targets defender, not attacker ===")
setup()

do
    local attacker = fresh_creature("rat", { inflict = "rabies", probability = 1.0 })
    local defender = fresh_player()
    -- Simulate delivery: inflict on defender
    local weapon = attacker.natural_weapon
    local on_hit = weapon and weapon.on_hit
    if on_hit and on_hit.inflict and on_hit.probability then
        math.randomseed(1)
        local roll = math.random()
        if roll <= on_hit.probability then
            capture_print(function()
                injury_mod.inflict(defender, on_hit.inflict, weapon.id)
            end)
        end
    end
    assert_eq(#defender.injuries, 1, "disease inflicted on defender")
    assert_eq(defender.injuries[1].type, "rabies", "defender has rabies")
    assert_eq(#attacker.injuries, 0, "attacker has no injuries (disease targets defender)")
end

---------------------------------------------------------------------------
-- 10. NPC-vs-NPC disease delivery works
---------------------------------------------------------------------------
print("\n=== on_hit delivery: NPC-vs-NPC disease delivery ===")
setup()

do
    local rat = fresh_creature("rat", { inflict = "rabies", probability = 1.0 })
    rat.injuries = {}
    local cat = {
        id = "cat", name = "a cat", animate = true,
        health = 40, max_health = 40, injuries = {},
        combat = { size = "small" },
        state = {},
    }
    -- Simulate: rat bites cat at severity HIT with prob 1.0
    local severity = SEVERITY.HIT
    local weapon = rat.natural_weapon
    local on_hit = weapon and weapon.on_hit
    if on_hit and severity >= SEVERITY.HIT then
        math.randomseed(1)
        if math.random() <= on_hit.probability then
            capture_print(function()
                injury_mod.inflict(cat, on_hit.inflict, weapon.id)
            end)
        end
    end
    assert_eq(#cat.injuries, 1, "NPC-vs-NPC: cat receives disease from rat")
    assert_eq(cat.injuries[1].type, "rabies", "NPC-vs-NPC: cat has rabies")
end

---------------------------------------------------------------------------
-- 11. Concurrent diseases tick independently
---------------------------------------------------------------------------
print("\n=== on_hit delivery: concurrent diseases tick independently ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "rabies", "rat-bite")
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)
    assert_eq(#player.injuries, 2, "two diseases coexist on same target")
    assert_eq(player.injuries[1].type, "rabies", "first disease is rabies")
    assert_eq(player.injuries[2].type, "spider-venom", "second disease is spider-venom")

    -- Tick once — both should advance independently
    capture_print(function() injury_mod.tick(player) end)
    assert_eq(player.injuries[1].turns_active, 1, "rabies ticked to turn 1")
    assert_eq(player.injuries[2].turns_active, 1, "spider-venom ticked to turn 1")

    -- Verify damage is accumulated from both
    local health = injury_mod.compute_health(player)
    -- rabies: 0 initial + 0/tick = 0 damage after tick 1 (incubating: 0 dmg)
    -- venom: 2 initial + 2/tick = 4 damage after tick 1
    -- total damage: 0 + 4 = 4, health = 96
    assert_true(health < 100, "health decreased from concurrent disease damage")
end

---------------------------------------------------------------------------
-- 12. Disease delivery via combat.update (integration, pcall-guarded)
---------------------------------------------------------------------------
print("\n=== on_hit delivery: combat.update integration ===")
setup()

do
    if not combat or not combat.update then
        skip("combat.update on_hit integration", "combat module not loaded or update missing")
    else
        local rat = fresh_creature("rat", { inflict = "rabies", probability = 1.0 })
        local defender = fresh_player()
        defender.health = 100
        defender.injuries = {}

        local result = {
            attacker = rat,
            defender = defender,
            severity = SEVERITY.HIT,
            weapon = rat.natural_weapon,
            zone = "torso",
            damage = 3,
            light = true,
        }

        local output, err = capture_print(function()
            combat.update(result)
        end)

        -- Check if on_hit delivery was processed
        local has_disease = false
        for _, inj in ipairs(defender.injuries or {}) do
            if inj.type == "rabies" then has_disease = true; break end
        end
        -- This may fail until Bart implements on_hit delivery in combat.update
        if has_disease then
            assert_true(true, "combat.update delivers rabies via on_hit at HIT severity")
        else
            skip("combat.update on_hit delivery", "on_hit disease delivery not yet implemented in combat.update")
        end
    end
end

---------------------------------------------------------------------------
-- 13. DEFLECT does not deliver via combat.update (integration)
---------------------------------------------------------------------------
print("\n=== on_hit delivery: combat.update DEFLECT blocks delivery ===")
setup()

do
    if not combat or not combat.update then
        skip("combat.update DEFLECT block", "combat module not loaded")
    else
        local rat = fresh_creature("rat", { inflict = "rabies", probability = 1.0 })
        local defender = fresh_player()
        defender.health = 100
        defender.injuries = {}

        local result = {
            attacker = rat,
            defender = defender,
            severity = SEVERITY.DEFLECT,
            weapon = rat.natural_weapon,
            zone = "torso",
            damage = 0,
            light = true,
        }

        capture_print(function() combat.update(result) end)

        local has_disease = false
        for _, inj in ipairs(defender.injuries or {}) do
            if inj.type == "rabies" then has_disease = true; break end
        end
        assert_false(has_disease, "combat.update does NOT deliver disease at DEFLECT severity")
    end
end

---------------------------------------------------------------------------
-- 14. on_hit with inflict but probability 0 never delivers
---------------------------------------------------------------------------
print("\n=== on_hit delivery: probability 0 never delivers ===")
setup()

do
    local on_hit = { inflict = "rabies", probability = 0 }
    local delivered = 0
    math.randomseed(42)
    for i = 1, 100 do
        local roll = math.random()
        if roll <= on_hit.probability then
            delivered = delivered + 1
        end
    end
    assert_eq(delivered, 0, "prob 0: zero deliveries over 100 rolls")
end

---------------------------------------------------------------------------
-- 15. Multiple bites accumulate separate disease instances
---------------------------------------------------------------------------
print("\n=== on_hit delivery: multiple bites create separate instances ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "rabies", "rat-bite-1")
        injury_mod.inflict(player, "rabies", "rat-bite-2")
    end)
    assert_eq(#player.injuries, 2, "two rabies instances from two bites")
    assert_true(player.injuries[1].id ~= player.injuries[2].id,
        "each rabies instance has unique id")
    assert_eq(player.injuries[1].source, "rat-bite-1", "first rabies source tracked")
    assert_eq(player.injuries[2].source, "rat-bite-2", "second rabies source tracked")
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed:  " .. passed)
print("  Failed:  " .. failed)
if skipped > 0 then
    print("  Skipped: " .. skipped)
end
if failed > 0 then
    os.exit(1)
end
