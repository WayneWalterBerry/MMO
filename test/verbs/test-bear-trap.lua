-- test/verbs/test-bear-trap.lua
-- EP9/EP10: Bear trap unit tests — FSM transitions, contact injury,
-- disarm guards, pipeline integration, sensory properties, backward compat.
--
-- Tests the bear-trap.lua object definition AND crushing-wound.lua injury
-- definition, verifying the Effects Pipeline refactor (commit f872ed3)
-- preserved all behavioral contracts.
--
-- Usage: lua test/verbs/test-bear-trap.lua
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
-- Load actual definitions from source
---------------------------------------------------------------------------
local BEAR_TRAP_PATH = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP
    .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "bear-trap.lua"
local CRUSHING_WOUND_PATH = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP
    .. "worlds" .. SEP .. "manor" .. SEP .. "injuries" .. SEP .. "crushing-wound.lua"

local trap_def = dofile(BEAR_TRAP_PATH)
local crushing_def = dofile(CRUSHING_WOUND_PATH)

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

local function fresh_trap()
    return deep_copy(trap_def)
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
    injury_mod.register_definition("crushing-wound", crushing_def)
end

local function array_contains(arr, val)
    for _, v in ipairs(arr or {}) do
        if v == val then return true end
    end
    return false
end

local function find_transition(obj, verb, from)
    for _, t in ipairs(obj.transitions or {}) do
        if t.verb == verb and t.from == from then return t end
    end
    return nil
end

---------------------------------------------------------------------------
-- 0. Object Identity & Metadata
---------------------------------------------------------------------------
suite("bear-trap — identity & metadata")

test("has valid guid", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.guid, "Should have a guid")
    h.assert_truthy(trap.guid:match("^{.*}$"), "GUID should be wrapped in braces")
end)

test("id is bear-trap", function()
    local trap = fresh_trap()
    h.assert_eq("bear-trap", trap.id, "id should be bear-trap")
end)

test("material is iron", function()
    local trap = fresh_trap()
    h.assert_eq("iron", trap.material, "Material should be iron")
end)

test("is not portable (armed)", function()
    local trap = fresh_trap()
    h.assert_eq(false, trap.portable, "Should NOT be portable when armed")
end)

test("template is furniture", function()
    local trap = fresh_trap()
    h.assert_eq("furniture", trap.template, "Template should be furniture")
end)

test("weight is 4.5", function()
    local trap = fresh_trap()
    h.assert_eq(4.5, trap.weight, "Weight should be 4.5")
end)

test("size is 3", function()
    local trap = fresh_trap()
    h.assert_eq(3, trap.size, "Size should be 3")
end)

test("is_trap flag is set", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.is_trap, "is_trap should be true")
end)

test("is_armed flag is set", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.is_armed, "is_armed should be true")
end)

test("is_dangerous flag is set", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.is_dangerous, "is_dangerous should be true")
end)

test("trap_type is spring-jaw", function()
    local trap = fresh_trap()
    h.assert_eq("spring-jaw", trap.trap_type, "trap_type should be spring-jaw")
end)

test("trap_injury_type is crushing-wound", function()
    local trap = fresh_trap()
    h.assert_eq("crushing-wound", trap.trap_injury_type, "trap_injury_type should be crushing-wound")
end)

test("trap_damage_amount is 15", function()
    local trap = fresh_trap()
    h.assert_eq(15, trap.trap_damage_amount, "trap_damage_amount should be 15")
end)

test("has expected categories", function()
    local trap = fresh_trap()
    h.assert_truthy(array_contains(trap.categories, "trap"), "Should be categorized as trap")
    h.assert_truthy(array_contains(trap.categories, "dangerous"), "Should be categorized as dangerous")
    h.assert_truthy(array_contains(trap.categories, "hazard"), "Should be categorized as hazard")
    h.assert_truthy(array_contains(trap.categories, "metal"), "Should be categorized as metal")
end)

test("has expected keywords", function()
    local trap = fresh_trap()
    h.assert_truthy(array_contains(trap.keywords, "trap"), "Keywords should include 'trap'")
    h.assert_truthy(array_contains(trap.keywords, "bear trap"), "Keywords should include 'bear trap'")
    h.assert_truthy(array_contains(trap.keywords, "jaws"), "Keywords should include 'jaws'")
end)

test("room_position is on the floor", function()
    local trap = fresh_trap()
    h.assert_eq("on the floor", trap.room_position, "room_position should be 'on the floor'")
end)

---------------------------------------------------------------------------
-- 1. FSM State Transitions — Initial State
---------------------------------------------------------------------------
suite("bear-trap FSM — initial state")

test("starts in set state", function()
    local trap = fresh_trap()
    h.assert_eq("set", trap._state, "Initial _state should be set")
    h.assert_eq("set", trap.initial_state, "initial_state field should be set")
end)

test("has valid FSM structure", function()
    local trap = fresh_trap()
    local def = fsm_mod.load(trap)
    h.assert_truthy(def, "fsm.load should recognize bear trap as FSM object")
end)

test("has three states: set, triggered, disarmed", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set, "Should have set state")
    h.assert_truthy(trap.states.triggered, "Should have triggered state")
    h.assert_truthy(trap.states.disarmed, "Should have disarmed state")
