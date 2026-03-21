-- test/injuries/test-self-infliction.lua
-- Tests for: stab/cut/slash self verbs, body area targeting, bandage
-- apply/remove dual-binding, weapon damage encoding, injury location.
--
-- Usage: lua test/injuries/test-self-infliction.lua
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

local function assert_nil(val, label)
    if val == nil then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected: nil")
        print("    actual:   " .. tostring(val))
    end
end

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
-- Injury definitions for testing
---------------------------------------------------------------------------
local bleeding_def = {
    id = "bleeding",
    name = "Bleeding Wound",
    category = "physical",
    damage_type = "over_time",
    initial_state = "active",
    on_inflict = {
        initial_damage = 5,
        damage_per_tick = 5,
        message = "Blood wells from the wound.",
    },
    states = {
        active = {
            name = "bleeding wound",
            symptom = "Blood flows steadily. You need something wrapped tight to stop it.",
            description = "Blood flows steadily from the wound.",
            damage_per_tick = 5,
        },
        treated = {
            name = "bandaged wound",
            symptom = "The bleeding has stopped under the bandage.",
            description = "A bandaged wound.",
            damage_per_tick = 0,
            auto_heal_turns = 10,
        },
        healed = {
            name = "healed wound",
            description = "The wound has closed.",
            terminal = true,
        },
    },
    healing_interactions = {
        bandage = {
            transitions_to = "treated",
            from_states = { "active" },
        },
    },
}

local minor_cut_def = {
    id = "minor-cut",
    name = "Minor Cut",
    category = "physical",
    damage_type = "one_time",
    initial_state = "active",
    on_inflict = {
        initial_damage = 3,
        damage_per_tick = 0,
        message = "A thin red line appears.",
    },
    states = {
        active = {
            name = "minor cut",
            symptom = "A shallow cut. It stings.",
            description = "A shallow cut.",
            damage_per_tick = 0,
            auto_heal_turns = 5,
        },
        treated = {
            name = "bandaged cut",
            symptom = "Bandaged. Healing.",
            description = "A bandaged minor cut.",
            damage_per_tick = 0,
            auto_heal_turns = 3,
        },
        healed = {
            name = "healed cut",
            description = "The cut has closed.",
            terminal = true,
        },
    },
    healing_interactions = {
        bandage = {
            transitions_to = "treated",
            from_states = { "active" },
        },
    },
}

---------------------------------------------------------------------------
-- Helpers
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

local function fresh_bandage()
    return {
        id = "bandage",
        name = "a clean linen bandage",
        keywords = {"bandage", "wrap", "dressing"},
        _state = "clean",
        initial_state = "clean",
        cures = { "bleeding", "minor-cut" },
        healing_boost = 2,
        applied_to = nil,
        portable = true,
        transitions = {
            {
                from = "clean", to = "applied",
                verb = "apply",
                message = "You press the bandage firmly against the wound and wrap it tight. The bleeding slows.",
            },
            {
                from = "applied", to = "soiled",
                verb = "remove",
                message = "You carefully unwrap the bandage. It comes away stained with blood.",
            },
        },
    }
end

local function setup()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("bleeding", bleeding_def)
    injury_mod.register_definition("minor-cut", minor_cut_def)
end

---------------------------------------------------------------------------
-- Tests: inflict with location
---------------------------------------------------------------------------
print("\n=== inflict — body location on injuries ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "self-inflicted", "left arm")
    end)
    assert_eq(#p.injuries, 1, "inflict with location adds injury")
    assert_eq(p.injuries[1].location, "left arm", "injury stores body location")
    assert_eq(p.injuries[1].type, "bleeding", "injury type is bleeding")
    assert_eq(p.injuries[1].source, "self-inflicted", "source is self-inflicted")
end

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", nil)
    end)
    assert_nil(p.injuries[1].location, "inflict without location stores nil")
end

---------------------------------------------------------------------------
-- Tests: inflict with override_damage
---------------------------------------------------------------------------
print("\n=== inflict — override damage from weapon ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "dagger", "right arm", 8)
    end)
    assert_eq(p.injuries[1].damage, 8, "override_damage overrides definition initial_damage")
    assert_eq(p.injuries[1].location, "right arm", "location set with override_damage")
end

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "minor-cut", "knife", "left hand", 4)
    end)
    assert_eq(p.injuries[1].damage, 4, "minor-cut override_damage works")
    assert_eq(p.injuries[1].damage_per_tick, 0, "minor-cut still has 0 damage_per_tick")
