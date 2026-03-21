-- test/injuries/test-injury-engine.lua
-- Tests for the injury engine: infliction, ticking, health computation,
-- healing, listing, and death detection.
--
-- Usage: lua test/injuries/test-injury-engine.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. package.path

local injury_mod = require("engine.injuries")

---------------------------------------------------------------------------
-- Test harness
---------------------------------------------------------------------------
local passed = 0
local failed = 0

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

-- Capture print output
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    fn()
    _G.print = old_print
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Test injury definition for nightshade
---------------------------------------------------------------------------
local nightshade_def = {
    id = "poisoned-nightshade",
    name = "Nightshade Poisoning",
    category = "toxin",
    damage_type = "over_time",
    initial_state = "active",
    on_inflict = {
        initial_damage = 15,
        damage_per_tick = 8,
        message = "Nightshade poison courses through your veins. Your stomach churns.",
    },
    states = {
        active = {
            name = "poisoned (nightshade)",
            symptom = "Your stomach churns. Nightshade burns in your veins. You need an antidote — fast.",
            description = "Your stomach churns. Nightshade burns in your veins.",
            damage_per_tick = 8,
        },
        treated = {
            name = "neutralized nightshade",
            symptom = "The antidote is working. The burning fades, but you still feel weak.",
            description = "The antidote is working. The burning fades.",
            damage_per_tick = 0,
            auto_heal_turns = 3,
        },
        healed = {
            name = "recovered from nightshade",
            description = "The poison has left your system.",
            terminal = true,
        },
        fatal = {
            name = "lethal nightshade poisoning",
            description = "The nightshade has won.",
            terminal = true,
            death_message = "The nightshade claims you. Everything goes dark.",
        },
    },
    healing_interactions = {
        ["antidote-nightshade"] = {
            transitions_to = "treated",
            from_states = { "active" },
        },
    },
}

-- Bruise: one-time damage, auto-heals
local bruise_def = {
    id = "bruise",
    name = "Bruise",
    category = "physical",
    damage_type = "one_time",
    initial_state = "active",
    on_inflict = {
        initial_damage = 10,
        message = "A nasty bruise forms.",
    },
    states = {
        active = {
            name = "bruise",
            symptom = "A dark, painful bruise.",
            description = "A dark, painful bruise.",
            damage_per_tick = 0,
            auto_heal_turns = 3,
        },
        healed = {
            name = "faded bruise",
            description = "The bruise has faded.",
            terminal = true,
        },
    },
    healing_interactions = {},
}

---------------------------------------------------------------------------
-- Setup / teardown
---------------------------------------------------------------------------
local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn = {},
        state = {},
    }
end

local function setup()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("poisoned-nightshade", nightshade_def)
    injury_mod.register_definition("bruise", bruise_def)
end

---------------------------------------------------------------------------
-- Tests: compute_health
---------------------------------------------------------------------------
print("\n=== compute_health — derived health calculation ===")
setup()

do
    local p = fresh_player()
    assert_eq(injury_mod.compute_health(p), 100, "full health with no injuries")
end

do
    local p = fresh_player()
    p.injuries = { { type = "bruise", damage = 10 } }
    assert_eq(injury_mod.compute_health(p), 90, "health reduced by single injury damage")
end

do
    local p = fresh_player()
    p.injuries = {
        { type = "bruise", damage = 10 },
        { type = "poisoned-nightshade", damage = 25 },
    }
    assert_eq(injury_mod.compute_health(p), 65, "health reduced by multiple injuries (additive)")
end

do
    local p = fresh_player()
    p.injuries = { { type = "bruise", damage = 150 } }
    assert_eq(injury_mod.compute_health(p), 0, "health clamped at 0 (never negative)")
end

---------------------------------------------------------------------------
-- Tests: inflict
---------------------------------------------------------------------------
print("\n=== inflict — injury creation ===")
setup()

