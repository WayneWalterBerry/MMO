-- test/verbs/test-fabric-burn.lua
-- Issue #166: Verify ALL fabric/cloth materials are burnable.
-- Covers: every fabric material (wool, velvet, linen, hemp, burlap, cotton, fabric),
--         realistic fabric objects, negative tests (stone, metal), full burn chain.
--
-- Usage: lua test/verbs/test-fabric-burn.lua
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
local materials_mod = require("engine.materials")

local test = h.test
local suite = h.suite
local eq = h.assert_eq

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

local function make_ctx(opts)
    opts = opts or {}
    local reg = registry_mod.new()
    local room = {
        id = "test-room",
        name = "Test Room",
        description = "A plain test room.",
        contents = opts.room_contents or {},
        exits = {},
    }
    local player = {
        hands = opts.hands or { nil, nil },
        worn = {},
        injuries = {},
        bags = {},
        state = opts.state or {},
    }
    return {
        registry = reg,
        current_room = room,
        player = player,
        time_offset = 20,
        game_start_time = os.time(),
        current_verb = "burn",
        known_objects = {},
        last_object = nil,
        verbs = handlers,
    }
end

---------------------------------------------------------------------------
-- 0. Material registry: all fabric materials have flammability >= 0.3
---------------------------------------------------------------------------
suite("fabric materials — flammability threshold")

local fabric_materials = {
    { name = "fabric",  expected = 0.6 },
    { name = "wool",    expected = 0.4 },
    { name = "cotton",  expected = 0.7 },
    { name = "velvet",  expected = 0.6 },
    { name = "linen",   expected = 0.5 },
    { name = "hemp",    expected = 0.5 },
    { name = "burlap",  expected = 0.6 },
}

for _, mat in ipairs(fabric_materials) do
    test(mat.name .. " flammability >= 0.3 (burn threshold)", function()
        local flam = materials_mod.get_property(mat.name, "flammability")
        h.assert_truthy(flam ~= nil, mat.name .. " should exist in material registry")
        h.assert_truthy(flam >= 0.3,
            mat.name .. " flammability " .. tostring(flam) .. " should be >= 0.3")
        eq(flam, mat.expected,
            mat.name .. " flammability should be " .. mat.expected)
    end)
end

---------------------------------------------------------------------------
-- 1. Burn each fabric material — object is destroyed
---------------------------------------------------------------------------
suite("burn — all fabric materials destroy object")

local fabric_objects = {
    { id = "wool-cloak",     keyword = "cloak",   material = "wool",   name = "a moth-eaten wool cloak" },
    { id = "curtains",       keyword = "curtains", material = "velvet", name = "heavy velvet curtains" },
    { id = "bandage",        keyword = "bandage",  material = "linen",  name = "a clean linen bandage" },
    { id = "bed-sheets",     keyword = "sheets",   material = "cotton", name = "rumpled bed sheets" },
    { id = "terrible-jacket", keyword = "jacket",  material = "fabric", name = "a terrible burlap jacket" },
    { id = "blanket",        keyword = "blanket",  material = "wool",   name = "a heavy wool blanket" },
    { id = "cloth",          keyword = "cloth",    material = "fabric", name = "a piece of cloth" },
    { id = "rag",            keyword = "rag",      material = "fabric", name = "a dirty rag" },
    { id = "cloth-scraps",   keyword = "scraps",   material = "fabric", name = "some cloth scraps" },
    { id = "grain-sack",     keyword = "grain sack", material = "burlap", name = "a heavy sack of grain" },
    { id = "pillow",         keyword = "pillow",   material = "linen",  name = "a goose-down pillow" },
    { id = "rope-coil",      keyword = "rope",     material = "hemp",   name = "a coil of rope" },
    { id = "thread",         keyword = "thread",   material = "cotton", name = "a spool of thread" },
    { id = "sack",           keyword = "sack",     material = "fabric", name = "a burlap sack" },
    { id = "rug",            keyword = "rug",      material = "wool",   name = "a threadbare rug" },
}

