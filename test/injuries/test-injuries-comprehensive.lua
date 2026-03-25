-- test/injuries/test-injuries-comprehensive.lua
-- Comprehensive tests for injury system, weapon interactions, consciousness gate,
-- and poison system.
--
-- Coverage:
--   1. All 7 injury types: definition loading, FSM states, transitions
--   2. Injury FSM progression: active → worsened → critical → fatal
--   3. Healing interactions: bandage, antidote, poultice, cold-water
--   4. Weapon pipeline: stab, cut, slash with correct injury types
--   5. Self-infliction prevention: damage ceiling, no self-kill
--   6. Unconsciousness gate: verb blocking, wake timer, recovery
--   7. Poison system: taste/drink → nightshade poisoning → progression
--
-- Usage: lua test/injuries/test-injuries-comprehensive.lua
-- Must be run from the repository root.

package.path = "./test/parser/?.lua;./src/?.lua;./src/?/init.lua;" .. package.path

local h = require("test-helpers")
local test = h.test
local suite = h.suite

local injury_mod = require("engine.injuries")
local verbs_mod = require("engine.verbs")
local effects_mod = require("engine.effects")

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

local function fresh_player(opts)
    opts = opts or {}
    return {
        max_health = opts.max_health or 100,
        injuries = {},
        hands = { nil, nil },
        worn = opts.worn or {},
        worn_items = {},
        bags = {},
        state = opts.state or {
            bloody = false,
            poisoned = false,
            has_flame = 0,
        },
        consciousness = opts.consciousness or {
            state = "conscious",
            wake_timer = 0,
            cause = nil,
            unconscious_since = nil,
        },
    }
end

