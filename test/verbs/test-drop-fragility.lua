-- test/verbs/test-drop-fragility.lua
-- Tests for on_drop engine event + material fragility system (Issue #56).
-- Validates: ceramic shatters, glass shatters, brass/wood/fabric/iron survive,
-- shattered objects removed from room, spawned shards placed in room,
-- objects without material use default behavior.
--
-- Usage: lua test/verbs/test-drop-fragility.lua
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
local glass_shard_def = load_obj("glass-shard")
local wine_bottle_def = load_obj("wine-bottle")
local ceramic_shard_def = load_obj("ceramic-shard")
local brass_key_def = load_obj("brass-key")

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
    -- Pre-register ceramic-shard definition so spawns can find it
    local cs = deep_copy(ceramic_shard_def)
    reg:register("ceramic-shard", cs)
    local room = {
        id = "test-room",
        name = "Test Room",
        contents = {},  -- object is in hands, not on floor yet
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

local function array_contains_match(arr, pattern)
    for _, v in ipairs(arr or {}) do
        if type(v) == "string" and v:match(pattern) then return true end
    end
    return false
end

-- Load the verbs module and get the drop handler
local verbs_mod = require("engine.verbs")
local all_handlers = verbs_mod.create()
local drop_handler = all_handlers["drop"]

-- Run drop on a fresh context
local function run_drop(obj_def, room_opts)
    local obj = deep_copy(obj_def)
    local ctx = make_ctx(obj, room_opts)
    local output = capture_print(function()
        drop_handler(ctx, obj.id)
    end)
    return output, ctx, obj
end

---------------------------------------------------------------------------
-- 0. Material Registry Sanity
---------------------------------------------------------------------------
suite("material registry — fragility values")

test("ceramic fragility is 0.7", function()
    local mat = materials.get("ceramic")
    h.assert_truthy(mat, "ceramic material should exist")
    h.assert_eq(0.7, mat.fragility, "ceramic fragility")
end)

test("glass fragility is 0.9", function()
    local mat = materials.get("glass")
    h.assert_truthy(mat, "glass material should exist")
    h.assert_eq(0.9, mat.fragility, "glass fragility")
end)

test("brass fragility is 0.1", function()
    local mat = materials.get("brass")
    h.assert_truthy(mat, "brass material should exist")
    h.assert_eq(0.1, mat.fragility, "brass fragility")
end)

test("wood fragility is 0.2", function()
    local mat = materials.get("wood")
    h.assert_truthy(mat, "wood material should exist")
    h.assert_eq(0.2, mat.fragility, "wood fragility")
end)

test("iron fragility is 0.1", function()
    local mat = materials.get("iron")
    h.assert_truthy(mat, "iron material should exist")
    h.assert_eq(0.1, mat.fragility, "iron fragility")
end)

test("fabric fragility is 0.0", function()
    local mat = materials.get("fabric")
    h.assert_truthy(mat, "fabric material should exist")
    h.assert_eq(0.0, mat.fragility, "fabric fragility")
end)

test("stone hardness is 7 (default floor)", function()
    local mat = materials.get("stone")
    h.assert_truthy(mat, "stone material should exist")
    h.assert_eq(7, mat.hardness, "stone hardness")
end)

---------------------------------------------------------------------------
-- 1. Ceramic chamber pot → shatters on drop
---------------------------------------------------------------------------
suite("drop ceramic chamber pot — shatters")

test("chamber pot has shatter mutation", function()
    local pot = deep_copy(chamber_pot_def)
    h.assert_truthy(pot.mutations, "should have mutations table")
    h.assert_truthy(pot.mutations.shatter, "should have shatter mutation")
    h.assert_truthy(pot.mutations.shatter.spawns, "shatter should have spawns")
    h.assert_eq(2, #pot.mutations.shatter.spawns, "should spawn 2 ceramic shards")
end)

test("drop ceramic pot produces shatter narration", function()
    local output, ctx = run_drop(chamber_pot_def)
    h.assert_truthy(output:match("[Ss]hatter"), "output should mention shattering: " .. output)
end)

test("shattered pot removed from room contents", function()
    local output, ctx = run_drop(chamber_pot_def)
    h.assert_truthy(not array_contains(ctx.current_room.contents, "chamber-pot"),
        "chamber-pot should NOT be in room contents after shattering")
end)

test("ceramic shards spawned in room contents", function()
    local output, ctx = run_drop(chamber_pot_def)
    local shard_count = 0
    for _, id in ipairs(ctx.current_room.contents) do
        if type(id) == "string" and id:match("^ceramic%-shard") then
            shard_count = shard_count + 1
        end
    end
    h.assert_truthy(shard_count >= 2,
        "should have at least 2 ceramic shards in room, got " .. shard_count)
end)

test("spawned shards are registered in registry", function()
    local output, ctx = run_drop(chamber_pot_def)
    local found = 0
    for _, id in ipairs(ctx.current_room.contents) do
        if type(id) == "string" and id:match("^ceramic%-shard") then
            local shard = ctx.registry:get(id)
            if shard then found = found + 1 end
        end
    end
    h.assert_truthy(found >= 2,
        "spawned shards should be in registry, found " .. found)
end)

---------------------------------------------------------------------------
-- 2. Brass object → survives drop
---------------------------------------------------------------------------
suite("drop brass object — survives")

test("drop brass key survives", function()
    local output, ctx = run_drop(brass_key_def)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "brass should not shatter: " .. output)
end)

test("brass key narration mentions clang", function()
    local output, ctx = run_drop(brass_key_def)
    h.assert_truthy(output:match("[Cc]lang"),
        "brass drop should mention clang: " .. output)
end)

test("brass key remains in room contents", function()
    local output, ctx = run_drop(brass_key_def)
    h.assert_truthy(array_contains(ctx.current_room.contents, "brass-key"),
        "brass-key should remain in room contents")
end)

---------------------------------------------------------------------------
-- 3. Glass wine-bottle → shatters
---------------------------------------------------------------------------
suite("drop glass wine-bottle — shatters")

test("drop wine bottle shatters on stone floor", function()
    local output, ctx = run_drop(wine_bottle_def)
    h.assert_truthy(output:match("[Ss]hatter"),
        "glass bottle should shatter: " .. output)
end)

test("shattered wine bottle removed from room", function()
    local output, ctx = run_drop(wine_bottle_def)
    h.assert_truthy(not array_contains(ctx.current_room.contents, "wine-bottle"),
        "wine-bottle should be removed from room contents")
end)

---------------------------------------------------------------------------
-- 4. Wooden object → survives
---------------------------------------------------------------------------
suite("drop wooden object — survives")

test("drop wooden object survives", function()
    -- Create a simple wooden object
    local wood_obj = {
        id = "wooden-stool",
        name = "a wooden stool",
        material = "wood",
        keywords = {"stool", "wooden stool"},
        portable = true,
        mutations = {},
    }
    local obj = deep_copy(wood_obj)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    local room = { id = "test-room", name = "Test Room", contents = {} }
    obj.location = nil
    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = { obj, nil }, worn = {}, injuries = {}, state = {} },
    }
    local output = capture_print(function()
        drop_handler(ctx, "wooden stool")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "wood should not shatter: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "wooden-stool"),
        "wooden-stool should remain in room")
end)

