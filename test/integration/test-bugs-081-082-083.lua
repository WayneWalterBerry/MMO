-- test/integration/test-bugs-081-082-083.lua
-- Regression tests for put verb parser fixes:
--   #81: Pronoun 'that'/'it' not resolved in put verb
--   #82: Put verb needs 'under' and 'inside' prepositions
--   #83: Missing placement verb aliases (set/drop/hide/stuff/toss/slide → put)

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../../test/parser/?.lua;"
             .. package.path

local passed = 0
local failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("  PASS " .. name)
        passed = passed + 1
    else
        print("  FAIL " .. name .. ": " .. tostring(err))
        failed = failed + 1
    end
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "assert_eq") .. " — expected: " .. tostring(b) .. " got: " .. tostring(a))
    end
end

local function assert_true(v, msg)
    if not v then error(msg or "expected true") end
end

local function assert_contains(haystack, needle, msg)
    if not haystack:find(needle, 1, true) then
        error((msg or "substring not found") .. "\n  expected: " .. needle .. "\n  in: " .. haystack)
    end
end

local function assert_not_contains(haystack, needle, msg)
    if haystack:find(needle, 1, true) then
        error((msg or "unexpected substring found") .. "\n  unexpected: " .. needle .. "\n  in: " .. haystack)
    end
end

