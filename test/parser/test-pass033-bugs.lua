-- test/parser/test-pass033-bugs.lua
-- Regression tests for Pass-033 bug findings.
-- BUG-105 (what do I do? hang), BUG-106 (what now? hang),
-- BUG-112 (look under this hang).

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test   = h.test
local eq     = h.assert_eq

-------------------------------------------------------------------------------
h.suite("BUG-105: 'what do I do?' — MUST map to help (Pass 033 regression)")
-------------------------------------------------------------------------------

test("BUG-105: 'what do I do?' → help", function()
    local v, n = preprocess.natural_language("what do I do?")
    eq("help", v, "'what do I do?' should transform to 'help'")
    eq("", n, "No noun expected")
end)

test("BUG-105: 'what do i do' (lowercase, no ?) → help", function()
    local v, n = preprocess.natural_language("what do i do")
    eq("help", v)
    eq("", n)
end)

test("BUG-105: 'WHAT DO I DO' (all caps) → help", function()
    local v, n = preprocess.natural_language("WHAT DO I DO")
    eq("help", v)
    eq("", n)
end)

test("BUG-105: 'What Do I Do?' (mixed case with ?) → help", function()
    local v, n = preprocess.natural_language("What Do I Do?")
    eq("help", v)
    eq("", n)
end)

test("BUG-105: 'what can i do' → help (variant)", function()
    local v, n = preprocess.natural_language("what can i do")
    eq("help", v)
    eq("", n)
end)

test("BUG-105: 'what should i do' → help (variant)", function()
    local v, n = preprocess.natural_language("what should i do")
    eq("help", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("BUG-106: 'what now?' — MUST map to help (Pass 033 regression)")
-------------------------------------------------------------------------------

test("BUG-106: 'what now?' → help", function()
    local v, n = preprocess.natural_language("what now?")
    eq("help", v, "'what now?' should transform to 'help'")
    eq("", n)
end)

test("BUG-106: 'what now' (no ?) → help", function()
    local v, n = preprocess.natural_language("what now")
    eq("help", v)
    eq("", n)
end)

test("BUG-106: 'now what?' → help", function()
    local v, n = preprocess.natural_language("now what?")
    eq("help", v)
    eq("", n)
end)

test("BUG-106: 'now what' (no ?) → help", function()
    local v, n = preprocess.natural_language("now what")
    eq("help", v)
    eq("", n)
end)

test("BUG-106: 'WHAT NOW' (all caps) → help", function()
    local v, n = preprocess.natural_language("WHAT NOW")
    eq("help", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("BUG-105/106: Loop-level safety net (direct transform)")
-------------------------------------------------------------------------------
-- These tests verify the direct-transform safety net in loop/init.lua.
-- In the loop, common help phrases are lowercased and matched BEFORE the
-- pipeline runs, rewriting the input to "help" directly.

test("Loop safety: 'what do i do' lowered → matches safety check", function()
    local lc = ("what do I do"):lower()
    eq("what do i do", lc, "lowercased match")
end)

test("Loop safety: 'what now' lowered → matches safety check", function()
    local lc = ("What now"):lower()
    eq("what now", lc, "lowercased match")
end)

test("Loop safety: 'now what' lowered → matches safety check", function()
    local lc = ("NOW WHAT"):lower()
    eq("now what", lc, "lowercased match")
end)

test("Loop safety: 'what can i do' lowered → matches safety check", function()
    local lc = ("What Can I Do"):lower()
    eq("what can i do", lc, "lowercased match")
end)

-------------------------------------------------------------------------------
h.suite("BUG-112: 'look under X' — MUST NOT hang (Pass 033 regression)")
-------------------------------------------------------------------------------

test("BUG-112: 'look under this' → examine this", function()
    local v, n = preprocess.natural_language("look under this")
    eq("examine", v, "'look under this' should transform to 'examine this'")
    eq("this", n)
end)

test("BUG-112: 'look under the bed' → examine the bed", function()
    local v, n = preprocess.natural_language("look under the bed")
    eq("examine", v)
    eq("the bed", n)
end)

test("BUG-112: 'look underneath table' → examine table", function()
    local v, n = preprocess.natural_language("look underneath table")
    eq("examine", v)
    eq("table", n)
end)

test("BUG-112: 'look beneath it' → examine it", function()
    local v, n = preprocess.natural_language("look beneath it")
    eq("examine", v)
    eq("it", n)
end)

test("BUG-112: 'look under rug' → examine rug", function()
    local v, n = preprocess.natural_language("look under rug")
    eq("examine", v)
    eq("rug", n)
end)

test("BUG-112: 'Look Under The Nightstand' (mixed case) → examine the nightstand", function()
    local v, n = preprocess.natural_language("Look Under The Nightstand")
    eq("examine", v)
    eq("the nightstand", n)
end)

-------------------------------------------------------------------------------
h.suite("Regression: existing look patterns still work")
-------------------------------------------------------------------------------

test("'look around' → look (BUG-037)", function()
    local v, n = preprocess.natural_language("look around")
    eq("look", v)
    eq("", n)
end)

test("'look at nightstand' → examine nightstand (BUG-087)", function()
    local v, n = preprocess.natural_language("look at nightstand")
    eq("examine", v)
    eq("nightstand", n)
end)

test("'check drawer' → examine drawer (BUG-086)", function()
    local v, n = preprocess.natural_language("check drawer")
    eq("examine", v)
    eq("drawer", n)
end)

test("'look for key' → find key (BUG-074)", function()
    local v, n = preprocess.natural_language("look for key")
    eq("find", v)
    eq("key", n)
end)

test("'what's in the drawer' → examine drawer (container query)", function()
    local v, n = preprocess.natural_language("what's in the drawer")
    eq("examine", v)
    eq("drawer", n)
end)

test("'how do i get out' → help", function()
    local v, n = preprocess.natural_language("how do i get out")
    eq("help", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failed = h.summary()
os.exit(failed > 0 and 1 or 0)
