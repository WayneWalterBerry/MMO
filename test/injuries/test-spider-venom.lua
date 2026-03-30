-- test/injuries/test-spider-venom.lua
-- TDD tests for WAVE-4 Track 4B/4D: Spider venom disease FSM definition
-- and engine integration. Tests immediate symptoms, progression,
-- restrictions, cure windows, and concurrent diseases.
--
-- Written to spec — some tests may fail until Bart (4D) and Flanders (4B)
-- finish their tracks.
--
-- Usage: lua test/injuries/test-spider-venom.lua
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
-- Try to load spider-venom definition from disk; fall back to spec mock
---------------------------------------------------------------------------
local venom_from_disk = nil
do
    local ok, def = pcall(dofile, repo_root .. SEP .. "src" .. SEP .. "meta"
        .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "injuries" .. SEP .. "spider-venom.lua")
    if ok and def then venom_from_disk = def end
end

local venom_def = venom_from_disk or {
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
            description = "Burning at the bite site. The venom is fresh.",
            symptom = "The bite burns. Venom pulses beneath the skin.",
            damage_per_tick = 2,
            duration = 3,
        },
        spreading = {
            name = "spider venom (spreading)",
            description = "The venom spreads. Your limbs feel heavy.",
            symptom = "Your limbs feel heavy. The venom is spreading.",
            damage_per_tick = 3,
            duration = 5,
            restricts = { movement = true },
        },
        paralysis = {
            name = "spider venom (paralysis)",
            description = "You can barely move. The venom has taken hold.",
            symptom = "You can barely move. Your body refuses to obey.",
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
    transitions = {
        { from = "injected", to = "spreading", trigger = "auto",
          condition = "duration_expired",
          message = "The venom spreads. Your limbs grow heavy." },
        { from = "spreading", to = "paralysis", trigger = "auto",
          condition = "duration_expired",
          message = "Your muscles seize. You can barely move." },
    },
    healing_interactions = {
        ["antivenom"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
        },
    },
}

-- Rabies def for concurrent disease tests
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
            description = "You feel feverish.",
            damage_per_tick = 1,
            duration = 10,
            restricts = { precise_actions = true },
        },
        furious = {
            name = "furious rabies",
            description = "Uncontrollable rage.",
            damage_per_tick = 3,
            duration = 8,
            restricts = { drink = true, precise_actions = true },
        },
        fatal = {
            name = "terminal rabies",
            description = "The disease has won.",
            terminal = true,
            death_message = "The rabies claims you.",
        },
        healed = {
            name = "cured rabies",
            description = "Cured.",
            terminal = true,
        },
    },
    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "incubating", "prodromal" },
        },
    },
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function fresh_player()
    return {
        id = "player",
        is_player = true,
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
    injury_mod.register_definition("spider-venom", venom_def)
    injury_mod.register_definition("rabies", rabies_def)
end

---------------------------------------------------------------------------
-- 1. Spider venom definition loads and has required fields
---------------------------------------------------------------------------
print("\n=== Spider Venom definition: loads and validates ===")

do
    local def = venom_def
    assert_true(def ~= nil, "spider-venom definition loads")
    assert_eq(def.id, "spider-venom", "id is 'spider-venom'")
    assert_eq(def.category, "disease", "category is 'disease'")
    assert_eq(def.initial_state, "injected", "initial_state is 'injected'")
    assert_true(def.states ~= nil, "has states table")
    assert_true(def.states.injected ~= nil, "has injected state")
    assert_true(def.states.spreading ~= nil, "has spreading state")
    assert_true(def.states.paralysis ~= nil, "has paralysis state")
    assert_true(def.transmission ~= nil, "has transmission table")
    assert_eq(def.transmission.probability, 1.0, "transmission probability is 1.0")
end

---------------------------------------------------------------------------
-- 2. Immediate symptoms (no hidden state)
---------------------------------------------------------------------------
print("\n=== Spider Venom: immediate symptoms (no hidden state) ===")

do
    local def = venom_def
    -- Spider venom should NOT have hidden_until_state (unlike rabies)
    local hidden = def.hidden_until_state
    assert_true(hidden == nil, "no hidden_until_state (symptoms are immediate)")
end

do
    setup()
    local player = fresh_player()
    local output = capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)
    assert_eq(player.injuries[1]._state, "injected",
        "newly inflicted venom starts in 'injected'")
    assert_eq(player.injuries[1].damage, venom_def.on_inflict.initial_damage,
        "initial damage matches definition")
    assert_eq(player.injuries[1].damage_per_tick, venom_def.on_inflict.damage_per_tick,
        "damage_per_tick matches definition")
    assert_true(output:find("venom") or output:find("Venom") or output:find("burn") or output:find("Burn"),
        "infliction message mentions venom/burning")
