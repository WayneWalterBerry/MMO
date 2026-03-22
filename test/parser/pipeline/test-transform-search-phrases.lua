-- test/parser/pipeline/test-transform-search-phrases.lua
-- Unit tests for Stage 5: transform_search_phrases (search/hunt/rummage/find compounds)
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

local transform_search_phrases = preprocess.stages.transform_search_phrases

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'search X for Y'")
-------------------------------------------------------------------------------

test("'search nightstand for matchbox' → articles stripped", function()
    local result = transform_search_phrases("search nightstand for matchbox")
    eq("search nightstand for matchbox", result)
end)

test("'search the nightstand for the matchbox' → articles stripped", function()
    local result = transform_search_phrases("search the nightstand for the matchbox")
    eq("search nightstand for matchbox", result)
end)

test("'search the room for a candle' → articles stripped", function()
    local result = transform_search_phrases("search the room for a candle")
    eq("search room for candle", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'search for X'")
-------------------------------------------------------------------------------

test("'search for the matchbox' → 'search matchbox'", function()
    local result = transform_search_phrases("search for the matchbox")
    eq("search matchbox", result)
end)

test("'search for matches' → 'search match' (BUG-111: singularized)", function()
    local result = transform_search_phrases("search for matches")
    eq("search match", result)
end)

test("'search for everything' → 'search' (sweep)", function()
    local result = transform_search_phrases("search for everything")
    eq("search", result)
end)

test("'search for anything' → 'search' (sweep)", function()
    local result = transform_search_phrases("search for anything")
    eq("search", result)
end)

test("'search for all' → 'search' (sweep)", function()
    local result = transform_search_phrases("search for all")
    eq("search", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'search around'")
-------------------------------------------------------------------------------

test("'search around' → 'search around'", function()
    local result = transform_search_phrases("search around")
    eq("search around", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'find Y in X'")
-------------------------------------------------------------------------------

test("'find matchbox in nightstand' → articles stripped", function()
    local result = transform_search_phrases("find matchbox in nightstand")
    eq("find matchbox in nightstand", result)
end)

test("'find the matchbox in the nightstand' → articles stripped", function()
    local result = transform_search_phrases("find the matchbox in the nightstand")
    eq("find matchbox in nightstand", result)
end)

test("'find a candle in the drawer' → articles stripped", function()
    local result = transform_search_phrases("find a candle in the drawer")
    eq("find candle in drawer", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'find X' simple")
-------------------------------------------------------------------------------

test("'find the matchbox' → 'find matchbox' (article stripped)", function()
    local result = transform_search_phrases("find the matchbox")
    eq("find matchbox", result)
end)

test("'find a candle' → 'find candle'", function()
    local result = transform_search_phrases("find a candle")
    eq("find candle", result)
end)

test("'find matches' → 'find match' (BUG-111: singularized)", function()
    local result = transform_search_phrases("find matches")
    eq("find match", result)
end)

test("'find everything' → 'search' (sweep)", function()
    local result = transform_search_phrases("find everything")
    eq("search", result)
end)

test("'find anything' → 'search' (sweep)", function()
    local result = transform_search_phrases("find anything")
    eq("search", result)
end)

test("'find all' → 'search' (sweep)", function()
    local result = transform_search_phrases("find all")
    eq("search", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'hunt for X'")
-------------------------------------------------------------------------------

test("'hunt for matches' → 'search match' (BUG-111: singularized)", function()
    local result = transform_search_phrases("hunt for matches")
    eq("search match", result)
end)

test("'hunt for the key' → 'search key' (article stripped)", function()
    local result = transform_search_phrases("hunt for the key")
    eq("search key", result)
end)

test("'hunt around' → 'search around'", function()
    local result = transform_search_phrases("hunt around")
    eq("search around", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'rummage' patterns")
-------------------------------------------------------------------------------

test("'rummage for matches' → 'search match' (BUG-111: singularized)", function()
    local result = transform_search_phrases("rummage for matches")
    eq("search match", result)
end)

test("'rummage through the drawer' → 'search the drawer'", function()
    local result = transform_search_phrases("rummage through the drawer")
    eq("search the drawer", result)
end)

test("'rummage around' → 'search around'", function()
    local result = transform_search_phrases("rummage around")
    eq("search around", result)
end)

test("'rummage' (bare) → 'search around'", function()
    local result = transform_search_phrases("rummage")
    eq("search around", result)
end)

test("'rummage the nightstand' → 'search nightstand' (article stripped)", function()
    local result = transform_search_phrases("rummage the nightstand")
    eq("search nightstand", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — 'feel around' / 'grope around'")
-------------------------------------------------------------------------------

test("'feel around the room' → 'feel'", function()
    local result = transform_search_phrases("feel around the room")
    eq("feel", result)
end)

test("'grope around the room' → 'feel'", function()
    local result = transform_search_phrases("grope around the room")
    eq("feel", result)
end)

-------------------------------------------------------------------------------
h.suite("Stage 5: transform_search_phrases — passthrough / non-search")
-------------------------------------------------------------------------------

test("'open door' passes through unchanged", function()
    eq("open door", transform_search_phrases("open door"))
end)

test("'take key' passes through unchanged", function()
    eq("take key", transform_search_phrases("take key"))
end)

test("'look around' passes through unchanged", function()
    eq("look around", transform_search_phrases("look around"))
end)

test("'examine nightstand' passes through unchanged", function()
    eq("examine nightstand", transform_search_phrases("examine nightstand"))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
