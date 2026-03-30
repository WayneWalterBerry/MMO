-- test/integration/test-stab-self-pipeline.lua
-- Integration test: "get knife" then "stab self" through effects pipeline.
-- Validates the FULL code path with effects_pipeline = true (D-EFFECTS-PIPELINE).
--
-- Bug report: "stab self" says "The wound doesn't take hold" on live despite
-- commit 009a935 routing self-infliction through effects.process().
--
-- Usage: lua test/integration/test-stab-self-pipeline.lua
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
local effects_mod = require("engine.effects")

local test    = h.test
local suite   = h.suite
local eq      = h.assert_eq
local truthy  = h.assert_truthy

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

-- Real knife definition WITH effects_pipeline (matches src/meta/worlds/manor/objects/knife.lua)
local function pipeline_knife()
    return {
        id = "knife",
        name = "a small knife",
        keywords = {"knife", "blade", "small knife", "dagger", "shiv", "paring knife"},
        categories = {"small", "tool", "weapon", "sharp", "metal"},
        portable = true,
        effects_pipeline = true,
        provides_tool = {"cutting_edge", "injury_source"},
        on_stab = {
            damage = 5,
            injury_type = "bleeding",
            description = "You stab the knife into your %s. It hurts more than you expected.",
            pain_description = "A blunt, throbbing pain.",
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "bleeding",
                  source = "knife", damage = 5,
                  message = "You stab the knife into your %s. It hurts more than you expected." },
            },
        },
        on_cut = {
            damage = 3,
            injury_type = "minor-cut",
            description = "You nick your %s with the knife. A shallow cut — it stings.",
            pipeline_effects = {
                { type = "inflict_injury", injury_type = "minor-cut",
                  source = "knife", damage = 3,
                  message = "You nick your %s with the knife. A shallow cut — it stings." },
            },
        },
        mutations = {},
    }
end

-- Legacy knife WITHOUT effects_pipeline (matches old test-combat-verbs.lua)
local function legacy_knife()
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

local function make_ctx(knife_fn)
    local knife = knife_fn()
    local objs = { knife = knife }
    local reg = make_mock_registry(objs)
    local player = fresh_player()
    player.hands[1] = knife

    local room = {
        id = "bedroom",
        name = "Your Bedroom",
        description = "A small bedroom.",
        contents = {},
        exits = {},
        light_level = 1,
    }

    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "stab",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
end

-- Register bleeding definition so injuries.load_definition finds it
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
            active = { name = "minor cut", damage_per_tick = 0 },
            healed = { name = "healed", terminal = true },
        },
        healing_interactions = {},
    })
end

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------

suite("=== STAB SELF: Legacy knife (no effects_pipeline) ===")

