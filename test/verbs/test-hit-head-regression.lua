-- test/verbs/test-hit-head-regression.lua
-- Regression tests for hit verb: defines the CONTRACT for issue #55
-- (hitting your head doesn't create injuries) and related body-area hits.
--
-- These tests define what SHOULD happen. Failures = bugs for Smithers to fix.
--
-- Usage: lua test/verbs/test-hit-head-regression.lua
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

---------------------------------------------------------------------------
-- Load modules
---------------------------------------------------------------------------

local injury_mod = require("engine.injuries")
injury_mod.clear_cache()
injury_mod.reset_id_counter()

-- Register injury definitions from actual meta files
local concussion_def = require("meta.worlds.manor.injuries.concussion")
injury_mod.register_definition("concussion", concussion_def)

local bruised_def = require("meta.worlds.manor.injuries.bruised")
injury_mod.register_definition("bruised", bruised_def)

local bleeding_def = require("meta.worlds.manor.injuries.bleeding")
injury_mod.register_definition("bleeding", bleeding_def)

local verbs_mod = require("engine.verbs")

---------------------------------------------------------------------------
-- TEST 9: "hit head" → creates concussion injury (unconsciousness)
---------------------------------------------------------------------------
suite("REGRESSION #55: hit head → concussion + unconsciousness")

test("hit head creates a concussion injury", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(#ctx.player.injuries > 0,
        "#55 REGRESSION: 'hit head' MUST create an injury")
    h.assert_eq("concussion", ctx.player.injuries[1].type,
        "#55 REGRESSION: hit head injury type must be 'concussion'")
end)

test("hit head sets player to unconscious state", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "#55 REGRESSION: hit head must set consciousness to 'unconscious'")
end)

test("hit head concussion has head as location", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")
    h.assert_eq("head", ctx.player.injuries[1].location,
        "#55 REGRESSION: concussion location must be 'head'")
end)

test("hit head produces narration about stars/impact", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(output:find("Stars") or output:find("stars") or output:find("slam"),
        "#55 REGRESSION: hit head must produce impact narration")
end)

test("hit head sets blow-to-head as unconsciousness cause", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_eq("blow-to-head", ctx.player.consciousness.cause,
        "#55 REGRESSION: unconsciousness cause must be 'blow-to-head'")
end)

---------------------------------------------------------------------------
-- TEST 10: Player goes unconscious for correct duration (5 turns bare fist)
---------------------------------------------------------------------------
suite("REGRESSION #55: unconsciousness duration")

test("bare fist hit head sets 5-turn wake timer", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_eq(5, ctx.player.consciousness.wake_timer,
        "#55 REGRESSION: bare fist hit head = 5 turn wake timer")
end)

test("wake timer counts down and player regains consciousness", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    -- Simulate countdown like the game loop does
    for i = 1, 5 do
        capture_print(function() injury_mod.tick(ctx.player) end)
        ctx.player.consciousness.wake_timer = ctx.player.consciousness.wake_timer - 1
    end

    h.assert_eq(0, ctx.player.consciousness.wake_timer,
        "#55 REGRESSION: wake timer must reach 0 after 5 ticks")

    -- Player wakes up
    if ctx.player.consciousness.wake_timer <= 0 then
        ctx.player.consciousness.state = "conscious"
    end
    h.assert_eq("conscious", ctx.player.consciousness.state,
        "#55 REGRESSION: player must regain consciousness after timer expires")
end)

---------------------------------------------------------------------------
-- TEST 11: "hit arm" → creates bruise injury
---------------------------------------------------------------------------
suite("REGRESSION #55: hit arm → bruise")

test("hit arm creates a bruised injury", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "arm") end)

    h.assert_truthy(#ctx.player.injuries > 0,
        "#55 REGRESSION: 'hit arm' MUST create an injury")
    h.assert_eq("bruised", ctx.player.injuries[1].type,
        "#55 REGRESSION: hit arm injury type must be 'bruised'")
end)

test("hit arm does NOT cause unconsciousness", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "arm") end)

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "#55 REGRESSION: arm hit must NOT cause unconsciousness")
end)

test("hit arm bruise has arm location", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "arm") end)

    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")
    h.assert_truthy(ctx.player.injuries[1].location and
        ctx.player.injuries[1].location:find("arm"),
        "#55 REGRESSION: bruise location must contain 'arm'")
end)

---------------------------------------------------------------------------
-- TEST 12: "hit leg" → creates bruise injury
---------------------------------------------------------------------------
suite("REGRESSION #55: hit leg → bruise")

test("hit leg creates a bruised injury", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "leg") end)

    h.assert_truthy(#ctx.player.injuries > 0,
        "#55 REGRESSION: 'hit leg' MUST create an injury")
    h.assert_eq("bruised", ctx.player.injuries[1].type,
        "#55 REGRESSION: hit leg injury type must be 'bruised'")
end)

test("hit leg bruise has leg location", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "leg") end)

    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")
    h.assert_truthy(ctx.player.injuries[1].location and
        ctx.player.injuries[1].location:find("leg"),
        "#55 REGRESSION: bruise location must contain 'leg'")
end)

test("hit leg does NOT cause unconsciousness", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "leg") end)

    h.assert_eq("conscious", ctx.player.consciousness.state,
        "#55 REGRESSION: leg hit must NOT cause unconsciousness")
end)

---------------------------------------------------------------------------
-- TEST 13: Injuries from hit appear in "injuries" output
---------------------------------------------------------------------------
suite("REGRESSION #55: hit injuries visible in injuries output")

test("concussion from hit head appears in injury list", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")
    local list_output = capture_print(function() injury_mod.list(ctx.player) end)
    h.assert_truthy(list_output:find("concuss") or list_output:find("Concuss") or list_output:find("head"),
        "#55 REGRESSION: concussion must appear in injury list")
end)

