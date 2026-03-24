-- test/verbs/test-hit-unconscious.lua
-- Tests for: hit verb, unconsciousness system, sleep+injury death,
-- helmet armor reduction, appearance subsystem, mirror integration.
--
-- Usage: lua test/verbs/test-hit-unconscious.lua
-- Must be run from repository root.

package.path = "./test/parser/?.lua;./src/?.lua;./src/?/init.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite
local assert_eq = h.assert_eq
local assert_truthy = h.assert_truthy
local assert_nil = h.assert_nil

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

--- Create a minimal game context for testing
local function make_ctx(opts)
    opts = opts or {}

    -- Minimal registry mock
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

-- Load injury module and register the test injury definitions
local injury_mod = require("engine.injuries")
injury_mod.clear_cache()
injury_mod.reset_id_counter()

-- Register concussion definition for tests
local concussion_def = require("meta.injuries.concussion")
injury_mod.register_definition("concussion", concussion_def)

-- Register bruised definition for tests
local bruised_def = require("meta.injuries.bruised")
injury_mod.register_definition("bruised", bruised_def)

-- Register bleeding definition for tests
local bleeding_def = require("meta.injuries.bleeding")
injury_mod.register_definition("bleeding", bleeding_def)

-- Load verbs module
local verbs_mod = require("engine.verbs")

---------------------------------------------------------------------------
-- HIT VERB TESTS
---------------------------------------------------------------------------

suite("hit — empty noun")
test("hit with no noun prints 'Hit what?'", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["hit"](ctx, "") end)
    assert_truthy(output:find("Hit what"), "Should ask 'Hit what?'")
end)

suite("hit head — unconsciousness")
test("hit head inflicts concussion and triggers unconsciousness", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["hit"](ctx, "head") end)
    assert_truthy(output:find("Stars"), "Should have narration about stars")
    assert_truthy(#ctx.player.injuries > 0, "Should have an injury")
    assert_eq("concussion", ctx.player.injuries[1].type, "Injury type should be concussion")
    assert_eq("unconscious", ctx.player.consciousness.state, "Player should be unconscious")
    assert_truthy(ctx.player.consciousness.wake_timer > 0, "Wake timer should be set")
    assert_eq("blow-to-head", ctx.player.consciousness.cause, "Cause should be blow-to-head")
end)

test("hit head bare fist sets 5-turn wake timer", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "head") end)
    assert_eq(5, ctx.player.consciousness.wake_timer, "Bare fist = 5 turns")
end)

suite("hit head with helmet — armor reduction")
test("helmet reduces unconsciousness duration", function()
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
    assert_eq("unconscious", ctx.player.consciousness.state, "Should be unconscious")
    -- 5 * (1 - 0.5) = 2.5, floor = 2
    assert_truthy(ctx.player.consciousness.wake_timer < 5, "Helmet should reduce timer")
    assert_truthy(ctx.player.consciousness.wake_timer >= 1, "Timer should be at least 1")
end)

test("hit helmeted head has helmet narration", function()
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
    assert_truthy(output:find("helmet") or output:find("Helmet"), "Should mention helmet in narration")
end)

suite("hit arm/leg — bruise")
test("hit arm inflicts bruise, NOT concussion", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["hit"](ctx, "arm") end)
    assert_truthy(#ctx.player.injuries > 0, "Should have an injury")
    assert_eq("bruised", ctx.player.injuries[1].type, "Injury type should be bruised")
    assert_eq("conscious", ctx.player.consciousness.state, "Should NOT be unconscious")
end)

test("hit leg inflicts bruise on leg", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["hit"](ctx, "leg") end)
    assert_truthy(#ctx.player.injuries > 0, "Should have an injury")
    assert_eq("bruised", ctx.player.injuries[1].type, "Injury type should be bruised")
    assert_truthy(ctx.player.injuries[1].location:find("leg"), "Location should be a leg")
end)

test("hit torso inflicts bruise on torso", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["hit"](ctx, "torso") end)
    assert_truthy(#ctx.player.injuries > 0, "Should have an injury")
    assert_eq("bruised", ctx.player.injuries[1].type, "Injury type should be bruised")
end)