test("legacy knife — stab self creates bleeding injury", function()
    setup_injuries()
    effects_mod.clear_interceptors()
    local ctx = make_ctx(legacy_knife)
    local output = capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    -- Should NOT contain "wound doesn't take hold"
    eq(nil, output:find("wound doesn't take hold"),
       "Legacy path should NOT say 'wound doesn't take hold'. Got: " .. output)
    -- Player should have an injury
    truthy(#ctx.player.injuries > 0,
        "Player should have at least one injury (legacy path). Injuries: " .. #ctx.player.injuries)
    eq("bleeding", ctx.player.injuries[1].type,
        "Injury type should be 'bleeding'")
end)

suite("=== STAB SELF: Pipeline knife (effects_pipeline = true) ===")

test("pipeline knife — stab self creates bleeding injury", function()
    setup_injuries()
    effects_mod.clear_interceptors()
    local ctx = make_ctx(pipeline_knife)
    local output = capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    print("  [DEBUG] Output: " .. output)
    print("  [DEBUG] Injuries count: " .. #ctx.player.injuries)
    for i, inj in ipairs(ctx.player.injuries) do
        print("  [DEBUG] Injury " .. i .. ": type=" .. tostring(inj.type) ..
              " source=" .. tostring(inj.source))
    end
    -- Should NOT contain "wound doesn't take hold"
    eq(nil, output:find("wound doesn't take hold"),
       "Pipeline path should NOT say 'wound doesn't take hold'. Got: " .. output)
    -- Player should have an injury
    truthy(#ctx.player.injuries > 0,
        "Player should have at least one injury (pipeline path). Injuries: " .. #ctx.player.injuries)
    eq("bleeding", ctx.player.injuries[1].type,
        "Injury type should be 'bleeding'")
end)

test("pipeline knife — injury source matches expected format", function()
    setup_injuries()
    effects_mod.clear_interceptors()
    local ctx = make_ctx(pipeline_knife)
    capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    truthy(#ctx.player.injuries > 0, "Must have at least one injury")
    local inj = ctx.player.injuries[1]
    truthy(inj.source:find("self%-inflicted"),
        "Source should contain 'self-inflicted', got: " .. tostring(inj.source))
end)

test("pipeline knife — stab self sets bloody state", function()
    setup_injuries()
    effects_mod.clear_interceptors()
    local ctx = make_ctx(pipeline_knife)
    capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    truthy(ctx.player.state.bloody, "Player state.bloody should be true")
    eq(10, ctx.player.state.bleed_ticks, "bleed_ticks should be 10")
end)

suite("=== STAB SELF: effects.process() direct verification ===")

test("effects.process inflict_injury creates injury on player", function()
    setup_injuries()
    effects_mod.clear_interceptors()
    local player = fresh_player()
    local fx_list = {
        { type = "inflict_injury", injury_type = "bleeding",
          source = "test-source", damage = 5, location = "arm",
          message = "Test stab." },
    }
    local fx_ctx = { player = player, registry = nil, source = nil }
    local result = effects_mod.process(fx_list, fx_ctx)
    print("  [DEBUG] effects.process returned: " .. tostring(result))
    print("  [DEBUG] player.injuries count: " .. #player.injuries)
    for i, inj in ipairs(player.injuries) do
        print("  [DEBUG] Injury " .. i .. ": type=" .. tostring(inj.type) ..
              " source=" .. tostring(inj.source))
    end
    truthy(result, "effects.process should return true")
    truthy(#player.injuries > 0, "Player should have an injury after effects.process")
    eq("bleeding", player.injuries[1].type)
    eq("test-source", player.injuries[1].source)
end)

suite("=== STAB SELF: Full flow — get knife then stab self ===")

test("full flow: knife in room → get knife → stab self → bleeding injury", function()
    setup_injuries()
    effects_mod.clear_interceptors()

    -- Set up room with knife on floor
    local knife = pipeline_knife()
    knife.location = "bedroom"
    local reg = make_mock_registry({ knife = knife })
    local player = fresh_player()
    local room = {
        id = "bedroom",
        name = "Your Bedroom",
        description = "A small bedroom.",
        contents = { "knife" },
        exits = {},
        light_level = 1,
    }

    local ctx = {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 8,
        game_start_time = os.time(),
        current_verb = "get",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }

    -- Step 1: "get knife"
    local output1 = capture_output(function()
        handlers["get"](ctx, "knife")
    end)
    print("  [DEBUG] get knife output: " .. output1)

    -- Check knife is in player's hands
    local has_knife = false
    for i = 1, 2 do
        local hand = ctx.player.hands[i]
        if hand then
            local obj = (type(hand) == "table") and hand or reg:get(hand)
            if obj and obj.id == "knife" then has_knife = true end
        end
    end
    truthy(has_knife, "Knife should be in player's hands after 'get knife'")

    -- Step 2: "stab self"
    ctx.current_verb = "stab"
    local output2 = capture_output(function()
        handlers["stab"](ctx, "self")
    end)
    print("  [DEBUG] stab self output: " .. output2)
    print("  [DEBUG] Injuries count: " .. #ctx.player.injuries)
    for i, inj in ipairs(ctx.player.injuries) do
        print("  [DEBUG] Injury " .. i .. ": type=" .. tostring(inj.type) ..
              " source=" .. tostring(inj.source) ..
              " damage=" .. tostring(inj.damage))
    end

    -- Should NOT say "wound doesn't take hold"
    eq(nil, output2:find("wound doesn't take hold"),
       "Should NOT see 'wound doesn't take hold'. Got: " .. output2)

    -- Player should have bleeding injury
    truthy(#ctx.player.injuries > 0,
        "Player should have at least one injury after 'stab self'")
    eq("bleeding", ctx.player.injuries[1].type,
        "Injury should be 'bleeding'")

    -- Player should be bloody
    truthy(ctx.player.state.bloody, "Player should be bloody")
end)

suite("=== STAB SELF: Diagnosis — what does effects.normalize do? ===")

test("normalize handles array of effect tables", function()
    local fx = {
        { type = "inflict_injury", injury_type = "bleeding" },
    }
    local result = effects_mod.normalize(fx)
    truthy(result, "normalize should return a table for array input")
    eq(1, #result, "Should have 1 effect")
    eq("inflict_injury", result[1].type)
end)

test("normalize handles single effect table", function()
    local fx = { type = "inflict_injury", injury_type = "bleeding" }
    local result = effects_mod.normalize(fx)
    truthy(result, "normalize should return a table for single effect")
    eq(1, #result, "Should wrap single effect in array")
    eq("inflict_injury", result[1].type)
end)

suite("=== WEB BUILD SIMULATION: injury defs missing from require() ===")

-- This test simulates the web build environment where
-- require("meta.worlds.manor.injuries.bleeding") FAILS because build-meta.ps1
-- does NOT copy src/meta/worlds/manor/injuries/ to web/dist/meta/injuries/.
-- The injury definition cache is cleared and no definitions are registered,
-- mimicking what happens on the live site.

test("BUG REPRO: pipeline knife with EMPTY injury cache -> 'wound doesn't take hold'", function()
    -- Clear injury cache to simulate web build (no preloaded definitions)
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    -- NOTE: NOT calling setup_injuries() — mimics web build

    -- Temporarily break require("meta.worlds.manor.injuries.bleeding") by removing from loaded
    local saved_bleeding = package.loaded["meta.injuries.bleeding"]
    local saved_preload  = package.preload["meta.injuries.bleeding"]
    package.loaded["meta.injuries.bleeding"] = nil
    package.preload["meta.injuries.bleeding"] = nil

    -- Poison the searcher so require can't find it via filesystem either
    -- (simulates the browser environment where no filesystem searchers work)
    local old_path = package.path
    -- Remove any path that could find src/meta/worlds/manor/injuries/
    package.path = ""

    effects_mod.clear_interceptors()
    local ctx = make_ctx(pipeline_knife)
    local output = capture_output(function()
        handlers["stab"](ctx, "self")
    end)

    -- Restore
    package.path = old_path
    package.loaded["meta.injuries.bleeding"] = saved_bleeding
    if saved_preload then
        package.preload["meta.injuries.bleeding"] = saved_preload
    end

    print("  [BUG REPRO] Output: " .. output)
    print("  [BUG REPRO] Injuries count: " .. #ctx.player.injuries)

    -- THIS IS THE BUG: we expect "wound doesn't take hold" because
    -- the injury definition can't be loaded
    truthy(output:find("wound doesn't take hold"),
        "BUG CONFIRMED: when injury defs are missing, we get 'wound doesn't take hold'. Output: " .. output)
    eq(0, #ctx.player.injuries,
        "No injuries created when definition is missing")
end)

test("BUG REPRO: legacy knife with EMPTY injury cache -> ALSO fails", function()
    -- This proves the bug affects BOTH paths (not just pipeline)
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()

    local saved_bleeding = package.loaded["meta.injuries.bleeding"]
    local saved_preload  = package.preload["meta.injuries.bleeding"]
    package.loaded["meta.injuries.bleeding"] = nil
    package.preload["meta.injuries.bleeding"] = nil
    local old_path = package.path
    package.path = ""

    effects_mod.clear_interceptors()
    local ctx = make_ctx(legacy_knife)
    local output = capture_output(function()
        handlers["stab"](ctx, "self")
    end)

    package.path = old_path
    package.loaded["meta.injuries.bleeding"] = saved_bleeding
    if saved_preload then
        package.preload["meta.injuries.bleeding"] = saved_preload
    end

    print("  [BUG REPRO] Legacy output: " .. output)
    print("  [BUG REPRO] Legacy injuries count: " .. #ctx.player.injuries)

    -- Legacy path also fails when definition is missing
    truthy(output:find("wound doesn't take hold"),
        "Legacy path ALSO fails when injury defs are missing. Output: " .. output)
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local exit_code = h.summary()
os.exit(exit_code == 0 and 0 or 1)