end)

---------------------------------------------------------------------------
-- 2. FSM Transitions — set → triggered (take)
---------------------------------------------------------------------------
suite("bear-trap FSM — set → triggered (take)")

test("take transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(trans, "Take transition should succeed")
    h.assert_eq("triggered", trap._state, "State should be triggered")
end)

test("grab alias transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "grab")
    h.assert_truthy(trans, "Grab alias should work")
    h.assert_eq("triggered", trap._state, "State should be triggered after grab")
end)

test("pick up alias transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "pick up")
    h.assert_truthy(trans, "Pick up alias should work")
    h.assert_eq("triggered", trap._state, "State should be triggered after pick up")
end)

test("get alias transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "get")
    h.assert_truthy(trans, "Get alias should work")
    h.assert_eq("triggered", trap._state, "State should be triggered after get")
end)

test("take transition message mentions SNAP", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_truthy(trans.message:find("SNAP"), "Take message should mention SNAP")
end)

test("take mutation clears is_armed", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_eq(false, trap.is_armed, "is_armed should be false after triggering")
end)

test("take mutation sets is_sprung", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(trap.is_sprung, "is_sprung should be true after triggering")
end)

test("take mutation clears is_dangerous", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_eq(false, trap.is_dangerous, "is_dangerous should be false after triggering")
end)

test("take mutation adds 'sprung' keyword", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(array_contains(trap.keywords, "sprung"),
        "Keywords should include 'sprung' after triggering")
end)

test("take mutation adds 'evidence' category", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(array_contains(trap.categories, "evidence"),
        "Categories should include 'evidence' after triggering")
end)

test("take mutation removes 'dangerous' category", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(not array_contains(trap.categories, "dangerous"),
        "Categories should NOT include 'dangerous' after triggering")
end)

---------------------------------------------------------------------------
-- 3. FSM Transitions — set → triggered (touch)
---------------------------------------------------------------------------
suite("bear-trap FSM — set → triggered (touch)")

test("touch transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "touch")
    h.assert_truthy(trans, "Touch transition should succeed")
    h.assert_eq("triggered", trap._state, "State should be triggered")
end)

test("handle alias transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "handle")
    h.assert_truthy(trans, "Handle alias should work")
    h.assert_eq("triggered", trap._state, "State should be triggered after handle")
end)

test("poke alias transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "poke")
    h.assert_truthy(trans, "Poke alias should work")
    h.assert_eq("triggered", trap._state, "State should be triggered after poke")
end)

test("prod alias transitions set to triggered", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "prod")
    h.assert_truthy(trans, "Prod alias should work")
    h.assert_eq("triggered", trap._state, "State should be triggered after prod")
end)

test("touch transition message mentions SNAP", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_truthy(trans.message:find("SNAP"), "Touch message should mention SNAP")
end)

test("touch mutation clears is_armed", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "touch")
    h.assert_eq(false, trap.is_armed, "is_armed should be false after touch trigger")
end)

test("touch mutation sets is_sprung", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "touch")
    h.assert_truthy(trap.is_sprung, "is_sprung should be true after touch trigger")
end)

---------------------------------------------------------------------------
-- 4. FSM Transitions — triggered → disarmed
---------------------------------------------------------------------------
suite("bear-trap FSM — triggered → disarmed")

test("disarm transitions triggered to disarmed (with correct context)", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    -- First trigger the trap
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    -- Context with player who has lockpicking skill
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
        target = { thin_tool = true },
    }
    local trans = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_truthy(trans, "Disarm transition should succeed with correct tool + skill")
    h.assert_eq("disarmed", trap._state, "State should be disarmed")
end)

test("disable alias works for disarm", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    local trans = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disable")
    h.assert_truthy(trans, "Disable alias should work")
    h.assert_eq("disarmed", trap._state, "State should be disarmed after disable")
end)

test("defuse alias works for disarm", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    local trans = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "defuse")
    h.assert_truthy(trans, "Defuse alias should work")
end)

test("neutralize alias works for disarm", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    local trans = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "neutralize")
    h.assert_truthy(trans, "Neutralize alias should work")
end)

test("disarm sets is_disarmed", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_truthy(trap.is_disarmed, "is_disarmed should be true after disarming")
end)

test("disarm makes trap portable", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_truthy(trap.portable, "Trap should be portable after disarming")
end)

test("disarm adds 'disarmed' keyword", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_truthy(array_contains(trap.keywords, "disarmed"),
        "Keywords should include 'disarmed' after disarming")
end)

test("disarm adds 'trophy' category", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_truthy(array_contains(trap.categories, "trophy"),
        "Categories should include 'trophy' after disarming")
end)

test("disarm message mentions lockpick and spring", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "disarm", "triggered")
    h.assert_truthy(trans.message:lower():find("lockpick"),
        "Disarm message should mention lockpick")
    h.assert_truthy(trans.message:lower():find("spring"),
        "Disarm message should mention spring mechanism")
end)

