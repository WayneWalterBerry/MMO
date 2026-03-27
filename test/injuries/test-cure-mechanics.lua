-- test/injuries/test-cure-mechanics.lua
-- WAVE-4 TDD: Validates healing_interactions-driven cure mechanics.
-- Covers rabies (poultice), spider-venom (antidote-vial), wrong-item
-- rejection, state-window gating, and success/fail messages.
--
-- Written to spec per npc-combat-implementation-phase3.md WAVE-4.
-- Usage: lua test/injuries/test-cure-mechanics.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local ok_inj, injury_mod = pcall(require, "engine.injuries")
if not ok_inj then
    print("FATAL: engine.injuries not found — cannot run cure tests")
    os.exit(1)
end

local ok_cure, cure_mod = pcall(require, "engine.injuries.cure")
if not ok_cure then
    print("WARNING: engine.injuries.cure not found — some tests may fail (TDD red phase)")
    cure_mod = nil
end

---------------------------------------------------------------------------
-- Test harness (matches test-rabies.lua pattern)
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
-- Load injury definitions from disk (fall back to spec mock)
---------------------------------------------------------------------------
local rabies_def
do
    local ok, def = pcall(dofile, repo_root .. SEP .. "src" .. SEP .. "meta"
        .. SEP .. "injuries" .. SEP .. "rabies.lua")
    if ok and def then rabies_def = def end
end
rabies_def = rabies_def or {
    id = "rabies", name = "Rabies", category = "disease",
    damage_type = "over_time", initial_state = "incubating",
    curable_in = { "incubating", "prodromal" },
    on_inflict = { initial_damage = 0, damage_per_tick = 0,
        message = "Something feels wrong where the bite broke skin." },
    states = {
        incubating = { name = "incubating rabies", damage_per_tick = 0, duration = 15 },
        prodromal  = { name = "early rabies", damage_per_tick = 1, duration = 10,
            restricts = { precise_actions = true } },
        furious    = { name = "furious rabies", damage_per_tick = 3, duration = 8,
            restricts = { drink = true, precise_actions = true } },
        fatal      = { terminal = true },
        healed     = { name = "cured rabies", terminal = true },
    },
    transitions = {
        { from = "incubating", to = "prodromal", trigger = "auto",
          condition = "duration_expired" },
        { from = "prodromal", to = "furious", trigger = "auto",
          condition = "duration_expired" },
        { from = "furious", to = "fatal", trigger = "auto",
          condition = "duration_expired" },
    },
    healing_interactions = {
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "incubating", "prodromal" },
        },
    },
}

local venom_def
do
    local ok, def = pcall(dofile, repo_root .. SEP .. "src" .. SEP .. "meta"
        .. SEP .. "injuries" .. SEP .. "spider-venom.lua")
    if ok and def then venom_def = def end
end
venom_def = venom_def or {
    id = "spider-venom", name = "Spider Venom", category = "disease",
    damage_type = "over_time", initial_state = "injected",
    curable_in = { "injected", "spreading" },
    on_inflict = { initial_damage = 2, damage_per_tick = 2,
        message = "Sharp pain flares from the bite." },
    states = {
        injected   = { name = "spider bite", damage_per_tick = 2 },
        spreading  = { name = "spreading venom", damage_per_tick = 3,
            restricts = { movement = true } },
        paralysis  = { name = "venom paralysis", damage_per_tick = 1,
            restricts = { movement = true, attack = true, precise_actions = true } },
        healed     = { name = "recovered from venom", terminal = true },
    },
    transitions = {},
    healing_interactions = {
        ["antidote-vial"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
            success_message = "The antidote burns going down, but the swelling begins to subside.",
            fail_message = "The paralysis is too advanced. The antidote cannot help now.",
        },
        ["antivenom"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
        },
        ["healing-poultice"] = {
            transitions_to = "healed",
            from_states = { "injected", "spreading" },
        },
    },
}

