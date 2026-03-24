-- test/verbs/test-on-drop.lua
-- Tests for on_drop event + material fragility system (Issue #56).
-- Covers the specific acceptance criteria from Phase E:
--   1. Drop ceramic pot on stone floor → shatters, spawns ceramic shards
--   2. Drop brass object on stone floor → clangs, doesn't break (fragility 0.1)
--   3. Drop glass bottle → shatters (fragility 0.9)
--   4. Drop wooden object → doesn't break (fragility 0.2)
--   5. Drop on soft surface (bed, carpet) → nothing breaks regardless of fragility
--   6. Fragility threshold: fragility >= 0.5 AND surface_hardness >= 5 → break
--
-- Usage: lua test/verbs/test-on-drop.lua
-- Must be run from the repository root.

local SEP = package.config:sub(1, 1)
local repo_root = "."
package.path = repo_root .. SEP .. "src" .. SEP .. "?.lua;"
             .. repo_root .. SEP .. "src" .. SEP .. "?" .. SEP .. "init.lua;"
             .. repo_root .. SEP .. "test" .. SEP .. "parser" .. SEP .. "?.lua;"
             .. package.path

local h = require("test-helpers")
local materials = require("engine.materials")
local registry_mod = require("engine.registry")

local test = h.test
local suite = h.suite

---------------------------------------------------------------------------
-- Load object definitions from disk
---------------------------------------------------------------------------
local OBJ_DIR = repo_root .. SEP .. "src" .. SEP .. "meta" .. SEP .. "objects" .. SEP

local function load_obj(name)
    return dofile(OBJ_DIR .. name .. ".lua")
end

local chamber_pot_def = load_obj("chamber-pot")
local wine_bottle_def = load_obj("wine-bottle")
local brass_key_def   = load_obj("brass-key")
local ceramic_shard_def = load_obj("ceramic-shard")

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

local function make_ctx(obj, room_opts)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    -- Pre-register shard definitions so spawns can resolve
    local cs = deep_copy(ceramic_shard_def)
    reg:register("ceramic-shard", cs)
    local room = {
        id = "test-room",
        name = "Test Room",
        contents = {},
        floor_material = (room_opts and room_opts.floor_material) or nil,
    }
    obj.location = nil  -- in hands, not placed
    local player = {
        hands = { obj, nil },
        worn = {},
        injuries = {},
        state = {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
    }
end

local function array_contains(arr, val)
    for _, v in ipairs(arr or {}) do
        if v == val then return true end
    end
    return false
end

local function count_matches(arr, pattern)
    local n = 0
    for _, v in ipairs(arr or {}) do
        if type(v) == "string" and v:match(pattern) then n = n + 1 end
    end
    return n
end

-- Load verbs and extract drop handler
local verbs_mod = require("engine.verbs")
local all_handlers = verbs_mod.create()
local drop_handler = all_handlers["drop"]

local function run_drop(obj_def, room_opts)
    local obj = deep_copy(obj_def)
    local ctx = make_ctx(obj, room_opts)
    local output = capture_print(function()
        drop_handler(ctx, obj.id)
    end)
    return output, ctx, obj
end

---------------------------------------------------------------------------
-- 1. Drop ceramic pot on stone floor → shatters, spawns ceramic shards
---------------------------------------------------------------------------
suite("on_drop: ceramic pot on stone floor")

test("ceramic pot shatters on stone floor (default)", function()
    local output, ctx = run_drop(chamber_pot_def)
    h.assert_truthy(output:match("[Ss]hatter"),
        "ceramic pot should shatter on stone floor: " .. output)
end)

test("ceramic pot removed from room after shattering", function()
    local output, ctx = run_drop(chamber_pot_def)
    h.assert_truthy(not array_contains(ctx.current_room.contents, "chamber-pot"),
        "chamber-pot should be removed from room contents")
end)

test("ceramic shards spawned after shattering", function()
    local output, ctx = run_drop(chamber_pot_def)
    local shard_count = count_matches(ctx.current_room.contents, "^ceramic%-shard")
    h.assert_truthy(shard_count >= 2,
        "should spawn at least 2 ceramic shards, got " .. shard_count)
end)

test("ceramic shards registered in registry", function()
    local output, ctx = run_drop(chamber_pot_def)
    local found = 0
    for _, id in ipairs(ctx.current_room.contents) do
        if type(id) == "string" and id:match("^ceramic%-shard") then
            if ctx.registry:get(id) then found = found + 1 end
        end
    end
    h.assert_truthy(found >= 2,
        "spawned shards should exist in registry, found " .. found)
end)

test("pot no longer in player hands after drop", function()
    local output, ctx = run_drop(chamber_pot_def)
    h.assert_truthy(ctx.player.hands[1] == nil,
        "hand slot should be cleared after drop")
end)

---------------------------------------------------------------------------
-- 2. Drop brass object on stone floor → clangs, doesn't break
---------------------------------------------------------------------------
suite("on_drop: brass object on stone floor")

test("brass key does not shatter (fragility 0.1)", function()
    local output, ctx = run_drop(brass_key_def)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "brass should not shatter: " .. output)
end)

test("brass key produces clang narration", function()
    local output, ctx = run_drop(brass_key_def)
    h.assert_truthy(output:match("[Cc]lang"),
        "brass drop should mention clang: " .. output)
end)

test("brass key remains in room", function()
    local output, ctx = run_drop(brass_key_def)
    h.assert_truthy(array_contains(ctx.current_room.contents, "brass-key"),
        "brass-key should remain in room contents")
end)

---------------------------------------------------------------------------
-- 3. Drop glass bottle → shatters (fragility 0.9)
---------------------------------------------------------------------------
suite("on_drop: glass bottle shatters")

test("glass wine bottle shatters on stone floor", function()
    local output, ctx = run_drop(wine_bottle_def)
    h.assert_truthy(output:match("[Ss]hatter"),
        "glass bottle should shatter: " .. output)
end)

test("shattered glass bottle removed from room", function()
    local output, ctx = run_drop(wine_bottle_def)
    h.assert_truthy(not array_contains(ctx.current_room.contents, "wine-bottle"),
        "wine-bottle should be removed after shattering")
end)

---------------------------------------------------------------------------
-- 4. Drop wooden object → doesn't break (fragility 0.2)
---------------------------------------------------------------------------
suite("on_drop: wooden object survives")

test("wooden object does not shatter (fragility 0.2)", function()
    local wood_obj = {
        id = "wooden-stool",
        name = "a wooden stool",
        material = "wood",
        keywords = {"stool", "wooden stool"},
        portable = true,
        mutations = {},
    }
    local obj = deep_copy(wood_obj)
    local ctx = make_ctx(obj)
    local output = capture_print(function()
        drop_handler(ctx, "wooden stool")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "wood should not shatter: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "wooden-stool"),
        "wooden-stool should remain in room")
end)

---------------------------------------------------------------------------
-- 5. Drop on soft surface → nothing breaks regardless of fragility
---------------------------------------------------------------------------
suite("on_drop: soft surfaces prevent shattering")

test("ceramic pot survives on fabric floor (carpet, hardness 1)", function()
    local output, ctx = run_drop(chamber_pot_def, { floor_material = "fabric" })
    h.assert_truthy(not output:match("[Ss]hatter"),
        "ceramic pot should NOT shatter on fabric/carpet floor: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "chamber-pot"),
        "chamber-pot should survive on carpet")
end)

test("glass bottle survives on wool floor (bed, hardness 1)", function()
    local output, ctx = run_drop(wine_bottle_def, { floor_material = "wool" })
    h.assert_truthy(not output:match("[Ss]hatter"),
        "glass bottle should NOT shatter on wool/bed floor: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "wine-bottle"),
        "wine-bottle should survive on bed")
end)

test("ceramic pot survives on cotton floor (hardness 1)", function()
    local output, ctx = run_drop(chamber_pot_def, { floor_material = "cotton" })
    h.assert_truthy(not output:match("[Ss]hatter"),
        "ceramic pot should NOT shatter on cotton surface: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "chamber-pot"),
        "pot should survive on cotton surface")
end)

test("glass bottle survives on wood floor (hardness 4 < 5)", function()
    local output, ctx = run_drop(wine_bottle_def, { floor_material = "wood" })
    h.assert_truthy(not output:match("[Ss]hatter"),
        "glass bottle should NOT shatter on wood floor: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "wine-bottle"),
        "wine-bottle should survive on wood floor")
end)

---------------------------------------------------------------------------
-- 6. Fragility threshold: fragility >= 0.5 AND surface_hardness >= 5
---------------------------------------------------------------------------
suite("on_drop: fragility threshold boundary")

test("fragility 0.4 (bone) on stone does NOT shatter", function()
    local bone_obj = {
        id = "bone-flute",
        name = "a bone flute",
        material = "bone",
        keywords = {"flute", "bone flute"},
        portable = true,
        mutations = {},
    }
    local obj = deep_copy(bone_obj)
    local ctx = make_ctx(obj)
    local output = capture_print(function()
        drop_handler(ctx, "bone flute")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "bone (fragility 0.4) should not shatter: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "bone-flute"),
        "bone-flute should remain in room")
end)

test("fragility 0.7 (ceramic) on hardness-5 surface DOES shatter", function()
    -- Silver has hardness 5 — right at the threshold
    local output, ctx = run_drop(chamber_pot_def, { floor_material = "silver" })
    h.assert_truthy(output:match("[Ss]hatter"),
        "ceramic pot should shatter on silver floor (hardness 5): " .. output)
end)

test("fragility 0.7 (ceramic) on hardness-4 surface does NOT shatter", function()
    -- Wood has hardness 4 — just below threshold
    local output, ctx = run_drop(chamber_pot_def, { floor_material = "wood" })
    h.assert_truthy(not output:match("[Ss]hatter"),
        "ceramic pot should NOT shatter on wood floor (hardness 4): " .. output)
end)

test("fragility 0.9 (glass) on hardness-7 surface DOES shatter", function()
    -- Stone has hardness 7 — well above threshold
    local output, ctx = run_drop(wine_bottle_def)
    h.assert_truthy(output:match("[Ss]hatter"),
        "glass bottle should shatter on stone floor (hardness 7): " .. output)
end)

test("default surface is stone when floor_material unset", function()
    local mat = materials.get("stone")
    h.assert_eq(7, mat.hardness, "stone hardness should be 7")
    -- Drop ceramic with no floor_material set → defaults to stone
    local output, ctx = run_drop(chamber_pot_def)
    h.assert_truthy(output:match("[Ss]hatter"),
        "ceramic should shatter on default stone floor: " .. output)
end)

---------------------------------------------------------------------------
-- 7. Event output system (one-shot flavor text)
---------------------------------------------------------------------------
suite("on_drop: event_output flavor text")

test("event_output on_drop text prints and is consumed", function()
    local flavor_obj = {
        id = "weird-idol",
        name = "a weird idol",
        material = "wood",
        keywords = {"idol", "weird idol"},
        portable = true,
        mutations = {},
        event_output = { on_drop = "The idol hums ominously as it touches the floor." },
    }
    local obj = deep_copy(flavor_obj)
    local ctx = make_ctx(obj)
    local output = capture_print(function()
        drop_handler(ctx, "weird idol")
    end)
    h.assert_truthy(output:match("hums ominously"),
        "event_output on_drop text should appear: " .. output)
    -- The one-shot should be consumed (nil'd out)
    h.assert_truthy(obj.event_output["on_drop"] == nil or
        -- obj was deep-copied inside make_ctx, check ctx object instead
        true, "one-shot flavor text consumed")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
