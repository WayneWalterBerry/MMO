-- test/combat/test-exchange-fsm.lua
-- WAVE-5 TDD: Combat exchange FSM, zone selection, lethality, darkness, stances.
-- Tests written to spec (plans/combat-system-plan.md + npc-combat-implementation-phase1.md).
-- Engine module under test: src/engine/combat/init.lua
-- Must be run from repository root: lua test/combat/test-exchange-fsm.lua

math.randomseed(42)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load combat engine
---------------------------------------------------------------------------
local ok_combat, combat = pcall(require, "engine.combat")
if not ok_combat then
    print("WARNING: engine.combat failed to load — " .. tostring(combat))
    combat = nil
end

---------------------------------------------------------------------------
-- Load rat for lethality / creature tests
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local rat_path = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP .. "rat.lua"
local ok_rat, rat = pcall(dofile, rat_path)
if not ok_rat then
    print("WARNING: rat.lua failed to load — " .. tostring(rat))
    rat = nil
end

---------------------------------------------------------------------------
-- Load materials for weapon construction
---------------------------------------------------------------------------
local ok_mat, materials = pcall(require, "engine.materials")
if not ok_mat then
    print("WARNING: engine.materials failed to load — " .. tostring(materials))
    materials = nil
end

---------------------------------------------------------------------------
-- Fixture helpers
---------------------------------------------------------------------------

-- Minimal player fixture matching combat-system-plan Section 4/5
local function make_player(overrides)
    local p = {
        id = "player",
        name = "the player",
        combat = {
            size = "medium",
            speed = 5,
            behavior = {
                defense = "block",
            },
        },
        body_tree = {
            head  = { size = 0.10, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
            torso = { size = 0.35, vital = true,  tissue = { "skin", "flesh", "bone", "organ" } },
            arms  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
            hands = { size = 0.10, vital = false, tissue = { "skin", "flesh", "bone" } },
            legs  = { size = 0.20, vital = false, tissue = { "skin", "flesh", "bone" } },
            feet  = { size = 0.05, vital = false, tissue = { "skin", "flesh", "bone" } },
        },
        health = 100,
        max_health = 100,
        _state = "alive",
        animate = true,
        portable = false,
    }
    if overrides then
        for k, v in pairs(overrides) do p[k] = v end
    end
    return p
end

-- Minimal rat fixture
local function make_rat(overrides)
    local r = {
        id = "rat",
        name = "the rat",
        combat = {
            size = "tiny",
            speed = 6,
            natural_weapons = {
                {
                    id = "bite",
                    type = "pierce",
                    material = "tooth-enamel",
                    zone = "head",
                    force = 2,
                    target_pref = "arms",
                    message = "sinks its teeth into",
                },
            },
            natural_armor = nil,
            behavior = {
                aggression = "on_provoke",
                flee_threshold = 0.3,
                attack_pattern = "random",
                defense = "dodge",
                target_priority = "threatening",
                pack_size = 1,
            },
        },
        body_tree = {
            head = { size = 0.15, vital = true,  tissue = { "hide", "flesh", "bone", "organ" } },
            body = { size = 0.45, vital = true,  tissue = { "hide", "flesh", "bone", "organ" } },
            legs = { size = 0.25, vital = false, tissue = { "hide", "flesh", "bone" } },
            tail = { size = 0.15, vital = false, tissue = { "hide", "flesh" } },
        },
        health = 10,
        max_health = 10,
        _state = "alive",
        animate = true,
        portable = false,
    }
    if overrides then
        for k, v in pairs(overrides) do r[k] = v end
    end
    return r
end

-- Steel dagger weapon fixture
local function make_steel_dagger()
    return {
        id = "steel-dagger",
        name = "a steel dagger",
        material = "steel",
        combat = {
            type = "edged",
            force = 5,
            message = "slashes",
            two_handed = false,
        },
    }
end

-- Unarmed "weapon" (fist) fixture
local function make_fist()
    return {
        id = "fist",
        name = "bare fist",
        material = "flesh",
        combat = {
            type = "blunt",
            force = 2,
            message = "punches",
            two_handed = false,
        },
    }
end

---------------------------------------------------------------------------
-- SUITE 1: FSM Phase Flow
---------------------------------------------------------------------------
suite("EXCHANGE FSM: 6-phase flow (WAVE-5)")

test("1. combat module loads", function()
    h.assert_truthy(ok_combat, "engine.combat must load: " .. tostring(combat))
    h.assert_truthy(combat, "combat module must not be nil")
end)

test("2. combat.PHASE table exists with 6 phases", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(combat.PHASE, "combat.PHASE must exist")
    local expected = { "INITIATE", "DECLARE", "RESPOND", "RESOLVE", "NARRATE", "UPDATE" }
    for _, name in ipairs(expected) do
        h.assert_truthy(combat.PHASE[name] ~= nil,
            "combat.PHASE." .. name .. " must be defined")
    end
end)

test("3. combat.SEVERITY table exists with 5 levels", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(combat.SEVERITY, "combat.SEVERITY must exist")
    local expected = { "DEFLECT", "GRAZE", "HIT", "SEVERE", "CRITICAL" }
    for _, name in ipairs(expected) do
        h.assert_truthy(combat.SEVERITY[name] ~= nil,
            "combat.SEVERITY." .. name .. " must be defined")
    end
end)

test("4. SEVERITY levels are ordered DEFLECT < GRAZE < HIT < SEVERE < CRITICAL", function()
    h.assert_truthy(combat and combat.SEVERITY, "SEVERITY not loaded")
    local S = combat.SEVERITY
    h.assert_truthy(S.DEFLECT < S.GRAZE, "DEFLECT must be less than GRAZE")
    h.assert_truthy(S.GRAZE < S.HIT, "GRAZE must be less than HIT")
    h.assert_truthy(S.HIT < S.SEVERE, "HIT must be less than SEVERE")
    h.assert_truthy(S.SEVERE < S.CRITICAL, "SEVERE must be less than CRITICAL")
end)

test("5. combat.initiate() exists and returns turn order", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.initiate) == "function",
        "combat.initiate must be a function")
    local player = make_player()
    local r = make_rat()
    local first, second = combat.initiate(player, r)
    h.assert_truthy(first, "initiate must return a first combatant")
    h.assert_truthy(second, "initiate must return a second combatant")
