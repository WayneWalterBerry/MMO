-- test/verbs/test-poison-bottle.lua
-- EP2 Regression tests: Poison Bottle contract BEFORE Effects Pipeline refactoring.
-- These tests define the behavioral contract that the refactor MUST preserve.
-- If a test passes now and fails after refactoring, the refactor broke something.
--
-- Categories:
--   1. FSM State Transitions (sealed→open→empty, rejected paths)
--   2. Consumption → Injury Flow (inflict, tick, death)
--   3. Sensory Properties (per-state descriptions, smell, taste, look)
--   4. Fair Warning Chain (label, smell, taste before lethal drink)
--   5. Nested Parts (cork detachment, label readability, liquid tracking)
--
-- Usage: lua test/verbs/test-poison-bottle.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local fsm_mod = require("engine.fsm")
local registry_mod = require("engine.registry")
local injury_mod = require("engine.injuries")

local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load actual definitions from source (the contract we're locking down)
---------------------------------------------------------------------------
local POISON_BOTTLE_PATH = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP
    .. "objects" .. SEP .. "poison-bottle.lua"
local NIGHTSHADE_INJURY_PATH = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP
    .. "injuries" .. SEP .. "poisoned-nightshade.lua"

local poison_def = dofile(POISON_BOTTLE_PATH)
local nightshade_injury_def = dofile(NIGHTSHADE_INJURY_PATH)

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[deep_copy(k)] = deep_copy(v)
    end
    return setmetatable(copy, getmetatable(orig))
end

local function fresh_poison_bottle()
    return deep_copy(poison_def)
end

local function make_registry_with(obj)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    return reg
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

local function setup_injuries()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("poisoned-nightshade", nightshade_injury_def)
end

-- Helper: check if a value exists in an array
local function array_contains(arr, val)
    for _, v in ipairs(arr or {}) do
        if v == val then return true end
    end
    return false
end

-- Helper: find a transition by verb and from-state
local function find_transition(obj, verb, from)
    for _, t in ipairs(obj.transitions or {}) do
        if t.verb == verb and t.from == from then return t end
    end
    return nil
end

---------------------------------------------------------------------------
-- 0. Object Identity & Metadata (contract baseline)
---------------------------------------------------------------------------
suite("poison-bottle — identity & metadata")

test("has valid guid", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.guid, "Should have a guid")
    h.assert_truthy(bottle.guid:match("^{.*}$"), "GUID should be wrapped in braces")
end)

test("id is poison-bottle", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("poison-bottle", bottle.id, "id should be poison-bottle")
end)

test("material is glass", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("glass", bottle.material, "Material should be glass")
end)

test("is portable", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.portable, "Should be portable")
end)

test("is_consumable is true", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.is_consumable, "Should be consumable")
end)

test("consumable_type is liquid", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("liquid", bottle.consumable_type, "consumable_type should be liquid")
end)

test("poison_type is nightshade", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("nightshade", bottle.poison_type, "poison_type should be nightshade")
end)

test("poison_severity is lethal", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("lethal", bottle.poison_severity, "poison_severity should be lethal")
end)

test("weight is 0.4", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq(0.4, bottle.weight, "Starting weight should be 0.4")
end)

test("has expected categories", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(array_contains(bottle.categories, "dangerous"), "Should be categorized as dangerous")
    h.assert_truthy(array_contains(bottle.categories, "consumable"), "Should be categorized as consumable")
    h.assert_truthy(array_contains(bottle.categories, "poison"), "Should be categorized as poison")
    h.assert_truthy(array_contains(bottle.categories, "glass"), "Should be categorized as glass")
end)

test("has bottle in keywords", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(array_contains(bottle.keywords, "poison bottle"), "Keywords should include 'poison bottle'")
    h.assert_truthy(array_contains(bottle.keywords, "poison"), "Keywords should include 'poison'")
end)

---------------------------------------------------------------------------
-- 1. FSM State Transitions
---------------------------------------------------------------------------
suite("poison-bottle FSM — initial state")