for _, obj_def in ipairs(fabric_objects) do
    test("burn " .. obj_def.id .. " (" .. obj_def.material .. ") catches fire", function()
        local obj = {
            id = obj_def.id,
            name = obj_def.name,
            keywords = { obj_def.keyword },
            material = obj_def.material,
        }
        local ctx = make_ctx({ state = { has_flame = 3 } })
        ctx.registry:register(obj_def.id, obj)
        ctx.player.hands[1] = obj
        local output = capture_output(function()
            handlers["burn"](ctx, obj_def.keyword)
        end)
        h.assert_truthy(output:find("catches fire") or output:find("burns") or output:find("flame"),
            obj_def.id .. " (" .. obj_def.material .. ") should burn; got: " .. output)
    end)
end

---------------------------------------------------------------------------
-- 2. Burn narration is appropriate for fabric
---------------------------------------------------------------------------
suite("burn — fabric narration quality")

test("burn wool-cloak produces fire-related narration", function()
    local obj = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak"},
        material = "wool",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("wool-cloak", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "cloak")
    end)
    -- Narration should contain fire-related words
    local has_fire_words = output:find("fire") or output:find("burn") or output:find("flame")
        or output:find("ignite") or output:find("ash") or output:find("smoke")
        or output:find("catch")
    h.assert_truthy(has_fire_words,
        "Burn narration should contain fire-related language; got: " .. output)
end)

test("burn velvet curtains produces fire-related narration", function()
    local obj = {
        id = "curtains",
        name = "heavy velvet curtains",
        keywords = {"curtains"},
        material = "velvet",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("curtains", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "curtains")
    end)
    local has_fire_words = output:find("fire") or output:find("burn") or output:find("flame")
        or output:find("ignite") or output:find("ash") or output:find("smoke")
        or output:find("catch")
    h.assert_truthy(has_fire_words,
        "Burn narration should contain fire-related language; got: " .. output)
end)

test("burn linen bandage produces fire-related narration", function()
    local obj = {
        id = "bandage",
        name = "a clean linen bandage",
        keywords = {"bandage"},
        material = "linen",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("bandage", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "bandage")
    end)
    local has_fire_words = output:find("fire") or output:find("burn") or output:find("flame")
        or output:find("ignite") or output:find("ash") or output:find("smoke")
        or output:find("catch")
    h.assert_truthy(has_fire_words,
        "Burn narration should contain fire-related language; got: " .. output)
end)

---------------------------------------------------------------------------
-- 3. Non-fabric materials STILL don't burn (negative tests)
---------------------------------------------------------------------------
suite("burn — non-fabric materials refuse to burn")