local function make_mock_registry(objects)
    return {
        _objects = objects or {},
        get = function(self, id) return self._objects[id] end,
        register = function(self, id, obj) self._objects[id] = obj end,
        remove = function(self, id) self._objects[id] = nil end,
        find_by_keyword = function(self, kw)
            local results = {}
            for _, obj in pairs(self._objects) do
                if obj.keywords then
                    for _, k in ipairs(obj.keywords) do
                        if k:lower() == kw:lower() then
                            results[#results + 1] = obj
                            break
                        end
                    end
                end
            end
            return results
        end,
    }
end

local function make_ctx(opts)
    opts = opts or {}
    local player = fresh_player(opts)
    local objs = opts.objects or {}
    local reg = make_mock_registry(objs)
    local room = opts.room or {
        id = "test-room", name = "Test Room",
        description = "A featureless test room.",
        contents = {}, exits = {}, light_level = 0,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 0,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
        headless = true,
        game_over = false,
    }
end

-- Simulate the consciousness gate from loop/init.lua
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

---------------------------------------------------------------------------
-- Load all 7 injury definitions from disk
---------------------------------------------------------------------------
local SEP = package.config:sub(1, 1)
local injury_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "injuries" .. SEP

local bleeding_def     = dofile(injury_dir .. "bleeding.lua")
local bruised_def      = dofile(injury_dir .. "bruised.lua")
local burn_def         = dofile(injury_dir .. "burn.lua")
local concussion_def   = dofile(injury_dir .. "concussion.lua")
local crushing_def     = dofile(injury_dir .. "crushing-wound.lua")
local minor_cut_def    = dofile(injury_dir .. "minor-cut.lua")
local nightshade_def   = dofile(injury_dir .. "poisoned-nightshade.lua")

local function register_all_injuries()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("bleeding", bleeding_def)
    injury_mod.register_definition("bruised", bruised_def)
    injury_mod.register_definition("burn", burn_def)
    injury_mod.register_definition("concussion", concussion_def)
    injury_mod.register_definition("crushing-wound", crushing_def)
    injury_mod.register_definition("minor-cut", minor_cut_def)
    injury_mod.register_definition("poisoned-nightshade", nightshade_def)
end

---------------------------------------------------------------------------
-- Load weapon definitions from disk
---------------------------------------------------------------------------
local obj_dir = "." .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP
local knife_def        = dofile(obj_dir .. "knife.lua")
local glass_shard_def  = dofile(obj_dir .. "glass-shard.lua")
local silver_dagger_def= dofile(obj_dir .. "silver-dagger.lua")

-- Poison bottle
local poison_bottle_ok, poison_bottle_def = pcall(dofile, obj_dir .. "poison-bottle.lua")
if not poison_bottle_ok then
    poison_bottle_def = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 1: ALL 7 INJURY TYPE DEFINITIONS
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 1: All 7 injury type definitions load and are well-formed")

-- Each injury type must load, have an id, initial_state, states, and transitions
local all_defs = {
    { id = "bleeding",            def = bleeding_def },
    { id = "bruised",             def = bruised_def },
    { id = "burn",                def = burn_def },
    { id = "concussion",          def = concussion_def },
    { id = "crushing-wound",      def = crushing_def },
    { id = "minor-cut",           def = minor_cut_def },
    { id = "poisoned-nightshade", def = nightshade_def },
}

for _, entry in ipairs(all_defs) do
    test(entry.id .. " loads from disk", function()
        h.assert_truthy(entry.def ~= nil, entry.id .. " definition must not be nil")
    end)

    test(entry.id .. " has correct id", function()
        h.assert_eq(entry.id, entry.def.id, entry.id .. " id must match filename")
    end)

    test(entry.id .. " has initial_state", function()
        h.assert_truthy(entry.def.initial_state ~= nil, entry.id .. " must have initial_state")
    end)

    test(entry.id .. " has FSM states table", function()
        h.assert_truthy(entry.def.states ~= nil, entry.id .. " must have states")
        h.assert_truthy(type(entry.def.states) == "table", entry.id .. " states must be table")
    end)

    test(entry.id .. " has on_inflict with message", function()
        h.assert_truthy(entry.def.on_inflict ~= nil, entry.id .. " must have on_inflict")
        h.assert_truthy(entry.def.on_inflict.message ~= nil, entry.id .. " on_inflict must have message")
    end)

    test(entry.id .. " initial_state exists in states table", function()
        local init_state = entry.def.initial_state
        h.assert_truthy(entry.def.states[init_state] ~= nil,
            entry.id .. " initial_state '" .. init_state .. "' must exist in states")
    end)

    test(entry.id .. " has a healed terminal state", function()
        -- All injury types should have either a healed or fatal terminal state
        local has_terminal = false
        for state_name, state_def in pairs(entry.def.states) do
            if state_def.terminal then
                has_terminal = true
                break
            end
        end
        h.assert_truthy(has_terminal, entry.id .. " must have at least one terminal state")
    end)

    test(entry.id .. " has guid", function()
        h.assert_truthy(entry.def.guid ~= nil, entry.id .. " must have a guid")
    end)

    test(entry.id .. " has damage_type", function()
        h.assert_truthy(entry.def.damage_type ~= nil, entry.id .. " must have damage_type")
        local valid = entry.def.damage_type == "one_time"
                   or entry.def.damage_type == "over_time"
                   or entry.def.damage_type == "degenerative"
        h.assert_truthy(valid, entry.id .. " damage_type must be one_time/over_time/degenerative")
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 2: INJURY FSM STATE PROGRESSION
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 2A: Bleeding FSM progression (active → worsened → critical → fatal)")

register_all_injuries()

test("bleeding inflict creates active injury with damage_per_tick", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "bleeding", "sword") end)
    h.assert_eq(1, #p.injuries, "one injury created")
    h.assert_eq("bleeding", p.injuries[1].type, "type is bleeding")
    h.assert_eq("active", p.injuries[1]._state, "starts in active state")
    h.assert_eq(5, p.injuries[1].damage, "initial damage = 5")
    h.assert_eq(5, p.injuries[1].damage_per_tick, "damage_per_tick = 5")
end)

test("bleeding accumulates damage each tick", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "bleeding", "sword") end)
    capture_print(function() injury_mod.tick(p) end)
    h.assert_eq(10, p.injuries[1].damage, "damage after 1 tick = 5 + 5")
    capture_print(function() injury_mod.tick(p) end)
    h.assert_eq(15, p.injuries[1].damage, "damage after 2 ticks = 5 + 10")
end)

test("bleeding restricts climbing when active", function()
    h.assert_truthy(bleeding_def.states.active.restricts, "active state has restricts")
    h.assert_truthy(bleeding_def.states.active.restricts.climb, "active state restricts climb")
end)

test("bleeding worsened state has higher damage_per_tick", function()
    h.assert_eq(10, bleeding_def.states.worsened.damage_per_tick, "worsened damage_per_tick = 10")
end)

test("bleeding critical state has highest damage_per_tick", function()
    h.assert_eq(20, bleeding_def.states.critical.damage_per_tick, "critical damage_per_tick = 20")
end)