test("starts in sealed state", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("sealed", bottle._state, "Initial _state should be sealed")
    h.assert_eq("sealed", bottle.initial_state, "initial_state field should be sealed")
end)

test("has valid FSM structure", function()
    local bottle = fresh_poison_bottle()
    local def = fsm_mod.load(bottle)
    h.assert_truthy(def, "fsm.load should recognize poison bottle as FSM object")
end)

test("has three states: sealed, open, empty", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.sealed, "Should have sealed state")
    h.assert_truthy(bottle.states.open, "Should have open state")
    h.assert_truthy(bottle.states.empty, "Should have empty state")
end)

---------------------------------------------------------------------------
suite("poison-bottle FSM — sealed → open")

test("open transitions sealed to open", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans = fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_truthy(trans, "Open transition should succeed")
    h.assert_eq("open", bottle._state, "State should be open")
end)

test("uncork alias transitions sealed to open", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans = fsm_mod.transition(reg, "poison-bottle", "open", {}, "uncork")
    h.assert_truthy(trans, "Uncork alias should work")
    h.assert_eq("open", bottle._state, "State should be open after uncork")
end)

test("unstop alias transitions sealed to open", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans = fsm_mod.transition(reg, "poison-bottle", "open", {}, "unstop")
    h.assert_truthy(trans, "Unstop alias should work")
    h.assert_eq("open", bottle._state, "State should be open after unstop")
end)

test("open transition applies weight mutation (cork removed)", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local orig_weight = bottle.weight
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_truthy(bottle.weight < orig_weight, "Weight should decrease after uncorking")
end)

test("open transition adds 'uncorked' keyword", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_truthy(array_contains(bottle.keywords, "uncorked"),
        "Keywords should include 'uncorked' after opening")
end)

test("open transition message mentions cork", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans = fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_truthy(trans.message:lower():find("cork"), "Open message should mention cork")
end)

test("open transition message mentions vapor", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans = fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_truthy(trans.message:lower():find("vapor"), "Open message should mention vapor")
end)

---------------------------------------------------------------------------
suite("poison-bottle FSM — open → empty (drink)")

test("drink transitions open to empty", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_truthy(trans, "Drink transition should succeed from open")
    h.assert_eq("empty", bottle._state, "State should be empty after drinking")
end)

test("quaff alias works for drink", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "quaff")
    h.assert_truthy(trans, "Quaff alias should work")
    h.assert_eq("empty", bottle._state, "State should be empty after quaff")
end)

test("sip alias works for drink", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "sip")
    h.assert_truthy(trans, "Sip alias should work")
end)

test("gulp alias works for drink", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "gulp")
    h.assert_truthy(trans, "Gulp alias should work")
end)

test("consume alias works for drink", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "consume")
    h.assert_truthy(trans, "Consume alias should work")
end)

test("drink sets weight to 0.1", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_eq(0.1, bottle.weight, "Weight should be 0.1 after drinking")
end)

test("drink removes 'dangerous' category", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_truthy(not array_contains(bottle.categories, "dangerous"),
        "Categories should NOT include 'dangerous' after drinking")
end)

test("drink adds 'empty' keyword", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_truthy(array_contains(bottle.keywords, "empty"),
        "Keywords should include 'empty' after drinking")
end)

test("drink sets is_consumable to false", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_eq(false, bottle.is_consumable, "is_consumable should be false after drinking")
end)

test("drink transition carries inflict_injury effect metadata", function()
    local bottle = fresh_poison_bottle()
    local drink_trans = find_transition(bottle, "drink", "open")
    h.assert_truthy(drink_trans, "Drink transition should exist")
    h.assert_truthy(drink_trans.effect, "Drink transition should have an effect")
    h.assert_eq("inflict_injury", drink_trans.effect.type, "Effect type should be inflict_injury")
    h.assert_eq("poisoned-nightshade", drink_trans.effect.injury_type, "Should inflict nightshade")
    h.assert_eq("poison-bottle", drink_trans.effect.source, "Source should be poison-bottle")
    h.assert_eq(10, drink_trans.effect.damage, "Drink effect damage should be 10")
end)