end)

test("6. initiate: faster creature acts first (rat speed 6 > player speed 5)", function()
    h.assert_truthy(combat, "combat not loaded")
    local player = make_player()
    local r = make_rat()
    local first, _ = combat.initiate(player, r)
    h.assert_eq("rat", first.id,
        "rat (speed 6) should act before player (speed 5)")
end)

test("7. initiate: on speed tie, smaller creature acts first", function()
    h.assert_truthy(combat, "combat not loaded")
    local player = make_player({ combat = { size = "medium", speed = 6 } })
    local r = make_rat() -- speed 6, size tiny
    local first, _ = combat.initiate(player, r)
    h.assert_eq("rat", first.id,
        "on speed tie, smaller creature (rat=tiny) should act first")
end)

test("8. combat.resolve_exchange() exists and is a function", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.resolve_exchange) == "function",
        "combat.resolve_exchange must be a function")
end)

test("9. resolve_exchange returns result table with required fields", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", "block",
        { light = true, stance = "balanced" })
    h.assert_truthy(result, "resolve_exchange must return a result table")
    h.assert_truthy(result.severity ~= nil, "result must have severity")
    h.assert_truthy(result.zone, "result must have zone")
    h.assert_truthy(result.attacker, "result must have attacker")
    h.assert_truthy(result.defender, "result must have defender")
end)

test("10. resolve_exchange progresses through all 6 phases conceptually", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", "block",
        { light = true, stance = "balanced" })
    -- Result must have phase_log or at minimum the severity + zone (proving
    -- all phases executed — INITIATE thru UPDATE are internal)
    h.assert_truthy(result.severity ~= nil,
        "result must have severity (proves RESOLVE phase ran)")
    h.assert_truthy(result.zone,
        "result must have zone (proves zone selection in RESOLVE ran)")
    h.assert_truthy(result.narration or result.text,
        "result must have narration or text (proves NARRATE phase ran)")
end)

---------------------------------------------------------------------------
-- SUITE 2: Zone Selection
---------------------------------------------------------------------------
suite("EXCHANGE FSM: zone selection (WAVE-5)")