suite("hit — synonyms")
test("punch routes to hit handler", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["punch"](ctx, "head") end)
    assert_eq("unconscious", ctx.player.consciousness.state, "punch head should cause unconsciousness")
end)

test("strike routes to hit handler", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["strike"](ctx, "arm") end)
    assert_truthy(#ctx.player.injuries > 0, "strike arm should inflict injury")
    assert_eq("bruised", ctx.player.injuries[1].type, "Should be bruise")
end)

test("bash routes to hit handler", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    local output = capture_print(function() handlers["bash"](ctx, "head") end)
    assert_eq("unconscious", ctx.player.consciousness.state, "bash head should cause unconsciousness")
end)

test("bonk routes to hit handler", function()
    local handlers = verbs_mod.create()
    assert_truthy(handlers["bonk"], "bonk should be a registered handler")
end)

test("smash routes to hit handler", function()
    local handlers = verbs_mod.create()
    assert_truthy(handlers["smash"], "smash should be a registered handler")
end)

test("thump routes to hit handler", function()
    local handlers = verbs_mod.create()
    assert_truthy(handlers["thump"], "thump should be a registered handler")
end)

suite("hit — body area aliases")
test("hit 'my head' resolves to head", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "my head") end)
    assert_eq("unconscious", ctx.player.consciousness.state, "'my head' should hit head")
end)

test("hit 'self' picks random body area", function()
    injury_mod.reset_id_counter()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()
    capture_print(function() handlers["hit"](ctx, "self") end)
    assert_truthy(#ctx.player.injuries > 0, "Should inflict some injury")
end)

---------------------------------------------------------------------------
-- UNCONSCIOUSNESS SYSTEM TESTS
---------------------------------------------------------------------------

suite("unconsciousness — wake up after timer")
test("player wakes up after countdown", function()
    injury_mod.reset_id_counter()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = {
            state = "unconscious",
            wake_timer = 1,  -- Will wake up this tick
            cause = "blow-to-head",
            unconscious_since = 0,
        },
        state = { bloody = false },
    }
    -- Simulate what the game loop consciousness gate does
    local inj_msgs, died = injury_mod.tick(player)
    assert_truthy(not died, "Should not die with no injuries")
    player.consciousness.wake_timer = player.consciousness.wake_timer - 1
    if player.consciousness.wake_timer <= 0 then
        player.consciousness.state = "conscious"
        player.consciousness.wake_timer = 0
        player.consciousness.cause = nil
    end
    assert_eq("conscious", player.consciousness.state, "Should be conscious after timer expires")
end)

suite("unconsciousness — bleed out during KO")
test("player dies from bleeding while unconscious", function()
    injury_mod.reset_id_counter()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-test",
                type = "bleeding",
                _state = "active",
                source = "test",
                location = "left arm",
                turns_active = 0,
                damage = 95,     -- Already near death
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
    -- Tick injuries — should push damage to 105, health becomes -5
    local msgs, died = injury_mod.tick(player)
    assert_truthy(died, "Player should die from bleeding while unconscious")
end)

suite("unconsciousness — survive and wake")
test("player survives bleeding and wakes up", function()
    injury_mod.reset_id_counter()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-test2",
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
            wake_timer = 2,
            cause = "blow-to-head",
            unconscious_since = 0,
        },
        state = { bloody = true },
    }
    -- Tick 1: damage goes to 15, wake_timer becomes 1
    local msgs1, died1 = injury_mod.tick(player)
    assert_truthy(not died1, "Should not die on tick 1")
    player.consciousness.wake_timer = player.consciousness.wake_timer - 1

    -- Tick 2: damage goes to 20, wake_timer becomes 0
    local msgs2, died2 = injury_mod.tick(player)
    assert_truthy(not died2, "Should not die on tick 2")
    player.consciousness.wake_timer = player.consciousness.wake_timer - 1

    assert_eq(0, player.consciousness.wake_timer, "Timer should be 0")
    -- Player wakes up
    player.consciousness.state = "conscious"
    assert_eq("conscious", player.consciousness.state, "Should be conscious after wake")

    -- Health check: 100 - 20 = 80
    local health = injury_mod.compute_health(player)
    assert_eq(80, health, "Health should be 80 after 2 ticks of 5 dmg/tick")