test("drink transition message mentions burns/fire", function()
    local bottle = fresh_poison_bottle()
    local drink_trans = find_transition(bottle, "drink", "open")
    h.assert_truthy(drink_trans.message:lower():find("burn") or
                    drink_trans.message:lower():find("fire"),
        "Drink message should mention burning")
end)

---------------------------------------------------------------------------
suite("poison-bottle FSM — open → empty (pour)")

test("pour transitions open to empty", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "pour")
    h.assert_truthy(trans, "Pour transition should succeed from open")
    h.assert_eq("empty", bottle._state, "State should be empty after pour")
end)

test("spill alias works for pour", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "spill")
    h.assert_truthy(trans, "Spill alias should work")
end)

test("dump alias works for pour", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "dump")
    h.assert_truthy(trans, "Dump alias should work")
end)

test("pour has NO inflict_injury effect", function()
    local bottle = fresh_poison_bottle()
    local pour_trans = find_transition(bottle, "pour", "open")
    h.assert_truthy(pour_trans, "Pour transition should exist")
    h.assert_nil(pour_trans.effect, "Pour should NOT inflict injury")
end)

test("pour sets weight to 0.1", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "pour")
    h.assert_eq(0.1, bottle.weight, "Weight should be 0.1 after pouring")
end)

test("pour message mentions hissing/floor", function()
    local bottle = fresh_poison_bottle()
    local pour_trans = find_transition(bottle, "pour", "open")
    h.assert_truthy(pour_trans.message:lower():find("hiss") or
                    pour_trans.message:lower():find("floor"),
        "Pour message should describe liquid hitting floor")
end)

---------------------------------------------------------------------------
suite("poison-bottle FSM — REJECTED transitions")

test("drink from sealed returns no_transition", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans, err = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_nil(trans, "Should NOT drink from sealed bottle")
    h.assert_eq("no_transition", err, "Error should be no_transition")
    h.assert_eq("sealed", bottle._state, "State should remain sealed")
end)

test("pour from sealed returns no_transition", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    local trans, err = fsm_mod.transition(reg, "poison-bottle", "empty", {}, "pour")
    h.assert_nil(trans, "Should NOT pour from sealed bottle")
    h.assert_eq("no_transition", err, "Error should be no_transition")
end)

test("empty state is terminal — blocks all transitions", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_eq("empty", bottle._state, "Should be in empty state")
    local trans, err = fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_nil(trans, "Should not transition from terminal empty state")
    h.assert_eq("terminal", err, "Error should be terminal")
end)

test("re-opening already open bottle returns no_transition", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local trans, err = fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    h.assert_nil(trans, "Should not re-open an already open bottle")
    h.assert_eq("no_transition", err, "Error should be no_transition")
end)

---------------------------------------------------------------------------
suite("poison-bottle FSM — get_transitions per state")

test("sealed state offers open and detach_part transitions", function()
    local bottle = fresh_poison_bottle()
    local transitions = fsm_mod.get_transitions(bottle)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["open"], "Sealed should offer open")
    h.assert_truthy(not verbs["drink"], "Sealed should NOT offer drink")
    h.assert_truthy(not verbs["pour"], "Sealed should NOT offer pour")
end)

test("open state offers drink and pour transitions", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    local transitions = fsm_mod.get_transitions(bottle)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["drink"], "Open should offer drink")
    h.assert_truthy(verbs["pour"], "Open should offer pour")
    h.assert_truthy(not verbs["open"], "Open should NOT offer open")
end)

---------------------------------------------------------------------------
-- 2. Consumption → Injury Flow
---------------------------------------------------------------------------
suite("poison-bottle — nightshade injury definition contract")

test("injury id is poisoned-nightshade", function()
    h.assert_eq("poisoned-nightshade", nightshade_injury_def.id, "Injury id")
end)

test("injury category is toxin", function()
    h.assert_eq("toxin", nightshade_injury_def.category, "Category should be toxin")
end)