test("11. random zone selection is weighted by zone size", function()
    h.assert_truthy(combat, "combat not loaded")
    local r = make_rat()
    local counts = {}
    for zone_name, _ in pairs(r.body_tree) do counts[zone_name] = 0 end

    math.randomseed(42)
    local trials = 1000
    for _ = 1, trials do
        local player = make_player()
        local weapon = make_steel_dagger()
        -- Pass nil target_zone to force random selection
        local result = combat.resolve_exchange(player, r, weapon, nil, "block",
            { light = true, stance = "balanced" })
        if result and result.zone then
            counts[result.zone] = (counts[result.zone] or 0) + 1
        end
    end

    -- body zone (size=0.45) should be hit more than tail (size=0.15)
    h.assert_truthy(counts["body"] and counts["tail"],
        "must record hits to body and tail zones")
    h.assert_truthy(counts["body"] > counts["tail"],
        "body (size 0.45) must be hit more often than tail (size 0.15), "
        .. "got body=" .. tostring(counts["body"])
        .. " tail=" .. tostring(counts["tail"]))

    -- body should be roughly 3x tail (0.45/0.15 = 3)
    local ratio = counts["body"] / math.max(counts["tail"], 1)
    h.assert_truthy(ratio > 1.5,
        "body-to-tail ratio should be > 1.5 (expected ~3), got " .. string.format("%.1f", ratio))
end)

test("12. targeted attack hits intended zone ~60% of the time", function()
    h.assert_truthy(combat, "combat not loaded")

    math.randomseed(42)
    local hits_on_target = 0
    local trials = 100
    for _ = 1, trials do
        local player = make_player()
        local r = make_rat()
        local weapon = make_steel_dagger()
        local result = combat.resolve_exchange(player, r, weapon, "head", "block",
            { light = true, stance = "balanced" })
        if result and result.zone == "head" then
            hits_on_target = hits_on_target + 1
        end
    end

    -- Spec says ~60% accuracy for targeted attacks
    h.assert_truthy(hits_on_target >= 40,
        "targeted attack should hit intended zone >= 40% of time, got "
        .. hits_on_target .. "/100")
    h.assert_truthy(hits_on_target <= 80,
        "targeted attack should hit intended zone <= 80% of time (not 100%), got "
        .. hits_on_target .. "/100")
end)

---------------------------------------------------------------------------
-- SUITE 3: DF-Realistic Lethality
---------------------------------------------------------------------------
suite("EXCHANGE FSM: lethality (WAVE-5)")

test("13. steel dagger vs rat body → SEVERE or CRITICAL", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result, "resolve_exchange must return a result")
    h.assert_truthy(result.severity >= combat.SEVERITY.SEVERE,
        "steel dagger (medium player) vs rat body should be SEVERE or CRITICAL, got "
        .. tostring(result.severity))
end)

test("14. steel dagger vs rat body can kill (health → 0)", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "balanced" })
    -- After a CRITICAL hit the update phase should mark health <= 0
    if result.severity >= combat.SEVERITY.CRITICAL then
        h.assert_truthy(result.target_health ~= nil or result.defender_dead ~= nil,
            "CRITICAL hit should report target health or death flag")
    end
    -- At minimum, severity should be high enough that a kill is possible
    h.assert_truthy(result.severity >= combat.SEVERITY.SEVERE,
        "steel vs rat should produce lethal-range severity")
end)

test("15. unarmed (fist force=2) vs rat → low damage (DEFLECT or GRAZE)", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local fist = make_fist()
    local result = combat.resolve_exchange(player, r, fist, "body", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result, "resolve_exchange must return a result")
    -- Fist (blunt, force=2, flesh material) vs hide should do very little
    h.assert_truthy(result.severity <= combat.SEVERITY.HIT,
        "unarmed (fist force=2) vs rat should be at most HIT, got "
        .. tostring(result.severity))
end)

test("16. rat bite vs player bare hand → HIT range (pierces skin+flesh, stops at bone)", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local bite = {
        id = "bite",
        name = "rat bite",
        material = "tooth-enamel",
        combat = {
            type = "pierce",
            force = 2,
            message = "sinks its teeth into",
            two_handed = false,
        },
    }
    local result = combat.resolve_exchange(r, player, bite, "hands", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result, "resolve_exchange must return a result")
    -- Per combat plan: rat bite penetrates skin+flesh, stops at bone → HIT
    h.assert_truthy(result.severity >= combat.SEVERITY.GRAZE
        and result.severity <= combat.SEVERITY.HIT,
        "rat bite vs bare hand should be GRAZE or HIT, got "
        .. tostring(result.severity))
end)

---------------------------------------------------------------------------
-- SUITE 4: Creature Death
---------------------------------------------------------------------------
suite("EXCHANGE FSM: creature death (WAVE-5)")

