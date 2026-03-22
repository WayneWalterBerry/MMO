-- test/parser/test-preprocess-phrases.lua
-- Regression tests for Pass-025 and Pass-026 bug findings.
-- Tests natural language phrase preprocessing: article stripping, politeness
-- removal, adverb removal, question transforms, synonym recognition.
--
-- Bug IDs tested: BUG-074, BUG-078, BUG-081, BUG-082, BUG-083, BUG-084,
--                 BUG-085, BUG-086, BUG-087, BUG-088

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

-------------------------------------------------------------------------------
h.suite("1. LOOK AT / CHECK → EXAMINE (BUG-086, BUG-087)")
-------------------------------------------------------------------------------

test("BUG-087: 'look at nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("look at nightstand")
    eq("examine", v, "Should convert 'look at X' to 'examine X'")
    eq("nightstand", n, "Should extract nightstand as target")
end)

test("BUG-087: 'look at the bed' → examine bed (article stripped)", function()
    local v, n = preprocess.natural_language("look at the bed")
    eq("examine", v, "Should convert 'look at X' to 'examine X'")
    -- noun may or may not have article; core test is verb conversion
    truthy(n and n:find("bed"), "Should target bed")
end)

test("BUG-086: 'check the nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("check the nightstand")
    eq("examine", v, "Should convert 'check X' to 'examine X'")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("BUG-086: 'check nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("check nightstand")
    eq("examine", v, "Should convert bare 'check X' to 'examine X'")
    eq("nightstand", n, "Should target nightstand")
end)

-------------------------------------------------------------------------------
h.suite("2. ARTICLE STRIPPING — 'the'/'a'/'an' from targets (BUG-081)")
-------------------------------------------------------------------------------

test("BUG-081: 'find the matchbox' → article 'the' stripped from target", function()
    local v, n = preprocess.natural_language("find the matchbox")
    eq("find", v, "Should be find verb")
    eq("matchbox", n, "Article 'the' should be stripped from target")
end)

test("BUG-081: 'find a candle' → article 'a' stripped from target", function()
    local v, n = preprocess.natural_language("find a candle")
    eq("find", v, "Should be find verb")
    eq("candle", n, "Article 'a' should be stripped from target")
end)

test("BUG-081: 'find an apple' → article 'an' stripped from target", function()
    local v, n = preprocess.natural_language("find an apple")
    eq("find", v, "Should be find verb")
    eq("apple", n, "Article 'an' should be stripped from target")
end)

test("BUG-081: 'search for the matchbox' → article stripped from target", function()
    local v, n = preprocess.natural_language("search for the matchbox")
    eq("search", v, "Should be search verb")
    eq("matchbox", n, "Article 'the' should be stripped from 'search for' target")
end)

-------------------------------------------------------------------------------
h.suite("3. LOOK FOR → FIND conversion (BUG-074 regression)")
-------------------------------------------------------------------------------

test("BUG-074 regression: 'look for a candle' → find candle", function()
    local v, n = preprocess.natural_language("look for a candle")
    eq("find", v, "Should convert 'look for' to 'find'")
    eq("candle", n, "Article 'a' should be stripped from target")
end)

test("BUG-074 regression: 'look for matches' → find matches", function()
    local v, n = preprocess.natural_language("look for matches")
    eq("find", v, "Should convert 'look for' to 'find'")
    eq("matches", n, "Target should be 'matches'")
end)

test("BUG-074 regression: 'look for the key' → find key", function()
    local v, n = preprocess.natural_language("look for the key")
    eq("find", v, "Should convert 'look for' to 'find'")
    eq("key", n, "Article 'the' should be stripped")
end)

-------------------------------------------------------------------------------
h.suite("4. POLITENESS STRIPPING (BUG-083)")
-------------------------------------------------------------------------------

test("BUG-083: 'could you search for matches' → search matches", function()
    local v, n = preprocess.natural_language("could you search for matches")
    eq("search", v, "Should strip 'could you' and parse 'search for matches'")
    eq("matches", n, "Should extract 'matches' as target")
end)

test("'please search the nightstand' → search nightstand (verified pass)", function()
    local v, n = preprocess.natural_language("please search the nightstand")
    eq("search", v, "Should strip 'please'")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("'can I search the room' → search room (verified pass)", function()
    local v, n = preprocess.natural_language("can I search the room")
    eq("search", v, "Should strip 'can I'")
    truthy(n and (n:find("room") or n == "around" or n == ""),
           "Should trigger room sweep or pass 'room'")
end)

test("'could you find the matchbox' → find matchbox", function()
    local v, n = preprocess.natural_language("could you find the matchbox")
    eq("find", v, "Should strip 'could you'")
    eq("matchbox", n, "Should extract target without article")
end)

-------------------------------------------------------------------------------
h.suite("5. ADVERB STRIPPING (BUG-085)")
-------------------------------------------------------------------------------

test("BUG-085: 'thoroughly search the room' → search room", function()
    local v, n = preprocess.natural_language("thoroughly search the room")
    eq("search", v, "Should strip adverb 'thoroughly'")
    truthy(n and (n:find("room") or n == "around" or n == ""),
           "Should pass room target or trigger sweep")
end)

test("'carefully search the nightstand' → search nightstand (verified pass)", function()
    local v, n = preprocess.natural_language("carefully search the nightstand")
    eq("search", v, "Should strip adverb 'carefully'")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("BUG-085: 'quickly search around' → search around", function()
    local v, n = preprocess.natural_language("quickly search around")
    eq("search", v, "Should strip adverb 'quickly'")
    eq("around", n, "Should preserve 'around'")
end)

test("BUG-085: 'slowly open the drawer' → open drawer", function()
    local v, n = preprocess.natural_language("slowly open the drawer")
    eq("open", v, "Should strip adverb 'slowly'")
    truthy(n and n:find("drawer"), "Should target drawer")
end)

-------------------------------------------------------------------------------
h.suite("6. SWEEP KEYWORDS — 'everything'/'anything' (BUG-078)")
-------------------------------------------------------------------------------

test("BUG-078: 'find everything' → triggers sweep, not literal target", function()
    local v, n = preprocess.natural_language("find everything")
    -- "everything" should either map to sweep (no target) or be handled
    -- It must NOT be treated as a literal target name "everything"
    eq("search", v, "Should convert 'find everything' to search sweep")
    truthy(n == "" or n == "around" or n == nil,
           "Target should be empty/around for sweep, not 'everything'")
end)

test("BUG-078: 'find anything' → triggers sweep", function()
    local v, n = preprocess.natural_language("find anything")
    eq("search", v, "Should convert 'find anything' to search sweep")
    truthy(n == "" or n == "around" or n == nil,
           "Target should be empty/around for sweep, not 'anything'")
end)

test("BUG-078: 'search for everything' → sweep", function()
    local v, n = preprocess.natural_language("search for everything")
    eq("search", v, "Should remain search verb")
    truthy(n == "" or n == "around" or n == nil,
           "'everything' should trigger sweep")
end)

-------------------------------------------------------------------------------
h.suite("7. QUESTION TRANSFORMS (BUG-082, BUG-084)")
-------------------------------------------------------------------------------

test("BUG-084: 'what can I find?' → search sweep (no hang)", function()
    local v, n = preprocess.natural_language("what can I find?")
    -- Should transform to a valid sweep command, not cause a hang
    truthy(v ~= nil, "Should return a valid verb (not nil)")
    truthy(v == "search" or v == "find" or v == "look",
           "Should transform to search/find/look, got: " .. tostring(v))
end)

test("'what's in the nightstand?' → examine nightstand (verified pass)", function()
    local v, n = preprocess.natural_language("what's in the nightstand?")
    eq("examine", v, "Should transform question to examine")
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("BUG-082: 'is there anything in the drawer?' → examine drawer", function()
    local v, n = preprocess.natural_language("is there anything in the drawer?")
    truthy(v ~= nil, "Should return a valid verb")
    truthy(v == "examine" or v == "search" or v == "feel",
           "Should transform to examine/search/feel, got: " .. tostring(v))
    truthy(n and n:find("drawer"),
           "Should target drawer, got: " .. tostring(n))
end)

test("'what's inside the wardrobe?' → examine wardrobe", function()
    local v, n = preprocess.natural_language("what's inside the wardrobe?")
    eq("examine", v, "Should transform to examine")
    truthy(n and n:find("wardrobe"), "Should target wardrobe")
end)

-------------------------------------------------------------------------------
h.suite("8. SYNONYM RECOGNITION — 'hunt for' (Pass-025 T-026)")
-------------------------------------------------------------------------------

test("'hunt for matches' → find/search matches", function()
    local v, n = preprocess.natural_language("hunt for matches")
    truthy(v == "find" or v == "search",
           "'hunt for' should be synonym for find/search, got: " .. tostring(v))
    eq("matches", n, "Should extract 'matches' as target")
end)

test("'hunt around' → search around", function()
    local v, n = preprocess.natural_language("hunt around")
    truthy(v == "search" or v == "find",
           "'hunt' should map to search/find, got: " .. tostring(v))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