test("damage_type is over_time", function()
    h.assert_eq("over_time", nightshade_injury_def.damage_type, "Should be over_time damage")
end)

test("initial_state is active", function()
    h.assert_eq("active", nightshade_injury_def.initial_state, "Should start in active state")
end)

test("on_inflict initial_damage is 10", function()
    h.assert_eq(10, nightshade_injury_def.on_inflict.initial_damage, "Initial damage should be 10")
end)

test("on_inflict damage_per_tick is 8", function()
    h.assert_eq(8, nightshade_injury_def.on_inflict.damage_per_tick, "Damage per tick should be 8")
end)

test("on_inflict has a message", function()
    h.assert_truthy(nightshade_injury_def.on_inflict.message, "Infliction message should exist")
end)

test("active state damage_per_tick is 8", function()
    h.assert_eq(8, nightshade_injury_def.states.active.damage_per_tick, "Active dpt should be 8")
end)

test("worsened state damage_per_tick is 15", function()
    h.assert_eq(15, nightshade_injury_def.states.worsened.damage_per_tick, "Worsened dpt should be 15")
end)

test("neutralized state damage_per_tick is 0", function()
    h.assert_eq(0, nightshade_injury_def.states.neutralized.damage_per_tick, "Neutralized dpt should be 0")
end)

test("fatal state is terminal", function()
    h.assert_truthy(nightshade_injury_def.states.fatal.terminal, "Fatal should be terminal")
end)

test("healed state is terminal", function()
    h.assert_truthy(nightshade_injury_def.states.healed.terminal, "Healed should be terminal")
end)

test("only nightshade antidote cures it", function()
    h.assert_truthy(nightshade_injury_def.healing_interactions["antidote-nightshade"],
        "Should accept antidote-nightshade")
    local cure_count = 0
    for _ in pairs(nightshade_injury_def.healing_interactions) do
        cure_count = cure_count + 1
    end
    h.assert_eq(1, cure_count, "Should have exactly 1 healing interaction (no generic cures)")
end)

test("active state restricts focus", function()
    h.assert_truthy(nightshade_injury_def.states.active.restricts,
        "Active state should have restrictions")
    h.assert_truthy(nightshade_injury_def.states.active.restricts.focus,
        "Active state should restrict focus")
end)

test("worsened state restricts multiple actions", function()
    local r = nightshade_injury_def.states.worsened.restricts
    h.assert_truthy(r, "Worsened state should have restrictions")
    h.assert_truthy(r.focus, "Worsened should restrict focus")
    h.assert_truthy(r.climb, "Worsened should restrict climb")
    h.assert_truthy(r.run, "Worsened should restrict run")
    h.assert_truthy(r.fight, "Worsened should restrict fight")
end)

---------------------------------------------------------------------------
suite("poison-bottle — injury engine integration")

test("inflicting nightshade creates injury on player", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)
    h.assert_eq(1, #p.injuries, "Should have 1 injury")
    h.assert_eq("poisoned-nightshade", p.injuries[1].type, "Injury type should match")
    h.assert_eq("poison-bottle", p.injuries[1].source, "Source should be poison-bottle")
    h.assert_eq("active", p.injuries[1]._state, "Injury should start in active state")
end)

test("nightshade ticks health down each turn", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle") end)
    local health_before = injury_mod.compute_health(p)
    capture_print(function() injury_mod.tick(p) end)
    local health_after = injury_mod.compute_health(p)
    h.assert_truthy(health_after < health_before,
        "Health should decrease each tick (was " .. health_before .. ", now " .. health_after .. ")")
end)

test("player can die from nightshade if untreated", function()
    setup_injuries()
    local p = fresh_player()
    p.max_health = 30
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle") end)
    local died = false
    for i = 1, 20 do
        capture_print(function()
            local _, d = injury_mod.tick(p)
            if d then died = true end
        end)
        if died then break end
    end
    h.assert_truthy(died, "Player should die from untreated nightshade poisoning")
end)