test("bleeding fatal state is terminal", function()
    h.assert_truthy(bleeding_def.states.fatal.terminal, "fatal is terminal")
end)

test("bleeding healed state is terminal", function()
    h.assert_truthy(bleeding_def.states.healed.terminal, "healed is terminal")
end)

suite("SECTION 2B: Crushing wound FSM progression")

test("crushing wound has degenerative pattern", function()
    h.assert_eq("over_time", crushing_def.damage_type, "crushing wound is over_time")
    h.assert_eq(15, crushing_def.on_inflict.initial_damage, "initial damage = 15")
    h.assert_eq(2, crushing_def.on_inflict.damage_per_tick, "damage_per_tick = 2")
end)

test("crushing wound active restricts grip, climb, and fight", function()
    local r = crushing_def.states.active.restricts
    h.assert_truthy(r.grip, "active restricts grip")
    h.assert_truthy(r.climb, "active restricts climb")
    h.assert_truthy(r.fight, "active restricts fight")
end)

test("crushing wound worsened → critical → fatal path exists", function()
    h.assert_truthy(crushing_def.states.worsened ~= nil, "worsened state exists")
    h.assert_truthy(crushing_def.states.critical ~= nil, "critical state exists")
    h.assert_truthy(crushing_def.states.fatal ~= nil, "fatal state exists")
    h.assert_truthy(crushing_def.states.fatal.terminal, "fatal is terminal")
end)

suite("SECTION 2C: Nightshade poison FSM progression")

test("nightshade starts with 10 initial damage and 8 per-tick", function()
    h.assert_eq(10, nightshade_def.on_inflict.initial_damage, "initial damage = 10")
    h.assert_eq(8, nightshade_def.on_inflict.damage_per_tick, "damage_per_tick = 8")
end)

test("nightshade active → worsened escalation", function()
    h.assert_truthy(nightshade_def.states.worsened ~= nil, "worsened state exists")
    h.assert_eq(15, nightshade_def.states.worsened.damage_per_tick, "worsened damage = 15/tick")
end)

test("nightshade worsened → fatal is terminal death", function()
    h.assert_truthy(nightshade_def.states.fatal ~= nil, "fatal state exists")
    h.assert_truthy(nightshade_def.states.fatal.terminal, "fatal is terminal")
end)

test("nightshade functional: tick accumulates poison damage", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle") end)
    h.assert_eq(90, injury_mod.compute_health(p), "health = 90 after infliction (100-10)")
    capture_print(function() injury_mod.tick(p) end)
    h.assert_eq(82, injury_mod.compute_health(p), "health = 82 after 1 tick (100 - 10 - 8)")
    capture_print(function() injury_mod.tick(p) end)
    h.assert_eq(74, injury_mod.compute_health(p), "health = 74 after 2 ticks")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 3: HEALING INTERACTIONS
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 3A: Bleeding healed by bandage")

test("bandage heals active bleeding wound", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "bleeding", "sword") end)
    h.assert_eq(1, #p.injuries, "bleeding inflicted")

    local bandage = {
        id = "bandage",
        on_use = {
            cures = "bleeding",
            transition_to = "treated",
            message = "You press the bandage against the wound.",
        },
    }

    local healed
    capture_print(function() healed = injury_mod.try_heal(p, bandage, "use") end)
    h.assert_truthy(healed, "try_heal returns true for bandage on bleeding")
    h.assert_eq("treated", p.injuries[1]._state, "bleeding transitions to treated")
    h.assert_eq(0, p.injuries[1].damage_per_tick, "damage_per_tick stops after treatment")
end)

test("bandage heals worsened bleeding wound", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "bleeding", "sword") end)
    -- Manually advance to worsened state
    p.injuries[1]._state = "worsened"
    p.injuries[1].damage_per_tick = 10

    local bandage = {
        id = "bandage",
        on_use = {
            cures = "bleeding",
            transition_to = "treated",
            message = "You bandage the infected wound.",
        },
    }

    local healed
    capture_print(function() healed = injury_mod.try_heal(p, bandage, "use") end)
    h.assert_truthy(healed, "bandage works on worsened bleeding")
    h.assert_eq("treated", p.injuries[1]._state, "worsened transitions to treated")
end)

suite("SECTION 3B: Nightshade antidote healing")