end)

---------------------------------------------------------------------------
-- SLEEP + INJURY DEATH TESTS
---------------------------------------------------------------------------

suite("sleep with injuries — injury ticking")
test("injury_mod.tick works correctly for sleep scenario", function()
    injury_mod.reset_id_counter()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-sleep",
                type = "bleeding",
                _state = "active",
                source = "test",
                location = "left arm",
                turns_active = 0,
                damage = 90,
                damage_per_tick = 15,
            },
        },
        state = { bloody = true },
    }
    -- One tick: damage goes to 105, health = -5
    local msgs, died = injury_mod.tick(player)
    assert_truthy(died, "Player should die from bleeding during sleep tick")
end)

---------------------------------------------------------------------------
-- APPEARANCE SUBSYSTEM TESTS
---------------------------------------------------------------------------

local appearance = require("engine.player.appearance")

suite("appearance — fresh player")
test("uninjured unarmored player gets simple description", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    assert_truthy(desc:find("unremarkable") or desc:find("plain") or desc:find("healthy"), "Fresh player should be unremarkable or healthy")
end)

suite("appearance — unconscious player")
test("unconscious player gets error message", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "unconscious", wake_timer = 5 },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    assert_truthy(desc:find("unconscious"), "Should mention unconscious")
end)

suite("appearance — injured player")
test("player with bleeding wound described", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-1",
                type = "bleeding",
                _state = "active",
                location = "left arm",
                severity = "moderate",
                turns_active = 0,
                damage = 10,
                damage_per_tick = 5,
            },
        },
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    assert_truthy(desc:find("gash") or desc:find("wound"), "Should describe the wound")
    assert_truthy(desc:find("left arm") or desc:find("arm"), "Should mention the location")
end)

test("player with bruise described", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bruise-1",
                type = "bruised",
                _state = "active",
                location = "torso",
                severity = "moderate",
                turns_active = 0,
                damage = 4,
                damage_per_tick = 0,
            },
        },
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    assert_truthy(desc:find("bruise"), "Should describe the bruise")
end)

suite("appearance — bandaged wound")
test("bandaged wound shows treatment", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "bleeding-2",
                type = "bleeding",
                _state = "treated",
                location = "left arm",
                severity = "moderate",
                turns_active = 5,
                damage = 10,
                damage_per_tick = 0,
                treatment = { type = "bandage" },
            },
        },
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, nil)
    assert_truthy(desc:find("bandage"), "Should mention bandage")
end)

suite("appearance — held items")
test("held item shows in description", function()
    local sword = {
        id = "sword",
        name = "a rusty sword",
    }
    local reg_data = { ["sword"] = sword }
    local reg = {
        get = function(self, id) return reg_data[id] end,
    }
    local player = {
        hands = { "sword", nil },
        worn = {},
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, reg)
    assert_truthy(desc:find("sword") or desc:find("grips"), "Should show held item")
end)

suite("appearance — low health")
test("low health shows pallor descriptors", function()
    local player = {
        hands = { nil, nil },
        worn = {},
        max_health = 100,
        injuries = {
            {
                id = "massive-wound",
                type = "bleeding",
                _state = "active",
                location = "torso",
                severity = "severe",
                turns_active = 10,
                damage = 80,
                damage_per_tick = 5,
            },
        },
        consciousness = { state = "conscious" },
        state = { bloody = true },
    }
    local desc = appearance.describe(player, nil)
    assert_truthy(desc:find("pale") or desc:find("sunken"), "Should describe low health pallor")
end)