do
    local p = fresh_player()
    local output = capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)
    assert_eq(#p.injuries, 1, "inflict adds injury to player")
    assert_eq(p.injuries[1].type, "poisoned-nightshade", "injury type matches")
    assert_eq(p.injuries[1].damage, 15, "initial damage set from definition")
    assert_eq(p.injuries[1].damage_per_tick, 8, "damage_per_tick set from definition")
    assert_eq(p.injuries[1].source, "poison-bottle", "source recorded")
    assert_eq(p.injuries[1]._state, "active", "initial state is active")
    assert_eq(p.injuries[1].turns_active, 0, "turns_active starts at 0")
    assert_true(output:find("Nightshade poison"), "infliction message printed")
end

do
    local p = fresh_player()
    local output = capture_print(function()
        injury_mod.inflict(p, "bruise", "fall")
    end)
    assert_eq(p.injuries[1].damage, 10, "bruise gets one-time damage")
    assert_eq(p.injuries[1].damage_per_tick, 0, "bruise has no per-tick damage")
end

---------------------------------------------------------------------------
-- Tests: tick
---------------------------------------------------------------------------
print("\n=== tick — per-turn injury processing ===")
setup()

do
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)
    assert_eq(p.injuries[1].damage, 15, "damage before tick")
    capture_print(function() injury_mod.tick(p) end)
    assert_eq(p.injuries[1].damage, 23, "damage after 1 tick (15 + 8)")
    assert_eq(p.injuries[1].turns_active, 1, "turns_active incremented")
    assert_eq(injury_mod.compute_health(p), 77, "health after 1 tick")
end

do
    -- Multiple ticks accumulate damage
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)
    for i = 1, 5 do
        capture_print(function() injury_mod.tick(p) end)
    end
    -- 15 + (5 * 8) = 55
    assert_eq(p.injuries[1].damage, 55, "damage after 5 ticks (15 + 40)")
    assert_eq(injury_mod.compute_health(p), 45, "health after 5 ticks")
end

do
    -- Stacking injuries: 2 poisons = double drain
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "test1")
        injury_mod.inflict(p, "poisoned-nightshade", "test2")
    end)
    assert_eq(#p.injuries, 2, "two injuries stacked")
    assert_eq(injury_mod.compute_health(p), 70, "health with 2 injuries (100 - 15 - 15)")
    capture_print(function() injury_mod.tick(p) end)
    -- Each gets +8: (15+8) + (15+8) = 46 damage total
    assert_eq(injury_mod.compute_health(p), 54, "double drain after tick")
end

---------------------------------------------------------------------------
-- Tests: auto-healing
---------------------------------------------------------------------------
print("\n=== tick — auto-healing (bruise heals after N turns) ===")
setup()

do
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "bruise", "fall") end)
    assert_eq(#p.injuries, 1, "bruise inflicted")
    assert_eq(injury_mod.compute_health(p), 90, "health with bruise")

    -- Tick 1, 2: still active
    capture_print(function() injury_mod.tick(p) end)
    assert_eq(#p.injuries, 1, "bruise active after tick 1")
    capture_print(function() injury_mod.tick(p) end)
    assert_eq(#p.injuries, 1, "bruise active after tick 2")

    -- Tick 3: auto-heals (auto_heal_turns = 3)
    capture_print(function() injury_mod.tick(p) end)
    assert_eq(#p.injuries, 0, "bruise removed after auto-heal (tick 3)")
    assert_eq(injury_mod.compute_health(p), 100, "full health after bruise heals")
end

---------------------------------------------------------------------------
-- Tests: death detection
---------------------------------------------------------------------------
print("\n=== tick — death detection ===")
setup()

do
    local p = fresh_player()
    p.max_health = 20  -- 20 health, nightshade does 15 initial + 8/tick = 23 after tick 1
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)
    assert_eq(injury_mod.compute_health(p), 5, "health before lethal tick")
    local msgs, died
    capture_print(function()
        msgs, died = injury_mod.tick(p)
    end)
    assert_true(died, "death detected when health <= 0 after tick")
end

do
    -- No death at healthy level
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "bruise", "test") end)
    local msgs, died
    capture_print(function()
        msgs, died = injury_mod.tick(p)
    end)
    assert_false(died, "no death when health > 0")
end

---------------------------------------------------------------------------
-- Tests: try_heal
---------------------------------------------------------------------------
print("\n=== try_heal — healing injuries ===")
setup()

do
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)

    local antidote = {
        id = "antidote-nightshade",
        name = "a vial of nightshade antidote",
        on_drink = {
            cures = "poisoned-nightshade",
            transition_to = "treated",
            message = "The antidote takes effect. The burning subsides.",
            consumable = true,
        },
    }

    local healed
    local output = capture_print(function()
        healed = injury_mod.try_heal(p, antidote, "drink")
    end)
    assert_true(healed, "try_heal returns true on success")
    assert_eq(p.injuries[1]._state, "treated", "injury transitioned to treated")
    assert_eq(p.injuries[1].damage_per_tick, 0, "damage_per_tick set to 0 after treatment")
    assert_true(output:find("antidote takes effect"), "healing message printed")
