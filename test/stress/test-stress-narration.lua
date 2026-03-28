-- test/stress/test-stress-narration.lua
-- WAVE-3: Stress narration tests (Smithers — UI Engineer).
-- Tests: trigger narration, level-change narration, cure narration,
--        status bar stress indicator.
--
-- Must be run from repository root: lua test/stress/test-stress-narration.lua

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------
local injury_ok, injury_mod = pcall(require, "engine.injuries")
if not injury_ok then
    print("WARNING: engine.injuries not loadable — " .. tostring(injury_mod))
    injury_mod = nil
end

local status_ok, status_mod = pcall(require, "engine.ui.status")

---------------------------------------------------------------------------
-- Stress definition (mirrors spec)
---------------------------------------------------------------------------
local stress_def = {
    id = "stress",
    name = "acute stress",
    category = "psychological",
    damage_type = "accumulator",
    initial_state = "active",
    on_inflict = { initial_damage = 0, message = "" },
    levels = {
        { name = "shaken",      threshold = 3,  description = "Your hands tremble slightly." },
        { name = "distressed",  threshold = 6,  description = "You're breathing hard, heart pounding." },
        { name = "overwhelmed", threshold = 10, description = "Panic grips you. Everything feels wrong." },
    },
    effects = {
        shaken      = { attack_penalty = -1 },
        distressed  = { attack_penalty = -2, flee_bias = 0.2 },
        overwhelmed = { attack_penalty = -2, flee_bias = 0.3, movement_penalty = 0.2 },
    },
    triggers = {
        witness_creature_death = 1,
        near_death_combat      = 2,
        witness_gore           = 1,
    },
    states = {
        active = { name = "stressed", description = "Psychological stress.", damage_per_tick = 0 },
        healed = { name = "calm", description = "The stress has passed.", terminal = true },
    },
    healing_interactions = {},
}

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------
local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        stress = 0,
        stress_level = nil,
        stress_effects = {},
        hands = { nil, nil },
        worn = {},
        state = {},
        room = "test-room",
    }
end

local function capture_output(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Error in capture: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function setup()
    if injury_mod and injury_mod.clear_cache then injury_mod.clear_cache() end
    if injury_mod and injury_mod.reset_id_counter then injury_mod.reset_id_counter() end
    if injury_mod and injury_mod.register_definition then
        injury_mod.register_definition("stress", stress_def)
    end
end

---------------------------------------------------------------------------
-- TESTS: Trigger Narration
---------------------------------------------------------------------------
suite("STRESS NARRATION: trigger messages (WAVE-3)")

test("1. witness_creature_death prints death narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    local output = capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_truthy(output:find("sight of death"), "Must narrate death witness")
end)

test("2. near_death_combat prints terror narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    local output = capture_output(function()
        injury_mod.add_stress(player, "near_death_combat")
    end)
    h.assert_truthy(output:find("wave of terror"), "Must narrate near-death terror")
end)

test("3. witness_gore prints gore narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    local output = capture_output(function()
        injury_mod.add_stress(player, "witness_gore")
    end)
    h.assert_truthy(output:find("gore turns your stomach"), "Must narrate gore witness")
end)

---------------------------------------------------------------------------
-- TESTS: Level-Change Narration
---------------------------------------------------------------------------
suite("STRESS NARRATION: level-change messages (WAVE-3)")

test("4. crossing shaken threshold prints tremble narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    -- 2 stress: below shaken (no level change yet)
    capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    -- 3rd stress crosses threshold=3 → shaken
    local output = capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_truthy(output:find("hands begin to tremble"),
        "Must narrate level change to shaken")
end)

test("5. crossing distressed threshold prints breathing narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    -- Build up to 5 stress (shaken)
    for i = 1, 5 do
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    end
    h.assert_eq("shaken", player.stress_level, "Must be shaken at stress=5")
    -- 6th stress crosses threshold=6 → distressed
    local output = capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_truthy(output:find("breathing quickens"),
        "Must narrate level change to distressed")
end)

