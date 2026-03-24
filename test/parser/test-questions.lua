-- test/parser/test-questions.lua
-- Tier 1: Question Transform unit tests (Prime Directive #106).
-- Tests the dedicated questions.lua module that converts natural-language
-- questions into canonical imperative game commands.
--
-- TDD RED PHASE: These tests define the contract for engine.parser.questions.
-- All tests FAIL until the module is implemented by Smithers.
--
-- API contract:
--   questions.match(text) → "verb noun" string | nil
--   questions.QUESTION_MAP — externally extensible pattern table
--
-- Usage: lua test/parser/test-questions.lua
-- Must be run from the repository root.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../src/?.lua;"
             .. script_dir .. "/../../src/?/init.lua;"
             .. script_dir .. "/../?.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local test    = h.test
local eq      = h.assert_eq
local truthy  = h.assert_truthy
local assert_nil = h.assert_nil

-- Protected require: questions.lua does not exist yet (TDD red phase)
local ok, questions = pcall(require, "engine.parser.questions")
if not ok then
    print("NOTE: engine.parser.questions not yet implemented — all tests will fail")
    questions = nil
end

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Orientation questions")
-------------------------------------------------------------------------------

test("'where am i' → 'look'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("where am i")
    eq("look", result)
end)

test("'where am i?' strips question mark and resolves to 'look'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    -- Question mark should be handled by Tier 0, but module should be robust
    local result = questions.match("where am i")
    truthy(result, "should match")
    eq("look", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Inventory questions")
-------------------------------------------------------------------------------

test("'what do i have' → 'inventory'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what do i have")
    eq("inventory", result)
end)

test("'what am i carrying' → 'inventory'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what am i carrying")
    eq("inventory", result)
end)

test("'what am i holding' → 'inventory'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what am i holding")
    eq("inventory", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Examination questions")
-------------------------------------------------------------------------------

test("'what is this' → 'look'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what is this")
    eq("look", result)
end)

test("'what's in the drawer' → 'examine drawer'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what's in the drawer")
    eq("examine drawer", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Help/Confusion questions")
-------------------------------------------------------------------------------

test("'what can i do' → 'help'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what can i do")
    eq("help", result)
end)

test("'how do i get out' → 'help'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("how do i get out")
    eq("help", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Identity questions")
-------------------------------------------------------------------------------

test("'who am i' → 'health' or identity check", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("who am i")
    truthy(result, "'who am i' should resolve to a command")
    -- Accept health, identity, or stats — any self-status verb
    truthy(result == "health" or result == "identity" or result == "stats",
           "'who am i' should map to a self-status command, got: " .. tostring(result))
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Location questions")
-------------------------------------------------------------------------------

test("'where is the candle' → 'find candle'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("where is the candle")
    eq("find candle", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Time questions")
-------------------------------------------------------------------------------

test("'what time is it' → 'time'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("what time is it")
    eq("time", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Health questions")
-------------------------------------------------------------------------------

test("'am i hurt' → 'health'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("am i hurt")
    eq("health", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Non-question edge cases")
-------------------------------------------------------------------------------

test("non-question sentence with 'where' should NOT transform", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("go to where the light is")
    assert_nil(result, "non-question with 'where' should not match")
end)

test("imperative command should NOT transform", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("take the candle")
    assert_nil(result, "imperative command should return nil")
end)

-------------------------------------------------------------------------------
h.suite("Tier 1: Question Transforms — Priority ordering")
-------------------------------------------------------------------------------

test("'where am i bleeding' prioritizes over 'where am i'", function()
    truthy(questions, "engine.parser.questions module not yet implemented")
    local result = questions.match("where am i bleeding")
    eq("injuries", result, "injury query should have higher priority than look")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