test("nightshade does not kill immediately (multi-turn)", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle") end)
    local health = injury_mod.compute_health(p)
    h.assert_truthy(health > 0, "Should not die on infliction alone (health = " .. health .. ")")
    local _, died
    capture_print(function() _, died = injury_mod.tick(p) end)
    h.assert_truthy(not died, "Should not die after first tick with full health")
end)

---------------------------------------------------------------------------
-- 3. Sensory Properties (per state)
---------------------------------------------------------------------------
suite("poison-bottle — sensory: sealed state")

test("sealed description mentions cork", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.sealed.description:lower():find("cork"),
        "Sealed description should mention cork")
end)

test("sealed description mentions skull and crossbones", function()
    local bottle = fresh_poison_bottle()
    local desc = bottle.states.sealed.description:lower()
    h.assert_truthy(desc:find("skull") and desc:find("crossbones"),
        "Sealed description should show skull and crossbones warning")
end)

test("sealed description mentions green liquid", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.sealed.description:lower():find("green"),
        "Sealed description should mention green liquid")
end)

test("sealed on_smell detects danger even through cork", function()
    local bottle = fresh_poison_bottle()
    local smell = bottle.states.sealed.on_smell:lower()
    h.assert_truthy(smell:find("acrid") or smell:find("dangerous"),
        "Sealed smell should hint at danger")
end)

test("sealed on_feel mentions cork stopper", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.sealed.on_feel:lower():find("cork"),
        "Sealed feel should mention cork")
end)

test("sealed on_taste is harmless (glass)", function()
    local bottle = fresh_poison_bottle()
    local taste = bottle.states.sealed.on_taste
    h.assert_truthy(taste, "Sealed on_taste should exist")
    h.assert_truthy(taste:lower():find("glass"),
        "Sealed taste should describe licking the outside (harmless glass)")
end)

test("sealed on_listen mentions sloshing", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.sealed.on_listen:lower():find("slosh"),
        "Sealed listen should mention sloshing liquid")
end)

test("sealed on_look function returns skull warning", function()
    local bottle = fresh_poison_bottle()
    local look_fn = bottle.states.sealed.on_look
    h.assert_truthy(type(look_fn) == "function", "Sealed on_look should be a function")
    local result = look_fn(bottle)
    h.assert_truthy(result:lower():find("skull"), "Sealed on_look should mention skull")
    h.assert_truthy(result:lower():find("not a beverage"),
        "Sealed on_look should warn 'not a beverage'")
end)

---------------------------------------------------------------------------
suite("poison-bottle — sensory: open state")

test("open description mentions vapor/fumes", function()
    local bottle = fresh_poison_bottle()
    local desc = bottle.states.open.description:lower()
    h.assert_truthy(desc:find("vapor") or desc:find("fume"),
        "Open description should mention vapor or fumes")
end)

test("open description mentions cork removed", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.open.description:lower():find("cork removed"),
        "Open description should mention cork removed")
end)

test("open on_smell mentions poisonous fumes", function()
    local bottle = fresh_poison_bottle()
    local smell = bottle.states.open.on_smell:lower()
    h.assert_truthy(smell:find("poison") or smell:find("fume"),
        "Open smell should mention poison or fumes")
end)

test("open on_taste mentions bitter/fire", function()
    local bottle = fresh_poison_bottle()
    local taste = bottle.states.open.on_taste:lower()
    h.assert_truthy(taste:find("bitter") or taste:find("fire"),
        "Open taste should mention bitter or fire")
end)

test("open on_feel mentions tingling vapor", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.open.on_feel:lower():find("tingle"),
        "Open feel should mention tingling from vapor")
end)

test("open on_listen mentions hissing", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.open.on_listen:lower():find("hiss"),
        "Open listen should mention hissing")
end)

test("open on_look function warns do not drink", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    -- After transition, bottle.on_look is the open state function
    -- and bottle.description is the open state description
    h.assert_truthy(type(bottle.on_look) == "function", "Open on_look should be a function")
    local result = bottle.on_look(bottle)
    h.assert_truthy(result:lower():find("do not drink"),
        "Open on_look should warn 'do not drink'")
end)