---------------------------------------------------------------------------
-- 5. Disarm Guards — Skill Check
---------------------------------------------------------------------------
suite("bear-trap FSM — disarm guard (skill check)")

test("disarm fails without lockpicking skill", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    -- Player without lockpicking
    local ctx = {
        player = {
            has_skill = function(skill) return false end,
        },
    }
    local trans, err = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_nil(trans, "Disarm should fail without lockpicking skill")
    h.assert_eq("guard_failed", err, "Error should be guard_failed")
    h.assert_eq("triggered", trap._state, "State should remain triggered")
end)

test("disarm fails without player context", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local trans, err = fsm_mod.transition(reg, "bear-trap", "disarmed", {}, "disarm")
    h.assert_nil(trans, "Disarm should fail without player context")
    h.assert_eq("guard_failed", err, "Error should be guard_failed")
end)

test("disarm fails with nil context", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local trans, err = fsm_mod.transition(reg, "bear-trap", "disarmed", nil, "disarm")
    h.assert_nil(trans, "Disarm should fail with nil context")
    h.assert_eq("guard_failed", err, "Error should be guard_failed")
end)

test("disarm fail_message mentions knowledge of locks", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "disarm", "triggered")
    h.assert_truthy(trans.fail_message, "Should have a fail_message")
    h.assert_truthy(trans.fail_message:lower():find("lock") or
                    trans.fail_message:lower():find("mechanism"),
        "Fail message should mention locks or mechanisms")
end)

test("disarm requires_tool is thin_tool", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "disarm", "triggered")
    h.assert_eq("thin_tool", trans.requires_tool, "Should require thin_tool")
end)

test("disarm from set state returns no_transition", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    local trans, err = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_nil(trans, "Should NOT disarm from set state directly")
    h.assert_eq("no_transition", err, "Error should be no_transition")
end)

---------------------------------------------------------------------------
-- 6. Safe Takes — triggered and disarmed
---------------------------------------------------------------------------
suite("bear-trap FSM — safe takes")

test("take from triggered stays triggered (safe take)", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local trans = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(trans, "Safe take from triggered should succeed")
    h.assert_eq("triggered", trap._state, "State should remain triggered")
end)

test("safe take from triggered makes portable", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    h.assert_truthy(trap.portable, "Should be portable after safe take from triggered")
end)

test("safe take message mentions blood", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "triggered")
    h.assert_truthy(trans.message:lower():find("blood"),
        "Safe take message should mention blood")
end)

test("safe take has NO inflict_injury effect", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "triggered")
    h.assert_nil(trans.effect, "Safe take should NOT have inflict_injury effect")
end)

test("take from disarmed stays disarmed", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    -- Trigger then disarm
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    local trans = fsm_mod.transition(reg, "bear-trap", "disarmed", {}, "take")
    h.assert_truthy(trans, "Take from disarmed should succeed")
    h.assert_eq("disarmed", trap._state, "State should remain disarmed")
end)

test("take from disarmed message mentions dead weight", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "disarmed")
    h.assert_truthy(trans.message:lower():find("dead weight"),
        "Disarmed take message should mention dead weight")
end)

test("take from disarmed has NO inflict_injury effect", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "disarmed")
    h.assert_nil(trans.effect, "Disarmed take should NOT have inflict_injury effect")
end)

---------------------------------------------------------------------------
-- 7. Contact Injury Effects — take (armed)
---------------------------------------------------------------------------
suite("bear-trap — contact injury: take (armed)")

test("take transition carries inflict_injury effect", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_truthy(trans, "Take transition from set should exist")
    h.assert_truthy(trans.effect, "Take transition should have an effect")
    h.assert_eq("inflict_injury", trans.effect.type, "Effect type should be inflict_injury")
end)

test("take effect targets crushing-wound", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq("crushing-wound", trans.effect.injury_type,
        "Should inflict crushing-wound")
end)

test("take effect source is bear-trap", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq("bear-trap", trans.effect.source, "Source should be bear-trap")
end)

test("take effect location is hand", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq("hand", trans.effect.location, "Location should be hand")
end)

test("take effect damage is 15", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq(15, trans.effect.damage, "Damage should be 15")
end)

test("take effect has a pain message", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_truthy(trans.effect.message, "Effect should have a message")
    h.assert_truthy(trans.effect.message:lower():find("crush") or
                    trans.effect.message:lower():find("pain") or
                    trans.effect.message:lower():find("jaw"),
        "Effect message should describe crushing injury")
end)

---------------------------------------------------------------------------
-- 8. Contact Injury Effects — touch (armed)
---------------------------------------------------------------------------
suite("bear-trap — contact injury: touch (armed)")

test("touch transition carries inflict_injury effect", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_truthy(trans, "Touch transition from set should exist")
    h.assert_truthy(trans.effect, "Touch transition should have an effect")
    h.assert_eq("inflict_injury", trans.effect.type, "Effect type should be inflict_injury")
end)

test("touch effect targets crushing-wound", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_eq("crushing-wound", trans.effect.injury_type,
        "Should inflict crushing-wound")
end)

test("touch effect source is bear-trap", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_eq("bear-trap", trans.effect.source, "Source should be bear-trap")
end)

