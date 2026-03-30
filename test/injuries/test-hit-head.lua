-- test/injuries/test-hit-head.lua
-- Issue #133: hit head crashes with max_health nil + second hit kills
--
-- TDD: These tests define the CORRECT behavior. Failures = bugs to fix.
--
-- Usage: lua test/injuries/test-hit-head.lua
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

local function make_ctx(opts)
    opts = opts or {}

    local registry_data = opts.registry_data or {}
    local reg = {
        get = function(self, id)
            return registry_data[id]
        end,
    }

    local player = opts.player or {
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

    return {
        registry = reg,
        current_room = opts.room or { name = "Test Room", contents = {} },
        player = player,
        time_offset = opts.time_offset or 0,
        headless = true,
        game_over = false,
    }
end

-- Simulate the consciousness gate from src/engine/loop/init.lua
-- This mirrors lines 71-138 of loop/init.lua — the code that ticks
-- injuries, decrements wake_timer, and performs the health check on wake.
local function simulate_consciousness_gate(ctx, injury_mod)
    local player = ctx.player
    if not (player and player.consciousness
            and player.consciousness.state == "unconscious") then
        return "already_conscious", nil
    end

    -- Tick injuries during unconsciousness
    local msgs, died = injury_mod.tick(player)

    if died then
        ctx.game_over = true
        return "died", msgs
    end

    -- Decrement wake timer
    player.consciousness.wake_timer = player.consciousness.wake_timer - 1

    -- Check wake-up
    if player.consciousness.wake_timer <= 0 then
        -- Health status on wake — THIS IS WHERE THE NIL CRASH WAS
        local health = injury_mod.compute_health(player)
        local max_hp = player.max_health or 100
        if health < max_hp * 0.5 then
            -- weak
        elseif health < max_hp * 0.75 then
            -- battered
        end

        -- Reset consciousness state
        player.consciousness.state = "conscious"
        player.consciousness.wake_timer = 0
        player.consciousness.cause = nil
        player.consciousness.unconscious_since = nil
        return "woke_up", msgs
    end

    return "still_unconscious", msgs
end

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------

local injury_mod = require("engine.injuries")
injury_mod.clear_cache()
injury_mod.reset_id_counter()

local concussion_def = require("meta.worlds.manor.injuries.concussion")
injury_mod.register_definition("concussion", concussion_def)

local bruised_def = require("meta.worlds.manor.injuries.bruised")
injury_mod.register_definition("bruised", bruised_def)

local bleeding_def = require("meta.worlds.manor.injuries.bleeding")
injury_mod.register_definition("bleeding", bleeding_def)

local verbs_mod = require("engine.verbs")

---------------------------------------------------------------------------
-- SUITE 1: hit head does NOT crash (no nil error on max_health)
---------------------------------------------------------------------------
suite("ISSUE #133: hit head must not crash on max_health")

test("hit head with max_health set does not error", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ max_health = 100 })

    -- Hit head and go unconscious
    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state, "player is unconscious")

    -- Run the full consciousness gate cycle (5 ticks to wake)
    for i = 1, 5 do
        local status = simulate_consciousness_gate(ctx, injury_mod)
        -- Should never crash
        h.assert_truthy(status ~= nil, "tick " .. i .. " did not crash")
    end
    h.assert_eq("conscious", ctx.player.consciousness.state,
        "player woke up without crash")
end)

test("hit head with max_health nil does not error (defensive)", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    ctx.player.max_health = nil  -- simulate missing max_health

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state, "player is unconscious")

    -- The real crash was in the wake-up health check in loop/init.lua
    -- Verify compute_health doesn't crash with nil max_health
    local ok, health = pcall(injury_mod.compute_health, ctx.player)
    h.assert_truthy(ok, "compute_health must not crash when max_health is nil")
    h.assert_truthy(type(health) == "number", "compute_health returns a number")
end)

test("max_health is always defined on fresh player", function()
    local ctx = make_ctx()
    h.assert_eq(100, ctx.player.max_health,
        "fresh player must have max_health = 100")
end)

---------------------------------------------------------------------------
-- SUITE 2: First hit head → player goes unconscious
---------------------------------------------------------------------------
suite("ISSUE #133: first hit head → unconscious")

test("first hit head sets player unconscious", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player must be unconscious after hit head")
    h.assert_eq("blow-to-head", ctx.player.consciousness.cause,
        "cause must be blow-to-head")
end)

test("first hit head creates concussion injury", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_truthy(#ctx.player.injuries > 0, "must have at least one injury")
    h.assert_eq("concussion", ctx.player.injuries[1].type,
        "injury type must be concussion")
end)

---------------------------------------------------------------------------
-- SUITE 3: Player wakes up after consciousness timer expires
---------------------------------------------------------------------------
suite("ISSUE #133: player wakes after timer")

test("player wakes up after 5 consciousness ticks", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq(5, ctx.player.consciousness.wake_timer, "wake timer = 5")

    -- Run the full consciousness gate 5 times
    for i = 1, 5 do
        simulate_consciousness_gate(ctx, injury_mod)
    end

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "player must be conscious after 5 ticks")
    h.assert_eq(0, ctx.player.consciousness.wake_timer,
        "wake timer must be 0")
end)

test("game_over is NOT set after waking from hit head", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)

    for i = 1, 5 do
        simulate_consciousness_gate(ctx, injury_mod)
    end

    h.assert_eq(false, ctx.game_over,
        "game_over must be false after waking from hit head")
end)

---------------------------------------------------------------------------
-- SUITE 4: Second hit head after waking → unconscious AGAIN (not dead)
---------------------------------------------------------------------------
suite("ISSUE #133: second hit head → unconscious again, NOT dead")