test("open room_presence mentions vapor", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.open.room_presence:lower():find("vapor"),
        "Open room_presence should mention vapor")
end)

---------------------------------------------------------------------------
suite("poison-bottle — sensory: empty state")

test("empty description mentions empty", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.empty.description:lower():find("empty"),
        "Empty description should mention empty")
end)

test("empty description mentions residue", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.empty.description:lower():find("residue"),
        "Empty description should mention residue")
end)

test("empty on_smell mentions residue or passed", function()
    local bottle = fresh_poison_bottle()
    local smell = bottle.states.empty.on_smell:lower()
    h.assert_truthy(smell:find("residue") or smell:find("passed"),
        "Empty smell should mention residue or danger passed")
end)

test("empty on_listen mentions silence", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.empty.on_listen:lower():find("silence"),
        "Empty listen should mention silence (nothing to slosh)")
end)

test("empty state is terminal", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.empty.terminal, "Empty state should be terminal")
end)

test("empty on_look function returns description", function()
    local bottle = fresh_poison_bottle()
    local reg = make_registry_with(bottle)
    fsm_mod.transition(reg, "poison-bottle", "open", {}, "open")
    fsm_mod.transition(reg, "poison-bottle", "empty", {}, "drink")
    h.assert_truthy(type(bottle.on_look) == "function", "Empty on_look should be a function")
    local result = bottle.on_look(bottle)
    h.assert_truthy(result:find("empty"), "Empty on_look should mention empty")
end)

---------------------------------------------------------------------------
-- 4. Fair Warning Chain
---------------------------------------------------------------------------
suite("poison-bottle — fair warning chain")

test("label is readable WITHOUT opening bottle", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.readable, "Label should be readable")
    h.assert_truthy(bottle.parts.label.readable_text, "Label should have readable_text")
end)

test("label clearly warns POISON", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.readable_text:find("POISON"),
        "Label text should contain 'POISON' in caps")
end)

test("label warns lethal if ingested", function()
    local bottle = fresh_poison_bottle()
    local text = bottle.parts.label.readable_text:lower()
    h.assert_truthy(text:find("lethal"), "Label should warn about lethality")
    h.assert_truthy(text:find("ingest"), "Label should mention ingestion")
end)

test("label identifies poison type (belladonna)", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.readable_text:lower():find("belladonna"),
        "Label should identify belladonna")
end)

test("label mentions antidote", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.readable_text:lower():find("antidote"),
        "Label should mention antidote (clue for cure)")
end)

test("sealed smell gives warning even through cork", function()
    local bottle = fresh_poison_bottle()
    local smell = bottle.states.sealed.on_smell:lower()
    h.assert_truthy(smell:find("dangerous") or smell:find("acrid"),
        "Sealed smell should warn of danger even through cork")
end)

test("open taste gives warning BEFORE lethal drink", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.states.open.on_taste, "Open on_taste should exist as warning")
    -- Taste and drink are separate interactions — taste warns, drink kills
    local drink_trans = find_transition(bottle, "drink", "open")
    h.assert_truthy(drink_trans, "Drink transition exists separately from taste")
end)

test("taste effect is sub-lethal (damage 5 vs drink's 10)", function()
    local bottle = fresh_poison_bottle()
    local effect = bottle.states.open.on_taste_effect
    h.assert_truthy(effect, "Open state should have on_taste_effect")
    h.assert_eq("inflict_injury", effect.type, "Taste effect type should be inflict_injury")
    h.assert_eq(5, effect.damage, "Taste damage should be 5 (less than drink's 10)")
    h.assert_eq("poisoned-nightshade", effect.injury_type, "Taste should inflict nightshade")
end)

test("skull and crossbones visible on sealed bottle", function()
    local bottle = fresh_poison_bottle()
    local desc = bottle.states.sealed.description:lower()
    h.assert_truthy(desc:find("skull"), "Skull should be visible on sealed bottle")
    h.assert_truthy(desc:find("crossbones"), "Crossbones should be visible on sealed bottle")
end)