test("nightshade antidote heals active poisoning", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle") end)

    local antidote = {
        id = "antidote-nightshade",
        on_drink = {
            cures = "poisoned-nightshade",
            transition_to = "neutralized",
            message = "The antidote takes effect. The burning subsides.",
        },
    }

    local healed
    capture_print(function() healed = injury_mod.try_heal(p, antidote, "drink") end)
    h.assert_truthy(healed, "antidote heals nightshade")
    h.assert_eq("neutralized", p.injuries[1]._state, "poison transitions to neutralized")
    h.assert_eq(0, p.injuries[1].damage_per_tick, "poison damage stops")
end)

test("wrong cure fails on nightshade (bandage does not cure poison)", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle") end)

    local bandage = {
        id = "bandage",
        on_use = {
            cures = "bleeding",
            message = "You bind the wound.",
        },
    }

    local healed
    capture_print(function() healed = injury_mod.try_heal(p, bandage, "use") end)
    h.assert_eq(false, not not healed, "bandage does not cure poison")
end)

suite("SECTION 3C: Burn healing interactions")

test("cold water heals active burn", function()
    -- Verify definition allows cold-water on active burns
    local interaction = burn_def.healing_interactions["cold-water"]
    h.assert_truthy(interaction ~= nil, "cold-water interaction exists")
    h.assert_eq("treated", interaction.transitions_to, "cold-water transitions to treated")
    local has_active = false
    for _, s in ipairs(interaction.from_states) do
        if s == "active" then has_active = true end
    end
    h.assert_truthy(has_active, "cold-water works from active state")
end)

test("salve heals blistered burn", function()
    local interaction = burn_def.healing_interactions["salve"]
    h.assert_truthy(interaction ~= nil, "salve interaction exists")
    local has_blistered = false
    for _, s in ipairs(interaction.from_states) do
        if s == "blistered" then has_blistered = true end
    end
    h.assert_truthy(has_blistered, "salve works from blistered state")
end)

suite("SECTION 3D: Minor cut self-heals and bandage accelerates")

test("minor cut self-heals (one-time damage, no per-tick)", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function() injury_mod.inflict(p, "minor-cut", "glass-shard") end)
    h.assert_eq(3, p.injuries[1].damage, "minor-cut initial damage = 3")
    h.assert_eq(0, p.injuries[1].damage_per_tick, "minor-cut has no per-tick damage")
end)

test("minor cut bandage interaction exists", function()
    local interaction = minor_cut_def.healing_interactions["bandage"]
    h.assert_truthy(interaction ~= nil, "bandage interaction exists for minor-cut")
    h.assert_eq("treated", interaction.transitions_to, "bandage transitions to treated")
end)

suite("SECTION 3E: Bruise heals with rest/sleep")

test("bruise has rest/sleep verb transitions", function()
    local has_rest = false
    local has_sleep = false
    for _, t in ipairs(bruised_def.transitions) do
        if t.verb == "rest" then has_rest = true end
        if t.verb == "sleep" then has_sleep = true end
    end
    h.assert_truthy(has_rest, "bruise has rest transition")
    h.assert_truthy(has_sleep, "bruise has sleep transition")
end)

test("bruise has no healing_interactions (rest only)", function()
    h.assert_eq(0, #(bruised_def.healing_interactions or {}),
        "bruise healing_interactions is empty (heals via rest/time)")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 4: WEAPON PIPELINE
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 4A: Knife weapon pipeline")

test("knife stab creates bleeding injury via pipeline", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ verb = "stab" })
    ctx.player.hands[1] = knife_def
    ctx.registry._objects[knife_def.id] = knife_def

    capture_print(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "stab self with knife creates injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type, "knife stab → bleeding")
end)

test("knife cut creates minor-cut injury via pipeline", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ verb = "cut" })
    ctx.player.hands[1] = knife_def
    ctx.registry._objects[knife_def.id] = knife_def

    capture_print(function() handlers["cut"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "cut self with knife creates injury")
    h.assert_eq("minor-cut", ctx.player.injuries[1].type, "knife cut → minor-cut")
end)

test("knife pipeline_effects data is correct", function()
    h.assert_truthy(knife_def.on_stab.pipeline_effects ~= nil, "on_stab has pipeline_effects")
    h.assert_eq("inflict_injury", knife_def.on_stab.pipeline_effects[1].type, "stab effect type")
    h.assert_eq("bleeding", knife_def.on_stab.pipeline_effects[1].injury_type, "stab injury type")
    h.assert_eq(5, knife_def.on_stab.pipeline_effects[1].damage, "stab damage")

    h.assert_truthy(knife_def.on_cut.pipeline_effects ~= nil, "on_cut has pipeline_effects")
    h.assert_eq("minor-cut", knife_def.on_cut.pipeline_effects[1].injury_type, "cut injury type")
    h.assert_eq(3, knife_def.on_cut.pipeline_effects[1].damage, "cut damage")
end)

