-- test/parser/test-preprocess.lua
-- Unit tests for engine/parser/preprocess.lua
-- Tests: preamble stripping, question patterns, verb aliases, parse splitting.

-- Set up package path to find engine modules from repo root
local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq

-------------------------------------------------------------------------------
h.suite("preprocess.parse — basic verb/noun splitting")
-------------------------------------------------------------------------------

test("single word returns verb only", function()
    local v, n = preprocess.parse("look")
    eq("look", v)
    eq("", n)
end)

test("two words split into verb and noun", function()
    local v, n = preprocess.parse("open wardrobe")
    eq("open", v)
    eq("wardrobe", n)
end)

test("multi-word noun preserved", function()
    local v, n = preprocess.parse("examine old crate")
    eq("examine", v)
    eq("old crate", n)
end)

test("leading/trailing whitespace trimmed", function()
    local v, n = preprocess.parse("  look  around  ")
    eq("look", v)
    eq("around", n)
end)

test("input lowercased", function()
    local v, n = preprocess.parse("LOOK AROUND")
    eq("look", v)
    eq("around", n)
end)

test("bare 'I' is kept as verb (inventory shortcut)", function()
    local v, n = preprocess.parse("i")
    eq("i", v)
    eq("", n)
end)

test("'I want to look' strips pronoun preamble", function()
    local v, n = preprocess.parse("I look around")
    -- BUG-036: "I" + noun re-parses the rest
    eq("look", v)
    eq("around", n)
end)

-------------------------------------------------------------------------------
h.suite("preprocess.natural_language — question patterns")
-------------------------------------------------------------------------------

test("'what am I holding' maps to inventory", function()
    local v, n = preprocess.natural_language("what am I holding")
    eq("inventory", v)
    eq("", n)
end)

test("'what am I carrying' maps to inventory", function()
    local v, n = preprocess.natural_language("what am I carrying")
    eq("inventory", v)
    eq("", n)
end)

test("'where am I' maps to look", function()
    local v, n = preprocess.natural_language("where am I")
    eq("look", v)
    eq("", n)
end)

test("'what do I see' maps to look", function()
    local v, n = preprocess.natural_language("what do I see")
    eq("look", v)
    eq("", n)
end)

test("'what time is it' maps to time", function()
    local v, n = preprocess.natural_language("what time is it")
    eq("time", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("preprocess.natural_language — preamble stripping")
-------------------------------------------------------------------------------

test("'I want to look around' strips preamble → look", function()
    local v, n = preprocess.natural_language("I want to look around")
    eq("look", v)
    eq("", n)
end)

test("'I'd like to open the crate' strips preamble → open crate", function()
    local v, n = preprocess.natural_language("I'd like to open the crate")
    -- preamble stripped, falls through to parse("open the crate")
    eq("open", v)
    eq("the crate", n)
end)

test("'I need to take the key' strips preamble → take key", function()
    local v, n = preprocess.natural_language("I need to take the key")
    eq("take", v)
    eq("the key", n)
end)

-------------------------------------------------------------------------------
h.suite("preprocess.natural_language — verb aliases (BUG-049)")
-------------------------------------------------------------------------------

test("'pry open crate' maps to open crate", function()
    local v, n = preprocess.natural_language("pry open crate")
    eq("open", v)
    eq("crate", n)
end)

test("'use crowbar on crate' maps to open crate", function()
    local v, n = preprocess.natural_language("use crowbar on crate")
    eq("open", v)
    eq("crate", n)
end)

test("'put out candle' maps to extinguish candle", function()
    local v, n = preprocess.natural_language("put out candle")
    eq("extinguish", v)
    eq("candle", n)
end)

test("'take off gloves' maps to remove gloves", function()
    local v, n = preprocess.natural_language("take off gloves")
    eq("remove", v)
    eq("gloves", n)
end)

-------------------------------------------------------------------------------
h.suite("preprocess.natural_language — edge cases")
-------------------------------------------------------------------------------

test("empty string returns nil", function()
    local v, n = preprocess.natural_language("")
    h.assert_nil(v, "verb should be nil for empty input")
end)

test("whitespace-only returns nil", function()
    local v, n = preprocess.natural_language("   ")
    h.assert_nil(v, "verb should be nil for whitespace input")
end)

test("unrecognized phrase returns nil (falls through)", function()
    local v, n = preprocess.natural_language("examine nightstand")
    h.assert_nil(v, "unrecognized phrases should return nil")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