test("warning hierarchy: READ safe → SMELL safe → TASTE warns → DRINK kills", function()
    local bottle = fresh_poison_bottle()
    -- READ: label is readable, no effect
    h.assert_truthy(bottle.parts.label.readable, "READ is safe (readable label)")
    -- SMELL sealed: no effect, just description
    h.assert_truthy(type(bottle.states.sealed.on_smell) == "string",
        "SMELL sealed is safe (string description, no effect)")
    -- TASTE open: has effect but sub-lethal
    h.assert_eq(5, bottle.states.open.on_taste_effect.damage,
        "TASTE is a warning (sub-lethal damage 5)")
    -- DRINK: lethal effect
    local drink_trans = find_transition(bottle, "drink", "open")
    h.assert_eq(10, drink_trans.effect.damage,
        "DRINK is the lethal action (damage 10)")
end)

---------------------------------------------------------------------------
-- 5. Nested Parts
---------------------------------------------------------------------------
suite("poison-bottle — nested parts: cork")

test("cork is detachable", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.cork.detachable, "Cork should be detachable")
end)

test("cork removal is NOT reversible", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq(false, bottle.parts.cork.reversible, "Cork removal should not be reversible")
end)

test("cork has correct detach verbs", function()
    local bottle = fresh_poison_bottle()
    local verbs = {}
    for _, v in ipairs(bottle.parts.cork.detach_verbs) do verbs[v] = true end
    h.assert_truthy(verbs["pull"], "detach_verbs should include 'pull'")
    h.assert_truthy(verbs["remove"], "detach_verbs should include 'remove'")
    h.assert_truthy(verbs["uncork"], "detach_verbs should include 'uncork'")
    h.assert_truthy(verbs["unstop"], "detach_verbs should include 'unstop'")
    h.assert_truthy(verbs["unseal"], "detach_verbs should include 'unseal'")
    h.assert_truthy(verbs["yank"], "detach_verbs should include 'yank'")
    h.assert_truthy(verbs["extract"], "detach_verbs should include 'extract'")
    h.assert_truthy(verbs["pop"], "detach_verbs should include 'pop'")
end)

test("cork factory creates valid independent object", function()
    local bottle = fresh_poison_bottle()
    local cork = bottle.parts.cork.factory(bottle)
    h.assert_truthy(cork, "Factory should return a cork object")
    h.assert_eq("poison-cork", cork.id, "Cork id should be poison-cork")
    h.assert_truthy(cork.portable, "Cork should be portable")
    h.assert_truthy(cork.keywords, "Cork should have keywords")
    h.assert_truthy(cork.description, "Cork should have description")
    h.assert_truthy(cork.on_feel, "Cork should have on_feel")
    h.assert_truthy(cork.on_smell, "Cork should have on_smell")
    h.assert_truthy(cork.on_taste, "Cork should have on_taste")
    h.assert_truthy(cork.on_listen, "Cork should have on_listen")
end)

test("cork factory inherits parent location", function()
    local bottle = fresh_poison_bottle()
    bottle.location = "test-room"
    local cork = bottle.parts.cork.factory(bottle)
    h.assert_eq("test-room", cork.location, "Cork location should match parent")
end)

test("cork factory generates unique guid each time", function()
    local bottle = fresh_poison_bottle()
    local cork1 = bottle.parts.cork.factory(bottle)
    local cork2 = bottle.parts.cork.factory(bottle)
    h.assert_truthy(cork1.guid ~= cork2.guid,
        "Each factory call should generate a unique guid")
end)

test("cork has correct keywords", function()
    local bottle = fresh_poison_bottle()
    local kw = {}
    for _, k in ipairs(bottle.parts.cork.keywords) do kw[k] = true end
    h.assert_truthy(kw["cork"], "Should include 'cork'")
    h.assert_truthy(kw["stopper"], "Should include 'stopper'")
    h.assert_truthy(kw["plug"], "Should include 'plug'")
end)

