-- test/verbs/test-stab-regression.lua
-- Regression tests for stab verb: defines the CONTRACT for issue #50
-- (stabbing with knife doesn't create injuries) and #49 (weapon inference).
--
-- These tests define what SHOULD happen. Failures = bugs for Smithers to fix.
--
-- Usage: lua test/verbs/test-stab-regression.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local verbs_mod = require("engine.verbs")
local registry_mod = require("engine.registry")
local injury_mod = require("engine.injuries")

local test = h.test
local suite = h.suite

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
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
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(captured, "\n")
end

local function fresh_knife()
    return {
        id = "knife",
        name = "a small knife",
        keywords = {"knife", "blade", "small knife", "dagger"},
        categories = {"small", "tool", "weapon", "sharp", "metal"},
        portable = true,
        provides_tool = {"cutting_edge", "injury_source"},
        on_stab = {
            damage = 5,
            injury_type = "bleeding",
            description = "You stab the knife into your %s. It hurts more than you expected.",
        },
        on_cut = {
            damage = 3,
            injury_type = "minor-cut",
            description = "You nick your %s with the knife. A shallow cut — it stings.",
        },
        mutations = {},
    }
end

local function fresh_silver_dagger()
    return {
        id = "silver-dagger",
        name = "a silver dagger",
        keywords = {"dagger", "silver dagger", "silver-dagger"},
        categories = {"weapon", "tool", "metal", "treasure", "sharp"},
        portable = true,
        provides_tool = {"cutting_edge", "injury_source", "ritual_blade"},
        on_stab = {
            damage = 8,
            injury_type = "bleeding",
            description = "You drive the silver dagger into your %s. Blood wells up immediately.",
        },
        on_cut = {
            damage = 4,
            injury_type = "minor-cut",
            description = "You draw the dagger's edge across your %s. A thin red line appears.",
        },
        on_slash = {
            damage = 6,
            injury_type = "bleeding",
            description = "You slash the dagger across your %s. The wound opens wide and bleeds freely.",
        },
        mutations = {},
    }
end

local function fresh_player()
    return {
        max_health = 100,
        injuries = {},
        hands = { nil, nil },
        worn_items = {},
        bags = {},
        worn = {},
        state = {},
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
    local knife = opts.knife or fresh_knife()
    local objs = opts.objects or {}
    if opts.knife_in_hand then
        objs.knife = knife
    end
    if opts.extra_objects then
        for k, v in pairs(opts.extra_objects) do objs[k] = v end
    end
    local reg = make_mock_registry(objs)
    local player = opts.player or fresh_player()
    if opts.knife_in_hand then
        player.hands[1] = knife
    end
    if opts.both_hands then
        player.hands[1] = opts.both_hands[1]
        player.hands[2] = opts.both_hands[2]
    end

    local room = opts.room or {
        id = "test-room",
        name = "Test Room",
        description = "A test room.",
        contents = opts.room_contents or {},
        exits = {},
        light_level = opts.light_level or 0,
    }

    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = opts.time_offset or 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
end

local function setup_injuries()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("bleeding", {
        id = "bleeding", name = "Bleeding Wound",
        category = "physical", damage_type = "over_time",
        initial_state = "active",
        on_inflict = { initial_damage = 5, damage_per_tick = 5, message = "Blood wells." },
        states = {
            active = { name = "bleeding", damage_per_tick = 5 },
            treated = { name = "bandaged", damage_per_tick = 0 },
            healed = { name = "healed", terminal = true },
        },
        healing_interactions = {},
    })
    injury_mod.register_definition("minor-cut", {
        id = "minor-cut", name = "Minor Cut",
        category = "physical", damage_type = "one_time",
        initial_state = "active",
        on_inflict = { initial_damage = 3, damage_per_tick = 0, message = "A thin red line." },
        states = {
            active = { name = "minor cut", damage_per_tick = 0, auto_heal_turns = 5 },
            healed = { name = "healed", terminal = true },
        },
        healing_interactions = {},
    })
end

---------------------------------------------------------------------------
-- TEST 1: "stab self with knife" while holding knife → creates stab wound
---------------------------------------------------------------------------
suite("REGRESSION #50: stab self with knife → creates injury")

test("stab self with knife creates a bleeding injury", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "#50 REGRESSION: stab self with knife MUST create an injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type,
        "#50 REGRESSION: injury type must be 'bleeding' (from knife on_stab profile)")
end)

test("stab wound has correct source attribution", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should create injury")
    local source = ctx.player.injuries[1].source
    h.assert_truthy(source and source:find("knife"),
        "#50 REGRESSION: injury source must reference the knife")
end)

test("stab wound has a body location assigned", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should create injury")
    h.assert_truthy(ctx.player.injuries[1].location ~= nil,
        "#50 REGRESSION: stab wound must have a location (body area)")
end)

test("stab wound starts with correct damage from knife profile", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Should create injury")
    -- Knife on_stab.damage = 5, left arm modifier = 1.0 → 5
    h.assert_eq(5, ctx.player.injuries[1].damage,
        "#50 REGRESSION: stab damage must match knife profile (5 for left arm)")
end)

---------------------------------------------------------------------------
-- TEST 2: Stab wound appears in "injuries" output
---------------------------------------------------------------------------
suite("REGRESSION #50: stab wound visible in injuries output")

test("stab wound shows in injury list after stabbing", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury first")

    -- Now check injury list output
    local list_output = capture_output(function() injury_mod.list(ctx.player) end)
    h.assert_truthy(list_output:find("bleeding") or list_output:find("Bleeding"),
        "#50 REGRESSION: 'injuries' command must show the stab wound")
end)

test("stab wound location appears in injuries output", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury first")

    local list_output = capture_output(function() injury_mod.list(ctx.player) end)
    h.assert_truthy(list_output:find("left arm"),
        "#50 REGRESSION: injuries output must show wound location")
end)

---------------------------------------------------------------------------
-- TEST 3: Stab wound ticks bleeding damage per turn
---------------------------------------------------------------------------
suite("REGRESSION #50: stab wound ticks bleeding damage")

test("stab wound accumulates damage on tick", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "self with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")

    local initial_damage = ctx.player.injuries[1].damage
    local initial_health = injury_mod.compute_health(ctx.player)

    -- Tick once
    capture_output(function() injury_mod.tick(ctx.player) end)

    local post_tick_damage = ctx.player.injuries[1].damage
    local post_tick_health = injury_mod.compute_health(ctx.player)

    h.assert_truthy(post_tick_damage > initial_damage,
        "#50 REGRESSION: stab wound must accumulate damage per tick")
    h.assert_truthy(post_tick_health < initial_health,
        "#50 REGRESSION: health must decrease after tick with stab wound")
end)

