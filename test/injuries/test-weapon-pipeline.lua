-- test/injuries/test-weapon-pipeline.lua
-- Regression tests for weapon effects pipeline migration (#50, #55).
-- Validates that knife, glass-shard, and silver-dagger have:
--   1. effects_pipeline = true
--   2. pipeline_effects arrays on all injury verbs
--   3. Injury verbs still create correct injuries via verb handlers
--   4. Injuries appear in "injuries" output
--
-- Usage: lua test/injuries/test-weapon-pipeline.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local verbs_mod = require("engine.verbs")
local injury_mod = require("engine.injuries")

---------------------------------------------------------------------------
-- Test harness
---------------------------------------------------------------------------
local passed = 0
local failed = 0

local function assert_eq(actual, expected, label)
    if actual == expected then
        passed = passed + 1
        print("  PASS " .. label)
    else
        failed = failed + 1
        print("  FAIL " .. label)
        print("    expected: " .. tostring(expected))
        print("    actual:   " .. tostring(actual))
    end
end

local function assert_true(val, label)
    assert_eq(not not val, true, label)
end

local function capture_output(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error("Handler error: " .. tostring(err)) end
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Load real object definitions from disk
---------------------------------------------------------------------------
local knife_def = dofile(repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "knife.lua")
local glass_shard_def = dofile(repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "glass-shard.lua")
local silver_dagger_def = dofile(repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "objects" .. SEP .. "silver-dagger.lua")

---------------------------------------------------------------------------
-- Load real injury definitions from disk
---------------------------------------------------------------------------
local bleeding_file = dofile(repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "injuries" .. SEP .. "bleeding.lua")
local minor_cut_file = dofile(repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "worlds" .. SEP .. "manor" .. SEP .. "injuries" .. SEP .. "minor-cut.lua")

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
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

local function setup_injuries()
    injury_mod.clear_cache()
    injury_mod.reset_id_counter()
    injury_mod.register_definition("bleeding", bleeding_file)
    injury_mod.register_definition("minor-cut", minor_cut_file)
end

local function make_ctx(weapon, opts)
    opts = opts or {}
    local player = fresh_player()
    player.hands[1] = weapon
    local objs = { [weapon.id] = weapon }
    local reg = make_mock_registry(objs)
    local room = {
        id = "test-room", name = "Test Room",
        description = "A test room.",
        contents = {}, exits = {}, light_level = 0,
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = opts.verb or "",
        injuries = player.injuries,
        known_objects = {},
        last_object = nil,
    }
end

local handlers = verbs_mod.create()

---------------------------------------------------------------------------
-- 1. DATA STRUCTURE — effects_pipeline flag
---------------------------------------------------------------------------
print("\n=== Pipeline flag: effects_pipeline = true ===")

assert_true(knife_def.effects_pipeline, "knife has effects_pipeline = true")
assert_true(glass_shard_def.effects_pipeline, "glass-shard has effects_pipeline = true")
assert_true(silver_dagger_def.effects_pipeline, "silver-dagger has effects_pipeline = true")

---------------------------------------------------------------------------
-- 2. DATA STRUCTURE — pipeline_effects arrays exist
---------------------------------------------------------------------------
print("\n=== Pipeline arrays: pipeline_effects on injury verbs ===")

-- Knife
assert_true(knife_def.on_stab.pipeline_effects ~= nil, "knife.on_stab has pipeline_effects")
assert_true(#knife_def.on_stab.pipeline_effects > 0, "knife.on_stab.pipeline_effects is non-empty")
assert_eq(knife_def.on_stab.pipeline_effects[1].type, "inflict_injury", "knife stab pipeline type is inflict_injury")
assert_eq(knife_def.on_stab.pipeline_effects[1].injury_type, "bleeding", "knife stab pipeline injury_type is bleeding")
assert_eq(knife_def.on_stab.pipeline_effects[1].damage, 5, "knife stab pipeline damage is 5")

assert_true(knife_def.on_cut.pipeline_effects ~= nil, "knife.on_cut has pipeline_effects")
assert_true(#knife_def.on_cut.pipeline_effects > 0, "knife.on_cut.pipeline_effects is non-empty")
assert_eq(knife_def.on_cut.pipeline_effects[1].type, "inflict_injury", "knife cut pipeline type is inflict_injury")
assert_eq(knife_def.on_cut.pipeline_effects[1].injury_type, "minor-cut", "knife cut pipeline injury_type is minor-cut")
assert_eq(knife_def.on_cut.pipeline_effects[1].damage, 3, "knife cut pipeline damage is 3")

-- Glass shard
assert_true(glass_shard_def.on_cut.pipeline_effects ~= nil, "glass-shard.on_cut has pipeline_effects")
assert_true(#glass_shard_def.on_cut.pipeline_effects > 0, "glass-shard.on_cut.pipeline_effects is non-empty")
assert_eq(glass_shard_def.on_cut.pipeline_effects[1].type, "inflict_injury", "shard cut pipeline type is inflict_injury")
assert_eq(glass_shard_def.on_cut.pipeline_effects[1].injury_type, "minor-cut", "shard cut pipeline injury_type is minor-cut")
assert_eq(glass_shard_def.on_cut.pipeline_effects[1].damage, 3, "shard cut pipeline damage is 3")

-- Glass shard: on_feel_effect is structured (not a bare string)
assert_true(type(glass_shard_def.on_feel_effect) == "table", "glass-shard.on_feel_effect is structured table")
assert_eq(glass_shard_def.on_feel_effect.type, "inflict_injury", "shard feel_effect type is inflict_injury")
assert_true(glass_shard_def.on_feel_effect.pipeline_routed, "shard feel_effect is pipeline_routed")

-- Silver dagger
assert_true(silver_dagger_def.on_stab.pipeline_effects ~= nil, "silver-dagger.on_stab has pipeline_effects")
assert_eq(silver_dagger_def.on_stab.pipeline_effects[1].injury_type, "bleeding", "dagger stab pipeline → bleeding")
assert_eq(silver_dagger_def.on_stab.pipeline_effects[1].damage, 8, "dagger stab pipeline damage is 8")

assert_true(silver_dagger_def.on_cut.pipeline_effects ~= nil, "silver-dagger.on_cut has pipeline_effects")
assert_eq(silver_dagger_def.on_cut.pipeline_effects[1].injury_type, "minor-cut", "dagger cut pipeline → minor-cut")
assert_eq(silver_dagger_def.on_cut.pipeline_effects[1].damage, 4, "dagger cut pipeline damage is 4")

assert_true(silver_dagger_def.on_slash.pipeline_effects ~= nil, "silver-dagger.on_slash has pipeline_effects")
assert_eq(silver_dagger_def.on_slash.pipeline_effects[1].injury_type, "bleeding", "dagger slash pipeline → bleeding")
assert_eq(silver_dagger_def.on_slash.pipeline_effects[1].damage, 6, "dagger slash pipeline damage is 6")

---------------------------------------------------------------------------
-- 3. BACKWARD COMPAT — legacy fields preserved
---------------------------------------------------------------------------
print("\n=== Backward compat: legacy fields preserved ===")

assert_eq(knife_def.on_stab.damage, 5, "knife.on_stab.damage preserved")
assert_eq(knife_def.on_stab.injury_type, "bleeding", "knife.on_stab.injury_type preserved")
assert_true(knife_def.on_stab.description ~= nil, "knife.on_stab.description preserved")

assert_eq(glass_shard_def.on_cut.damage, 3, "glass-shard.on_cut.damage preserved")
assert_eq(glass_shard_def.on_cut.injury_type, "minor-cut", "glass-shard.on_cut.injury_type preserved")
assert_true(glass_shard_def.on_cut.self_damage, "glass-shard.on_cut.self_damage preserved")

assert_eq(silver_dagger_def.on_slash.damage, 6, "silver-dagger.on_slash.damage preserved")
assert_eq(silver_dagger_def.on_slash.injury_type, "bleeding", "silver-dagger.on_slash.injury_type preserved")

---------------------------------------------------------------------------
-- 4. PIPELINE SOURCE — source field matches object id
---------------------------------------------------------------------------
print("\n=== Pipeline source: source matches object id ===")

assert_eq(knife_def.on_stab.pipeline_effects[1].source, "knife", "knife stab source is 'knife'")
assert_eq(knife_def.on_cut.pipeline_effects[1].source, "knife", "knife cut source is 'knife'")
assert_eq(glass_shard_def.on_cut.pipeline_effects[1].source, "glass-shard", "shard cut source is 'glass-shard'")
assert_eq(silver_dagger_def.on_stab.pipeline_effects[1].source, "silver-dagger", "dagger stab source is 'silver-dagger'")
assert_eq(silver_dagger_def.on_cut.pipeline_effects[1].source, "silver-dagger", "dagger cut source is 'silver-dagger'")
assert_eq(silver_dagger_def.on_slash.pipeline_effects[1].source, "silver-dagger", "dagger slash source is 'silver-dagger'")

---------------------------------------------------------------------------
-- 5. GOAP PREREQUISITES — warns hints present
---------------------------------------------------------------------------
print("\n=== GOAP prerequisites: warns hints ===")

assert_true(knife_def.prerequisites ~= nil, "knife has prerequisites")
assert_true(knife_def.prerequisites.stab ~= nil, "knife has stab prerequisites")
assert_true(knife_def.prerequisites.cut ~= nil, "knife has cut prerequisites")

assert_true(glass_shard_def.prerequisites ~= nil, "glass-shard has prerequisites")
assert_true(glass_shard_def.prerequisites.cut ~= nil, "glass-shard has cut prerequisites")

assert_true(silver_dagger_def.prerequisites ~= nil, "silver-dagger has prerequisites")
assert_true(silver_dagger_def.prerequisites.stab ~= nil, "silver-dagger has stab prerequisites")
assert_true(silver_dagger_def.prerequisites.cut ~= nil, "silver-dagger has cut prerequisites")
assert_true(silver_dagger_def.prerequisites.slash ~= nil, "silver-dagger has slash prerequisites")

---------------------------------------------------------------------------
-- 6. FUNCTIONAL — stab self with knife creates bleeding injury
---------------------------------------------------------------------------
print("\n=== Functional: stab self with knife → bleeding ===")
setup_injuries()

do
    local ctx = make_ctx(knife_def, { verb = "stab" })
    local output = capture_output(function() handlers["stab"](ctx, "self with knife") end)
    assert_true(#ctx.player.injuries > 0, "stab self with knife creates injury")
    assert_eq(ctx.player.injuries[1].type, "bleeding", "stab with knife → bleeding injury")
    assert_true(ctx.player.injuries[1].source:find("knife"), "injury source references knife")
end

---------------------------------------------------------------------------
-- 7. FUNCTIONAL — cut self with glass shard creates minor-cut
---------------------------------------------------------------------------
print("\n=== Functional: cut self with glass shard → minor-cut ===")
setup_injuries()

do
    local ctx = make_ctx(glass_shard_def, { verb = "cut" })
    local output = capture_output(function() handlers["cut"](ctx, "self with glass shard") end)
    assert_true(#ctx.player.injuries > 0, "cut self with glass shard creates injury")
    assert_eq(ctx.player.injuries[1].type, "minor-cut", "cut with glass shard → minor-cut")
    assert_true(ctx.player.injuries[1].source:find("glass%-shard"), "injury source references glass-shard")
end

---------------------------------------------------------------------------
-- 8. FUNCTIONAL — stab self with silver dagger creates bleeding
---------------------------------------------------------------------------
print("\n=== Functional: stab self with silver dagger → bleeding ===")
setup_injuries()

do
    local ctx = make_ctx(silver_dagger_def, { verb = "stab" })
    -- Use "arm" to get a deterministic body area (left arm, modifier 1.0)
    -- so damage = base 8 * 1.0 = 8 (not random per BUG-151)
    local output = capture_output(function() handlers["stab"](ctx, "arm with silver dagger") end)
    assert_true(#ctx.player.injuries > 0, "stab self with silver dagger creates injury")
    assert_eq(ctx.player.injuries[1].type, "bleeding", "stab with dagger → bleeding")
    assert_eq(ctx.player.injuries[1].damage, 8, "dagger stab damage is 8 (arm, 1.0x)")
end

---------------------------------------------------------------------------
-- 9. FUNCTIONAL — slash self with silver dagger creates bleeding
---------------------------------------------------------------------------
print("\n=== Functional: slash self with silver dagger → bleeding ===")
setup_injuries()

do
    local ctx = make_ctx(silver_dagger_def, { verb = "slash" })
    local output = capture_output(function() handlers["slash"](ctx, "self with silver dagger") end)
    assert_true(#ctx.player.injuries > 0, "slash self with silver dagger creates injury")
    assert_eq(ctx.player.injuries[1].type, "bleeding", "slash with dagger → bleeding")
end

---------------------------------------------------------------------------
-- 10. FUNCTIONAL — injuries appear in list output
---------------------------------------------------------------------------
print("\n=== Functional: injuries appear in 'injuries' output ===")
setup_injuries()

do
    local p = fresh_player()
    capture_output(function()
        injury_mod.inflict(p, "bleeding", "knife", "left arm", 5)
    end)
    local output = capture_output(function() injury_mod.list(p) end)
    assert_true(output:find("bleeding") or output:find("Bleeding"), "injuries list shows bleeding after knife stab")
    assert_true(output:find("left arm"), "injuries list shows body location")
end

do
    local p = fresh_player()
    capture_output(function()
        injury_mod.inflict(p, "minor-cut", "glass-shard", "right hand", 3)
    end)
    local output = capture_output(function() injury_mod.list(p) end)
    assert_true(output:find("cut") or output:find("Cut"), "injuries list shows cut after glass shard")
    assert_true(output:find("right hand"), "injuries list shows hand location")
end

---------------------------------------------------------------------------
-- 11. INJURY TYPES EXIST — referenced injuries are loadable
---------------------------------------------------------------------------
print("\n=== Injury types: referenced definitions exist on disk ===")

assert_true(bleeding_file ~= nil, "bleeding.lua loads successfully")
assert_eq(bleeding_file.id, "bleeding", "bleeding.lua has correct id")
assert_true(bleeding_file.states ~= nil, "bleeding.lua has FSM states")

assert_true(minor_cut_file ~= nil, "minor-cut.lua loads successfully")
assert_eq(minor_cut_file.id, "minor-cut", "minor-cut.lua has correct id")
assert_true(minor_cut_file.states ~= nil, "minor-cut.lua has FSM states")

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    os.exit(1)
end