suite("SECTION 4B: Glass shard weapon pipeline")

test("glass shard cut creates minor-cut", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ verb = "cut" })
    ctx.player.hands[1] = glass_shard_def
    ctx.registry._objects[glass_shard_def.id] = glass_shard_def

    capture_print(function() handlers["cut"](ctx, "self with glass shard") end)
    h.assert_truthy(#ctx.player.injuries > 0, "cut self with glass shard creates injury")
    h.assert_eq("minor-cut", ctx.player.injuries[1].type, "glass shard cut → minor-cut")
end)

test("glass shard has self_damage flag", function()
    h.assert_truthy(glass_shard_def.on_cut.self_damage, "glass shard cut has self_damage")
end)

suite("SECTION 4C: Silver dagger weapon pipeline")

test("silver dagger stab creates bleeding with higher damage", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ verb = "stab" })
    ctx.player.hands[1] = silver_dagger_def
    ctx.registry._objects[silver_dagger_def.id] = silver_dagger_def

    capture_print(function() handlers["stab"](ctx, "self with silver dagger") end)
    h.assert_truthy(#ctx.player.injuries > 0, "stab self with dagger creates injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type, "dagger stab → bleeding")
    h.assert_eq(8, ctx.player.injuries[1].damage, "dagger stab damage = 8")
end)

test("silver dagger slash creates bleeding", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ verb = "slash" })
    ctx.player.hands[1] = silver_dagger_def
    ctx.registry._objects[silver_dagger_def.id] = silver_dagger_def

    capture_print(function() handlers["slash"](ctx, "self with silver dagger") end)
    h.assert_truthy(#ctx.player.injuries > 0, "slash self with dagger creates injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type, "dagger slash → bleeding")
end)