test("touch effect location is hand", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_eq("hand", trans.effect.location, "Location should be hand")
end)

test("touch effect damage is 15", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_eq(15, trans.effect.damage, "Damage should be 15")
end)

test("touch effect has a pain message", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_truthy(trans.effect.message, "Effect should have a message")
    h.assert_truthy(trans.effect.message:lower():find("bone") or
                    trans.effect.message:lower():find("clamp") or
                    trans.effect.message:lower():find("jaw"),
        "Effect message should describe crushing impact")
end)

---------------------------------------------------------------------------
-- 9. On-Feel Effect (armed state)
---------------------------------------------------------------------------
suite("bear-trap — on_feel effect (armed state)")

test("set state has on_feel_effect", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_feel_effect, "Set state should have on_feel_effect")
end)

test("on_feel_effect type is inflict_injury", function()
    local trap = fresh_trap()
    h.assert_eq("inflict_injury", trap.states.set.on_feel_effect.type,
        "on_feel_effect type should be inflict_injury")
end)

test("on_feel_effect targets crushing-wound", function()
    local trap = fresh_trap()
    h.assert_eq("crushing-wound", trap.states.set.on_feel_effect.injury_type,
        "on_feel_effect should target crushing-wound")
end)

test("on_feel_effect damage is 15", function()
    local trap = fresh_trap()
    h.assert_eq(15, trap.states.set.on_feel_effect.damage,
        "on_feel_effect damage should be 15")
end)

test("on_feel_effect is pipeline_routed", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_feel_effect.pipeline_routed,
        "on_feel_effect should be pipeline_routed")
end)

test("on_feel text describes snap", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_feel:find("SNAP"),
        "Set state on_feel should mention SNAP")
end)

---------------------------------------------------------------------------
-- 10. Pipeline Integration (D-EFFECTS-PIPELINE)
---------------------------------------------------------------------------
suite("bear-trap — effects pipeline integration")

test("effects_pipeline flag is true", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.effects_pipeline, "effects_pipeline should be true")
end)

test("take transition has pipeline_effects array", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_truthy(trans.pipeline_effects, "Take transition should have pipeline_effects")
    h.assert_truthy(type(trans.pipeline_effects) == "table", "pipeline_effects should be a table")
    h.assert_truthy(#trans.pipeline_effects > 0, "pipeline_effects should not be empty")
end)

test("take pipeline_effects[1] is inflict_injury", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    local first = trans.pipeline_effects[1]
    h.assert_eq("inflict_injury", first.type, "First pipeline effect should be inflict_injury")
    h.assert_eq("crushing-wound", first.injury_type, "Should inflict crushing-wound")
    h.assert_eq(15, first.damage, "Damage should be 15")
end)

test("take pipeline_effects includes narrate step", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    local found_narrate = false
    for _, effect in ipairs(trans.pipeline_effects) do
        if effect.type == "narrate" then found_narrate = true; break end
    end
    h.assert_truthy(found_narrate, "Pipeline should include a narrate step")
end)

test("take pipeline_effects includes mutate steps", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    local mutate_count = 0
    for _, effect in ipairs(trans.pipeline_effects) do
        if effect.type == "mutate" then mutate_count = mutate_count + 1 end
    end
    h.assert_truthy(mutate_count >= 3,
        "Pipeline should include at least 3 mutate steps (is_armed, is_sprung, is_dangerous)")
end)

test("touch transition has pipeline_effects array", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_truthy(trans.pipeline_effects, "Touch transition should have pipeline_effects")
    h.assert_truthy(#trans.pipeline_effects > 0, "pipeline_effects should not be empty")
end)

test("touch pipeline_effects[1] is inflict_injury", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    local first = trans.pipeline_effects[1]
    h.assert_eq("inflict_injury", first.type, "First pipeline effect should be inflict_injury")
    h.assert_eq("crushing-wound", first.injury_type, "Should inflict crushing-wound")
    h.assert_eq(15, first.damage, "Damage should be 15")
end)

test("touch pipeline_effects includes narrate step", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    local found_narrate = false
    for _, effect in ipairs(trans.pipeline_effects) do
        if effect.type == "narrate" then found_narrate = true; break end
    end
    h.assert_truthy(found_narrate, "Touch pipeline should include narrate step")
end)

---------------------------------------------------------------------------
-- 11. Backward Compatibility (legacy fields alongside pipeline)
---------------------------------------------------------------------------
suite("bear-trap — backward compatibility")

test("take has both legacy effect AND pipeline_effects", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_truthy(trans.effect, "Legacy effect field should exist")
    h.assert_truthy(trans.pipeline_effects, "Pipeline effects should also exist")
end)

test("take has both legacy mutate AND pipeline_effects mutates", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_truthy(trans.mutate, "Legacy mutate field should exist")
    h.assert_truthy(trans.pipeline_effects, "Pipeline effects with mutate steps should exist")
end)

test("touch has both legacy effect AND pipeline_effects", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "touch", "set")
    h.assert_truthy(trans.effect, "Legacy effect field should exist")
    h.assert_truthy(trans.pipeline_effects, "Pipeline effects should also exist")
end)

test("legacy effect and pipeline_effects[1] agree on injury type", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq(trans.effect.injury_type, trans.pipeline_effects[1].injury_type,
        "Legacy and pipeline injury types should match")
end)

test("legacy effect and pipeline_effects[1] agree on damage", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq(trans.effect.damage, trans.pipeline_effects[1].damage,
        "Legacy and pipeline damage should match")
end)

test("legacy effect and pipeline_effects[1] agree on source", function()
    local trap = fresh_trap()
    local trans = find_transition(trap, "take", "set")
    h.assert_eq(trans.effect.source, trans.pipeline_effects[1].source,
        "Legacy and pipeline source should match")
end)

---------------------------------------------------------------------------
-- 12. Sensory Properties — set (armed) state
---------------------------------------------------------------------------
suite("bear-trap — sensory: set state")

test("set name is 'a bear trap'", function()
    local trap = fresh_trap()
    h.assert_eq("a bear trap", trap.states.set.name, "Set state name")
end)

test("set description mentions iron jaws", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.description:lower():find("iron"),
        "Set description should mention iron")
    h.assert_truthy(trap.states.set.description:lower():find("jaw"),
        "Set description should mention jaws")
end)

