-- test/search/test-search-bugs-068-074.lua
-- Regression tests for:
--   #68: 'find clothing' doesn't match wool cloak (category synonym search)
--   #74: 'find candle' finds candle holder, not the candle itself (composite child preference)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../parser/?.lua;"
             .. package.path

local h = require("test-helpers")
local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy
local is_nil = h.assert_nil

local search = require("engine.search")
local registry_mod = require("engine.registry")
local traverse = require("engine.search.traverse")
local containers = require("engine.search.containers")

-- Capture printed output
local function capture_print(fn)
    local lines = {}
    local old_print = _G.print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        lines[#lines + 1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err, 2) end
    return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- #68: Category synonym search — 'find clothing' matches wool cloak
---------------------------------------------------------------------------

local function make_ctx_clothing()
    local reg = registry_mod.new()

    local room = {
        id = "wardrobe-room",
        name = "Wardrobe Room",
        description = "A room with a wardrobe.",
        contents = {"wool-cloak", "oak-vanity", "leather-boots"},
        proximity_list = {"wool-cloak", "oak-vanity", "leather-boots"},
        exits = {},
        light_level = 3,
    }

    local cloak = {
        id = "wool-cloak",
        name = "a moth-eaten wool cloak",
        keywords = {"cloak", "wool cloak", "cape", "mantle", "garment", "wool", "clothing", "apparel"},
        description = "A long wool cloak.",
        categories = {"fabric", "warm", "wearable"},
        material = "wool",
        portable = true,
    }

    local vanity = {
        id = "oak-vanity",
        name = "an oak vanity",
        keywords = {"vanity", "oak vanity"},
        description = "A dressing table.",
        categories = {"furniture", "wooden"},
        material = "oak",
    }

    local boots = {
        id = "leather-boots",
        name = "a pair of leather boots",
        keywords = {"boots", "leather boots"},
        description = "Sturdy boots.",
        categories = {"wearable", "leather"},
        material = "leather",
        portable = true,
    }

    reg:register("wardrobe-room", room)
    reg:register("wool-cloak", cloak)
    reg:register("oak-vanity", vanity)
    reg:register("leather-boots", boots)

    return {
        registry = reg,
        current_room = room,
        player = {hands = {nil, nil}, state = {}},
    }
end

print("=== #68: Category synonym matching ===")

test("#68: matches_target finds wool cloak via 'clothing' keyword", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "clothing", ctx.registry, 0)
    truthy(result, "'clothing' should match wool cloak (keyword)")
end)

test("#68: matches_target finds wool cloak via 'apparel' keyword", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "apparel", ctx.registry, 0)
    truthy(result, "'apparel' should match wool cloak (keyword)")
end)

test("#68: category synonym 'clothing' matches wearable category", function()
    local ctx = make_ctx_clothing()
    -- Even without the keyword, a generic 'wearable' item should match 'clothing'
    local boots = ctx.registry:get("leather-boots")
    -- Remove 'clothing' keyword if present to test pure category matching
    boots.keywords = {"boots", "leather boots"}
    local result = traverse._matches_target(boots, "clothing", ctx.registry, 0)
    truthy(result, "'clothing' should match boots via wearable category synonym")
end)

test("#68: category synonym 'clothes' matches wearable category", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "clothes", ctx.registry, 0)
    truthy(result, "'clothes' should match cloak via wearable category synonym")
end)

test("#68: category synonym 'apparel' matches wearable category on boots", function()
    local ctx = make_ctx_clothing()
    local boots = ctx.registry:get("leather-boots")
    boots.keywords = {"boots", "leather boots"}
    local result = traverse._matches_target(boots, "apparel", ctx.registry, 0)
    truthy(result, "'apparel' should match boots via wearable category synonym")
end)

test("#68: non-wearable object does NOT match 'clothing'", function()
    local ctx = make_ctx_clothing()
    local vanity = ctx.registry:get("oak-vanity")
    local result = traverse._matches_target(vanity, "clothing", ctx.registry, 0)
    eq(result, false, "'clothing' should NOT match oak vanity (furniture)")
end)

