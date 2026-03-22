-- test/parser/pipeline/test-normalize.lua
-- Unit tests for Stage 1: normalize (trim, lowercase, strip question marks)
-- Tests the individual stage function in isolation.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../../src/?.lua;"
             .. script_dir .. "/../../../src/?/init.lua;"
             .. script_dir .. "/../../../?.lua;"
             .. script_dir .. "/../../../?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq

local normalize = preprocess.stages.normalize

-------------------------------------------------------------------------------
h.suite("Stage 1: normalize — trim whitespace")
-------------------------------------------------------------------------------

test("leading spaces stripped", function()
    eq("look around", normalize("   look around"))
end)

test("trailing spaces stripped", function()
    eq("look around", normalize("look around   "))
end)

test("leading and trailing spaces stripped", function()
    eq("look around", normalize("   look around   "))
end)

test("tabs and mixed whitespace trimmed", function()
    eq("open door", normalize("\t open door \t"))
end)

test("internal whitespace preserved", function()
    eq("look at nightstand", normalize("  look at nightstand  "))
end)

-------------------------------------------------------------------------------
h.suite("Stage 1: normalize — lowercase")
-------------------------------------------------------------------------------

test("all uppercase lowered", function()
    eq("look around", normalize("LOOK AROUND"))
end)

test("mixed case lowered", function()
    eq("search nightstand", normalize("Search Nightstand"))
end)

test("single uppercase word lowered", function()
    eq("inventory", normalize("INVENTORY"))
end)

test("already lowercase is no-op", function()
    eq("take key", normalize("take key"))
end)

test("mixed case with numbers preserved", function()
    eq("room42", normalize("Room42"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 1: normalize — strip question marks")
-------------------------------------------------------------------------------

test("trailing question mark stripped", function()
    eq("where am i", normalize("where am i?"))
end)

test("multiple trailing question marks stripped", function()
    eq("what is this", normalize("what is this???"))
end)

test("question mark in middle NOT stripped", function()
    eq("what? is this", normalize("what? is this"))
end)

test("question mark combined with uppercase", function()
    eq("where am i", normalize("WHERE AM I?"))
end)

test("question mark combined with whitespace", function()
    eq("what is this", normalize("  What is this?  "))
end)

-------------------------------------------------------------------------------
h.suite("Stage 1: normalize — edge cases")
-------------------------------------------------------------------------------

test("empty string returns empty", function()
    eq("", normalize(""))
end)

test("nil input returns empty", function()
    eq("", normalize(nil))
end)

test("whitespace-only returns empty", function()
    eq("", normalize("   "))
end)

test("single character preserved", function()
    eq("i", normalize("i"))
end)

test("just a question mark returns empty", function()
    eq("", normalize("?"))
end)

test("already normalized text is no-op", function()
    eq("open crate", normalize("open crate"))
end)

test("question mark after space: trailing space preserved (trim-then-strip)", function()
    -- normalize trims first, then strips trailing ?; space before ? remains
    eq("what is here ", normalize("what is here ?"))
end)

test("multiple question marks only returns empty", function()
    eq("", normalize("???"))
end)

test("complex combined: uppercase, spaces, question mark", function()
    eq("what's in the nightstand", normalize("  What's In The Nightstand?  "))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