suite("appearance — armor")
test("worn head armor shows in description", function()
    local helmet = {
        id = "iron-helmet",
        name = "a dented iron helmet",
        wear_slot = "head",
        is_helmet = true,
    }
    local reg_data = { ["iron-helmet"] = helmet }
    local reg = {
        get = function(self, id) return reg_data[id] end,
    }
    local player = {
        hands = { nil, nil },
        worn = { "iron-helmet" },
        max_health = 100,
        injuries = {},
        consciousness = { state = "conscious" },
        state = {},
    }
    local desc = appearance.describe(player, reg)
    assert_truthy(desc:find("helmet") or desc:find("iron"), "Should describe helmet")
end)

---------------------------------------------------------------------------
-- MIRROR INTEGRATION TESTS
---------------------------------------------------------------------------

suite("mirror — is_mirror flag")
test("mirror object has is_mirror flag", function()
    local mirror = require("meta.objects.mirror")
    assert_truthy(mirror.is_mirror, "Mirror should have is_mirror = true")
end)

test("vanity object does NOT have is_mirror flag", function()
    local vanity = require("meta.objects.vanity")
    assert_eq(nil, vanity.is_mirror, "Vanity should not have is_mirror (mirror is separate object)")
end)

---------------------------------------------------------------------------
-- APPEARANCE INTERNAL HELPER TESTS
---------------------------------------------------------------------------

suite("appearance — compose_natural")
test("single phrase returned as-is", function()
    local result = appearance._compose_natural({"hello"})
    assert_eq("hello", result, "Single phrase")
end)

test("two phrases joined with 'and'", function()
    local result = appearance._compose_natural({"a bruise", "a cut"})
    assert_eq("a bruise and a cut", result, "Two phrases")
end)

test("three phrases joined with Oxford comma", function()
    local result = appearance._compose_natural({"a bruise", "a cut", "a burn"})
    assert_eq("a bruise, a cut, and a burn", result, "Three phrases")
end)

suite("appearance — get_injuries_at")
test("finds injuries matching body region", function()
    local player = {
        injuries = {
            { location = "left arm", type = "bleeding" },
            { location = "head", type = "concussion" },
            { location = "right leg", type = "bruised" },
        },
    }
    local arm_injuries = appearance._get_injuries_at(player, {"arm"})
    assert_eq(1, #arm_injuries, "Should find 1 arm injury")
    assert_eq("left arm", arm_injuries[1].location, "Should be left arm injury")
end)

suite("appearance — injury phrase composition")
test("renders bleeding wound phrase", function()
    local injury = {
        type = "bleeding",
        location = "left arm",
        severity = "moderate",
        _state = "active",
    }
    local phrase = appearance._render_injury_phrase(injury)
    assert_truthy(phrase:find("gash"), "Should say gash for bleeding")
    assert_truthy(phrase:find("left arm"), "Should include location")
end)

test("renders treated injury with bandage", function()
    local injury = {
        type = "bleeding",
        location = "left arm",
        severity = "moderate",
        _state = "treated",
        treatment = { type = "bandage" },
    }
    local phrase = appearance._render_injury_phrase(injury)
    assert_truthy(phrase:find("bandage"), "Should mention bandage for treated injury")
end)

---------------------------------------------------------------------------
-- CONCUSSION INJURY DEFINITION TESTS
---------------------------------------------------------------------------

suite("concussion injury definition")
test("concussion causes unconsciousness", function()
    assert_truthy(concussion_def.causes_unconsciousness, "Should have causes_unconsciousness flag")
end)

test("concussion has severity durations", function()
    assert_eq(3, concussion_def.unconscious_duration.minor, "Minor = 3 turns")
    assert_eq(5, concussion_def.unconscious_duration.moderate, "Moderate = 5 turns")
    assert_eq(10, concussion_def.unconscious_duration.severe, "Severe = 10 turns")
    assert_eq(20, concussion_def.unconscious_duration.critical, "Critical = 20 turns")
end)

test("concussion initial state is active", function()
    assert_eq("active", concussion_def.initial_state, "Initial state should be active")
end)

test("concussion has healed terminal state", function()
    assert_truthy(concussion_def.states.healed.terminal, "Healed should be terminal")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