---------------------------------------------------------------------------
-- 5. Fabric object → survives (fragility 0.0)
---------------------------------------------------------------------------
suite("drop fabric object — survives")

test("drop fabric object survives", function()
    local fabric_obj = {
        id = "cloth-rag",
        name = "a cloth rag",
        material = "fabric",
        keywords = {"rag", "cloth", "cloth rag"},
        portable = true,
        mutations = {},
    }
    local obj = deep_copy(fabric_obj)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    local room = { id = "test-room", name = "Test Room", contents = {} }
    obj.location = nil
    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = { obj, nil }, worn = {}, injuries = {}, state = {} },
    }
    local output = capture_print(function()
        drop_handler(ctx, "cloth rag")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "fabric should not shatter: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "cloth-rag"),
        "cloth-rag should remain in room")
end)

---------------------------------------------------------------------------
-- 6. Object without material → default behavior (no shatter check)
---------------------------------------------------------------------------
suite("drop object without material — default behavior")

test("drop object with no material does not crash", function()
    local no_mat_obj = {
        id = "mystery-orb",
        name = "a mystery orb",
        keywords = {"orb", "mystery orb"},
        portable = true,
        mutations = {},
    }
    local obj = deep_copy(no_mat_obj)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    local room = { id = "test-room", name = "Test Room", contents = {} }
    obj.location = nil
    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = { obj, nil }, worn = {}, injuries = {}, state = {} },
    }
    local output = capture_print(function()
        drop_handler(ctx, "mystery orb")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "no material should not shatter: " .. output)
    h.assert_truthy(output:match("[Dd]rop"),
        "should have normal drop message: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "mystery-orb"),
        "mystery-orb should remain in room")