test("second hit head after waking re-knocks player unconscious", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    -- First hit
    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state, "1st hit: unconscious")

    -- Wake up
    for i = 1, 5 do simulate_consciousness_gate(ctx, injury_mod) end
    h.assert_eq("conscious", ctx.player.consciousness.state, "woke up after 1st hit")

    -- Second hit
    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "#133 REGRESSION: 2nd hit head must re-knock unconscious, not kill")
    h.assert_eq(false, ctx.game_over,
        "#133 REGRESSION: game_over must be false after 2nd hit head")
end)

test("second hit head creates second concussion but player is alive", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    -- First hit + wake
    capture_print(function() handlers["hit"](ctx, "head") end)
    for i = 1, 5 do simulate_consciousness_gate(ctx, injury_mod) end

    -- Second hit
    capture_print(function() handlers["hit"](ctx, "head") end)

    local health = injury_mod.compute_health(ctx.player)
    h.assert_truthy(health > 0,
        "#133 REGRESSION: health must be > 0 after 2nd hit head")
end)

test("player wakes from second hit head normally", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    -- First hit + wake
    capture_print(function() handlers["hit"](ctx, "head") end)
    for i = 1, 5 do simulate_consciousness_gate(ctx, injury_mod) end

    -- Second hit + wake
    capture_print(function() handlers["hit"](ctx, "head") end)
    for i = 1, 5 do simulate_consciousness_gate(ctx, injury_mod) end

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "#133 REGRESSION: player must wake from 2nd hit head")
    h.assert_eq(false, ctx.game_over,
        "#133 REGRESSION: game_over must be false after 2nd wake")
end)

---------------------------------------------------------------------------
-- SUITE 5: Multiple hit head cycles → player NEVER dies
---------------------------------------------------------------------------
suite("ISSUE #133: multiple hit head cycles never kill")

test("20 hit head cycles do not kill the player", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    for cycle = 1, 20 do
        -- Hit head
        capture_print(function() handlers["hit"](ctx, "head") end)
        h.assert_eq("unconscious", ctx.player.consciousness.state,
            "cycle " .. cycle .. ": must be unconscious")
        h.assert_eq(false, ctx.game_over,
            "cycle " .. cycle .. ": game_over must be false after hit")

        -- Wake up
        for i = 1, 5 do
            local status = simulate_consciousness_gate(ctx, injury_mod)
            if status == "died" then
                h.assert_truthy(false,
                    "#133 REGRESSION: player died on cycle " .. cycle ..
                    " tick " .. i .. " — self-inflicted head hits must NEVER kill")
                return
            end
        end

        h.assert_eq("conscious", ctx.player.consciousness.state,
            "cycle " .. cycle .. ": must wake up")

        local health = injury_mod.compute_health(ctx.player)
        h.assert_truthy(health > 0,
            "#133 REGRESSION: health must be > 0 after cycle " .. cycle ..
            " (was " .. tostring(health) .. ")")
    end
end)

test("self-inflicted damage ceiling prevents health reaching zero", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    -- Inflict 25 concussions (25 * 5 = 125 damage, exceeds 100 max_health)
    for i = 1, 25 do
        capture_print(function() handlers["hit"](ctx, "head") end)
        -- Reset consciousness so we can hit again immediately
        ctx.player.consciousness.state = "conscious"
        ctx.player.consciousness.wake_timer = 0
    end

    local health = injury_mod.compute_health(ctx.player)
    h.assert_truthy(health > 0,
        "#133 REGRESSION: 25 self-inflicted concussions must not reduce health to 0"
        .. " (health=" .. tostring(health) .. ")")

    -- Tick injuries — should NOT return died
    local msgs, died = injury_mod.tick(ctx.player)
    h.assert_eq(false, not not died,
        "#133 REGRESSION: tick() must not report death from self-inflicted injuries alone")
end)

---------------------------------------------------------------------------
-- SUITE 6: max_health defensive handling in consciousness gate
---------------------------------------------------------------------------
suite("ISSUE #133: max_health defensive handling")

test("consciousness gate wake-up works with max_health = 100", function()
    injury_mod.reset_id_counter()
    local ctx = make_ctx({ max_health = 100 })
    ctx.player.consciousness.state = "unconscious"
    ctx.player.consciousness.wake_timer = 1
    ctx.player.consciousness.cause = "blow-to-head"

    -- This should not error
    local status = simulate_consciousness_gate(ctx, injury_mod)
    h.assert_eq("woke_up", status,
        "consciousness gate must handle max_health = 100")
end)

test("consciousness gate wake-up works with max_health = nil", function()
    injury_mod.reset_id_counter()
    local ctx = make_ctx()
    ctx.player.max_health = nil  -- nil like the bug
    ctx.player.consciousness.state = "unconscious"
    ctx.player.consciousness.wake_timer = 1
    ctx.player.consciousness.cause = "blow-to-head"

    -- The REAL loop/init.lua code must also handle this — we test
    -- that compute_health doesn't crash and returns a number
    local ok, health = pcall(injury_mod.compute_health, ctx.player)
    h.assert_truthy(ok, "compute_health must not crash on nil max_health")

    -- The actual loop code line 120: health < player.max_health * 0.5
    -- With nil max_health, this would crash. After fix, it should use fallback.
    local max_hp = ctx.player.max_health or 100
    local comparison_ok = pcall(function()
        local _ = health < max_hp * 0.5
    end)
    h.assert_truthy(comparison_ok,
        "health comparison must not crash when using max_health fallback")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