end

---------------------------------------------------------------------------
-- Tests: list shows body location
---------------------------------------------------------------------------
print("\n=== list — injuries verb shows location ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local output = capture_print(function() injury_mod.list(p) end)
    assert_true(output:find("left arm"), "list output includes body location")
    assert_true(output:find("bleeding"), "list output includes injury name")
end

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "torso")
        injury_mod.inflict(p, "minor-cut", "test", "right hand")
    end)
    local output = capture_print(function() injury_mod.list(p) end)
    assert_true(output:find("torso"), "list shows torso location")
    assert_true(output:find("right hand"), "list shows right hand location")
end

---------------------------------------------------------------------------
-- Tests: find_by_id
---------------------------------------------------------------------------
print("\n=== find_by_id — find injury by instance ID ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "minor-cut", "test", "right hand")
    end)
    local inj, idx = injury_mod.find_by_id(p, p.injuries[1].id)
    assert_true(inj ~= nil, "find_by_id finds first injury")
    assert_eq(idx, 1, "find_by_id returns correct index")
    assert_eq(inj.type, "bleeding", "find_by_id returns correct injury")

    local miss = injury_mod.find_by_id(p, "nonexistent-999")
    assert_nil(miss, "find_by_id returns nil for unknown ID")
end

---------------------------------------------------------------------------
-- Tests: resolve_target
---------------------------------------------------------------------------
print("\n=== resolve_target — injury targeting ===")
setup()

do
    -- Auto-target: single treatable injury
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local injury, err = injury_mod.resolve_target(p, nil, {"bleeding"})
    assert_true(injury ~= nil, "auto-target works with single treatable injury")
    assert_eq(err, "", "no error on auto-target")
    assert_eq(injury.type, "bleeding", "auto-target returns the bleeding injury")
end

do
    -- Auto-target: multiple treatable injuries → disambiguation
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "bleeding", "test", "right arm")
    end)
    local injury, err = injury_mod.resolve_target(p, nil, {"bleeding"})
    assert_nil(injury, "auto-target fails with multiple treatable injuries")
    assert_true(err:find("Which injury"), "disambiguation prompt shown")
end

do
    -- Target by body location
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "bleeding", "test", "right leg")
    end)
    local injury, err = injury_mod.resolve_target(p, "left arm", {"bleeding"})
    assert_true(injury ~= nil, "target by location finds injury")
    assert_eq(injury.location, "left arm", "target by location returns correct injury")
end

do
    -- Target by injury type
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "minor-cut", "test", "right hand")
    end)
    local injury, err = injury_mod.resolve_target(p, "bleeding", {"bleeding", "minor-cut"})
    assert_true(injury ~= nil, "target by type finds injury")
    assert_eq(injury.type, "bleeding", "target by type returns correct injury")
end

do
    -- Target by ordinal
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "bleeding", "test", "right arm")
    end)
    local injury, err = injury_mod.resolve_target(p, "second", {"bleeding"})
    assert_true(injury ~= nil, "target by ordinal finds injury")
    assert_eq(injury.location, "right arm", "target by ordinal returns second injury")
end

do
    -- No injuries
    local p = fresh_player()
    local injury, err = injury_mod.resolve_target(p, nil, {"bleeding"})
    assert_nil(injury, "resolve_target returns nil with no injuries")
    assert_true(err:find("don't have any injuries"), "appropriate error for no injuries")
end

do
    -- No treatable injuries (already treated)
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    p.injuries[1].treatment = { type = "bandage" }
    local injury, err = injury_mod.resolve_target(p, nil, {"bleeding"})
    assert_nil(injury, "resolve_target skips already-treated injuries")
end

do
    -- Target by display name substring
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local injury, err = injury_mod.resolve_target(p, "bleeding", {"bleeding"})
    assert_true(injury ~= nil, "target by display name substring works")
end