test("stab wound drains 5 hp per tick (bleeding profile)", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    h.assert_truthy(#ctx.player.injuries > 0, "Must have injury")

    local dmg_before = ctx.player.injuries[1].damage
    capture_output(function() injury_mod.tick(ctx.player) end)
    local dmg_after = ctx.player.injuries[1].damage

    h.assert_eq(5, dmg_after - dmg_before,
        "#50 REGRESSION: bleeding stab wound must drain 5 damage per tick")
end)

---------------------------------------------------------------------------
-- TEST 4: Multiple stabs create multiple injuries
---------------------------------------------------------------------------
suite("REGRESSION #50: multiple stabs → multiple injuries")

test("two stabs create two separate injury instances", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })

    capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    capture_output(function() handlers["stab"](ctx, "my right arm with knife") end)

    h.assert_truthy(#ctx.player.injuries >= 2,
        "#50 REGRESSION: each stab must create a separate injury instance")
end)

test("multiple stabs accumulate total damage", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })

    capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    capture_output(function() handlers["stab"](ctx, "my right arm with knife") end)

    -- Two stabs at 5 damage each = 10 total, health = 90
    local health = injury_mod.compute_health(ctx.player)
    h.assert_truthy(health <= 90,
        "#50 REGRESSION: multiple stabs must reduce health cumulatively")
end)