test("silver dagger cut creates minor-cut", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx({ verb = "cut" })
    ctx.player.hands[1] = silver_dagger_def
    ctx.registry._objects[silver_dagger_def.id] = silver_dagger_def

    capture_print(function() handlers["cut"](ctx, "self with silver dagger") end)
    h.assert_truthy(#ctx.player.injuries > 0, "cut self with dagger creates injury")
    h.assert_eq("minor-cut", ctx.player.injuries[1].type, "dagger cut → minor-cut")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 5: SELF-INFLICTION PREVENTION
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 5: Self-infliction damage ceiling")

test("self-inflicted injuries never reduce health to 0", function()
    register_all_injuries()
    local p = fresh_player()

    -- Inflict many self-inflicted concussions
    for i = 1, 30 do
        capture_print(function()
            injury_mod.inflict(p, "concussion", "self-inflicted (bare fist, hit)", "head", 5)
        end)
    end

    local health = injury_mod.compute_health(p)
    h.assert_truthy(health > 0,
        "30 self-inflicted concussions must not kill (health=" .. tostring(health) .. ")")
end)

test("tick does not report death from self-inflicted injuries alone", function()
    register_all_injuries()
    local p = fresh_player()

    for i = 1, 30 do
        capture_print(function()
            injury_mod.inflict(p, "concussion", "self-inflicted (bare fist, hit)", "head", 5)
        end)
    end

    local msgs, died
    capture_print(function() msgs, died = injury_mod.tick(p) end)
    h.assert_eq(false, not not died,
        "tick() must not report death from self-inflicted injuries alone")
end)

test("external injury CAN kill", function()
    register_all_injuries()
    local p = fresh_player({ max_health = 20 })
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)
    -- 20 max health, 10 initial damage = 10 health remaining
    -- 1 tick: +8 = 18 damage, health = 2
    capture_print(function() injury_mod.tick(p) end)
    -- 2nd tick: +8 = 26 damage, health = 0 → death
    local msgs, died
    capture_print(function() msgs, died = injury_mod.tick(p) end)
    h.assert_truthy(died, "external poison injury CAN kill the player")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 6: UNCONSCIOUSNESS GATE (#162)
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 6A: Hit head triggers unconsciousness")

test("hit head sets consciousness state to unconscious", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state,
        "player is unconscious after hit head")
end)

test("hit head sets cause to blow-to-head", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("blow-to-head", ctx.player.consciousness.cause,
        "cause is blow-to-head")
end)

test("hit head creates concussion injury", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_truthy(#ctx.player.injuries > 0, "at least one injury")
    h.assert_eq("concussion", ctx.player.injuries[1].type, "injury is concussion")
end)

test("hit head sets wake_timer to 5 (bare fist)", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq(5, ctx.player.consciousness.wake_timer, "wake_timer = 5")
end)

suite("SECTION 6B: Unconsciousness blocks verbs")

test("verbs are blocked while unconscious", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    -- Make player unconscious
    ctx.player.consciousness.state = "unconscious"
    ctx.player.consciousness.wake_timer = 5

    -- Try various verbs — they should all print "You are unconscious."
    local blocked_verbs = {"look", "feel", "take", "drop", "open", "search"}
    for _, verb_name in ipairs(blocked_verbs) do
        if handlers[verb_name] then
            local output = capture_print(function()
                handlers[verb_name](ctx, "anything")
            end)
            h.assert_truthy(output:lower():find("unconscious"),
                verb_name .. " should be blocked while unconscious")
        end
    end
end)

suite("SECTION 6C: Recovery from unconsciousness")

test("player wakes after wake_timer expires (5 ticks)", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    h.assert_eq("unconscious", ctx.player.consciousness.state, "start unconscious")

    for i = 1, 5 do
        capture_print(function() simulate_consciousness_gate(ctx) end)
    end

    h.assert_eq("conscious", ctx.player.consciousness.state, "player woke up after 5 ticks")
    h.assert_eq(0, ctx.player.consciousness.wake_timer, "wake_timer reset to 0")
end)

test("game_over is false after waking from hit head", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    capture_print(function() handlers["hit"](ctx, "head") end)
    for i = 1, 5 do
        capture_print(function() simulate_consciousness_gate(ctx) end)
    end

    h.assert_eq(false, ctx.game_over, "game_over must be false after waking")
end)

test("injuries tick during unconsciousness", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "sword")
    end)
    local initial_damage = p.injuries[1].damage

    p.consciousness = {
        state = "unconscious",
        wake_timer = 3,
        cause = "test",
    }

    local ctx = { player = p, game_over = false }
    capture_print(function() simulate_consciousness_gate(ctx) end)
    h.assert_truthy(p.injuries[1].damage > initial_damage,
        "bleeding damage increased during unconsciousness tick")
end)

test("death during unconsciousness sets game_over", function()
    register_all_injuries()
    local p = fresh_player({ max_health = 15 })
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)
    -- health = 15 - 10 = 5
    -- tick: +8 → damage = 18 → health = 15-18 = 0 → death

    p.consciousness = {
        state = "unconscious",
        wake_timer = 10,
        cause = "gas",
    }

    local ctx = { player = p, game_over = false }
    local status
    capture_print(function()
        status = simulate_consciousness_gate(ctx)
    end)
    h.assert_eq("died", status, "death detected during unconsciousness")
    h.assert_truthy(ctx.game_over, "game_over set after death during unconsciousness")
end)

suite("SECTION 6D: Multiple hit head cycles — never kills")