---------------------------------------------------------------------------
-- Tests: apply_treatment (dual binding)
---------------------------------------------------------------------------
print("\n=== apply_treatment — bandage dual binding ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local bandage = fresh_bandage()
    local injury = p.injuries[1]

    injury_mod.apply_treatment(p, bandage, injury)

    assert_eq(bandage.applied_to, injury.id, "bandage.applied_to points to injury")
    assert_eq(bandage._state, "applied", "bandage FSM transitions to applied")
    assert_true(injury.treatment ~= nil, "injury has treatment reference")
    assert_eq(injury.treatment.type, "bandage", "injury.treatment.type is bandage")
    assert_eq(injury.treatment.item_id, "bandage", "injury.treatment.item_id is bandage")
    assert_eq(injury.treatment.healing_boost, 2, "injury.treatment.healing_boost is 2")
    assert_eq(injury._state, "treated", "injury FSM transitions to treated")
    assert_eq(injury.damage_per_tick, 0, "injury drain stops (damage_per_tick = 0)")
end

do
    -- Bandage on minor-cut
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "minor-cut", "test", "right hand")
    end)
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])
    assert_eq(p.injuries[1]._state, "treated", "minor-cut transitions to treated")
    assert_eq(bandage._state, "applied", "bandage applied to minor-cut")
end

do
    -- Health check: bandaged injury stops draining
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local before_health = injury_mod.compute_health(p)
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])

    -- Tick should NOT increase damage
    capture_print(function() injury_mod.tick(p) end)
    local after_health = injury_mod.compute_health(p)
    assert_eq(p.injuries[1].damage_per_tick, 0, "bandaged injury has 0 drain")
    assert_eq(injury_mod.compute_total_drain(p), 0, "total drain is 0 with bandage")
end

---------------------------------------------------------------------------
-- Tests: remove_treatment
---------------------------------------------------------------------------
print("\n=== remove_treatment — bandage removal ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])

    -- Now remove
    local ok, err = injury_mod.remove_treatment(p, bandage)
    assert_true(ok, "remove_treatment succeeds")
    assert_nil(bandage.applied_to, "bandage.applied_to cleared")
    assert_eq(bandage._state, "soiled", "bandage transitions to soiled")
    assert_nil(p.injuries[1].treatment, "injury.treatment cleared")
    assert_eq(p.injuries[1]._state, "active", "injury reverts to active state")
    assert_eq(p.injuries[1].damage_per_tick, 5, "injury drain resumes")
end

do
    -- Remove bandage that isn't applied
    local bandage = fresh_bandage()
    local p = fresh_player()
    local ok, err = injury_mod.remove_treatment(p, bandage)
    assert_false(ok, "remove_treatment fails if not applied")
    assert_true(err:find("isn't applied"), "error message for non-applied bandage")
end

do
    -- Remove bandage when injury already healed (orphaned reference)
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])
    -- Simulate injury healing (remove from array)
    p.injuries = {}

    local ok = injury_mod.remove_treatment(p, bandage)
    assert_true(ok, "remove_treatment succeeds even when injury is gone")
    assert_eq(bandage._state, "soiled", "bandage transitions to soiled on orphan removal")
    assert_nil(bandage.applied_to, "bandage.applied_to cleared on orphan removal")
end

---------------------------------------------------------------------------
-- Tests: bandage on ONE injury at a time
---------------------------------------------------------------------------
print("\n=== bandage exclusivity — one injury at a time ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "bleeding", "test", "right arm")
    end)
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])

    -- Bandage is now applied — applied_to is set
    assert_true(bandage.applied_to ~= nil, "bandage is bound to first injury")

    -- The second injury should NOT be targetable by this same bandage
    -- (because we'd check applied_to before calling apply_treatment in the verb handler)
    -- Here we verify the data model supports this check
    assert_true(bandage.applied_to == p.injuries[1].id, "bandage bound to injury 1, not 2")
end

---------------------------------------------------------------------------
-- Tests: compute_total_drain
---------------------------------------------------------------------------
print("\n=== compute_total_drain — sum of active drain ===")
setup()

do
    local p = fresh_player()
    assert_eq(injury_mod.compute_total_drain(p), 0, "no injuries = 0 drain")
end

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    assert_eq(injury_mod.compute_total_drain(p), 5, "one bleeding = 5 drain")
end

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "bleeding", "test", "right arm")
    end)
    assert_eq(injury_mod.compute_total_drain(p), 10, "two bleedings = 10 drain")

    -- Bandage one
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])
    assert_eq(injury_mod.compute_total_drain(p), 5, "one bandaged + one untreated = 5 drain")
end

---------------------------------------------------------------------------
-- Tests: weapon damage encoding
---------------------------------------------------------------------------
print("\n=== weapon damage encoding — on_stab/on_cut/on_slash profiles ===")
setup()