test("set description mentions springs", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.description:lower():find("spring"),
        "Set description should mention springs")
end)

test("set room_presence describes parted jaws", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.room_presence:lower():find("parted"),
        "Set room_presence should mention parted jaws")
end)

test("set on_feel mentions SNAP", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_feel:find("SNAP"),
        "Set on_feel should mention SNAP")
end)

test("set on_smell mentions rust", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_smell:lower():find("rust"),
        "Set on_smell should mention rust")
end)

test("set on_listen mentions metallic", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_listen:lower():find("metallic"),
        "Set on_listen should mention metallic")
end)

test("set on_taste warns player away", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.on_taste, "Set on_taste should exist")
end)

test("set on_look is a function", function()
    local trap = fresh_trap()
    h.assert_eq("function", type(trap.states.set.on_look), "Set on_look should be a function")
end)

test("set on_look warns do not touch", function()
    local trap = fresh_trap()
    local result = trap.states.set.on_look(trap)
    h.assert_truthy(result:lower():find("do not touch"),
        "Set on_look should warn 'do not touch'")
end)

test("set state is_dangerous is true", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.is_dangerous, "Set state is_dangerous should be true")
end)

test("set state is_armed is true", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.set.is_armed, "Set state is_armed should be true")
end)

---------------------------------------------------------------------------
-- 13. Sensory Properties — triggered state
---------------------------------------------------------------------------
suite("bear-trap — sensory: triggered state")

test("triggered name is 'a sprung bear trap'", function()
    local trap = fresh_trap()
    h.assert_eq("a sprung bear trap", trap.states.triggered.name, "Triggered state name")
end)

test("triggered description mentions snapped shut", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.triggered.description:lower():find("snapped shut"),
        "Triggered description should mention snapped shut")
end)

test("triggered description mentions blood", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.triggered.description:lower():find("blood"),
        "Triggered description should mention blood")
end)

test("triggered room_presence mentions sprung", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.triggered.room_presence:lower():find("sprung"),
        "Triggered room_presence should mention sprung")
end)

test("triggered on_feel says mechanism is slack", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.triggered.on_feel:lower():find("slack"),
        "Triggered on_feel should mention slack mechanism")
end)

test("triggered on_smell mentions blood", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.triggered.on_smell:lower():find("blood"),
        "Triggered on_smell should mention blood")
end)

test("triggered is_dangerous is false", function()
    local trap = fresh_trap()
    h.assert_eq(false, trap.states.triggered.is_dangerous,
        "Triggered is_dangerous should be false")
end)

test("triggered is_armed is false", function()
    local trap = fresh_trap()
    h.assert_eq(false, trap.states.triggered.is_armed,
        "Triggered is_armed should be false")
end)

test("triggered is_sprung is true", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.triggered.is_sprung,
        "Triggered is_sprung should be true")
end)

test("triggered on_look is a function", function()
    local trap = fresh_trap()
    h.assert_eq("function", type(trap.states.triggered.on_look),
        "Triggered on_look should be a function")
end)

---------------------------------------------------------------------------
-- 14. Sensory Properties — disarmed state
---------------------------------------------------------------------------
suite("bear-trap — sensory: disarmed state")

test("disarmed name is 'a disarmed bear trap'", function()
    local trap = fresh_trap()
    h.assert_eq("a disarmed bear trap", trap.states.disarmed.name, "Disarmed state name")
end)

test("disarmed description mentions harmless", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.disarmed.description:lower():find("harmless"),
        "Disarmed description should mention harmless")
end)

test("disarmed description mentions springs neutralized", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.disarmed.description:lower():find("neutralized"),
        "Disarmed description should mention springs neutralized")
end)

test("disarmed room_presence mentions locked safely", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.disarmed.room_presence:lower():find("safely"),
        "Disarmed room_presence should mention safely")
end)

test("disarmed on_feel says inert", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.disarmed.on_feel:lower():find("inert"),
        "Disarmed on_feel should mention inert")
end)