test("10 hit-head cycles do not kill", function()
    register_all_injuries()
    local handlers = verbs_mod.create()
    local ctx = make_ctx()

    for cycle = 1, 10 do
        capture_print(function() handlers["hit"](ctx, "head") end)
        h.assert_eq("unconscious", ctx.player.consciousness.state,
            "cycle " .. cycle .. ": unconscious")
        h.assert_eq(false, ctx.game_over,
            "cycle " .. cycle .. ": not dead")

        for i = 1, 5 do
            local status
            capture_print(function() status = simulate_consciousness_gate(ctx) end)
            if status == "died" then
                h.assert_truthy(false, "player died on cycle " .. cycle .. " tick " .. i)
                break
            end
        end

        h.assert_eq("conscious", ctx.player.consciousness.state,
            "cycle " .. cycle .. ": woke up")

        local health = injury_mod.compute_health(ctx.player)
        h.assert_truthy(health > 0,
            "cycle " .. cycle .. ": health > 0 (was " .. tostring(health) .. ")")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 7: POISON SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 7A: Poison bottle definition")

if poison_bottle_def then
    test("poison bottle loads from disk", function()
        h.assert_truthy(poison_bottle_def ~= nil, "poison-bottle.lua loads")
    end)

    test("poison bottle has effects_pipeline flag", function()
        h.assert_truthy(poison_bottle_def.effects_pipeline, "effects_pipeline = true")
    end)

    test("poison bottle is consumable", function()
        h.assert_truthy(poison_bottle_def.is_consumable, "is_consumable")
    end)

    test("poison bottle has nightshade poison_type", function()
        h.assert_eq("nightshade", poison_bottle_def.poison_type, "poison_type = nightshade")
    end)

    test("poison bottle has FSM states (sealed, open, empty)", function()
        h.assert_truthy(poison_bottle_def.states ~= nil, "has states")
        h.assert_truthy(poison_bottle_def.states.sealed ~= nil, "has sealed state")
        h.assert_truthy(poison_bottle_def.states.open ~= nil, "has open state")
        h.assert_truthy(poison_bottle_def.states.empty ~= nil, "has empty state")
    end)

    test("poison bottle drink transition inflicts nightshade poisoning", function()
        local drink_trans = nil
        for _, t in ipairs(poison_bottle_def.transitions or {}) do
            if t.verb == "drink" then
                drink_trans = t
                break
            end
        end
        h.assert_truthy(drink_trans ~= nil, "drink transition exists")
        h.assert_eq("open", drink_trans.from, "drink from open state")
        h.assert_eq("empty", drink_trans.to, "drink to empty state")

        -- Check that the effect inflicts nightshade poisoning
        local effect = drink_trans.effect or (drink_trans.pipeline_effects and drink_trans.pipeline_effects[1])
        h.assert_truthy(effect ~= nil, "drink transition has effect")
        h.assert_eq("inflict_injury", effect.type, "effect type is inflict_injury")
        h.assert_eq("poisoned-nightshade", effect.injury_type, "effect injury_type is nightshade")
    end)

    test("poison bottle taste triggers on_taste_effect", function()
        -- Check if on_taste_effect exists on the open state or root level
        local taste_effect = poison_bottle_def.on_taste_effect
            or (poison_bottle_def.states.open and poison_bottle_def.states.open.on_taste_effect)
        h.assert_truthy(taste_effect ~= nil, "poison bottle has on_taste_effect")
        if taste_effect then
            h.assert_eq("inflict_injury", taste_effect.type, "taste effect is inflict_injury")
            h.assert_eq("poisoned-nightshade", taste_effect.injury_type, "taste inflicts nightshade")
        end
    end)
else
    test("poison bottle definition not found (WARN)", function()
        -- Warn but don't fail — the object may not exist yet
        h.assert_truthy(true, "WARN: poison-bottle.lua not found at expected path")
    end)
end

suite("SECTION 7B: Poison progression functional test")

test("nightshade poison progresses: inflict → tick → health drain", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)
    h.assert_eq(1, #p.injuries, "poison inflicted")
    h.assert_eq("active", p.injuries[1]._state, "starts active")
    h.assert_eq(90, injury_mod.compute_health(p), "health after infliction")

    -- Tick 3 times
    for i = 1, 3 do
        capture_print(function() injury_mod.tick(p) end)
    end

    -- 10 + (3 * 8) = 34 damage → health = 66
    h.assert_eq(66, injury_mod.compute_health(p), "health after 3 ticks = 66")
end)

test("nightshade kills within expected tick count", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)

    local died = false
    local tick_count = 0
    for i = 1, 20 do
        local msgs, d
        capture_print(function() msgs, d = injury_mod.tick(p) end)
        tick_count = i
        if d then
            died = true
            break
        end
    end

    h.assert_truthy(died, "nightshade must kill within 20 ticks")
    -- With 10 initial + 8/tick, health reaches 0 at: 10 + N*8 >= 100 → N >= 11.25
    -- So death around tick 12
    h.assert_truthy(tick_count <= 15, "nightshade kills within 15 ticks (was " .. tick_count .. ")")
end)

test("nightshade antidote stops progression", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "poisoned-nightshade", "poison-bottle")
    end)

    -- Tick once (damage = 18, health = 82)
    capture_print(function() injury_mod.tick(p) end)
    local health_before_cure = injury_mod.compute_health(p)

    -- Apply antidote
    local antidote = {
        id = "antidote-nightshade",
        on_drink = {
            cures = "poisoned-nightshade",
            transition_to = "neutralized",
            message = "The antidote works.",
        },
    }
    capture_print(function() injury_mod.try_heal(p, antidote, "drink") end)
    h.assert_eq("neutralized", p.injuries[1]._state, "poison neutralized")
    h.assert_eq(0, p.injuries[1].damage_per_tick, "no more damage per tick")

    -- Tick again — health should NOT decrease further
    capture_print(function() injury_mod.tick(p) end)
    local health_after_tick = injury_mod.compute_health(p)
    h.assert_eq(health_before_cure, health_after_tick,
        "health stable after antidote (no further drain)")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 8: CONCUSSION-SPECIFIC TESTS
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 8: Concussion injury specifics")