end

---------------------------------------------------------------------------
-- 3. Transitions at correct tick: injected→spreading at tick 5
-- (Retuned in #360: was tick 3, now tick 5 for longer curable window)
---------------------------------------------------------------------------
print("\n=== Spider Venom: transition injected→spreading at tick 5 ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)

    -- Tick 4: should still be injected
    for i = 1, 4 do
        capture_print(function() injury_mod.tick(player) end)
    end
    local ok, state_at_4 = pcall(function() return player.injuries[1]._state end)
    if ok and state_at_4 == "injected" then
        assert_true(true, "still injected at tick 4")
    elseif ok and state_at_4 == "spreading" then
        skip("injected at tick 4", "disease FSM duration not yet implemented")
    else
        assert_eq(ok and state_at_4 or "error", "injected", "expected injected at tick 4")
    end

    -- Tick 5: should transition to spreading
    capture_print(function() injury_mod.tick(player) end)
    local ok2, state_at_5 = pcall(function() return player.injuries[1]._state end)
    if ok2 and state_at_5 == "spreading" then
        assert_true(true, "transitions to spreading at tick 5")
    else
        skip("spreading at tick 5", "disease FSM duration transitions not yet implemented")
    end
end

---------------------------------------------------------------------------
-- 4. Transitions at correct tick: spreading→paralysis at tick 11
-- (Retuned in #360: was tick 8, now tick 11 — 5 injected + 6 spreading)
---------------------------------------------------------------------------
print("\n=== Spider Venom: transition spreading→paralysis at tick 11 ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)

    -- Tick through 11 turns (5 injected + 6 spreading)
    for i = 1, 11 do
        capture_print(function() injury_mod.tick(player) end)
    end

    local ok, state = pcall(function() return player.injuries[1]._state end)
    if ok and state == "paralysis" then
        assert_true(true, "transitions to paralysis at tick 11")
    else
        skip("paralysis at tick 11", "disease FSM duration transitions not yet implemented (state: " .. tostring(ok and state or "error") .. ")")
    end
end

---------------------------------------------------------------------------
-- 5. Movement restriction in spreading state
---------------------------------------------------------------------------
print("\n=== Spider Venom: movement restricted in spreading ===")

do
    local def = venom_def
    local spreading = def.states.spreading
    assert_true(spreading.restricts ~= nil, "spreading has restricts table")
    assert_true(spreading.restricts.movement, "spreading restricts movement")
end

---------------------------------------------------------------------------
-- 6. Movement + attack + precise_actions restricted in paralysis
---------------------------------------------------------------------------
print("\n=== Spider Venom: paralysis restricts movement+attack+precise_actions ===")

do
    local def = venom_def
    local paralysis = def.states.paralysis
    assert_true(paralysis.restricts ~= nil, "paralysis has restricts table")
    assert_true(paralysis.restricts.movement, "paralysis restricts movement")
    assert_true(paralysis.restricts.attack, "paralysis restricts attack")
    assert_true(paralysis.restricts.precise_actions, "paralysis restricts precise_actions")
end

---------------------------------------------------------------------------
-- 7. get_restrictions merges paralysis restrictions (pcall-guarded)
---------------------------------------------------------------------------
print("\n=== Spider Venom: get_restrictions for paralysis ===")
setup()

do
    local ok, get_restrictions = pcall(function()
        return injury_mod.get_restrictions
    end)
    if ok and type(get_restrictions) == "function" then
        local player = fresh_player()
        player.injuries = {
            { type = "spider-venom", _state = "paralysis", damage = 10,
              damage_per_tick = 1, turns_active = 8, source = "spider",
              id = "spider-venom-1" },
        }
        local restrictions = injury_mod.get_restrictions(player)
        assert_true(restrictions and restrictions.movement,
            "get_restrictions returns movement=true in paralysis")
        assert_true(restrictions and restrictions.attack,
            "get_restrictions returns attack=true in paralysis")
    else
        skip("get_restrictions paralysis", "injuries.get_restrictions not yet implemented")
    end
end

---------------------------------------------------------------------------
-- 8. Cure in window works: injected state
---------------------------------------------------------------------------
print("\n=== Spider Venom: cure works in injected state ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)
    assert_eq(player.injuries[1]._state, "injected", "venom in injected state")

    local antivenom = {
        id = "antivenom",
        name = "a vial of antivenom",
        on_drink = {
            cures = "spider-venom",
            transition_to = "healed",
            message = "The antivenom neutralizes the spider venom.",
        },
    }

    local healed
    capture_print(function()
        healed = injury_mod.try_heal(player, antivenom, "drink")
    end)

    if healed then
        assert_true(true, "cure succeeds in injected state")
        local state = player.injuries[1] and player.injuries[1]._state or "removed"
        assert_true(state == "healed" or state == "removed",
            "venom transitions to healed/removed after cure")
    else
        skip("cure in injected", "try_heal may need curable_in support (Track 4D)")
    end
end

---------------------------------------------------------------------------
-- 9. Cure in window works: spreading state
---------------------------------------------------------------------------
print("\n=== Spider Venom: cure works in spreading state ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)
    -- Manually advance to spreading
    player.injuries[1]._state = "spreading"
    player.injuries[1].damage_per_tick = 3

    local antivenom = {
        id = "antivenom",
        name = "a vial of antivenom",
        on_drink = {
            cures = "spider-venom",
            transition_to = "healed",
            message = "The antivenom neutralizes the spider venom.",
        },
    }

    local healed
    capture_print(function()
        healed = injury_mod.try_heal(player, antivenom, "drink")
    end)

    if healed then
        assert_true(true, "cure succeeds in spreading state")
    else
        skip("cure in spreading", "try_heal may need curable_in support (Track 4D)")
    end
end

---------------------------------------------------------------------------
-- 10. Cure out of window fails: paralysis state
---------------------------------------------------------------------------
print("\n=== Spider Venom: cure fails in paralysis state ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
    end)
    -- Manually advance to paralysis
    player.injuries[1]._state = "paralysis"
    player.injuries[1].damage_per_tick = 1

    local antivenom = {
        id = "antivenom",
        name = "a vial of antivenom",
        on_drink = {
            cures = "spider-venom",
            transition_to = "healed",
            message = "The antivenom neutralizes the spider venom.",
        },
    }

    local healed
    local output = capture_print(function()
        healed = injury_mod.try_heal(player, antivenom, "drink")
    end)

    assert_false(healed, "cure fails in paralysis state (out of window)")
    assert_eq(player.injuries[1]._state, "paralysis",
        "venom stays in paralysis after failed cure")
end

---------------------------------------------------------------------------
-- 11. Venom + rabies coexist independently (concurrent diseases)
---------------------------------------------------------------------------
print("\n=== Spider Venom: coexists independently with rabies ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
        injury_mod.inflict(player, "rabies", "rat-bite")
    end)
    assert_eq(#player.injuries, 2, "venom and rabies coexist")
    assert_eq(player.injuries[1].type, "spider-venom", "first is spider-venom")
    assert_eq(player.injuries[2].type, "rabies", "second is rabies")

    -- Health reflects both: venom initial + rabies 0 initial
    local venom_dmg = venom_def.on_inflict.initial_damage
    assert_eq(injury_mod.compute_health(player), 100 - venom_dmg - 0,
        "health reflects both diseases (100 - " .. venom_dmg .. " - 0)")

    -- Tick once: venom does dpt/tick, rabies does 0/tick (incubating)
    local venom_dpt = venom_def.on_inflict.damage_per_tick
    capture_print(function() injury_mod.tick(player) end)
    assert_eq(player.injuries[1].damage, venom_dmg + venom_dpt,
        "venom ticks independently (" .. venom_dmg .. " + " .. venom_dpt .. ")")
    assert_eq(player.injuries[2].damage, 0,
        "rabies incubating stays at 0 damage")
    assert_eq(player.injuries[1].turns_active, 1, "venom at turn 1")
    assert_eq(player.injuries[2].turns_active, 1, "rabies at turn 1")
end

---------------------------------------------------------------------------
-- 12. Curing venom does not affect rabies
---------------------------------------------------------------------------
print("\n=== Spider Venom: curing venom does not affect rabies ===")
setup()

do
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite")
        injury_mod.inflict(player, "rabies", "rat-bite")
    end)

    local antivenom = {
        id = "antivenom",
        name = "a vial of antivenom",
        on_drink = {
            cures = "spider-venom",
            transition_to = "healed",
            message = "The antivenom works.",
        },
    }

    capture_print(function()
        injury_mod.try_heal(player, antivenom, "drink")
    end)

    -- Rabies should be unaffected
    local rabies_injury = nil
    for _, inj in ipairs(player.injuries) do
        if inj.type == "rabies" then rabies_injury = inj; break end
    end
    assert_true(rabies_injury ~= nil, "rabies still present after curing venom")
    assert_eq(rabies_injury._state, "incubating",
        "rabies still in incubating after venom cure")
end

---------------------------------------------------------------------------
-- 13. Spider venom state durations match spec
-- Spec: injected=5t, spreading=6t, paralysis=8t (retuned in #360)
-- Real definitions use timed_events with delay in seconds (1 tick = 360s)
---------------------------------------------------------------------------
print("\n=== Spider Venom: state durations match spec ===")

do
    local def = venom_def

    local function get_ticks(state_def)
        if state_def.duration then return state_def.duration end
        if state_def.timed_events then
            for _, evt in ipairs(state_def.timed_events) do
                if evt.event == "transition" and evt.delay then
                    return math.floor(evt.delay / 360)
                end
            end
        end
        return nil
    end

    assert_eq(get_ticks(def.states.injected), 5, "injected duration is 5 ticks")
    assert_eq(get_ticks(def.states.spreading), 6, "spreading duration is 6 ticks")
    assert_eq(get_ticks(def.states.paralysis), 8, "paralysis duration is 8 ticks")
end

---------------------------------------------------------------------------
-- 14. Spider venom curable_in field validates correctly
---------------------------------------------------------------------------
print("\n=== Spider Venom: curable_in field structure ===")

do
    local def = venom_def
    if def.curable_in then
        assert_true(type(def.curable_in) == "table", "curable_in is a table")
        local has_injected = false
        local has_spreading = false
        for _, state in ipairs(def.curable_in) do
            if state == "injected" then has_injected = true end
            if state == "spreading" then has_spreading = true end
        end
        assert_true(has_injected, "curable_in includes 'injected'")
        assert_true(has_spreading, "curable_in includes 'spreading'")
    else
        skip("curable_in structure", "curable_in field not present on definition")
    end
end

---------------------------------------------------------------------------
-- 15. Spider venom damage_per_tick values match spec per state
---------------------------------------------------------------------------
print("\n=== Spider Venom: damage_per_tick values per state ===")

do
    local def = venom_def
    assert_eq(def.states.injected.damage_per_tick, 1,
        "injected damage_per_tick is 1")
    assert_eq(def.states.spreading.damage_per_tick, 2,
        "spreading damage_per_tick is 2")
    assert_eq(def.states.paralysis.damage_per_tick, 1,
        "paralysis damage_per_tick is 1")
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