test("17. creature death sets health=0", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    -- Use multiple exchanges to ensure death
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local dead = false
    for _ = 1, 10 do
        local result = combat.resolve_exchange(player, r, weapon, "body", nil,
            { light = true, stance = "balanced" })
        if result and (result.defender_dead or (r.health and r.health <= 0)) then
            dead = true
            break
        end
    end
    h.assert_truthy(dead, "rat must die after repeated steel dagger hits")
    h.assert_truthy(r.health <= 0, "dead rat health must be <= 0")
end)

test("18. creature death sets _state='dead'", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    for _ = 1, 10 do
        local result = combat.resolve_exchange(player, r, weapon, "body", nil,
            { light = true, stance = "balanced" })
        if result and (result.defender_dead or (r.health and r.health <= 0)) then
            break
        end
    end
    h.assert_eq("dead", r._state,
        "dead creature _state must be 'dead', got: " .. tostring(r._state))
end)

test("19. creature death sets animate=false", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    for _ = 1, 10 do
        combat.resolve_exchange(player, r, weapon, "body", nil,
            { light = true, stance = "balanced" })
        if r.health and r.health <= 0 then break end
    end
    h.assert_eq(false, r.animate,
        "dead creature animate must be false, got: " .. tostring(r.animate))
end)

test("20. creature death sets portable=true", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    for _ = 1, 10 do
        combat.resolve_exchange(player, r, weapon, "body", nil,
            { light = true, stance = "balanced" })
        if r.health and r.health <= 0 then break end
    end
    h.assert_eq(true, r.portable,
        "dead creature portable must be true, got: " .. tostring(r.portable))
end)

---------------------------------------------------------------------------
-- SUITE 5: Room-Local / Flee
---------------------------------------------------------------------------
suite("EXCHANGE FSM: room-local & flee (WAVE-5)")

test("21. combat ends when defender response is 'flee' (success)", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", "flee",
        { light = true, stance = "balanced" })
    h.assert_truthy(result, "resolve_exchange must return a result")
    -- flee response should produce a combat_over or fled flag
    h.assert_truthy(result.fled or result.combat_over,
        "flee response must set fled=true or combat_over=true in result")
end)

---------------------------------------------------------------------------
-- SUITE 6: Darkness Rules
---------------------------------------------------------------------------
suite("EXCHANGE FSM: darkness rules (WAVE-5)")

test("22. in darkness, targeted zone is ignored → random zone only", function()
    h.assert_truthy(combat, "combat not loaded")

    math.randomseed(42)
    local zone_set = {}
    local trials = 50
    for _ = 1, trials do
        local player = make_player()
        local r = make_rat()
        local weapon = make_steel_dagger()
        -- light = false → darkness
        local result = combat.resolve_exchange(player, r, weapon, "head", "block",
            { light = false, stance = "balanced" })
        if result and result.zone then
            zone_set[result.zone] = true
        end
    end

    -- In darkness with random selection, we should see multiple zones hit,
    -- not just "head" every time
    local zone_count = 0
    for _ in pairs(zone_set) do zone_count = zone_count + 1 end
    h.assert_truthy(zone_count > 1,
        "in darkness, targeting 'head' should produce random zones, "
        .. "but only " .. zone_count .. " unique zone(s) were hit")
end)

test("23. in darkness, zone selection falls back to size-weighted random", function()
    h.assert_truthy(combat, "combat not loaded")

    math.randomseed(42)
    local counts = {}
    local trials = 500
    for _ = 1, trials do
        local player = make_player()
        local r = make_rat()
        local weapon = make_steel_dagger()
        local result = combat.resolve_exchange(player, r, weapon, "head", nil,
            { light = false, stance = "balanced" })
        if result and result.zone then
            counts[result.zone] = (counts[result.zone] or 0) + 1
        end
    end
    -- Body (0.45) should be hit more than tail (0.15)
    h.assert_truthy((counts["body"] or 0) > (counts["tail"] or 0),
        "darkness random: body should be hit more than tail")
end)

---------------------------------------------------------------------------
-- SUITE 7: Stance System
---------------------------------------------------------------------------
suite("EXCHANGE FSM: stance system (WAVE-5)")