do
    -- Simulate what the verb handler does: read weapon profile, inflict injury
    local dagger = {
        id = "silver-dagger",
        on_stab = {
            damage = 8,
            injury_type = "bleeding",
            description = "You drive the silver dagger into your %s. Blood wells up immediately.",
        },
        on_cut = {
            damage = 4,
            injury_type = "minor-cut",
            description = "You draw the dagger's edge across your %s. A thin red line appears.",
        },
        on_slash = {
            damage = 6,
            injury_type = "bleeding",
            description = "You slash the dagger across your %s. The wound opens wide.",
        },
    }

    -- Read on_stab profile
    local profile = dagger.on_stab
    assert_eq(profile.damage, 8, "dagger on_stab damage is 8")
    assert_eq(profile.injury_type, "bleeding", "dagger on_stab injury_type is bleeding")
    assert_true(profile.description:find("%%s"), "dagger on_stab description has %s placeholder")

    -- Inflict with the profile's values
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, profile.injury_type, "silver-dagger", "left arm", profile.damage)
    end)
    assert_eq(p.injuries[1].damage, 8, "weapon damage applied as initial damage")
    assert_eq(p.injuries[1].type, "bleeding", "weapon injury_type determines injury type")
    assert_eq(p.injuries[1].location, "left arm", "body location stored")

    -- String substitution works
    local msg = string.format(profile.description, "left arm")
    assert_true(msg:find("left arm"), "description %s replaced with body area")
end

do
    -- Read on_cut profile
    local knife = {
        id = "knife",
        on_cut = {
            damage = 3,
            injury_type = "minor-cut",
            description = "You nick your %s with the knife.",
        },
    }
    local profile = knife.on_cut
    assert_eq(profile.damage, 3, "knife on_cut damage is 3")
    assert_eq(profile.injury_type, "minor-cut", "knife on_cut injury_type is minor-cut")
end

do
    -- Weapon without on_slash returns nil
    local knife = { id = "knife", on_stab = { damage = 5 }, on_cut = { damage = 3 } }
    assert_nil(knife.on_slash, "knife has no on_slash profile")
end

---------------------------------------------------------------------------
-- Tests: body area damage modifiers (engine-side)
---------------------------------------------------------------------------
print("\n=== body area damage modifiers ===")
setup()

do
    local mods = {
        ["left arm"]   = 1.0,
        ["right arm"]  = 1.0,
        ["left hand"]  = 1.0,
        ["right hand"] = 1.0,
        ["left leg"]   = 1.0,
        ["right leg"]  = 1.0,
        ["torso"]      = 1.5,
        ["stomach"]    = 1.5,
        ["head"]       = 2.0,
    }

    -- Torso hit: 8 * 1.5 = 12
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "torso", math.floor(8 * mods["torso"]))
    end)
    assert_eq(p.injuries[1].damage, 12, "torso modifier: 8 * 1.5 = 12")

    -- Head hit: 8 * 2.0 = 16
    setup()
    p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "head", math.floor(8 * mods["head"]))
    end)
    assert_eq(p.injuries[1].damage, 16, "head modifier: 8 * 2.0 = 16")

    -- Arm hit: 8 * 1.0 = 8
    setup()
    p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm", math.floor(8 * mods["left arm"]))
    end)
    assert_eq(p.injuries[1].damage, 8, "arm modifier: 8 * 1.0 = 8")
end

---------------------------------------------------------------------------
-- Tests: random body area selection (statistical)
---------------------------------------------------------------------------
print("\n=== random body area — weighted selection ===")
setup()