test("disarmed is_dangerous is false", function()
    local trap = fresh_trap()
    h.assert_eq(false, trap.states.disarmed.is_dangerous,
        "Disarmed is_dangerous should be false")
end)

test("disarmed is_armed is false", function()
    local trap = fresh_trap()
    h.assert_eq(false, trap.states.disarmed.is_armed,
        "Disarmed is_armed should be false")
end)

test("disarmed is_disarmed is true", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.disarmed.is_disarmed,
        "Disarmed is_disarmed should be true")
end)

test("disarmed portable is true", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.states.disarmed.portable,
        "Disarmed state portable should be true")
end)

test("disarmed on_look is a function", function()
    local trap = fresh_trap()
    h.assert_eq("function", type(trap.states.disarmed.on_look),
        "Disarmed on_look should be a function")
end)

test("disarmed on_look mentions carry without fear", function()
    local trap = fresh_trap()
    local result = trap.states.disarmed.on_look(trap)
    h.assert_truthy(result:lower():find("without fear"),
        "Disarmed on_look should mention carrying without fear")
end)

---------------------------------------------------------------------------
-- 15. get_transitions per state
---------------------------------------------------------------------------
suite("bear-trap FSM — get_transitions per state")

test("set state offers take and touch transitions", function()
    local trap = fresh_trap()
    local transitions = fsm_mod.get_transitions(trap)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["take"], "Set should offer take")
    h.assert_truthy(verbs["touch"], "Set should offer touch")
    h.assert_truthy(not verbs["disarm"], "Set should NOT offer disarm")
end)

test("triggered state offers take and disarm transitions", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local transitions = fsm_mod.get_transitions(trap)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["take"], "Triggered should offer take (safe)")
    h.assert_truthy(verbs["disarm"], "Triggered should offer disarm")
    h.assert_truthy(not verbs["touch"], "Triggered should NOT offer touch")
end)

test("disarmed state offers only take transition", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)
    fsm_mod.transition(reg, "bear-trap", "triggered", {}, "take")
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    local transitions = fsm_mod.get_transitions(trap)
    local verbs = {}
    for _, t in ipairs(transitions) do verbs[t.verb] = true end
    h.assert_truthy(verbs["take"], "Disarmed should offer take")
    h.assert_truthy(not verbs["disarm"], "Disarmed should NOT offer disarm")
    h.assert_truthy(not verbs["touch"], "Disarmed should NOT offer touch")
end)

---------------------------------------------------------------------------
-- 16. GOAP Prerequisites
---------------------------------------------------------------------------
suite("bear-trap — GOAP prerequisites")

test("disarm prerequisite requires triggered state", function()
    local trap = fresh_trap()
    h.assert_eq("triggered", trap.prerequisites.disarm.requires_state,
        "Disarm should require triggered state")
end)

test("disarm prerequisite requires lockpicking", function()
    local trap = fresh_trap()
    h.assert_eq("lockpicking", trap.prerequisites.disarm.requires_skill,
        "Disarm should require lockpicking skill")
end)

test("disarm prerequisite requires thin_tool", function()
    local trap = fresh_trap()
    h.assert_eq("thin_tool", trap.prerequisites.disarm.requires_tool,
        "Disarm should require thin_tool")
end)

test("take prerequisite warns about injury", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.prerequisites.take.warns, "Take prereq should have warns")
    h.assert_truthy(array_contains(trap.prerequisites.take.warns, "injury"),
        "Take warns should include injury")
    h.assert_truthy(array_contains(trap.prerequisites.take.warns, "crushing-wound"),
        "Take warns should include crushing-wound")
end)

test("touch prerequisite warns about injury", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.prerequisites.touch.warns, "Touch prereq should have warns")
    h.assert_truthy(array_contains(trap.prerequisites.touch.warns, "crushing-wound"),
        "Touch warns should include crushing-wound")
end)

test("feel prerequisite warns about injury", function()
    local trap = fresh_trap()
    h.assert_truthy(trap.prerequisites.feel.warns, "Feel prereq should have warns")
    h.assert_truthy(array_contains(trap.prerequisites.feel.warns, "crushing-wound"),
        "Feel warns should include crushing-wound")
end)

---------------------------------------------------------------------------
-- 17. Crushing Wound Injury Definition Contract
---------------------------------------------------------------------------
suite("crushing-wound — injury definition contract")

test("injury id is crushing-wound", function()
    h.assert_eq("crushing-wound", crushing_def.id, "Injury id")
end)

test("injury name is Crushing Wound", function()
    h.assert_eq("Crushing Wound", crushing_def.name, "Injury name")
end)

test("injury category is physical", function()
    h.assert_eq("physical", crushing_def.category, "Category should be physical")
end)

test("damage_type is over_time", function()
    h.assert_eq("over_time", crushing_def.damage_type, "Should be over_time damage")
end)

test("initial_state is active", function()
    h.assert_eq("active", crushing_def.initial_state, "Should start in active state")
end)

test("on_inflict initial_damage is 15", function()
    h.assert_eq(15, crushing_def.on_inflict.initial_damage, "Initial damage should be 15")
end)