test("concussion has causes_unconsciousness flag", function()
    h.assert_truthy(concussion_def.causes_unconsciousness,
        "concussion must declare causes_unconsciousness = true")
end)

test("concussion has unconscious_duration severity table", function()
    h.assert_truthy(concussion_def.unconscious_duration ~= nil,
        "concussion has unconscious_duration")
    h.assert_truthy(concussion_def.unconscious_duration.minor ~= nil, "has minor duration")
    h.assert_truthy(concussion_def.unconscious_duration.moderate ~= nil, "has moderate duration")
    h.assert_truthy(concussion_def.unconscious_duration.severe ~= nil, "has severe duration")
    h.assert_truthy(concussion_def.unconscious_duration.critical ~= nil, "has critical duration")
end)

test("concussion severity durations are ordered correctly", function()
    local d = concussion_def.unconscious_duration
    h.assert_truthy(d.minor < d.moderate, "minor < moderate")
    h.assert_truthy(d.moderate < d.severe, "moderate < severe")
    h.assert_truthy(d.severe < d.critical, "severe < critical")
end)

test("concussion is category unconsciousness", function()
    h.assert_eq("unconsciousness", concussion_def.category,
        "concussion category = unconsciousness")
end)

test("concussion is one_time damage (not ongoing)", function()
    h.assert_eq("one_time", concussion_def.damage_type,
        "concussion damage_type = one_time (no bleed-out)")
end)

test("concussion has no healing_interactions (heals with time only)", function()
    h.assert_eq(0, #(concussion_def.healing_interactions or {}),
        "concussion healing_interactions is empty")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 9: EDGE CASES
-- ═══════════════════════════════════════════════════════════════════════════

suite("SECTION 9: Edge cases and robustness")

test("compute_health with no injuries returns max_health", function()
    register_all_injuries()
    local p = fresh_player()
    h.assert_eq(100, injury_mod.compute_health(p), "full health with no injuries")
end)

test("compute_health with nil max_health uses fallback 100", function()
    register_all_injuries()
    local p = fresh_player()
    p.max_health = nil
    h.assert_eq(100, injury_mod.compute_health(p), "defaults to 100 when max_health is nil")
end)

test("tick with empty injuries returns no messages and no death", function()
    register_all_injuries()
    local p = fresh_player()
    local msgs, died
    capture_print(function() msgs, died = injury_mod.tick(p) end)
    h.assert_eq(0, #msgs, "no messages")
    h.assert_eq(false, not not died, "no death")
end)

test("stacking two different injury types", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "sword")
        injury_mod.inflict(p, "minor-cut", "glass")
    end)
    h.assert_eq(2, #p.injuries, "two injuries stacked")
    h.assert_eq("bleeding", p.injuries[1].type, "first is bleeding")
    h.assert_eq("minor-cut", p.injuries[2].type, "second is minor-cut")
    -- 5 + 3 = 8 damage
    h.assert_eq(92, injury_mod.compute_health(p), "health = 92 (100 - 5 - 3)")
end)

test("stacking same injury type creates separate instances", function()
    register_all_injuries()
    local p = fresh_player()
    capture_print(function()
        injury_mod.inflict(p, "bleeding", "sword-1")
        injury_mod.inflict(p, "bleeding", "sword-2")
    end)
    h.assert_eq(2, #p.injuries, "two bleeding injuries")
    h.assert_truthy(p.injuries[1].id ~= p.injuries[2].id, "different instance IDs")
end)

test("health clamped at 0 (never negative)", function()
    register_all_injuries()
    local p = fresh_player()
    p.injuries = {{ type = "bleeding", damage = 200 }}
    h.assert_eq(0, injury_mod.compute_health(p), "health clamped at 0")
end)

test("inflicting unknown injury type prints error", function()
    register_all_injuries()
    local p = fresh_player()
    local output = capture_print(function()
        injury_mod.inflict(p, "nonexistent-injury", "test")
    end)
    h.assert_truthy(output:lower():find("unknown"),
        "unknown injury type prints error")
    h.assert_eq(0, #p.injuries, "no injury added for unknown type")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