test("detach_part transition exists for cork", function()
    local bottle = fresh_poison_bottle()
    local found = false
    for _, t in ipairs(bottle.transitions) do
        if t.trigger == "detach_part" and t.part_id == "cork" then
            found = true
            h.assert_eq("sealed", t.from, "Cork detach should transition from sealed")
            h.assert_eq("open", t.to, "Cork detach should transition to open")
            break
        end
    end
    h.assert_truthy(found, "Should have detach_part transition for cork")
end)

---------------------------------------------------------------------------
suite("poison-bottle — nested parts: label")

test("label is NOT detachable", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq(false, bottle.parts.label.detachable, "Label should not be detachable")
end)

test("label is readable", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.readable, "Label should be readable")
end)

test("label readable_text contains POISON warning", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.readable_text:find("POISON"),
        "Label text should contain 'POISON'")
end)

test("label has read and examine verbs", function()
    local bottle = fresh_poison_bottle()
    local verbs = {}
    for _, v in ipairs(bottle.parts.label.read_verbs) do verbs[v] = true end
    h.assert_truthy(verbs["read"], "read_verbs should include 'read'")
    h.assert_truthy(verbs["examine"], "read_verbs should include 'examine'")
end)

test("label has correct keywords", function()
    local bottle = fresh_poison_bottle()
    local kw = {}
    for _, k in ipairs(bottle.parts.label.keywords) do kw[k] = true end
    h.assert_truthy(kw["label"], "Should include 'label'")
    h.assert_truthy(kw["skull"], "Should include 'skull'")
    h.assert_truthy(kw["crossbones"], "Should include 'crossbones'")
    h.assert_truthy(kw["warning"], "Should include 'warning'")
end)

test("label has feel and smell sensory properties", function()
    local bottle = fresh_poison_bottle()
    h.assert_truthy(bottle.parts.label.on_feel, "Label should have on_feel")
    h.assert_truthy(bottle.parts.label.on_smell, "Label should have on_smell")
end)

---------------------------------------------------------------------------
suite("poison-bottle — liquid state tracks bottle state")

test("sealed state describes liquid inside (murky green)", function()
    local bottle = fresh_poison_bottle()
    local desc = bottle.states.sealed.description:lower()
    h.assert_truthy(desc:find("green"), "Sealed should describe green liquid")
    h.assert_truthy(desc:find("liquid") or desc:find("inside"),
        "Sealed should reference liquid inside")
end)

test("open state describes exposed liquid (swirls/vapor)", function()
    local bottle = fresh_poison_bottle()
    local desc = bottle.states.open.description:lower()
    h.assert_truthy(desc:find("liquid") or desc:find("vapor"),
        "Open should describe exposed liquid or vapor")
end)

test("empty state describes absence of liquid (residue only)", function()
    local bottle = fresh_poison_bottle()
    local desc = bottle.states.empty.description:lower()
    h.assert_truthy(desc:find("empty"), "Empty should describe emptiness")
    h.assert_truthy(desc:find("residue"), "Empty should mention residue")
end)

---------------------------------------------------------------------------
suite("poison-bottle — GOAP prerequisites contract")

test("drink requires open state", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("open", bottle.prerequisites.drink.requires_state,
        "Drink prerequisite should require open state")
end)

test("pour requires open state", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("open", bottle.prerequisites.pour.requires_state,
        "Pour prerequisite should require open state")
end)

test("open requires sealed state and free hands", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("sealed", bottle.prerequisites.open.requires_state,
        "Open prerequisite should require sealed state")
    h.assert_truthy(bottle.prerequisites.open.requires_free_hands,
        "Open prerequisite should require free hands")
end)

test("uncork requires sealed state and free hands", function()
    local bottle = fresh_poison_bottle()
    h.assert_eq("sealed", bottle.prerequisites.uncork.requires_state,
        "Uncork prerequisite should require sealed state")
    h.assert_truthy(bottle.prerequisites.uncork.requires_free_hands,
        "Uncork prerequisite should require free hands")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
