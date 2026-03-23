-- test/parser/pipeline/test-transform-look-patterns.lua
-- Unit tests for Stage 4: transform_look_patterns (look at/for/around, check)
-- Tests the individual stage function in isolation.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../../src/?.lua;"
             .. script_dir .. "/../../../src/?/init.lua;"
             .. script_dir .. "/../../../?.lua;"
             .. script_dir .. "/../../../?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

local transform_look_patterns = preprocess.stages.transform_look_patterns

-------------------------------------------------------------------------------
h.suite("Stage 4: transform_look_patterns — 'look at X' → examine")
-------------------------------------------------------------------------------

test("'look at nightstand' → 'examine nightstand'", function()
    eq("examine nightstand", transform_look_patterns("look at nightstand"))
end)

test("'look at the bed' → 'examine the bed'", function()
    eq("examine the bed", transform_look_patterns("look at the bed"))
end)

test("'look at old painting' → 'examine old painting'", function()
    eq("examine old painting", transform_look_patterns("look at old painting"))
end)

test("'look at the rusty key' → 'examine the rusty key'", function()
    eq("examine the rusty key", transform_look_patterns("look at the rusty key"))
end)

test("'look at me' → 'appearance' (BUG-129: self-referential look)", function()
    eq("appearance", transform_look_patterns("look at me"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 4: transform_look_patterns — 'look for X' → find")
-------------------------------------------------------------------------------

test("'look for a candle' → 'find candle' (article stripped)", function()
    eq("find candle", transform_look_patterns("look for a candle"))
end)

test("'look for the key' → 'find key' (article stripped)", function()
    eq("find key", transform_look_patterns("look for the key"))
end)

test("'look for matches' → 'find matches'", function()
    eq("find matches", transform_look_patterns("look for matches"))
end)

test("'look for an apple' → 'find apple' (article stripped)", function()
    eq("find apple", transform_look_patterns("look for an apple"))
end)

test("'look for the matchbox' → 'find matchbox'", function()
    eq("find matchbox", transform_look_patterns("look for the matchbox"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 4: transform_look_patterns — 'look around' → look")
-------------------------------------------------------------------------------

test("'look around' → 'look'", function()
    eq("look", transform_look_patterns("look around"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 4: transform_look_patterns — 'look in X' (no match)")
-------------------------------------------------------------------------------

test("'look in nightstand' passes through (not matched by this stage)", function()
    -- "look in" is NOT matched by transform_look_patterns; only look at/for/around
    eq("look in nightstand", transform_look_patterns("look in nightstand"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 4: transform_look_patterns — 'check X' → examine")
-------------------------------------------------------------------------------

test("'check nightstand' → 'examine nightstand'", function()
    eq("examine nightstand", transform_look_patterns("check nightstand"))
end)

test("'check the drawer' → 'examine the drawer'", function()
    eq("examine the drawer", transform_look_patterns("check the drawer"))
end)

test("'check door' → 'examine door'", function()
    eq("examine door", transform_look_patterns("check door"))
end)

test("'check around' → 'examine around'", function()
    eq("examine around", transform_look_patterns("check around"))
end)

test("'check the old painting' → 'examine the old painting'", function()
    eq("examine the old painting", transform_look_patterns("check the old painting"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 4: transform_look_patterns — passthrough / non-look verbs")
-------------------------------------------------------------------------------

test("'open door' passes through unchanged", function()
    eq("open door", transform_look_patterns("open door"))
end)

test("'take key' passes through unchanged", function()
    eq("take key", transform_look_patterns("take key"))
end)

test("'search nightstand' passes through unchanged", function()
    eq("search nightstand", transform_look_patterns("search nightstand"))
end)

test("'examine nightstand' passes through unchanged", function()
    eq("examine nightstand", transform_look_patterns("examine nightstand"))
end)

test("'find matches' passes through unchanged", function()
    eq("find matches", transform_look_patterns("find matches"))
end)

test("'look' alone passes through unchanged", function()
    eq("look", transform_look_patterns("look"))
end)

test("'feel around' passes through unchanged", function()
    eq("feel around", transform_look_patterns("feel around"))
end)

test("'go north' passes through unchanged", function()
    eq("go north", transform_look_patterns("go north"))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