end

do
    -- Wrong antidote fails
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)

    local wrong_item = {
        id = "bandage",
        name = "a bandage",
        on_use = {
            cures = "bleeding",
            message = "You bind the wound.",
        },
    }

    local healed
    local output = capture_print(function()
        healed = injury_mod.try_heal(p, wrong_item, "use")
    end)
    assert_false(healed, "wrong cure type fails")
    assert_true(output:find("don't have that kind"), "mismatch message printed")
end

---------------------------------------------------------------------------
-- Tests: treated → auto-healed removal
---------------------------------------------------------------------------
print("\n=== tick — treated injury auto-heals and is removed ===")
setup()

do
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)

    -- Treat it
    local antidote = {
        id = "antidote-nightshade",
        on_drink = {
            cures = "poisoned-nightshade",
            transition_to = "treated",
            message = "Healed.",
        },
    }
    capture_print(function() injury_mod.try_heal(p, antidote, "drink") end)
    assert_eq(p.injuries[1]._state, "treated", "injury in treated state")
    assert_eq(p.injuries[1].damage_per_tick, 0, "no more tick damage")

    -- Tick through auto-heal (3 turns)
    for i = 1, 2 do
        capture_print(function() injury_mod.tick(p) end)
    end
    assert_eq(#p.injuries, 1, "still present before auto-heal completes")

    capture_print(function() injury_mod.tick(p) end)
    assert_eq(#p.injuries, 0, "treated injury removed after auto-heal turns")
    assert_eq(injury_mod.compute_health(p), 100, "full health restored after treated injury heals")
end

---------------------------------------------------------------------------
-- Tests: list (injuries verb)
---------------------------------------------------------------------------
print("\n=== list — injuries verb output ===")
setup()

do
    local p = fresh_player()
    local output = capture_print(function() injury_mod.list(p) end)
    assert_true(output:find("feel fine"), "no injuries shows feel-fine message")
end

do
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "test") end)
    local output = capture_print(function() injury_mod.list(p) end)
    assert_true(output:find("examine yourself"), "injuries header shown")
    assert_true(output:find("nightshade"), "injury name shown")
    assert_true(output:find("antidote"), "treatment hint in symptom text")
end

---------------------------------------------------------------------------
-- Tests: no injuries — tick is safe
---------------------------------------------------------------------------
print("\n=== tick — safe with no injuries ===")
setup()

do
    local p = fresh_player()
    local msgs, died
    capture_print(function()
        msgs, died = injury_mod.tick(p)
    end)
    assert_eq(#msgs, 0, "no messages with no injuries")
    assert_false(died, "no death with no injuries")
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    os.exit(1)
end