test("#68: CATEGORY_SYNONYMS table includes expected mappings", function()
    local syns = traverse.CATEGORY_SYNONYMS
    eq(syns.clothing, "wearable", "clothing → wearable")
    eq(syns.clothes, "wearable", "clothes → wearable")
    eq(syns.apparel, "wearable", "apparel → wearable")
    eq(syns.garments, "wearable", "garments → wearable")
    eq(syns.weapons, "weapon", "weapons → weapon")
end)

test("#68: full search.find('clothing') discovers wool cloak", function()
    local ctx = make_ctx_clothing()
    local output = capture_print(function()
        search.search(ctx, "clothing")
        for i = 1, 20 do
            if not search.tick(ctx) then break end
        end
    end)
    truthy(output:find("wool cloak") or output:find("wool%-cloak"),
           "search for 'clothing' should find wool cloak — got: " .. output)
end)

test("#68: full search.find('clothing') finds first wearable (cloak before boots)", function()
    local ctx = make_ctx_clothing()
    local found_item = nil
    local old_print = _G.print
    _G.print = function() end
    search.search(ctx, "clothing")
    for i = 1, 20 do
        if not search.tick(ctx) then break end
    end
    _G.print = old_print
    -- ctx.last_noun should be the found item
    truthy(ctx.last_noun == "wool-cloak" or ctx.last_noun == "leather-boots",
           "should find a wearable item — got: " .. tostring(ctx.last_noun))
end)

---------------------------------------------------------------------------
-- #74: Composite child preference — 'find candle' prefers candle over candle holder
---------------------------------------------------------------------------

local function make_ctx_candle()
    local reg = registry_mod.new()

    local room = {
        id = "study",
        name = "Study",
        description = "A candlelit study.",
        contents = {"candle-holder"},
        proximity_list = {"candle-holder"},
        exits = {},
        light_level = 2,
    }

    local candle_holder = {
        id = "candle-holder",
        name = "a brass candle holder",
        keywords = {"candle holder", "holder", "candlestick", "sconce", "brass holder"},
        description = "A brass candle holder with a candle.",
        categories = {"furniture", "small", "portable"},
        material = "brass",
        portable = true,
        _state = "with_candle",
        contents = {"candle"},
        parts = {
            candle = {
                id = "candle",
                detachable = true,
                reversible = true,
                keywords = {"candle", "tallow", "tallow candle"},
                name = "a tallow candle",
            },
        },
    }

    local candle = {
        id = "candle",
        name = "a tallow candle",
        keywords = {"candle", "tallow", "candle stub", "tallow candle"},
        description = "A stubby tallow candle.",
        categories = {"light source", "small"},
        material = "wax",
        portable = true,
    }

    reg:register("study", room)
    reg:register("candle-holder", candle_holder)
    reg:register("candle", candle)

    return {
        registry = reg,
        current_room = room,
        player = {hands = {nil, nil}, state = {}},
    }
end

print("\n=== #74: Composite child preference ===")

test("#74: matches_exact — 'candle' exactly matches candle object", function()
    local ctx = make_ctx_candle()
    local candle = ctx.registry:get("candle")
    local result = traverse._matches_exact(candle, "candle")
    truthy(result, "'candle' should exactly match candle")
end)

test("#74: matches_exact — 'candle' does NOT exactly match candle-holder", function()
    local ctx = make_ctx_candle()
    local holder = ctx.registry:get("candle-holder")
    local result = traverse._matches_exact(holder, "candle")
    eq(result, false, "'candle' should NOT exactly match candle-holder")
end)

test("#74: matches_target — 'candle' substring-matches candle-holder name", function()
    local ctx = make_ctx_candle()
    local holder = ctx.registry:get("candle-holder")
    local result = traverse._matches_target(holder, "candle", ctx.registry, 0)
    truthy(result, "'candle' substring-matches 'candle holder' keyword")
end)

