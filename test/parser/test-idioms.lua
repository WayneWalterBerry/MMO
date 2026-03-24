-- test/parser/test-idioms.lua
-- Tier 3: Idiom Library unit tests (Prime Directive #106).
-- Tests the dedicated idioms.lua module that expands natural English
-- phrases into canonical game commands.
--
-- TDD RED PHASE: These tests define the contract for engine.parser.idioms.
-- All tests FAIL until the module is implemented by Smithers.
--
-- API contract:
--   idioms.match(text) → result_text, matched_bool
--   idioms.IDIOM_TABLE  — externally extensible pattern table
--
-- Usage: lua test/parser/test-idioms.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../?.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local test   = h.test
local eq     = h.assert_eq
local truthy = h.assert_truthy

-- Protected require: idioms.lua does not exist yet (TDD red phase)
local ok, idioms = pcall(require, "engine.parser.idioms")
if not ok then
    print("NOTE: engine.parser.idioms not yet implemented — all tests will fail")
    idioms = nil
end

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Look/Examine idioms")
-------------------------------------------------------------------------------

test("'take a look' → 'look'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("take a look")
    eq("look", result)
end)

test("'take a look at candle' → 'examine candle'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("take a look at candle")
    eq("examine candle", result)
end)

test("'have a look' → 'look'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("have a look")
    eq("look", result)
end)

test("'check it out' → 'examine it'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("check it out")
    eq("examine it", result)
end)

test("'check out the mirror' → 'examine the mirror'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("check out the mirror")
    eq("examine the mirror", result)
end)

test("'study the rug' → 'examine the rug'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("study the rug")
    eq("examine the rug", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Get/Take idioms")
-------------------------------------------------------------------------------

test("'pick it up' → 'get it'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("pick it up")
    eq("get it", result)
end)

test("'pick up the candle' → 'get the candle'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("pick up the candle")
    eq("get the candle", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Drop/Discard idioms")
-------------------------------------------------------------------------------

test("'put it down' → 'drop it'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("put it down")
    eq("drop it", result)
end)

test("'get rid of candle' → 'drop candle'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("get rid of candle")
    eq("drop candle", result)
end)

test("'ditch the key' → 'drop the key'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("ditch the key")
    eq("drop the key", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Sit/Rest/Sleep idioms")
-------------------------------------------------------------------------------

test("'have a seat' → 'sit'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("have a seat")
    eq("sit", result)
end)

test("'go to sleep' → 'sleep'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("go to sleep")
    eq("sleep", result)
end)

test("'have a rest' → 'sleep'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("have a rest")
    eq("sleep", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Fire/Light idioms")
-------------------------------------------------------------------------------

test("'set fire to candle' → 'light candle'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("set fire to candle")
    eq("light candle", result)
end)

test("'blow out candle' → 'extinguish candle'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("blow out candle")
    eq("extinguish candle", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Sensory idioms")
-------------------------------------------------------------------------------

test("'give it a sniff' → 'smell it'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("give it a sniff")
    eq("smell it", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Manipulation idioms")
-------------------------------------------------------------------------------

test("'toss candle' → 'throw candle'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("toss candle")
    eq("throw candle", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — Meta idioms")
-------------------------------------------------------------------------------

test("'check my pockets' → 'inventory'", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result = idioms.match("check my pockets")
    eq("inventory", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — False positive prevention")
-------------------------------------------------------------------------------

test("'get candle and matchbox' must NOT be split by idiom", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result, matched = idioms.match("get candle and matchbox")
    eq("get candle and matchbox", result, "compound command must pass through unchanged")
end)

test("unrecognized phrase passes through unchanged", function()
    truthy(idioms, "engine.parser.idioms module not yet implemented")
    local result, matched = idioms.match("xyzzy")
    eq("xyzzy", result, "unrecognized input should pass through")
    eq(false, matched, "unrecognized input should not flag as matched")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