test("bruise from hit arm appears in injury list", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "arm") end)

    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")
    local list_output = capture_print(function() injury_mod.list(ctx.player) end)
    h.assert_truthy(list_output:find("bruis") or list_output:find("Bruis"),
        "#55 REGRESSION: bruise must appear in injury list")
end)

test("injuries output includes health after hit", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")
    local health = injury_mod.compute_health(ctx.player)
    h.assert_truthy(health < 100,
        "#55 REGRESSION: health must be reduced after hit head (concussion does initial damage)")
end)

---------------------------------------------------------------------------
-- TEST 14: Armor on head reduces unconsciousness duration
---------------------------------------------------------------------------
suite("REGRESSION #55: helmet armor reduces unconsciousness duration")

test("helmet with reduces_unconsciousness halves wake timer", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local helmet = {
        id = "iron-helmet",
        name = "an iron helmet",
        wear_slot = "head",
        is_helmet = true,
        reduces_unconsciousness = 0.5,
    }
    local ctx = make_ctx({
        worn = { "iron-helmet" },
        registry_data = { ["iron-helmet"] = helmet },
    })
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "#55 REGRESSION: should still go unconscious with helmet")
    -- 5 * (1 - 0.5) = 2.5, floor = 2
    h.assert_truthy(ctx.player.consciousness.wake_timer < 5,
        "#55 REGRESSION: helmet must reduce wake timer below bare-fist 5")
    h.assert_truthy(ctx.player.consciousness.wake_timer >= 1,
        "#55 REGRESSION: wake timer must be at least 1 even with helmet")
end)

test("helmet hit produces helmet-specific narration", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local helmet = {
        id = "iron-helmet",
        name = "an iron helmet",
        wear_slot = "head",
        is_helmet = true,
        reduces_unconsciousness = 0.5,
    }
    local ctx = make_ctx({
        worn = { "iron-helmet" },
        registry_data = { ["iron-helmet"] = helmet },
    })
    local output = capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(output:find("[Hh]elmet"),
        "#55 REGRESSION: helmet narration must mention helmet")
end)

test("full-protection helmet (1.0 reduction) sets timer to 1", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local helmet = {
        id = "great-helm",
        name = "a great helm",
        wear_slot = "head",
        is_helmet = true,
        reduces_unconsciousness = 0.9,
    }
    local ctx = make_ctx({
        worn = { "great-helm" },
        registry_data = { ["great-helm"] = helmet },
    })
    capture_print(function() handlers["hit"](ctx, "head") end)

    -- 5 * (1 - 0.9) = 0.5, floor = 0, clamped to 1
    h.assert_eq(1, ctx.player.consciousness.wake_timer,
        "#55 REGRESSION: maximum reduction must still leave at least 1 turn")
end)

---------------------------------------------------------------------------
-- TEST 15: Hit verb works through Effects Pipeline
-- Note: effects_pipeline is not yet implemented in the engine. This test
-- defines the CONTRACT for when it IS implemented. Expected to fail now.
---------------------------------------------------------------------------
suite("REGRESSION #55: Effects Pipeline integration (future)")

test("player with effects_pipeline=true still gets injury from hit", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    -- Set effects_pipeline flag (future feature)
    ctx.player.effects_pipeline = true
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_truthy(#ctx.player.injuries > 0,
        "#55 REGRESSION: effects_pipeline flag must not prevent injury creation")
    h.assert_eq("concussion", ctx.player.injuries[1].type,
        "#55 REGRESSION: concussion must still be created with effects_pipeline enabled")
end)

test("player with effects_pipeline=true still goes unconscious from hit head", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    ctx.player.effects_pipeline = true
    capture_print(function() handlers["hit"](ctx, "head") end)

    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "#55 REGRESSION: unconsciousness must work with effects_pipeline enabled")
end)

---------------------------------------------------------------------------
-- BONUS: Bleed out while unconscious (existing but critical contract)
---------------------------------------------------------------------------
suite("REGRESSION #55: bleed out during unconsciousness")

test("player with bleeding injury dies while unconscious", function()
    injury_mod.reset_id_counter()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-regression",
                type = "bleeding",
                _state = "active",
                source = "stab-wound",
                location = "left arm",
                turns_active = 0,
                damage = 95,
                damage_per_tick = 10,
            },
        },
        consciousness = {
            state = "unconscious",
            wake_timer = 5,
            cause = "blow-to-head",
            unconscious_since = 0,
        },
        state = { bloody = true },
    }

    local msgs, died = injury_mod.tick(player)
    h.assert_truthy(died,
        "#55 REGRESSION: player must die from bleeding while unconscious")
end)

test("player with minor injury survives unconsciousness", function()
    injury_mod.reset_id_counter()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-minor",
                type = "bleeding",
                _state = "active",
                source = "test",
                location = "left arm",
                turns_active = 0,
                damage = 10,
                damage_per_tick = 5,
            },
        },
        consciousness = {
            state = "unconscious",
            wake_timer = 3,
            cause = "blow-to-head",
            unconscious_since = 0,
        },
        state = { bloody = true },
    }

    -- 3 ticks: damage goes 10→15→20→25, health = 75
    for i = 1, 3 do
        local msgs, died = injury_mod.tick(player)
        h.assert_truthy(not died, "Should not die on tick " .. i)
        player.consciousness.wake_timer = player.consciousness.wake_timer - 1
    end

    h.assert_eq(0, player.consciousness.wake_timer, "Timer should reach 0")
    local health = injury_mod.compute_health(player)
    h.assert_truthy(health > 0,
        "#55 REGRESSION: player with minor injury must survive unconsciousness")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