test("burn stone cobblestone says can't burn", function()
    local obj = {
        id = "cobblestone",
        name = "a loose cobblestone",
        keywords = {"cobblestone", "stone"},
        material = "stone",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("cobblestone", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "cobblestone")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Stone should be unburnable; got: " .. output)
    h.assert_truthy(ctx.registry:get("cobblestone") ~= nil, "Stone should remain in registry")
end)

test("burn steel chain says can't burn", function()
    local obj = {
        id = "chain",
        name = "a steel chain",
        keywords = {"chain"},
        material = "steel",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("chain", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "chain")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Steel should be unburnable; got: " .. output)
    h.assert_truthy(ctx.registry:get("chain") ~= nil, "Chain should remain in registry")
end)

test("burn brass spittoon says can't burn", function()
    local obj = {
        id = "spittoon",
        name = "a brass spittoon",
        keywords = {"spittoon"},
        material = "brass",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("spittoon", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "spittoon")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Brass should be unburnable; got: " .. output)
    h.assert_truthy(ctx.registry:get("spittoon") ~= nil, "Spittoon should remain in registry")
end)

test("burn silver dagger says can't burn", function()
    local obj = {
        id = "silver-dagger",
        name = "a silver dagger",
        keywords = {"dagger"},
        material = "silver",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("silver-dagger", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "dagger")
    end)
    h.assert_truthy(output:find("can't burn"),
        "Silver should be unburnable; got: " .. output)
    h.assert_truthy(ctx.registry:get("silver-dagger") ~= nil, "Dagger should remain in registry")
end)

---------------------------------------------------------------------------
-- 4. Full chain: take → burn → destroyed
---------------------------------------------------------------------------
suite("burn — full chain: hold + burn = destroyed")

test("hold wool-cloak, burn it, object is destroyed", function()
    local obj = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak"},
        material = "wool",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("wool-cloak", obj)
    -- Simulate: player already holding the object
    ctx.player.hands[1] = obj
    h.assert_truthy(ctx.player.hands[1] ~= nil, "Player should hold the cloak")
    local output = capture_output(function()
        handlers["burn"](ctx, "cloak")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns") or output:find("flame"),
        "Cloak should burn; got: " .. output)
    eq(ctx.registry:get("wool-cloak"), nil, "Cloak should be destroyed after burning")
    eq(ctx.player.hands[1], nil, "Hand should be empty after burning held object")
end)

test("hold cotton bed-sheets, burn them, object is destroyed", function()
    local obj = {
        id = "bed-sheets",
        name = "rumpled bed sheets",
        keywords = {"sheets", "bed sheets"},
        material = "cotton",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("bed-sheets", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "sheets")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns") or output:find("flame"),
        "Sheets should burn; got: " .. output)
    eq(ctx.registry:get("bed-sheets"), nil, "Sheets should be destroyed after burning")
    eq(ctx.player.hands[1], nil, "Hand should be empty after burning held sheets")
end)

test("hold burlap grain-sack, burn it, object is destroyed", function()
    local obj = {
        id = "grain-sack",
        name = "a heavy sack of grain",
        keywords = {"grain sack"},
        material = "burlap",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("grain-sack", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "grain sack")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns") or output:find("flame"),
        "Grain sack should burn; got: " .. output)
    eq(ctx.registry:get("grain-sack"), nil, "Grain sack should be destroyed after burning")
    eq(ctx.player.hands[1], nil, "Hand should be empty after burning held sack")
end)

test("hold hemp rope, burn it, object is destroyed", function()
    local obj = {
        id = "rope-coil",
        name = "a coil of rope",
        keywords = {"rope"},
        material = "hemp",
    }
    local ctx = make_ctx({ state = { has_flame = 3 } })
    ctx.registry:register("rope-coil", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "rope")
    end)
    h.assert_truthy(output:find("catches fire") or output:find("burns") or output:find("flame"),
        "Rope should burn; got: " .. output)
    eq(ctx.registry:get("rope-coil"), nil, "Rope should be destroyed after burning")
    eq(ctx.player.hands[1], nil, "Hand should be empty after burning held rope")
end)

---------------------------------------------------------------------------
-- 5. Burn without flame — fabric still needs fire
---------------------------------------------------------------------------
suite("burn — fabric requires flame")

test("burn wool-cloak without flame says no flame", function()
    local obj = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak"},
        material = "wool",
    }
    local ctx = make_ctx({ state = {} })
    ctx.registry:register("wool-cloak", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "cloak")
    end)
    h.assert_truthy(output:find("no flame"),
        "Should say no flame available; got: " .. output)
    h.assert_truthy(ctx.registry:get("wool-cloak") ~= nil, "Cloak should not burn without flame")
end)

test("burn linen pillow without flame says no flame", function()
    local obj = {
        id = "pillow",
        name = "a goose-down pillow",
        keywords = {"pillow"},
        material = "linen",
    }
    local ctx = make_ctx({ state = {} })
    ctx.registry:register("pillow", obj)
    ctx.player.hands[1] = obj
    local output = capture_output(function()
        handlers["burn"](ctx, "pillow")
    end)
    h.assert_truthy(output:find("no flame"),
        "Should say no flame available; got: " .. output)
    h.assert_truthy(ctx.registry:get("pillow") ~= nil, "Pillow should not burn without flame")
end)

print("\nExit code: " .. h.summary())