-- Capture print output during a function call
local function capture(fn)
    local captured = {}
    local old_print = _G.print
    _G.print = function(...)
        local args = {}
        for i = 1, select("#", ...) do args[i] = tostring(select(i, ...)) end
        captured[#captured + 1] = table.concat(args, "\t")
    end
    local ok, err = pcall(fn)
    _G.print = old_print
    if not ok then error(err) end
    return table.concat(captured, "\n")
end

-- Reset require cache for clean test isolation
local function reset_modules()
    for k, _ in pairs(package.loaded) do
        if k:match("^engine%.") or k:match("^meta%.") then
            package.loaded[k] = nil
        end
    end
end

---------------------------------------------------------------------------
-- Shared setup: create a test context with objects
---------------------------------------------------------------------------
local function make_ctx(opts)
    opts = opts or {}
    reset_modules()

    local registry_mod = require("engine.registry")
    local reg = registry_mod.new()

    -- Knife (holdable item)
    local knife = {
        id = "knife",
        name = "a sharp knife",
        keywords = { "knife", "blade" },
        size = 1,
    }
    reg:register("knife", knife)

    -- Key (holdable item)
    local key = {
        id = "brass-key",
        name = "a brass key",
        keywords = { "key", "brass key" },
        size = 1,
    }
    reg:register("brass-key", key)

    -- Matchbox (holdable item)
    local matchbox = {
        id = "matchbox",
        name = "a small matchbox",
        keywords = { "matchbox", "box" },
        size = 1,
    }
    reg:register("matchbox", matchbox)

    -- Nightstand (multi-surface furniture)
    local nightstand = {
        id = "nightstand",
        name = "a small nightstand",
        keywords = { "nightstand", "stand" },
        categories = { "furniture", "container" },
        container = true,
        surfaces = {
            top = {
                capacity = 5,
                max_item_size = 3,
                contents = {},
                accessible = true,
            },
            inside = {
                capacity = 3,
                max_item_size = 2,
                contents = {},
                accessible = true,
            },
        },
        contents = {},
    }
    reg:register("nightstand", nightstand)

    -- Drawer (simple container)
    local drawer = {
        id = "drawer",
        name = "a wooden drawer",
        keywords = { "drawer" },
        container = true,
        contents = {},
    }
    reg:register("drawer", drawer)

    -- Rug (no surfaces, supports "underneath")
    local rug = {
        id = "rug",
        name = "a worn rug",
        keywords = { "rug", "mat", "carpet" },
    }
    reg:register("rug", rug)

    -- Bed (multi-surface)
    local bed = {
        id = "bed",
        name = "a large bed",
        keywords = { "bed" },
        categories = { "furniture" },
        surfaces = {
            top = {
                capacity = 5,
                max_item_size = 3,
                contents = {},
                accessible = true,
            },
        },
        contents = {},
    }
    reg:register("bed", bed)

    -- Vanity (multi-surface)
    local vanity = {
        id = "vanity",
        name = "an oak vanity",
        keywords = { "vanity" },
        categories = { "furniture" },
        surfaces = {
            top = {
                capacity = 5,
                max_item_size = 3,
                contents = {},
                accessible = true,
            },
        },
        contents = {},
    }
    reg:register("vanity", vanity)

    -- Room
    local room = {
        id = "bedroom",
        name = "the bedroom",
        contents = { "nightstand", "drawer", "rug", "bed", "vanity" },
        light_level = opts.light_level or 1,
    }
    reg:register("bedroom", room)

    -- Containment module
    local containment = {
        can_contain = function(item, container, surface_name, registry)
            return true, nil
        end,
    }

    -- Player with items in hands
    local player = {
        hands = {},
        worn = {},
        bags = {},
    }

    if opts.hold_knife then
        player.hands[1] = knife
    end
    if opts.hold_key then
        local slot = player.hands[1] and 2 or 1
        player.hands[slot] = key
    end
    if opts.hold_matchbox then
        local slot = player.hands[1] and 2 or 1
        player.hands[slot] = matchbox
    end

    local ctx = {
        player = player,
        current_room = room,
        registry = reg,
        containment = containment,
        current_verb = "put",
        known_objects = {},
    }

    -- Load verbs
    local verbs_mod = require("engine.verbs")
    local handlers = verbs_mod.create()
    ctx.verbs = handlers

    return ctx, handlers, reg
end

---------------------------------------------------------------------------
-- #81: Pronoun resolution in put verb
---------------------------------------------------------------------------
print("=== #81: Pronoun resolution in put verb ===")

test("#81: 'put it on nightstand' resolves pronoun from context window", function()
    local ctx, handlers = make_ctx({ hold_knife = true })

    -- Push knife to context window so "it" resolves to knife
    local cw = require("engine.parser.context")
    cw.reset()
    cw.push(ctx.registry:get("knife"))

    local output = capture(function()
        handlers["put"](ctx, "it on nightstand")
    end)
    assert_contains(output, "You put", "#81: pronoun 'it' should resolve to knife")
    assert_contains(output, "knife", "#81: output should mention knife")
    assert_contains(output, "nightstand", "#81: output should mention nightstand")
end)

test("#81: 'put that in drawer' resolves pronoun from context window", function()
    local ctx, handlers = make_ctx({ hold_key = true })

    local cw = require("engine.parser.context")
    cw.reset()
    cw.push(ctx.registry:get("brass-key"))

    local output = capture(function()
        handlers["put"](ctx, "that in drawer")
    end)
    assert_contains(output, "You put", "#81: pronoun 'that' should resolve to key")
    assert_contains(output, "key", "#81: output should mention key")
end)

test("#81: 'put this on bed' resolves pronoun from context window", function()
    local ctx, handlers = make_ctx({ hold_matchbox = true })

    local cw = require("engine.parser.context")
    cw.reset()
    cw.push(ctx.registry:get("matchbox"))

    local output = capture(function()
        handlers["put"](ctx, "this on bed")
    end)
    assert_contains(output, "You put", "#81: pronoun 'this' should resolve to matchbox")
    assert_contains(output, "matchbox", "#81: output should mention matchbox")
end)

test("#81: non-pronoun item still works (no regression)", function()
    local ctx, handlers = make_ctx({ hold_knife = true })

    local output = capture(function()
        handlers["put"](ctx, "knife on nightstand")
    end)
    assert_contains(output, "You put", "direct noun should still work")
    assert_contains(output, "knife", "should mention knife")
end)

---------------------------------------------------------------------------
-- #82: Under/inside prepositions
---------------------------------------------------------------------------
print("\n=== #82: Under and inside prepositions ===")

test("#82: 'put key under rug' — under preposition", function()
    local ctx, handlers = make_ctx({ hold_key = true })

    local output = capture(function()
        handlers["put"](ctx, "key under rug")
    end)
    assert_contains(output, "You put", "#82: 'under' should be parsed")
    assert_contains(output, "key", "#82: output should mention key")
    assert_contains(output, "under", "#82: output should say 'under'")
    assert_contains(output, "rug", "#82: output should mention rug")
end)

test("#82: 'put key underneath rug' — underneath preposition", function()
    local ctx, handlers = make_ctx({ hold_key = true })

    local output = capture(function()
        handlers["put"](ctx, "key underneath rug")
    end)
    assert_contains(output, "You put", "#82: 'underneath' should be parsed")
    assert_contains(output, "under", "#82: output should use 'under'")
end)

test("#82: 'put key beneath rug' — beneath preposition", function()
    local ctx, handlers = make_ctx({ hold_key = true })

    local output = capture(function()
        handlers["put"](ctx, "key beneath rug")
    end)
    assert_contains(output, "You put", "#82: 'beneath' should be parsed")
    assert_contains(output, "under", "#82: output should use 'under'")
end)

test("#82: 'put key inside drawer' — inside preposition maps to 'in'", function()
    local ctx, handlers = make_ctx({ hold_key = true })

    local output = capture(function()
        handlers["put"](ctx, "key inside drawer")
    end)
    assert_contains(output, "You put", "#82: 'inside' should be parsed")
    assert_contains(output, "key", "#82: output should mention key")
end)

test("#82: 'put key under nightstand' routes to underneath surface", function()
    local ctx, handlers, reg = make_ctx({ hold_key = true })

    -- Add an underneath surface to nightstand
    local ns = reg:get("nightstand")
    ns.surfaces.underneath = {
        capacity = 3,
        max_item_size = 2,
        contents = {},
        accessible = true,
    }

    local output = capture(function()
        handlers["put"](ctx, "key under nightstand")
    end)
    assert_contains(output, "You put", "#82: under + surface should work")
    assert_eq(ns.surfaces.underneath.contents[1], "brass-key",
        "#82: key should be in underneath surface")
end)

test("#82: 'in' and 'on' still work (regression check)", function()
    local ctx, handlers = make_ctx({ hold_knife = true })

    local output = capture(function()
        handlers["put"](ctx, "knife in drawer")
    end)
    assert_contains(output, "You put", "existing 'in' prep should still work")
end)

test("#82: 'on' still works (regression check)", function()
    local ctx, handlers = make_ctx({ hold_knife = true })

    local output = capture(function()
        handlers["put"](ctx, "knife on nightstand")
    end)
    assert_contains(output, "You put", "existing 'on' prep should still work")
end)

---------------------------------------------------------------------------
-- #83: Placement verb aliases via preprocess
---------------------------------------------------------------------------
print("\n=== #83: Placement verb aliases ===")

local preprocess = require("engine.parser.preprocess")

test("#83: 'set knife on vanity' → 'put knife on vanity'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("set knife on vanity")
    assert_eq(result, "put knife on vanity", "'set X on Y' should map to 'put X on Y'")
end)

test("#83: 'drop knife on bed' → 'put knife on bed'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("drop knife on bed")
    assert_eq(result, "put knife on bed", "'drop X on Y' should map to 'put X on Y'")
end)

test("#83: 'hide key under rug' → 'put key under rug'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("hide key under rug")
    assert_eq(result, "put key under rug", "'hide X under Y' should map to 'put X under Y'")
end)

test("#83: 'stuff matchbox in drawer' → 'put matchbox in drawer'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("stuff matchbox in drawer")
    assert_eq(result, "put matchbox in drawer", "'stuff X in Y' should map to 'put X in Y'")
end)

test("#83: 'toss knife on bed' → 'put knife on bed'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("toss knife on bed")
    assert_eq(result, "put knife on bed", "'toss X on Y' should map to 'put X on Y'")
end)

test("#83: 'slide key under rug' → 'put key under rug'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("slide key under rug")
    assert_eq(result, "put key under rug", "'slide X under Y' should map to 'put X under Y'")
end)

test("#83: 'stuff matchbox into drawer' → 'put matchbox in drawer'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("stuff matchbox into drawer")
    assert_eq(result, "put matchbox in drawer", "'stuff X into Y' should map to 'put X in Y'")
end)

test("#83: 'toss knife onto bed' → 'put knife on bed'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("toss knife onto bed")
    assert_eq(result, "put knife on bed", "'toss X onto Y' should map to 'put X on Y'")
end)

test("#83: 'hide key inside drawer' → 'put key inside drawer'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("hide key inside drawer")
    assert_eq(result, "put key inside drawer", "'hide X inside Y' should map to 'put X inside Y'")
end)

test("#83: 'slide key underneath rug' → 'put key under rug'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("slide key underneath rug")
    assert_eq(result, "put key under rug", "'slide X underneath Y' should map to 'put X under Y'")
end)

-- Regression: make sure existing transforms aren't broken
test("#83 regression: 'set fire to candle' still maps to 'light candle'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    -- This is in IDIOM_TABLE, tested via expand_idioms (runs before transform_compound_actions)
    local v, n = pp.natural_language("set fire to candle")
    assert_eq(v, "light", "'set fire to X' must still map to light")
    assert_eq(n, "candle", "noun should be candle")
end)

test("#83 regression: 'drop knife' (bare, no prep) stays as 'drop'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("drop knife")
    assert_eq(result, "drop knife", "bare 'drop X' must NOT transform to put")
end)

test("#83 regression: 'put down knife' still maps to 'drop knife'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local v, n = pp.natural_language("put down knife")
    assert_eq(v, "drop", "'put down X' must still map to drop")
    assert_eq(n, "knife", "noun should be knife")
end)

test("#83 regression: 'put out candle' still maps to 'extinguish candle'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("put out candle")
    assert_eq(result, "extinguish candle", "'put out X' must still map to extinguish")
end)

test("#83 regression: 'put on cloak' still maps to 'wear cloak'", function()
    reset_modules()
    local pp = require("engine.parser.preprocess")
    local result = pp.stages.transform_compound_actions("put on cloak")
    assert_eq(result, "wear cloak", "'put on X' must still map to wear")
end)

test("#83 regression: existing 'place' alias still works", function()
    local ctx, handlers = make_ctx({ hold_knife = true })

    local output = capture(function()
        handlers["place"](ctx, "knife on nightstand")
    end)
    assert_contains(output, "You put", "'place' alias should still work")
end)

---------------------------------------------------------------------------
-- Results
---------------------------------------------------------------------------
print("\n--- Results ---")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
if failed > 0 then
    print("Failures:")
    os.exit(1)
end