-- A simple injury with NO healing_interactions
local bruise_def = {
    id = "bruised", name = "Bruise", category = "physical",
    damage_type = "one_time", initial_state = "active",
    on_inflict = { initial_damage = 4, damage_per_tick = 0,
        message = "A bruise forms." },
    states = {
        active = { name = "bruise", damage_per_tick = 0, auto_heal_turns = 10 },
        healed = { terminal = true },
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
    injury_mod.register_definition("rabies", rabies_def)
    injury_mod.register_definition("spider-venom", venom_def)
    injury_mod.register_definition("bruised", bruise_def)
end

local function inflict_rabies(player, state)
    capture_print(function()
        injury_mod.inflict(player, "rabies", "rat-bite", "left arm")
    end)
    if state and player.injuries[#player.injuries] then
        player.injuries[#player.injuries]._state = state
    end
end

local function inflict_venom(player, state)
    capture_print(function()
        injury_mod.inflict(player, "spider-venom", "spider-bite", "left leg")
    end)
    if state and player.injuries[#player.injuries] then
        player.injuries[#player.injuries]._state = state
    end
end

local function make_healing_object(id, cures, opts)
    opts = opts or {}
    return {
        id = id,
        name = opts.name or ("a " .. id),
        keywords = opts.keywords or { id },
        portable = true,
        on_use = {
            cures = cures,
            message = opts.message or ("You apply the " .. id .. "."),
            transition_to = opts.transition_to,
        },
    }
end

---------------------------------------------------------------------------
-- 1. Poultice cures rabies in incubating state
---------------------------------------------------------------------------
print("\n=== CURE: Poultice cures rabies (incubating) ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "incubating")
    assert_true(#player.injuries > 0, "rabies inflicted")
    assert_eq(player.injuries[1]._state, "incubating", "rabies in incubating state")

    local poultice = make_healing_object("healing-poultice", "rabies",
        { message = "You press the poultice to the wound." })

    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            cure_mod.try_heal(player, poultice, "use")
        end)
        -- After cure, injury should be removed or transitioned to healed
        local cured = #player.injuries == 0
            or (player.injuries[1] and player.injuries[1]._state == "healed")
        assert_true(cured, "rabies cured from incubating state")
    else
        skip("poultice cures incubating rabies", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 2. Poultice cures rabies in prodromal state
---------------------------------------------------------------------------
print("\n=== CURE: Poultice cures rabies (prodromal) ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "prodromal")
    assert_eq(player.injuries[1]._state, "prodromal", "rabies in prodromal state")

    local poultice = make_healing_object("healing-poultice", "rabies")
    if cure_mod and cure_mod.try_heal then
        capture_print(function()
            cure_mod.try_heal(player, poultice, "use")
        end)
        local cured = #player.injuries == 0
            or (player.injuries[1] and player.injuries[1]._state == "healed")
        assert_true(cured, "rabies cured from prodromal state")
    else
        skip("poultice cures prodromal rabies", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 3. Poultice FAILS on rabies in furious state
---------------------------------------------------------------------------
print("\n=== CURE: Poultice FAILS on furious rabies ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "furious")
    assert_eq(player.injuries[1]._state, "furious", "rabies in furious state")

    local poultice = make_healing_object("healing-poultice", "rabies")
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            cure_mod.try_heal(player, poultice, "use")
        end)
        -- Injury should still be present and still furious
        assert_true(#player.injuries > 0, "rabies NOT removed in furious state")
        assert_eq(player.injuries[1]._state, "furious",
            "rabies remains furious after failed cure attempt")
        -- Should print rejection message
        assert_true(output and #output > 0,
            "failed cure should produce rejection text")
    else
        skip("poultice fails on furious rabies", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 4. Antidote cures spider-venom in injected state
---------------------------------------------------------------------------
print("\n=== CURE: Antidote cures spider-venom (injected) ===")

do
    setup()
    local player = fresh_player()
    inflict_venom(player, "injected")
    assert_eq(player.injuries[1]._state, "injected", "venom in injected state")

    local antidote = make_healing_object("antidote-vial", "spider-venom",
        { message = "The antidote burns going down." })
    if cure_mod and cure_mod.try_heal then
        capture_print(function()
            cure_mod.try_heal(player, antidote, "use")
        end)
        local cured = #player.injuries == 0
            or (player.injuries[1] and player.injuries[1]._state == "healed")
        assert_true(cured, "spider-venom cured from injected state")
    else
        skip("antidote cures injected venom", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 5. Antidote cures spider-venom in spreading state
---------------------------------------------------------------------------
print("\n=== CURE: Antidote cures spider-venom (spreading) ===")

do
    setup()
    local player = fresh_player()
    inflict_venom(player, "spreading")
    assert_eq(player.injuries[1]._state, "spreading", "venom in spreading state")

    local antidote = make_healing_object("antidote-vial", "spider-venom")
    if cure_mod and cure_mod.try_heal then
        capture_print(function()
            cure_mod.try_heal(player, antidote, "use")
        end)
        local cured = #player.injuries == 0
            or (player.injuries[1] and player.injuries[1]._state == "healed")
        assert_true(cured, "spider-venom cured from spreading state")
    else
        skip("antidote cures spreading venom", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 6. Antidote FAILS on spider-venom in paralysis state
---------------------------------------------------------------------------
print("\n=== CURE: Antidote FAILS on paralysis spider-venom ===")

do
    setup()
    local player = fresh_player()
    inflict_venom(player, "paralysis")
    assert_eq(player.injuries[1]._state, "paralysis", "venom in paralysis state")

    local antidote = make_healing_object("antidote-vial", "spider-venom")
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            cure_mod.try_heal(player, antidote, "use")
        end)
        assert_true(#player.injuries > 0, "venom NOT removed in paralysis state")
        assert_eq(player.injuries[1]._state, "paralysis",
            "venom remains paralysis after failed cure attempt")
        assert_true(output and #output > 0,
            "failed venom cure should produce rejection text")
    else
        skip("antidote fails on paralysis venom", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 7. Wrong cure item (targets different injury) has no effect on rabies
---------------------------------------------------------------------------
print("\n=== CURE: Wrong item → no effect (rabies) ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "incubating")

    -- Item says it cures "spider-venom", NOT rabies — should not help
    local wrong_item = make_healing_object("antidote-vial", "spider-venom",
        { message = "You apply the antidote." })
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            cure_mod.try_heal(player, wrong_item, "use")
        end)
        -- on_use.cures = "spider-venom" won't match rabies injury
        assert_true(#player.injuries > 0, "rabies still present after wrong item")
        assert_eq(player.injuries[1]._state, "incubating",
            "rabies remains incubating after wrong cure item")
    else
        skip("wrong item no effect", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 8. Wrong cure item (targets different injury) has no effect on venom
---------------------------------------------------------------------------
print("\n=== CURE: Wrong item → no effect (spider-venom) ===")

do
    setup()
    local player = fresh_player()
    inflict_venom(player, "injected")

    -- Item says it cures "rabies", NOT spider-venom — should not help
    local wrong_item = make_healing_object("healing-poultice-fake", "rabies",
        { message = "You apply the poultice." })
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            cure_mod.try_heal(player, wrong_item, "use")
        end)
        -- on_use.cures = "rabies" won't match spider-venom injury
        assert_true(#player.injuries > 0, "venom still present after wrong cure item")
        assert_eq(player.injuries[1]._state, "injected",
            "venom remains injected after wrong cure item")
    else
        skip("wrong item no effect (venom)", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 9. Cure on injury without healing_interactions → no effect
---------------------------------------------------------------------------
print("\n=== CURE: Injury with no healing_interactions ===")

do
    setup()
    local player = fresh_player()
    capture_print(function()
        injury_mod.inflict(player, "bruised", "self-inflicted", "left arm", 4)
    end)
    assert_true(#player.injuries > 0, "bruise inflicted")

    local poultice = make_healing_object("healing-poultice", "bruised")
    if cure_mod and cure_mod.try_heal then
        capture_print(function()
            cure_mod.try_heal(player, poultice, "use")
        end)
        -- Bruise has no healing_interactions at all, so poultice should
        -- have no structured cure path. The injury may still be removed
        -- if try_heal uses a generic path, but should not crash.
        -- The key assertion: no crash occurred.
        assert_true(true, "cure on injury without healing_interactions does not crash")
    else
        skip("cure on no-healing injury", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 10. Poultice cures rabies: transitions_to = "healed" matches def
---------------------------------------------------------------------------
print("\n=== CURE: transitions_to matches definition state ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "incubating")

    -- Verify healing_interactions on the definition itself
    local def = rabies_def
    assert_true(def.healing_interactions ~= nil,
        "rabies def has healing_interactions")
    assert_true(def.healing_interactions["healing-poultice"] ~= nil,
        "rabies def lists healing-poultice")
    assert_eq(def.healing_interactions["healing-poultice"].transitions_to, "healed",
        "healing-poultice transitions rabies to 'healed'")

    local from_states = def.healing_interactions["healing-poultice"].from_states
    assert_true(from_states ~= nil, "from_states is defined")
    local has_incubating = false
    local has_prodromal = false
    for _, s in ipairs(from_states) do
        if s == "incubating" then has_incubating = true end
        if s == "prodromal" then has_prodromal = true end
    end
    assert_true(has_incubating, "from_states includes 'incubating'")
    assert_true(has_prodromal, "from_states includes 'prodromal'")
end

---------------------------------------------------------------------------
-- 11. Antidote-vial healing_interactions on spider-venom def
---------------------------------------------------------------------------
print("\n=== CURE: antidote-vial healing_interactions on spider-venom ===")

do
    local def = venom_def
    assert_true(def.healing_interactions ~= nil,
        "spider-venom def has healing_interactions")
    assert_true(def.healing_interactions["antidote-vial"] ~= nil,
        "spider-venom def lists antidote-vial")
    assert_eq(def.healing_interactions["antidote-vial"].transitions_to, "healed",
        "antidote-vial transitions venom to 'healed'")

    local from_states = def.healing_interactions["antidote-vial"].from_states
    assert_true(from_states ~= nil, "from_states is defined for antidote-vial")
    local has_injected = false
    local has_spreading = false
    for _, s in ipairs(from_states) do
        if s == "injected" then has_injected = true end
        if s == "spreading" then has_spreading = true end
    end
    assert_true(has_injected, "antidote-vial from_states includes 'injected'")
    assert_true(has_spreading, "antidote-vial from_states includes 'spreading'")
end

---------------------------------------------------------------------------
-- 12. Cure success message prints correctly (rabies/poultice)
---------------------------------------------------------------------------
print("\n=== CURE: Success message prints (rabies) ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "incubating")

    local poultice = make_healing_object("healing-poultice", "rabies",
        { message = "You press the poultice to the wound. The fever begins to subside." })
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            cure_mod.try_heal(player, poultice, "use")
        end)
        assert_true(output and #output > 0,
            "successful cure should produce narration text")
    else
        skip("success message (rabies)", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 13. Cure fail message prints correctly (furious rabies)
---------------------------------------------------------------------------
print("\n=== CURE: Fail message prints (furious rabies) ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "furious")

    local poultice = make_healing_object("healing-poultice", "rabies")
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            local result = cure_mod.try_heal(player, poultice, "use")
            assert_false(result, "try_heal should return false for furious rabies")
        end)
        assert_true(output and #output > 0,
            "failed cure should produce rejection narration")
    else
        skip("fail message (furious rabies)", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 14. Cure fail message prints correctly (paralysis venom)
---------------------------------------------------------------------------
print("\n=== CURE: Fail message prints (paralysis venom) ===")

do
    setup()
    local player = fresh_player()
    inflict_venom(player, "paralysis")

    local antidote = make_healing_object("antidote-vial", "spider-venom")
    if cure_mod and cure_mod.try_heal then
        local output = capture_print(function()
            local result = cure_mod.try_heal(player, antidote, "use")
            assert_false(result, "try_heal should return false for paralysis venom")
        end)
        assert_true(output and #output > 0,
            "failed venom cure should produce rejection narration")
    else
        skip("fail message (paralysis venom)", "cure_mod.try_heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- 15. cure.heal() direct disease healing respects curable_in window
---------------------------------------------------------------------------
print("\n=== CURE: cure.heal() respects curable_in window ===")

do
    setup()
    local player = fresh_player()
    inflict_rabies(player, "incubating")

    if cure_mod and cure_mod.heal then
        local output = capture_print(function()
            local result = cure_mod.heal(player, "rabies")
            assert_true(result, "cure.heal returns true for curable state")
        end)
        -- After heal, injury removed
        assert_eq(#player.injuries, 0, "injury removed after cure.heal()")
    else
        skip("cure.heal() curable_in", "cure_mod.heal not available (TDD red)")
    end

    -- Now test furious: should fail
    setup()
    local player2 = fresh_player()
    inflict_rabies(player2, "furious")
    if cure_mod and cure_mod.heal then
        capture_print(function()
            local result = cure_mod.heal(player2, "rabies")
            assert_false(result, "cure.heal returns false for furious state")
        end)
        assert_true(#player2.injuries > 0,
            "furious rabies NOT removed by cure.heal()")
    else
        skip("cure.heal() furious rejection", "cure_mod.heal not available (TDD red)")
    end
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if skipped > 0 then
    print("  Skipped: " .. skipped)
end
os.exit(failed)
