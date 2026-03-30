-- test/injuries/test-unconsciousness-triggers.lua
-- TDD RED PHASE: Failing tests for unconsciousness trigger objects (#162)
--
-- Tests the 4 trigger objects specified in
-- docs/design/injuries/unconsciousness-triggers.md:
--   1. falling-rock-trap   (severe, 10-15 turns)
--   2. unstable-ceiling    (severe, 12-18 turns, stacks concussion + crushing-wound)
--   3. poison-gas-vent     (minor, 3-5 turns, resets after wake)
--   4. falling-club-trap   (moderate, 6-10 turns)
--
-- All tests should FAIL in TDD red phase — trigger objects don't exist yet.
--
-- Usage: lua test/injuries/test-unconsciousness-triggers.lua
-- Must be run from the repository root.

package.path = "./test/parser/?.lua;./src/?.lua;./src/?/init.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

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
    if not ok then error(err, 2) end
    return table.concat(lines, "\n")
end

-- Load injury engine
local injury_mod = require("engine.injuries")
injury_mod.clear_cache()
injury_mod.reset_id_counter()

local concussion_def = require("meta.worlds.manor.injuries.concussion")
injury_mod.register_definition("concussion", concussion_def)

local bleeding_def = require("meta.worlds.manor.injuries.bleeding")
injury_mod.register_definition("bleeding", bleeding_def)

local crushing_def = require("meta.worlds.manor.injuries.crushing-wound")
injury_mod.register_definition("crushing-wound", crushing_def)

-- Try to load the 4 trigger object definitions.
-- These DON'T EXIST yet — TDD red phase. We pcall to avoid hard crash.
local rock_trap_ok, rock_trap_def = pcall(require, "meta.worlds.manor.objects.falling-rock-trap")
local ceiling_ok, ceiling_def = pcall(require, "meta.worlds.manor.objects.unstable-ceiling")
local gas_ok, gas_def = pcall(require, "meta.worlds.manor.objects.poison-gas-vent")
local club_ok, club_def = pcall(require, "meta.worlds.manor.objects.falling-club-trap")

-- Load verb handlers
local verbs_ok, verbs_mod = pcall(require, "engine.verbs")

-- Simulate the consciousness gate (mirrors loop/init.lua)
local function simulate_consciousness_gate(ctx)
    local player = ctx.player
    if not (player and player.consciousness
            and player.consciousness.state == "unconscious") then
        return "already_conscious", nil
    end

    local msgs, died = injury_mod.tick(player)

    if died then
        ctx.game_over = true
        return "died", msgs
    end

    player.consciousness.wake_timer = player.consciousness.wake_timer - 1

    if player.consciousness.wake_timer <= 0 then
        local health = injury_mod.compute_health(player)
        local max_hp = player.max_health or 100
        player.consciousness.state = "conscious"
        player.consciousness.wake_timer = 0
        player.consciousness.cause = nil
        player.consciousness.unconscious_since = nil
        return "woke_up", msgs
    end

    return "still_unconscious", msgs
end

local function fresh_player(opts)
    opts = opts or {}
    return {
        hands = { nil, nil },
        worn = opts.worn or {},
        max_health = opts.max_health or 100,
        injuries = opts.injuries or {},
        consciousness = opts.consciousness or {
            state = "conscious",
            wake_timer = 0,
            cause = nil,
            unconscious_since = nil,
        },
        state = opts.state or {
            bloody = false,
            poisoned = false,
            has_flame = 0,
        },
    }
end

local function make_ctx(opts)
    opts = opts or {}
    local player = opts.player or fresh_player(opts)

    local registry_data = opts.registry_data or {}
    local reg = {
        get = function(self, id) return registry_data[id] end,
        find_by_keyword = function(self, kw)
            for _, obj in pairs(registry_data) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k == kw then return obj end
                    end
                end
                if obj.id == kw then return obj end
            end
            return nil
        end,
    }

    return {
        registry = reg,
        current_room = opts.room or { id = "test-room", name = "Test Room", contents = {} },
        player = player,
        time_offset = opts.time_offset or 0,
        headless = true,
        game_over = false,
    }
end

---------------------------------------------------------------------------
-- SUITE 1: Trigger object definitions exist and have required fields
---------------------------------------------------------------------------
suite("#162 — Trigger object definitions exist")

test("falling-rock-trap.lua loads from meta.objects", function()
    h.assert_truthy(rock_trap_ok,
        "falling-rock-trap.lua must exist in src/meta/worlds/manor/objects/")
    h.assert_truthy(rock_trap_def, "falling-rock-trap must return a table")
end)

test("unstable-ceiling.lua loads from meta.objects", function()
    h.assert_truthy(ceiling_ok,
        "unstable-ceiling.lua must exist in src/meta/worlds/manor/objects/")
    h.assert_truthy(ceiling_def, "unstable-ceiling must return a table")
end)

test("poison-gas-vent.lua loads from meta.objects", function()
    h.assert_truthy(gas_ok,
        "poison-gas-vent.lua must exist in src/meta/worlds/manor/objects/")
    h.assert_truthy(gas_def, "poison-gas-vent must return a table")
end)

test("falling-club-trap.lua loads from meta.objects", function()
    h.assert_truthy(club_ok,
        "falling-club-trap.lua must exist in src/meta/worlds/manor/objects/")
    h.assert_truthy(club_def, "falling-club-trap must return a table")
end)

---------------------------------------------------------------------------
-- SUITE 2: Each trigger declares unconsciousness metadata
---------------------------------------------------------------------------
suite("#162 — Trigger objects declare unconsciousness fields")

test("falling-rock-trap declares causes_unconsciousness", function()
    h.assert_truthy(rock_trap_ok, "object must load first")
    h.assert_eq(true, rock_trap_def.causes_unconsciousness,
        "falling-rock-trap must have causes_unconsciousness = true")
end)

test("falling-rock-trap has severe severity", function()
    h.assert_truthy(rock_trap_ok, "object must load first")
    h.assert_eq("severe", rock_trap_def.unconscious_severity,
        "falling-rock-trap severity must be severe")
end)

test("unstable-ceiling declares causes_unconsciousness", function()
    h.assert_truthy(ceiling_ok, "object must load first")
    h.assert_eq(true, ceiling_def.causes_unconsciousness,
        "unstable-ceiling must have causes_unconsciousness = true")
end)

test("unstable-ceiling has severe severity", function()
    h.assert_truthy(ceiling_ok, "object must load first")
    h.assert_eq("severe", ceiling_def.unconscious_severity,
        "unstable-ceiling severity must be severe")
end)

test("poison-gas-vent declares causes_unconsciousness", function()
    h.assert_truthy(gas_ok, "object must load first")
    h.assert_eq(true, gas_def.causes_unconsciousness,
        "poison-gas-vent must have causes_unconsciousness = true")
end)

test("poison-gas-vent has minor severity", function()
    h.assert_truthy(gas_ok, "object must load first")
    h.assert_eq("minor", gas_def.unconscious_severity,
        "poison-gas-vent severity must be minor")
end)

test("falling-club-trap declares causes_unconsciousness", function()
    h.assert_truthy(club_ok, "object must load first")
    h.assert_eq(true, club_def.causes_unconsciousness,
        "falling-club-trap must have causes_unconsciousness = true")
end)

test("falling-club-trap has moderate severity", function()
    h.assert_truthy(club_ok, "object must load first")
    h.assert_eq("moderate", club_def.unconscious_severity,
        "falling-club-trap severity must be moderate")
end)

---------------------------------------------------------------------------
-- SUITE 3: Duration varies by trigger type
---------------------------------------------------------------------------
suite("#162 — Duration varies by trigger severity")

test("rock trap duration maps to severe concussion (10+ turns)", function()
    h.assert_truthy(rock_trap_ok, "object must load first")
    local severity = rock_trap_def.unconscious_severity
    h.assert_eq("severe", severity, "severity must be severe")
    local duration = concussion_def.unconscious_duration[severity]
    h.assert_truthy(duration and duration >= 10,
        "severe concussion duration must be >= 10 turns (got "
        .. tostring(duration) .. ")")
end)

test("gas vent duration maps to minor concussion (3+ turns)", function()
    h.assert_truthy(gas_ok, "object must load first")
    local severity = gas_def.unconscious_severity
    h.assert_eq("minor", severity, "severity must be minor")
    local duration = concussion_def.unconscious_duration[severity]
    h.assert_truthy(duration and duration >= 3 and duration <= 5,
        "minor concussion duration must be 3-5 turns (got "
        .. tostring(duration) .. ")")
end)

test("club trap duration maps to moderate concussion (5+ turns)", function()
    h.assert_truthy(club_ok, "object must load first")
    local severity = club_def.unconscious_severity
    h.assert_eq("moderate", severity, "severity must be moderate")
    local duration = concussion_def.unconscious_duration[severity]
    h.assert_truthy(duration and duration >= 5,
        "moderate concussion duration must be >= 5 turns (got "
        .. tostring(duration) .. ")")
end)

test("rock trap KO is longer than gas vent KO", function()
    h.assert_truthy(rock_trap_ok and gas_ok, "both objects must load")
    local rock_dur = concussion_def.unconscious_duration[
        rock_trap_def.unconscious_severity] or 0
    local gas_dur = concussion_def.unconscious_duration[
        gas_def.unconscious_severity] or 0
    h.assert_truthy(rock_dur > gas_dur,
        "rock duration (" .. rock_dur .. ") must exceed gas duration (" .. gas_dur .. ")")
end)

---------------------------------------------------------------------------
-- SUITE 4: Self-infliction triggers unconsciousness
---------------------------------------------------------------------------
suite("#162 — Self-infliction causes unconsciousness")

test("'breathe gas' triggers unconsciousness via poison-gas-vent", function()
    h.assert_truthy(gas_ok and verbs_ok, "gas vent + verbs must load")
    local handlers = verbs_mod.create()
    local ctx = make_ctx({
        registry_data = { ["poison-gas-vent"] = gas_def },
    })

    capture_print(function() handlers["breathe"](ctx, "gas") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must be unconscious after 'breathe gas'")
end)

test("'trigger rock trap' triggers unconsciousness via falling-rock-trap", function()
    h.assert_truthy(rock_trap_ok and verbs_ok, "rock trap + verbs must load")
    local handlers = verbs_mod.create()
    local ctx = make_ctx({
        registry_data = { ["falling-rock-trap"] = rock_trap_def },
    })

    capture_print(function() handlers["trigger"](ctx, "rock trap") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must be unconscious after 'trigger rock trap'")
end)

test("'step on plate' triggers unconsciousness via falling-club-trap", function()
    h.assert_truthy(club_ok and verbs_ok, "club trap + verbs must load")
    local handlers = verbs_mod.create()
    local ctx = make_ctx({
        registry_data = { ["falling-club-trap"] = club_def },
    })

    capture_print(function() handlers["step"](ctx, "plate") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must be unconscious after 'step on plate'")
end)

test("'push beam' triggers unconsciousness via unstable-ceiling", function()
    h.assert_truthy(ceiling_ok and verbs_ok, "ceiling + verbs must load")
    local handlers = verbs_mod.create()
    local ctx = make_ctx({
        registry_data = { ["unstable-ceiling"] = ceiling_def },
    })

    capture_print(function() handlers["push"](ctx, "beam") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must be unconscious after 'push beam'")
end)

---------------------------------------------------------------------------
-- SUITE 5: Ceiling collapse stacks concussion + crushing-wound
---------------------------------------------------------------------------
suite("#162 — Ceiling collapse inflicts dual injuries")

test("unstable-ceiling inflicts both concussion and crushing-wound", function()
    h.assert_truthy(ceiling_ok and verbs_ok, "ceiling + verbs must load")
    local handlers = verbs_mod.create()
    local ctx = make_ctx({
        registry_data = { ["unstable-ceiling"] = ceiling_def },
    })

    capture_print(function() handlers["push"](ctx, "beam") end)

    local has_concussion = false
    local has_crushing = false
    for _, inj in ipairs(ctx.player.injuries) do
        if inj.type == "concussion" then has_concussion = true end
        if inj.type == "crushing-wound" then has_crushing = true end
    end

    h.assert_truthy(has_concussion,
        "ceiling collapse must inflict concussion injury")
    h.assert_truthy(has_crushing,
        "ceiling collapse must inflict crushing-wound injury")
end)

---------------------------------------------------------------------------
-- SUITE 6: Injuries tick during unconsciousness
---------------------------------------------------------------------------
suite("#162 — Injuries continue ticking during unconsciousness")

test("bleeding ticks during rock trap unconsciousness", function()
    injury_mod.reset_id_counter()
    local player = fresh_player()

    -- Inflict bleeding first (external source)
    capture_print(function()
        injury_mod.inflict(player, "bleeding", "knife-wound")
    end)
    local health_before = injury_mod.compute_health(player)

    -- Simulate unconsciousness from rock trap
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 10
    player.consciousness.cause = "falling-rock-trap"

    -- Tick 3 turns while unconscious
    local ctx = make_ctx({ player = player })
    for i = 1, 3 do
        simulate_consciousness_gate(ctx)
    end

    local health_after = injury_mod.compute_health(player)
    h.assert_truthy(health_after < health_before,
        "health must decrease during unconsciousness from bleeding "
        .. "(before=" .. health_before .. " after=" .. health_after .. ")")
end)

test("nightshade poison ticks during gas vent unconsciousness", function()
    injury_mod.reset_id_counter()

    -- Register nightshade if available
    local ns_ok, ns_def = pcall(require, "meta.worlds.manor.injuries.poisoned-nightshade")
    h.assert_truthy(ns_ok, "nightshade injury definition must load")
    injury_mod.register_definition("poisoned-nightshade", ns_def)

    local player = fresh_player()

    -- Inflict nightshade first (external source)
    capture_print(function()
        injury_mod.inflict(player, "poisoned-nightshade", "poison-bottle")
    end)
    local health_before = injury_mod.compute_health(player)

    -- Simulate gas vent KO (short: 3-5 turns)
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 3
    player.consciousness.cause = "poison-gas-vent"

    local ctx = make_ctx({ player = player })
    for i = 1, 3 do
        simulate_consciousness_gate(ctx)
    end

    local health_after = injury_mod.compute_health(player)
    h.assert_truthy(health_after < health_before,
        "nightshade poison must tick during gas KO "
        .. "(before=" .. health_before .. " after=" .. health_after .. ")")
end)

---------------------------------------------------------------------------
-- SUITE 7: Player wakes up in same room after duration expires
---------------------------------------------------------------------------
suite("#162 — Player wakes in same room after KO duration")

test("player wakes in same room after rock trap KO", function()
    injury_mod.reset_id_counter()
    local test_room = { id = "cellar-passage", name = "Cellar Passage", contents = {} }
    local player = fresh_player()

    -- Simulate severe concussion KO (10 turns)
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 10
    player.consciousness.cause = "falling-rock-trap"

    local ctx = make_ctx({ player = player, room = test_room })

    for i = 1, 10 do
        simulate_consciousness_gate(ctx)
    end

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "player must be conscious after 10 ticks")
    h.assert_eq("cellar-passage", ctx.current_room.id,
        "player must be in same room after waking")
end)

test("player wakes in same room after gas vent KO", function()
    injury_mod.reset_id_counter()
    local test_room = { id = "storage-cellar", name = "Storage Cellar", contents = {} }
    local player = fresh_player()

    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 3
    player.consciousness.cause = "poison-gas-vent"

    local ctx = make_ctx({ player = player, room = test_room })

    for i = 1, 3 do
        simulate_consciousness_gate(ctx)
    end

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "player must be conscious after 3 ticks")
    h.assert_eq("storage-cellar", ctx.current_room.id,
        "player must be in same room after waking from gas")
end)

test("player wakes in same room after club trap KO", function()
    injury_mod.reset_id_counter()
    local test_room = { id = "hallway", name = "Hallway", contents = {} }
    local player = fresh_player()

    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 6
    player.consciousness.cause = "falling-club-trap"

    local ctx = make_ctx({ player = player, room = test_room })

    for i = 1, 6 do
        simulate_consciousness_gate(ctx)
    end

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "player must be conscious after 6 ticks")
    h.assert_eq("hallway", ctx.current_room.id,
        "player must be in same room after waking from club trap")
end)

---------------------------------------------------------------------------
-- SUITE 8: Commands rejected while unconscious
---------------------------------------------------------------------------
suite("#162 — Commands rejected with narration during unconsciousness")

test("'look' rejected while unconscious with narration", function()
    h.assert_truthy(verbs_ok, "verbs must load")
    local handlers = verbs_mod.create()
    local player = fresh_player()
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 5
    player.consciousness.cause = "falling-rock-trap"

    local ctx = make_ctx({ player = player })

    -- The verb handler (or game loop gate) must check consciousness
    -- BEFORE executing the command. Currently look crashes on nil noun
    -- when called while unconscious — this is exactly the bug TDD catches.
    -- The handler should detect unconscious state and print rejection text.
    local output = ""
    local ok, err = pcall(function()
        output = capture_print(function()
            handlers["look"](ctx, "around")
        end)
    end)

    -- Either: handler ran without error and rejected gracefully, OR
    -- the consciousness gate should have prevented the call entirely.
    h.assert_truthy(ok,
        "look while unconscious must not crash (got: " .. tostring(err) .. ")")
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must still be unconscious after rejected 'look'")
    h.assert_truthy(output and #output > 0,
        "rejected command must produce narration text")
end)

test("'inventory' rejected while unconscious", function()
    h.assert_truthy(verbs_ok, "verbs must load")
    local handlers = verbs_mod.create()
    local player = fresh_player()
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 5
    player.consciousness.cause = "poison-gas-vent"

    local ctx = make_ctx({ player = player })
    local output = capture_print(function()
        handlers["inventory"](ctx, nil)
    end)

    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must still be unconscious after rejected 'inventory'")
end)

test("'get' rejected while unconscious", function()
    h.assert_truthy(verbs_ok, "verbs must load")
    local handlers = verbs_mod.create()
    local player = fresh_player()
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 8
    player.consciousness.cause = "falling-club-trap"

    local ctx = make_ctx({ player = player })
    local output = capture_print(function()
        handlers["get"](ctx, "candle")
    end)

    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must still be unconscious after rejected 'get'")
end)

---------------------------------------------------------------------------
-- SUITE 9: Trigger object required fields (sensory, FSM, material)
---------------------------------------------------------------------------
suite("#162 — Trigger objects have required sensory/FSM fields")

test("falling-rock-trap has on_feel (primary dark sense)", function()
    h.assert_truthy(rock_trap_ok, "object must load first")
    h.assert_truthy(rock_trap_def.on_feel and #rock_trap_def.on_feel > 0,
        "falling-rock-trap must have on_feel description")
end)

test("poison-gas-vent has FSM states (leaking, active, plugged)", function()
    h.assert_truthy(gas_ok, "object must load first")
    h.assert_truthy(gas_def.states, "gas vent must have states table")
    h.assert_truthy(gas_def.states.leaking,
        "gas vent must have 'leaking' state")
    h.assert_truthy(gas_def.states.active,
        "gas vent must have 'active' state")
    h.assert_truthy(gas_def.states.plugged,
        "gas vent must have 'plugged' state")
end)

test("falling-rock-trap has FSM states (armed, triggered, spent)", function()
    h.assert_truthy(rock_trap_ok, "object must load first")
    h.assert_truthy(rock_trap_def.states, "rock trap must have states table")
    h.assert_truthy(rock_trap_def.states.armed,
        "rock trap must have 'armed' state")
    h.assert_truthy(rock_trap_def.states.triggered,
        "rock trap must have 'triggered' state")
    h.assert_truthy(rock_trap_def.states.spent,
        "rock trap must have 'spent' state")
end)

test("falling-club-trap has on_feel and keywords", function()
    h.assert_truthy(club_ok, "object must load first")
    h.assert_truthy(club_def.on_feel and #club_def.on_feel > 0,
        "club trap must have on_feel description")
    h.assert_truthy(club_def.keywords and #club_def.keywords > 0,
        "club trap must have keywords list")
end)

---------------------------------------------------------------------------
-- SUITE 10: Self-inflicted KO + external injury stacking (death risk)
---------------------------------------------------------------------------
suite("#162 — Self-inflicted KO + external bleeding = death possible")

test("self-KO with active external bleeding can cause death", function()
    injury_mod.reset_id_counter()
    local player = fresh_player({ max_health = 30 })

    -- Inflict bleeding from external source (5 initial + 5/tick)
    capture_print(function()
        injury_mod.inflict(player, "bleeding", "knife-wound")
    end)

    -- Self-inflicted unconsciousness (long duration)
    player.consciousness.state = "unconscious"
    player.consciousness.wake_timer = 15
    player.consciousness.cause = "self-inflicted:falling-rock-trap"

    -- Tick until death or wake
    local ctx = make_ctx({ player = player })
    local died = false
    for i = 1, 15 do
        local status = simulate_consciousness_gate(ctx)
        if status == "died" then
            died = true
            break
        end
    end

    -- With 30 HP, 5 initial bleed damage (25 HP left), 5/tick bleed:
    -- After 5 ticks: 25 - 25 = 0 → should die
    h.assert_truthy(died,
        "self-inflicted KO + external bleeding must allow death "
        .. "(D-SELF-INFLICT-CEILING doesn't protect external injuries)")
end)

---------------------------------------------------------------------------
-- SUITE 11: Gas vent resets after wake (re-KO possible)
---------------------------------------------------------------------------
suite("#162 — Gas vent resets (can KO again after wake)")

test("gas vent returns to leaking state after player wakes", function()
    h.assert_truthy(gas_ok, "gas vent must load")

    -- Verify the FSM design: active → leaking (reset cycle)
    h.assert_truthy(gas_def.states, "gas vent must have states")

    -- Find a transition from active back to leaking
    local has_reset = false
    if gas_def.transitions then
        for _, t in ipairs(gas_def.transitions) do
            if t.from == "active" and t.to == "leaking" then
                has_reset = true
                break
            end
        end
    end
    h.assert_truthy(has_reset,
        "gas vent must have transition from 'active' back to 'leaking' (reset)")
end)

test("gas vent can knock player out twice in succession", function()
    h.assert_truthy(gas_ok and verbs_ok, "gas vent + verbs must load")
    local handlers = verbs_mod.create()

    -- #402: Reset shared gas_def state (earlier tests may have changed it
    -- via fsm.transition, which now correctly mutates state)
    gas_def._state = "leaking"

    -- First KO
    local ctx = make_ctx({
        registry_data = { ["poison-gas-vent"] = gas_def },
    })
    capture_print(function() handlers["breathe"](ctx, "gas") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "first gas KO must work")

    -- Wake up
    for i = 1, 5 do simulate_consciousness_gate(ctx) end
    ctx.player.consciousness.state = "conscious"
    ctx.player.consciousness.wake_timer = 0

    -- #402: fsm_interact now correctly changes state via fsm.transition(),
    -- so the vent is in "active" state after the first KO. Simulate the
    -- game-loop auto-reset (from="active", to="leaking", trigger="auto",
    -- condition="player_wakes") that would fire when the player wakes.
    gas_def._state = "leaking"

    -- Second KO (gas resets)
    capture_print(function() handlers["breathe"](ctx, "gas") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "second gas KO must work (vent resets after wake)")
end)

---------------------------------------------------------------------------
-- SUITE 12: Trigger objects use concussion injury type
---------------------------------------------------------------------------
suite("#162 — All triggers use concussion injury type")

test("falling-rock-trap specifies concussion as injury_type", function()
    h.assert_truthy(rock_trap_ok, "object must load first")
    h.assert_eq("concussion", rock_trap_def.injury_type,
        "rock trap must use concussion injury type")
end)

test("poison-gas-vent specifies concussion as injury_type", function()
    h.assert_truthy(gas_ok, "object must load first")
    h.assert_eq("concussion", gas_def.injury_type,
        "gas vent must use concussion injury type")
end)

test("falling-club-trap specifies concussion as injury_type", function()
    h.assert_truthy(club_ok, "object must load first")
    h.assert_eq("concussion", club_def.injury_type,
        "club trap must use concussion injury type")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