test("on_inflict damage_per_tick is 2", function()
    h.assert_eq(2, crushing_def.on_inflict.damage_per_tick, "Damage per tick should be 2")
end)

test("on_inflict has a message", function()
    h.assert_truthy(crushing_def.on_inflict.message, "Infliction message should exist")
    h.assert_truthy(crushing_def.on_inflict.message:lower():find("crush"),
        "Infliction message should mention crushing")
end)

test("active state damage_per_tick is 2", function()
    h.assert_eq(2, crushing_def.states.active.damage_per_tick, "Active dpt should be 2")
end)

test("treated state damage_per_tick is 0", function()
    h.assert_eq(0, crushing_def.states.treated.damage_per_tick, "Treated dpt should be 0")
end)

test("worsened state damage_per_tick is 5", function()
    h.assert_eq(5, crushing_def.states.worsened.damage_per_tick, "Worsened dpt should be 5")
end)

test("critical state damage_per_tick is 12", function()
    h.assert_eq(12, crushing_def.states.critical.damage_per_tick, "Critical dpt should be 12")
end)

test("fatal state is terminal", function()
    h.assert_truthy(crushing_def.states.fatal.terminal, "Fatal should be terminal")
end)

test("healed state is terminal", function()
    h.assert_truthy(crushing_def.states.healed.terminal, "Healed should be terminal")
end)

test("has 6 injury states", function()
    local count = 0
    for _ in pairs(crushing_def.states) do count = count + 1 end
    h.assert_eq(6, count, "Should have 6 injury states (active, treated, worsened, critical, fatal, healed)")
end)

test("active state restricts grip", function()
    h.assert_truthy(crushing_def.states.active.restricts, "Active should have restrictions")
    h.assert_truthy(crushing_def.states.active.restricts.grip,
        "Active should restrict grip")
end)

test("active state restricts climb and fight", function()
    local r = crushing_def.states.active.restricts
    h.assert_truthy(r.climb, "Active should restrict climb")
    h.assert_truthy(r.fight, "Active should restrict fight")
end)

test("treated state only restricts grip", function()
    local r = crushing_def.states.treated.restricts
    h.assert_truthy(r, "Treated should have restrictions")
    h.assert_truthy(r.grip, "Treated should restrict grip")
end)

test("worsened restricts multiple actions including run", function()
    local r = crushing_def.states.worsened.restricts
    h.assert_truthy(r.grip, "Worsened should restrict grip")
    h.assert_truthy(r.run, "Worsened should restrict run")
    h.assert_truthy(r.fight, "Worsened should restrict fight")
end)

test("critical restricts focus", function()
    local r = crushing_def.states.critical.restricts
    h.assert_truthy(r.focus, "Critical should restrict focus")
end)

---------------------------------------------------------------------------
-- 18. Crushing Wound — Healing Interactions
---------------------------------------------------------------------------
suite("crushing-wound — healing interactions")

test("bandage treats active and worsened", function()
    local bi = crushing_def.healing_interactions["bandage"]
    h.assert_truthy(bi, "Bandage should be a healing interaction")
    h.assert_eq("treated", bi.transitions_to, "Bandage should transition to treated")
    h.assert_truthy(array_contains(bi.from_states, "active"),
        "Bandage should work from active")
    h.assert_truthy(array_contains(bi.from_states, "worsened"),
        "Bandage should work from worsened")
end)

test("healing-poultice treats active, worsened, and critical", function()
    local hp = crushing_def.healing_interactions["healing-poultice"]
    h.assert_truthy(hp, "Healing-poultice should be a healing interaction")
    h.assert_eq("treated", hp.transitions_to, "Poultice should transition to treated")
    h.assert_truthy(array_contains(hp.from_states, "active"),
        "Poultice should work from active")
    h.assert_truthy(array_contains(hp.from_states, "worsened"),
        "Poultice should work from worsened")
    h.assert_truthy(array_contains(hp.from_states, "critical"),
        "Poultice should work from critical")
end)

test("has exactly 2 healing interactions", function()
    local count = 0
    for _ in pairs(crushing_def.healing_interactions) do count = count + 1 end
    h.assert_eq(2, count, "Should have exactly 2 healing interactions")
end)

---------------------------------------------------------------------------
-- 19. Crushing Wound — Timed Events (Degradation)
---------------------------------------------------------------------------
suite("crushing-wound — timed events")

test("active state has timed event to worsened", function()
    local te = crushing_def.states.active.timed_events
    h.assert_truthy(te, "Active should have timed_events")
    h.assert_eq("worsened", te[1].to_state, "Active should time out to worsened")
    h.assert_eq(4320, te[1].delay, "Active->worsened delay should be 4320 (12 turns)")
end)

test("treated state has timed event to healed", function()
    local te = crushing_def.states.treated.timed_events
    h.assert_truthy(te, "Treated should have timed_events")
    h.assert_eq("healed", te[1].to_state, "Treated should time out to healed")
    h.assert_eq(5400, te[1].delay, "Treated->healed delay should be 5400 (15 turns)")
end)

