-- test/parser/test-pass033-context-bugs.lua
-- Regression tests for Pass-033 context window bugs: BUG-113, BUG-114, BUG-115.
--
-- BUG-113: Bare `pick up` after discovery → auto-fill from context window
-- BUG-114: "the one I found" → resolve from search discovery memory
-- BUG-115: "the thing on X" → spatial reference resolution

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")
local context_window = require("engine.parser.context")

local test = h.test
local eq   = h.assert_eq

local function fresh()
    context_window.reset()
end

-------------------------------------------------------------------------------
h.suite("BUG-113: Bare 'pick up' → 'take' (context fallback in loop)")
-------------------------------------------------------------------------------

test("BUG-113: 'pick up' (bare) preprocesses to 'take'", function()
    local v, n = preprocess.natural_language("pick up")
    eq("take", v, "'pick up' should become verb 'take'")
    eq("", n, "noun should be empty for bare 'pick up'")
end)

test("BUG-113: 'Pick Up' (mixed case) preprocesses to 'take'", function()
    local v, n = preprocess.natural_language("Pick Up")
    eq("take", v)
    eq("", n)
end)

test("BUG-113: 'PICK UP' (all caps) preprocesses to 'take'", function()
    local v, n = preprocess.natural_language("PICK UP")
    eq("take", v)
    eq("", n)
end)

test("BUG-113: 'pick up matchbox' still works (not bare)", function()
    -- "pick up matchbox" should NOT collapse to bare "take"
    -- It should parse as verb=pick, noun=up matchbox → take handler strips "up"
    local v, n = preprocess.natural_language("pick up matchbox")
    if v then
        -- Pipeline matched — check it didn't break the target
        assert(n ~= "", "noun should not be empty for 'pick up matchbox'")
    else
        -- Pipeline didn't match — parse fallback
        v, n = preprocess.parse("pick up matchbox")
        eq("pick", v)
        eq("up matchbox", n, "parse should keep 'up matchbox' as noun")
    end
end)

test("BUG-113: 'pick up the key' still works", function()
    local v, n = preprocess.natural_language("pick up the key")
    if v then
        assert(n ~= "", "noun should not be empty for 'pick up the key'")
    else
        v, n = preprocess.parse("pick up the key")
        eq("pick", v)
        eq("up the key", n)
    end
end)

test("BUG-113: context_window.peek() returns last pushed object", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    local obj = context_window.peek()
    eq("matchbox", obj and obj.id or nil, "peek should return last discovery")
end)

-------------------------------------------------------------------------------
h.suite("BUG-114: 'the one I found' → discovery context resolution")
-------------------------------------------------------------------------------

test("BUG-114: resolve 'the one I found' from discoveries", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    local obj = context_window.resolve("the one I found")
    eq("matchbox", obj and obj.id or nil)
end)

test("BUG-114: resolve 'one I found' (no article) from discoveries", function()
    fresh()
    context_window.push_discovery({ id = "key", name = "brass key" })
    local obj = context_window.resolve("one I found")
    eq("key", obj and obj.id or nil)
end)

test("BUG-114: resolve 'the one I discovered' from discoveries", function()
    fresh()
    context_window.push_discovery({ id = "bottle", name = "glass bottle" })
    local obj = context_window.resolve("the one I discovered")
    eq("bottle", obj and obj.id or nil)
end)

test("BUG-114: resolve 'one I discovered' from discoveries", function()
    fresh()
    context_window.push_discovery({ id = "bottle", name = "glass bottle" })
    local obj = context_window.resolve("one I discovered")
    eq("bottle", obj and obj.id or nil)
end)

test("BUG-114: resolve 'one I just found' from discoveries", function()
    fresh()
    context_window.push_discovery({ id = "candle", name = "wax candle" })
    local obj = context_window.resolve("one I just found")
    eq("candle", obj and obj.id or nil)
end)

test("BUG-114: discovery resolution returns nil when no discoveries", function()
    fresh()
    context_window.push({ id = "lamp", name = "brass lamp" })
    local obj = context_window.resolve("the one I found")
    eq(nil, obj, "no discoveries → nil")
end)

test("BUG-114: discovery resolves most recent discovery", function()
    fresh()
    context_window.push_discovery({ id = "matchbox", name = "small matchbox" })
    context_window.push_discovery({ id = "candle", name = "wax candle" })
    local obj = context_window.resolve("the one I found")
    eq("candle", obj and obj.id or nil, "should resolve to most recent discovery")
end)

test("BUG-114: existing 'thing I found' still works", function()
    fresh()
    context_window.push_discovery({ id = "gem", name = "red gem" })
    local obj = context_window.resolve("the thing I found")
    eq("gem", obj and obj.id or nil)
end)

test("BUG-114: existing 'what I found' still works", function()
    fresh()
    context_window.push_discovery({ id = "gem", name = "red gem" })
    local obj = context_window.resolve("what I found")
    eq("gem", obj and obj.id or nil)
end)

-------------------------------------------------------------------------------
h.suite("BUG-115: 'the thing on X' → spatial reference preprocessing")
-------------------------------------------------------------------------------
-- Spatial resolution itself lives in find_visible (verbs/init.lua).
-- Here we test that the preprocess pipeline correctly passes through
-- spatial phrases so they reach find_visible intact.

test("BUG-115: 'check the thing on the nightstand' → examine the thing on the nightstand", function()
    local v, n = preprocess.natural_language("check the thing on the nightstand")
    eq("examine", v, "'check' should map to 'examine'")
    eq("the thing on the nightstand", n, "spatial phrase should be preserved as noun")
end)

test("BUG-115: 'please carefully check the thing on the nightstand' → examine", function()
    local v, n = preprocess.natural_language("please carefully check the thing on the nightstand")
    eq("examine", v, "politeness/adverbs stripped, 'check' → 'examine'")
    eq("the thing on the nightstand", n)
end)

test("BUG-115: 'examine something on the table' preserves spatial phrase", function()
    local v, n = preprocess.natural_language("examine something on the table")
    if v then
        eq("examine", v)
        -- noun should contain the spatial reference
        assert(n:match("on the table"), "spatial reference should be in noun")
    else
        v, n = preprocess.parse("examine something on the table")
        eq("examine", v)
        assert(n:match("on the table"), "spatial reference should be in noun")
    end
end)

test("BUG-115: 'look at the thing on the nightstand' → examine the thing on the nightstand", function()
    local v, n = preprocess.natural_language("look at the thing on the nightstand")
    eq("examine", v, "'look at' should map to 'examine'")
    eq("the thing on the nightstand", n)
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