test("multiple stab wounds all appear in injuries list", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })

    capture_output(function() handlers["stab"](ctx, "my left arm with knife") end)
    capture_output(function() handlers["stab"](ctx, "my right arm with knife") end)

    local list_output = capture_output(function() injury_mod.list(ctx.player) end)
    h.assert_truthy(list_output:find("left arm"),
        "#50 REGRESSION: first stab location must appear in list")
    h.assert_truthy(list_output:find("right arm"),
        "#50 REGRESSION: second stab location must appear in list")
end)

---------------------------------------------------------------------------
-- TEST 5: "stab yourself" with one weapon in hand → infers weapon (#49)
---------------------------------------------------------------------------
suite("REGRESSION #49: weapon inference — stab self with single weapon")

test("stab self with knife in hand infers knife automatically", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "#49 REGRESSION: 'stab self' with knife in hand must auto-infer knife and create injury")
    h.assert_eq("bleeding", ctx.player.injuries[1].type,
        "#49 REGRESSION: inferred knife stab must produce bleeding injury")
end)

test("stab yourself with knife in hand infers weapon", function()
    setup_injuries()
    local ctx = make_ctx({ knife_in_hand = true, verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "myself") end)
    h.assert_truthy(#ctx.player.injuries > 0,
        "#49 REGRESSION: 'stab myself' with knife in hand must auto-infer weapon")
end)

---------------------------------------------------------------------------
-- TEST 6: "stab yourself" with no weapon → helpful error
---------------------------------------------------------------------------
suite("REGRESSION #49: no weapon → helpful error message")

test("stab self with empty hands gives weapon-needed error", function()
    setup_injuries()
    local ctx = make_ctx({ verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Should NOT create injury with no weapon")
    h.assert_truthy(output:find("nothing sharp") or output:find("need a weapon") or output:find("need something"),
        "#49 REGRESSION: must give helpful error about needing a weapon")
end)

---------------------------------------------------------------------------
-- TEST 7: "stab yourself" with multiple weapons → disambiguation
---------------------------------------------------------------------------
suite("REGRESSION #49: multiple weapons → disambiguation prompt")

test("stab self with two weapons prompts disambiguation", function()
    setup_injuries()
    local knife = fresh_knife()
    local dagger = fresh_silver_dagger()
    local ctx = make_ctx({
        verb = "stab",
        both_hands = { knife, dagger },
        objects = { knife = knife, ["silver-dagger"] = dagger },
    })
    local output = capture_output(function() handlers["stab"](ctx, "self") end)
    h.assert_truthy(#ctx.player.injuries == 0,
        "Should NOT auto-pick when ambiguous")
    h.assert_truthy(output:find("with what") or output:find("holding"),
        "#49 REGRESSION: must prompt disambiguation when multiple weapons held")
end)

---------------------------------------------------------------------------
-- TEST 8: Knife has correct weapon metadata
---------------------------------------------------------------------------
suite("REGRESSION: knife weapon metadata contract")

test("knife has 'weapon' in categories", function()
    local knife = fresh_knife()
    local found = false
    for _, cat in ipairs(knife.categories) do
        if cat == "weapon" then found = true; break end
    end
    h.assert_truthy(found, "Knife must have 'weapon' category")
end)

test("knife has on_stab profile with damage", function()
    local knife = fresh_knife()
    h.assert_truthy(knife.on_stab, "Knife must have on_stab profile")
    h.assert_truthy(knife.on_stab.damage and knife.on_stab.damage > 0,
        "Knife on_stab must have positive damage")
end)

test("knife on_stab.injury_type is bleeding", function()
    local knife = fresh_knife()
    h.assert_eq("bleeding", knife.on_stab.injury_type,
        "Knife stab must produce 'bleeding' injury type")
end)

test("knife has injury_source in provides_tool", function()
    local knife = fresh_knife()
    local found = false
    for _, tool in ipairs(knife.provides_tool) do
        if tool == "injury_source" then found = true; break end
    end
    h.assert_truthy(found, "Knife must provide 'injury_source' tool capability")
end)

test("knife on_stab.description has body area placeholder", function()
    local knife = fresh_knife()
    h.assert_truthy(knife.on_stab.description:find("%%s"),
        "Knife stab description must have %s placeholder for body area")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