test("6. crossing overwhelmed threshold prints panic narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    -- Build to 9 stress (distressed)
    for i = 1, 9 do
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    end
    h.assert_eq("distressed", player.stress_level, "Must be distressed at stress=9")
    -- 10th stress crosses threshold=10 → overwhelmed
    local output = capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_truthy(output:find("Panic overwhelms you"),
        "Must narrate level change to overwhelmed")
end)

test("7. no level-change narration when level stays the same", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    -- Get to shaken (3 stress)
    for i = 1, 3 do
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    end
    h.assert_eq("shaken", player.stress_level, "Must be shaken at stress=3")
    -- 4th stress: still shaken (next threshold is 6)
    local output = capture_output(function()
        injury_mod.add_stress(player, "witness_creature_death")
    end)
    h.assert_truthy(not output:find("hands begin to tremble"),
        "Must NOT repeat level-change narration when level unchanged")
end)

---------------------------------------------------------------------------
-- TESTS: Cure Narration
---------------------------------------------------------------------------
suite("STRESS NARRATION: cure messages (WAVE-3)")

test("8. curing stress prints fade narration", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    -- Build stress
    for i = 1, 3 do
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    end
    h.assert_eq(3, player.stress, "Pre-condition: stress=3")
    local ctx = { room = { id = "safe", creatures = {} } }
    local output = capture_output(function()
        injury_mod.cure_stress(player, ctx)
    end)
    h.assert_truthy(output:find("panic slowly fades"),
        "Must narrate stress cure")
    h.assert_eq(0, player.stress, "Stress must be 0 after cure")
end)

---------------------------------------------------------------------------
-- TESTS: Status Bar Integration
---------------------------------------------------------------------------
suite("STRESS NARRATION: status bar indicator (WAVE-3)")

test("9. status bar shows stress level when stressed", function()
    h.assert_truthy(status_ok, "engine.ui.status must load")
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()
    -- Build to shaken
    for i = 1, 3 do
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    end

    -- Mock UI context
    local status_left, status_right
    local mock_ui = {
        status = function(l, r) status_left = l; status_right = r end,
        is_enabled = function() return true end,
    }
    local ctx = {
        player = player,
        current_room = { id = "start-room", name = "Bedroom" },
        ui = mock_ui,
        time_offset = 0,
        game_start_time = os.time(),
    }

    local updater = status_mod.create_updater()
    updater(ctx)

    h.assert_truthy(status_right and status_right:find("Shaken"),
        "Status bar right side must contain 'Shaken' when player is shaken, got: "
        .. tostring(status_right))
end)

test("10. status bar hides stress when player has no stress", function()
    h.assert_truthy(status_ok, "engine.ui.status must load")
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()

    local player = fresh_player()

    local status_left, status_right
    local mock_ui = {
        status = function(l, r) status_left = l; status_right = r end,
        is_enabled = function() return true end,
    }
    local ctx = {
        player = player,
        current_room = { id = "start-room", name = "Bedroom" },
        ui = mock_ui,
        time_offset = 0,
        game_start_time = os.time(),
    }

    local updater = status_mod.create_updater()
    updater(ctx)

    local has_stress_text = status_right and (
        status_right:find("Shaken") or
        status_right:find("Distressed") or
        status_right:find("Overwhelmed")
    )
    h.assert_truthy(not has_stress_text,
        "Status bar must NOT show stress level when unstressed, got: "
        .. tostring(status_right))
end)

test("11. injuries list includes stress description", function()
    h.assert_truthy(injury_mod, "engine.injuries must load")
    setup()
    local player = fresh_player()
    for i = 1, 3 do
        capture_output(function()
            injury_mod.add_stress(player, "witness_creature_death")
        end)
    end
    local output = capture_output(function()
        injury_mod.list(player)
    end)
    h.assert_truthy(output:find("hands tremble"),
        "injuries list must show stress description, got: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