do
    -- Run many trials and check distribution is weighted correctly
    local BODY_AREA_WEIGHTS = {
        { area = "left arm",   weight = 3 },
        { area = "right arm",  weight = 3 },
        { area = "left hand",  weight = 2 },
        { area = "right hand", weight = 2 },
        { area = "left leg",   weight = 2 },
        { area = "right leg",  weight = 2 },
        { area = "torso",      weight = 1 },
        { area = "stomach",    weight = 1 },
    }
    local TOTAL_WEIGHT = 16

    local function random_body_area()
        local roll = math.random(1, TOTAL_WEIGHT)
        local acc = 0
        for _, entry in ipairs(BODY_AREA_WEIGHTS) do
            acc = acc + entry.weight
            if roll <= acc then return entry.area end
        end
        return "left arm"
    end

    math.randomseed(42)  -- Deterministic for testing
    local counts = {}
    local trials = 1000
    for i = 1, trials do
        local area = random_body_area()
        counts[area] = (counts[area] or 0) + 1
    end

    -- Arms should be most common (weight 3 each = ~18.75% each)
    local arm_total = (counts["left arm"] or 0) + (counts["right arm"] or 0)
    assert_true(arm_total > 250, "arms are most common targets (" .. arm_total .. "/1000)")

    -- Head should never appear in random selection (weight 0)
    assert_nil(counts["head"], "head never selected randomly (weight 0)")

    -- Torso + stomach should be least common (weight 1 each = ~6.25% each)
    local body_total = (counts["torso"] or 0) + (counts["stomach"] or 0)
    assert_true(body_total < arm_total, "torso+stomach less common than arms")

    -- All areas should appear at least once in 1000 trials
    for _, entry in ipairs(BODY_AREA_WEIGHTS) do
        if entry.weight > 0 then
            assert_true((counts[entry.area] or 0) > 0,
                entry.area .. " appears in random selection")
        end
    end
end

---------------------------------------------------------------------------
-- Tests: format_injury_options
---------------------------------------------------------------------------
print("\n=== format_injury_options — disambiguation display ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
        injury_mod.inflict(p, "bleeding", "test", "right leg")
    end)

    local output = injury_mod.format_injury_options(p.injuries)
    assert_true(output:find("Which injury"), "options header shown")
    assert_true(output:find("left arm"), "left arm option shown")
    assert_true(output:find("right leg"), "right leg option shown")
    assert_true(output:find("1%."), "first option numbered")
    assert_true(output:find("2%."), "second option numbered")
end

---------------------------------------------------------------------------
-- Tests: full bandage lifecycle
---------------------------------------------------------------------------
print("\n=== full lifecycle — inflict → bandage → heal ===")
setup()

do
    local p = fresh_player()
    p.max_health = 100

    -- Step 1: Inflict a bleeding wound
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "self-inflicted", "left arm", 8)
    end)
    assert_eq(#p.injuries, 1, "step 1: injury inflicted")
    assert_eq(injury_mod.compute_health(p), 92, "step 1: health = 100 - 8 = 92")
    assert_eq(injury_mod.compute_total_drain(p), 5, "step 1: drain = 5/tick")

    -- Step 2: Tick without treatment (health drops)
    capture_print(function() injury_mod.tick(p) end)
    assert_eq(p.injuries[1].damage, 13, "step 2: damage = 8 + 5 = 13")
    assert_eq(injury_mod.compute_health(p), 87, "step 2: health = 100 - 13 = 87")

    -- Step 3: Apply bandage
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])
    assert_eq(p.injuries[1].damage_per_tick, 0, "step 3: drain stopped")
    assert_eq(p.injuries[1]._state, "treated", "step 3: injury treated")
    assert_eq(bandage._state, "applied", "step 3: bandage applied")

    -- Step 4: Tick with treatment (health stable, no additional damage)
    local dmg_before = p.injuries[1].damage
    capture_print(function() injury_mod.tick(p) end)
    assert_eq(p.injuries[1].damage, dmg_before, "step 4: damage frozen while bandaged")
    assert_eq(injury_mod.compute_total_drain(p), 0, "step 4: total drain = 0")

    -- Step 5: Remove bandage prematurely
    injury_mod.remove_treatment(p, bandage)
    assert_eq(bandage._state, "soiled", "step 5: bandage soiled")
    assert_eq(p.injuries[1]._state, "active", "step 5: injury reverted to active")
    assert_eq(p.injuries[1].damage_per_tick, 5, "step 5: drain resumed")

    -- Step 6: Tick after removal (draining again)
    capture_print(function() injury_mod.tick(p) end)
    assert_true(p.injuries[1].damage > dmg_before, "step 6: damage increasing again")
end

---------------------------------------------------------------------------
-- Tests: treated injury shows [treated] in list
---------------------------------------------------------------------------
print("\n=== list — treated injury marker ===")
setup()

do
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "test", "left arm")
    end)
    local bandage = fresh_bandage()
    injury_mod.apply_treatment(p, bandage, p.injuries[1])

    local output = capture_print(function() injury_mod.list(p) end)
    assert_true(output:find("%[treated%]"), "list shows [treated] marker for bandaged injury")
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