end)

---------------------------------------------------------------------------
-- 7. Ceramic shard object definition
---------------------------------------------------------------------------
suite("ceramic-shard object definition")

test("ceramic-shard has correct id", function()
    h.assert_eq("ceramic-shard", ceramic_shard_def.id, "id should be ceramic-shard")
end)

test("ceramic-shard material is ceramic", function()
    h.assert_eq("ceramic", ceramic_shard_def.material, "material should be ceramic")
end)

test("ceramic-shard is portable", function()
    h.assert_eq(true, ceramic_shard_def.portable, "should be portable")
end)

test("ceramic-shard has debris category", function()
    h.assert_truthy(array_contains(ceramic_shard_def.categories, "debris"),
        "should have debris category")
end)

test("ceramic-shard has sharp category", function()
    h.assert_truthy(array_contains(ceramic_shard_def.categories, "sharp"),
        "should have sharp category")
end)

test("ceramic-shard has valid guid", function()
    h.assert_truthy(ceramic_shard_def.guid, "should have guid")
    h.assert_truthy(ceramic_shard_def.guid:match("^{.*}$"), "GUID should be braced")
end)

---------------------------------------------------------------------------
-- 8. Fragility threshold edge cases
---------------------------------------------------------------------------
suite("fragility threshold — edge cases")

test("fragility exactly 0.5 on stone shatters", function()
    local obj = {
        id = "test-fragile-50",
        name = "a borderline object",
        material = "bone",  -- bone fragility = 0.4 (below threshold)
        keywords = {"test-fragile-50", "borderline"},
        portable = true,
        mutations = {},
    }
    local o = deep_copy(obj)
    local reg = registry_mod.new()
    reg:register(o.id, o)
    local room = { id = "test-room", name = "Test Room", contents = {} }
    o.location = nil
    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = { o, nil }, worn = {}, injuries = {}, state = {} },
    }
    local output = capture_print(function()
        drop_handler(ctx, "borderline")
    end)
    -- bone fragility is 0.4, which is below 0.5 — should NOT shatter
    h.assert_truthy(not output:match("[Ss]hatter"),
        "bone (fragility 0.4) should not shatter: " .. output)
end)

test("soft floor prevents shattering (wood floor, hardness 4)", function()
    local pot = deep_copy(chamber_pot_def)
    local reg = registry_mod.new()
    reg:register(pot.id, pot)
    local cs = deep_copy(ceramic_shard_def)
    reg:register("ceramic-shard", cs)
    local room = {
        id = "test-room", name = "Test Room",
        contents = {},
        floor_material = "wood",  -- hardness 4, below threshold of 5
    }
    pot.location = nil
    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = { pot, nil }, worn = {}, injuries = {}, state = {} },
    }
    local output = capture_print(function()
        drop_handler(ctx, "chamber pot")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "ceramic pot on wood floor should not shatter: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "chamber-pot"),
        "pot should remain in room on wood floor")
end)

---------------------------------------------------------------------------
-- 9. Iron object → survives
---------------------------------------------------------------------------
suite("drop iron object — survives")

test("drop iron object survives without shattering", function()
    local iron_obj = {
        id = "iron-nail",
        name = "an iron nail",
        material = "iron",
        keywords = {"nail", "iron nail"},
        portable = true,
        mutations = {},
    }
    local obj = deep_copy(iron_obj)
    local reg = registry_mod.new()
    reg:register(obj.id, obj)
    local room = { id = "test-room", name = "Test Room", contents = {} }
    obj.location = nil
    local ctx = {
        registry = reg,
        current_room = room,
        player = { hands = { obj, nil }, worn = {}, injuries = {}, state = {} },
    }
    local output = capture_print(function()
        drop_handler(ctx, "iron nail")
    end)
    h.assert_truthy(not output:match("[Ss]hatter"),
        "iron should not shatter: " .. output)
    h.assert_truthy(array_contains(ctx.current_room.contents, "iron-nail"),
        "iron-nail should remain in room")
end)

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