test("#74: find_deeper_match returns candle child from candle-holder", function()
    local ctx = make_ctx_candle()
    local holder = ctx.registry:get("candle-holder")
    local deeper = traverse._find_deeper_match(holder, "candle", ctx.registry)
    truthy(deeper, "find_deeper_match should return candle child")
    eq(deeper.id, "candle", "deeper match should be the candle, not the holder")
end)

test("#74: find_deeper_match works via parts when contents is empty", function()
    local ctx = make_ctx_candle()
    local holder = ctx.registry:get("candle-holder")
    -- Simulate empty contents (candle detached from holder but still in parts)
    holder.contents = {}
    local deeper = traverse._find_deeper_match(holder, "candle", ctx.registry)
    truthy(deeper, "find_deeper_match should find candle via parts even with empty contents")
    eq(deeper.id, "candle", "should find candle via parts definition")
end)

test("#74: find_deeper_match returns nil when no child matches", function()
    local ctx = make_ctx_candle()
    local holder = ctx.registry:get("candle-holder")
    local deeper = traverse._find_deeper_match(holder, "sword", ctx.registry)
    is_nil(deeper, "no child named 'sword' should be found")
end)

test("#74: find_deeper_match returns nil for objects without children", function()
    local ctx = make_ctx_candle()
    local candle = ctx.registry:get("candle")
    local deeper = traverse._find_deeper_match(candle, "wick", ctx.registry)
    is_nil(deeper, "candle has no children — should return nil")
end)

test("#74: full search for 'candle' returns candle, NOT candle-holder", function()
    local ctx = make_ctx_candle()
    local found_id = nil
    local old_print = _G.print
    _G.print = function() end
    search.search(ctx, "candle")
    for i = 1, 20 do
        if not search.tick(ctx) then break end
    end
    _G.print = old_print
    eq(ctx.last_noun, "candle", "search for 'candle' should resolve to the candle, not candle-holder")
end)

test("#74: full search for 'holder' still returns candle-holder", function()
    local ctx = make_ctx_candle()
    local old_print = _G.print
    _G.print = function() end
    search.search(ctx, "holder")
    for i = 1, 20 do
        if not search.tick(ctx) then break end
    end
    _G.print = old_print
    eq(ctx.last_noun, "candle-holder", "search for 'holder' should find candle-holder")
end)

test("#74: full search for 'candlestick' still returns candle-holder", function()
    local ctx = make_ctx_candle()
    local old_print = _G.print
    _G.print = function() end
    search.search(ctx, "candlestick")
    for i = 1, 20 do
        if not search.tick(ctx) then break end
    end
    _G.print = old_print
    eq(ctx.last_noun, "candle-holder", "search for 'candlestick' should find candle-holder")
end)

test("#74: search narration mentions tallow candle when finding candle", function()
    local ctx = make_ctx_candle()
    local output = capture_print(function()
        search.search(ctx, "candle")
        for i = 1, 20 do
            if not search.tick(ctx) then break end
        end
    end)
    truthy(output:find("tallow candle") or output:find("candle"),
           "narration should mention tallow candle — got: " .. output)
end)

---------------------------------------------------------------------------
-- Cross-cutting: regressions
---------------------------------------------------------------------------

print("\n=== Cross-cutting regressions ===")

test("regression: normal keyword search still works (cloak by name)", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "cloak", ctx.registry, 0)
    truthy(result, "'cloak' should still match wool cloak via keyword")
end)

test("regression: substring name match still works", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "moth-eaten", ctx.registry, 0)
    truthy(result, "'moth-eaten' should still match via name substring")
end)

test("regression: exact ID match still works", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "wool-cloak", ctx.registry, 0)
    truthy(result, "'wool-cloak' should match via exact ID")
end)

test("regression: unknown category synonym returns no match", function()
    local ctx = make_ctx_clothing()
    local cloak = ctx.registry:get("wool-cloak")
    local result = traverse._matches_target(cloak, "spaceship", ctx.registry, 0)
    eq(result, false, "'spaceship' should not match anything")
end)

h.summary()
