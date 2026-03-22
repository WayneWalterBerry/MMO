-- test/parser/test-pass031-bugs.lua
-- Regression tests for Pass-031 bug findings.
-- BUG-104 through BUG-111: question hangs, politeness gaps, idiom gaps,
-- search target resolution, fuzzy noun matching.
--
-- Bug IDs tested: BUG-104, BUG-105, BUG-106, BUG-107, BUG-108, BUG-109,
--                 BUG-110, BUG-111

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

-------------------------------------------------------------------------------
h.suite("BUG-104: 'what's this?' — must NOT hang, should map to look")
-------------------------------------------------------------------------------

test("BUG-104: 'what's this?' → look (no hang)", function()
    local v, n = preprocess.natural_language("what's this?")
    eq("look", v, "'what's this?' should transform to 'look'")
    eq("", n, "No noun expected")
end)

test("BUG-104: 'what is this?' → look (no hang)", function()
    local v, n = preprocess.natural_language("what is this?")
    eq("look", v, "'what is this?' should transform to 'look'")
    eq("", n, "No noun expected")
end)

test("BUG-104: 'whats this' (no apostrophe, no ?) → look", function()
    local v, n = preprocess.natural_language("whats this")
    eq("look", v, "'whats this' should transform to 'look'")
end)

test("BUG-104: 'what's in X' still works (regression)", function()
    local v, n = preprocess.natural_language("what's in the nightstand?")
    eq("examine", v, "'what's in X' should still transform to 'examine'")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

-------------------------------------------------------------------------------
h.suite("BUG-105: 'what do I do?' — must NOT hang, should map to help")
-------------------------------------------------------------------------------

test("BUG-105: 'what do I do?' → help (no hang)", function()
    local v, n = preprocess.natural_language("what do I do?")
    eq("help", v, "'what do I do?' should transform to 'help'")
    eq("", n, "No noun expected")
end)

test("BUG-105: 'what do i do' (lowercase, no ?) → help", function()
    local v, n = preprocess.natural_language("what do i do")
    eq("help", v)
    eq("", n)
end)

test("BUG-105: 'What can I do?' → help (variant)", function()
    local v, n = preprocess.natural_language("What can I do?")
    eq("help", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("BUG-106: 'what now?' — must NOT hang, should map to help")
-------------------------------------------------------------------------------

test("BUG-106: 'what now?' → help (no hang)", function()
    local v, n = preprocess.natural_language("what now?")
    eq("help", v, "'what now?' should transform to 'help'")
    eq("", n, "No noun expected")
end)

test("BUG-106: 'what now' (no ?) → help", function()
    local v, n = preprocess.natural_language("what now")
    eq("help", v)
    eq("", n)
end)

test("BUG-106: 'now what?' → help (reversed)", function()
    local v, n = preprocess.natural_language("now what?")
    eq("help", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("BUG-107: 'would you mind examining X' — gerund after politeness")
-------------------------------------------------------------------------------

test("BUG-107: 'would you mind examining the nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("would you mind examining the nightstand")
    eq("examine", v, "Gerund 'examining' should reduce to 'examine'")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("BUG-107: 'would you mind opening the drawer' → open drawer", function()
    local v, n = preprocess.natural_language("would you mind opening the drawer")
    eq("open", v, "Gerund 'opening' should reduce to 'open'")
    truthy(n and n:find("drawer"), "Should target drawer")
end)

test("BUG-107: 'would you mind looking around' → look", function()
    local v, n = preprocess.natural_language("would you mind looking around")
    eq("look", v, "Gerund 'looking' should reduce to 'look'")
end)

test("BUG-107: 'would you mind searching the room' → search room", function()
    local v, n = preprocess.natural_language("would you mind searching the room")
    eq("search", v, "Gerund 'searching' should reduce to 'search'")
    truthy(n and n:find("room"), "Should target room")
end)

test("BUG-107: gerund strip in combo — 'please examining' → examine", function()
    local v, n = preprocess.natural_language("please examining the bed")
    eq("examine", v, "Gerund after 'please' should be stripped")
    truthy(n and n:find("bed"), "Should target bed")
end)

-------------------------------------------------------------------------------
h.suite("BUG-108: 'I'd like to know what's in X' — preamble not stripped")
-------------------------------------------------------------------------------

test("BUG-108: 'I'd like to know what's in the drawer' → examine drawer", function()
    local v, n = preprocess.natural_language("I'd like to know what's in the drawer")
    eq("examine", v, "'I'd like to know' preamble should be stripped")
    truthy(n and n:find("drawer"), "Should target drawer")
end)

test("BUG-108: 'I want to know what's in the nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("I want to know what's in the nightstand")
    eq("examine", v, "'I want to know' preamble should be stripped")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("BUG-108: 'I need to know what time it is' → time", function()
    local v, n = preprocess.natural_language("I need to know what time it is")
    eq("time", v, "'I need to know' preamble should be stripped")
end)

test("BUG-108: 'I'd like to know where am I' → look", function()
    local v, n = preprocess.natural_language("I'd like to know where am I")
    eq("look", v, "'I'd like to know' + 'where am I' should give 'look'")
end)

-------------------------------------------------------------------------------
h.suite("BUG-109: 'have a look around' — idiom not recognized")
-------------------------------------------------------------------------------

test("BUG-109: 'have a look around' → look", function()
    local v, n = preprocess.natural_language("have a look around")
    eq("look", v, "'have a look around' should map to 'look'")
    eq("", n)
end)

test("BUG-109: 'maybe I should have a look around' → look", function()
    local v, n = preprocess.natural_language("maybe I should have a look around")
    eq("look", v, "Preamble stripped + idiom recognized")
    eq("", n)
end)

test("BUG-109: 'take a look around' → look", function()
    local v, n = preprocess.natural_language("take a look around")
    eq("look", v, "'take a look around' should map to 'look'")
    eq("", n)
end)

test("BUG-109: 'have a look' still works → look", function()
    local v, n = preprocess.natural_language("have a look")
    eq("look", v, "'have a look' should still map to 'look'")
    eq("", n)
end)

test("BUG-109: 'have a look at the nightstand' still works → examine nightstand", function()
    local v, n = preprocess.natural_language("have a look at the nightstand")
    eq("examine", v, "'have a look at X' should still map to 'examine X'")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

-------------------------------------------------------------------------------
h.suite("BUG-110: 'where is the matchbox?' — search wrong target")
-------------------------------------------------------------------------------

test("BUG-110: 'where is the matchbox?' → find matchbox (not search matchbox)", function()
    local v, n = preprocess.natural_language("where is the matchbox?")
    eq("find", v, "'where is X' should produce 'find X' not 'search X'")
    eq("matchbox", n, "Should target matchbox")
end)

test("BUG-110: 'where is the key?' → find key", function()
    local v, n = preprocess.natural_language("where is the key?")
    eq("find", v)
    eq("key", n)
end)

test("BUG-110: 'where's the candle?' → find candle", function()
    local v, n = preprocess.natural_language("where's the candle?")
    eq("find", v)
    eq("candle", n)
end)

-------------------------------------------------------------------------------
h.suite("BUG-111: 'search for matches' — plural doesn't fuzzy-match 'matchbox'")
-------------------------------------------------------------------------------

test("BUG-111: 'search for matches' → search match (singularized)", function()
    local v, n = preprocess.natural_language("search for matches")
    eq("search", v)
    eq("match", n, "'matches' should be singularized to 'match' for fuzzy matching")
end)

test("BUG-111: 'find matches' → find match (singularized)", function()
    local v, n = preprocess.natural_language("find matches")
    eq("find", v)
    eq("match", n)
end)

test("BUG-111: 'search for torches' → search torch (singularized)", function()
    local v, n = preprocess.natural_language("search for torches")
    eq("search", v)
    eq("torch", n, "'torches' should singularize to 'torch'")
end)

test("BUG-111: 'find candles' → find candle (singularized)", function()
    local v, n = preprocess.natural_language("find candles")
    eq("find", v)
    eq("candle", n, "'candles' should singularize to 'candle'")
end)

test("BUG-111: 'search for matchbox' unchanged (already singular)", function()
    local v, n = preprocess.natural_language("search for matchbox")
    eq("search", v)
    eq("matchbox", n, "Already singular noun should not be changed")
end)

test("BUG-111: 'find key' unchanged (already singular)", function()
    local v, n = preprocess.natural_language("find key")
    eq("find", v)
    eq("key", n, "Already singular noun should not be changed")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