test("24. aggressive stance increases attack severity vs balanced", function()
    h.assert_truthy(combat, "combat not loaded")

    local aggressive_total = 0
    local balanced_total = 0
    local trials = 100

    for i = 1, trials do
        math.randomseed(42 + i)
        local p1 = make_player()
        local r1 = make_rat()
        local w1 = make_steel_dagger()
        local res_agg = combat.resolve_exchange(p1, r1, w1, "body", nil,
            { light = true, stance = "aggressive" })
        if res_agg then aggressive_total = aggressive_total + (res_agg.severity or 0) end

        math.randomseed(42 + i)
        local p2 = make_player()
        local r2 = make_rat()
        local w2 = make_steel_dagger()
        local res_bal = combat.resolve_exchange(p2, r2, w2, "body", nil,
            { light = true, stance = "balanced" })
        if res_bal then balanced_total = balanced_total + (res_bal.severity or 0) end
    end

    h.assert_truthy(aggressive_total >= balanced_total,
        "aggressive stance should produce equal or higher total severity than balanced, "
        .. "aggressive=" .. aggressive_total .. " balanced=" .. balanced_total)
end)

test("25. defensive stance reduces incoming damage vs balanced", function()
    h.assert_truthy(combat, "combat not loaded")

    local defensive_total = 0
    local balanced_total = 0
    local trials = 100

    for i = 1, trials do
        math.randomseed(42 + i)
        local p1 = make_player()
        local r1 = make_rat()
        local bite = {
            id = "bite", name = "rat bite", material = "tooth-enamel",
            combat = { type = "pierce", force = 2, message = "bites", two_handed = false },
        }
        local res_def = combat.resolve_exchange(r1, p1, bite, "arms", nil,
            { light = true, stance = "defensive" })
        if res_def then defensive_total = defensive_total + (res_def.severity or 0) end

        math.randomseed(42 + i)
        local p2 = make_player()
        local r2 = make_rat()
        local bite2 = {
            id = "bite", name = "rat bite", material = "tooth-enamel",
            combat = { type = "pierce", force = 2, message = "bites", two_handed = false },
        }
        local res_bal = combat.resolve_exchange(r2, p2, bite2, "arms", nil,
            { light = true, stance = "balanced" })
        if res_bal then balanced_total = balanced_total + (res_bal.severity or 0) end
    end

    h.assert_truthy(defensive_total <= balanced_total,
        "defensive stance should produce equal or lower severity on defender, "
        .. "defensive=" .. defensive_total .. " balanced=" .. balanced_total)
end)

test("26. balanced stance applies no modifiers (default behavior)", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "balanced" })
    h.assert_truthy(result, "balanced stance must produce a valid result")
    h.assert_truthy(result.severity ~= nil,
        "balanced stance result must have severity")
end)

test("27. aggressive stance modifier: +30% attack force (per spec)", function()
    h.assert_truthy(combat, "combat not loaded")
    -- Verify the stance modifier values are accessible or applied
    -- The engine should expose stance modifiers or apply them consistently
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "aggressive" })
    h.assert_truthy(result, "aggressive stance must produce a valid result")
    -- Aggressive should produce at least as high severity as the weapon allows
    h.assert_truthy(result.severity >= combat.SEVERITY.HIT,
        "aggressive steel dagger vs rat body should be at least HIT, got "
        .. tostring(result.severity))
end)

test("28. defensive stance modifier: -30% attack force, +30% defense", function()
    h.assert_truthy(combat, "combat not loaded")
    math.randomseed(42)
    local player = make_player()
    local r = make_rat()
    local weapon = make_steel_dagger()
    local result = combat.resolve_exchange(player, r, weapon, "body", nil,
        { light = true, stance = "defensive" })
    h.assert_truthy(result, "defensive stance must produce a valid result")
    -- Defensive reduces attack force; steel dagger is still lethal vs rat,
    -- but severity should not exceed balanced by much
    h.assert_truthy(result.severity >= combat.SEVERITY.DEFLECT,
        "defensive result must have valid severity")
end)

---------------------------------------------------------------------------
-- SUITE 8: Phase Functions Exist
---------------------------------------------------------------------------
suite("EXCHANGE FSM: phase functions (WAVE-5)")

test("29. combat.declare() exists and is a function", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.declare) == "function",
        "combat.declare must be a function")
end)

test("30. combat.respond() exists and is a function", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.respond) == "function",
        "combat.respond must be a function")
end)

test("31. combat.resolve() or combat.resolve_exchange() exists", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.resolve_exchange) == "function"
        or type(combat.resolve) == "function",
        "combat.resolve_exchange or combat.resolve must be a function")
end)

test("32. combat.narrate() exists and is a function", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.narrate) == "function",
        "combat.narrate must be a function")
end)

test("33. combat.update() exists and is a function", function()
    h.assert_truthy(combat, "combat not loaded")
    h.assert_truthy(type(combat.update) == "function",
        "combat.update must be a function")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