test("worsened state has timed event to critical", function()
    local te = crushing_def.states.worsened.timed_events
    h.assert_truthy(te, "Worsened should have timed_events")
    h.assert_eq("critical", te[1].to_state, "Worsened should time out to critical")
    h.assert_eq(3600, te[1].delay, "Worsened->critical delay should be 3600 (10 turns)")
end)

test("critical state has timed event to fatal", function()
    local te = crushing_def.states.critical.timed_events
    h.assert_truthy(te, "Critical should have timed_events")
    h.assert_eq("fatal", te[1].to_state, "Critical should time out to fatal")
    h.assert_eq(1800, te[1].delay, "Critical->fatal delay should be 1800 (5 turns)")
end)

---------------------------------------------------------------------------
-- 20. Injury Engine Integration — Inflict and Tick
---------------------------------------------------------------------------
suite("bear-trap — injury engine: inflict crushing-wound")

test("inflicting crushing-wound creates injury on player", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "crushing-wound", "bear-trap")
    end)
    h.assert_eq(1, #p.injuries, "Should have 1 injury")
    h.assert_eq("crushing-wound", p.injuries[1].type, "Injury type should match")
    h.assert_eq("bear-trap", p.injuries[1].source, "Source should be bear-trap")
    h.assert_eq("active", p.injuries[1]._state, "Injury should start in active state")
end)

test("crushing-wound initial damage is 15", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "crushing-wound", "bear-trap")
    end)
    h.assert_eq(15, p.injuries[1].damage, "Initial damage should be 15")
end)

test("crushing-wound damage_per_tick is 2", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "crushing-wound", "bear-trap")
    end)
    h.assert_eq(2, p.injuries[1].damage_per_tick, "Damage per tick should be 2")
end)

test("crushing-wound ticks health down each turn", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "crushing-wound", "bear-trap") end)
    local health_before = injury_mod.compute_health(p)
    capture_print(function() injury_mod.tick(p) end)
    local health_after = injury_mod.compute_health(p)
    h.assert_truthy(health_after < health_before,
        "Health should decrease each tick (was " .. health_before .. ", now " .. health_after .. ")")
end)

test("crushing-wound accumulates damage over 5 ticks", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "crushing-wound", "bear-trap") end)
    for i = 1, 5 do
        capture_print(function() injury_mod.tick(p) end)
    end
    -- 15 + (5 * 2) = 25
    h.assert_eq(25, p.injuries[1].damage,
        "Damage after 5 ticks should be 25 (15 + 5*2)")
    h.assert_eq(75, injury_mod.compute_health(p),
        "Health after 5 ticks should be 75")
end)

test("crushing-wound does not kill immediately", function()
    setup_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "crushing-wound", "bear-trap") end)
    local health = injury_mod.compute_health(p)
    h.assert_truthy(health > 0,
        "Should not die on infliction alone (health = " .. health .. ")")
    local _, died
    capture_print(function() _, died = injury_mod.tick(p) end)
    h.assert_truthy(not died, "Should not die after first tick with full health")
end)

test("player can eventually die from untreated crushing-wound", function()
    setup_injuries()
    local p = fresh_player()
    p.max_health = 30
    capture_print(function() injury_mod.inflict(p, "crushing-wound", "bear-trap") end)
    local died = false
    for i = 1, 50 do
        capture_print(function()
            local _, d = injury_mod.tick(p)
            if d then died = true end
        end)
        if died then break end
    end
    h.assert_truthy(died, "Player should die from untreated crushing wound (low health)")
end)

---------------------------------------------------------------------------
-- 21. Full FSM Journey: set → triggered → disarmed
---------------------------------------------------------------------------
suite("bear-trap — full FSM journey")

test("complete lifecycle: set → triggered → disarmed → take", function()
    local trap = fresh_trap()
    local reg = make_registry_with(trap)

    -- Step 1: Armed
    h.assert_eq("set", trap._state, "Should start in set")
    h.assert_truthy(trap.is_armed, "Should be armed")

    -- Step 2: Trigger via touch
    local t1 = fsm_mod.transition(reg, "bear-trap", "triggered", {}, "touch")
    h.assert_truthy(t1, "Touch trigger should succeed")
    h.assert_eq("triggered", trap._state, "Should be triggered")
    h.assert_eq(false, trap.is_armed, "Should no longer be armed")
    h.assert_truthy(trap.is_sprung, "Should be sprung")

    -- Step 3: Disarm with lockpicking
    local ctx = {
        player = {
            has_skill = function(skill) return skill == "lockpicking" end,
        },
    }
    local t2 = fsm_mod.transition(reg, "bear-trap", "disarmed", ctx, "disarm")
    h.assert_truthy(t2, "Disarm should succeed")
    h.assert_eq("disarmed", trap._state, "Should be disarmed")
    h.assert_truthy(trap.is_disarmed, "Should have is_disarmed flag")
    h.assert_truthy(trap.portable, "Should be portable")

    -- Step 4: Safe take
    local t3 = fsm_mod.transition(reg, "bear-trap", "disarmed", {}, "take")
    h.assert_truthy(t3, "Take from disarmed should succeed")
    h.assert_eq("disarmed", trap._state, "Should remain disarmed")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local fail_count = h.summary()
if fail_count > 0 then
    os.exit(1)
end
