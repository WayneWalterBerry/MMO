-- test/parser/pipeline/test-pipeline-integration.lua
-- Integration tests for the full preprocessing pipeline end-to-end.
-- Calls preprocess.natural_language() to verify stages compose correctly.

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

-------------------------------------------------------------------------------
h.suite("Pipeline Integration: complex multi-stage reductions")
-------------------------------------------------------------------------------

test("'Please carefully search the nightstand for the matchbox' → clean command", function()
    local v, n = preprocess.natural_language("Please carefully search the nightstand for the matchbox")
    eq("search", v, "Verb should be search")
    truthy(n and n:find("nightstand"), "Should target nightstand")
    truthy(n and n:find("matchbox"), "Should include matchbox target")
end)

test("'Could you please look at the nightstand?' → examine nightstand", function()
    local v, n = preprocess.natural_language("Could you please look at the nightstand?")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("'I want to carefully search for the matchbox' → search matchbox", function()
    local v, n = preprocess.natural_language("I want to carefully search for the matchbox")
    eq("search", v)
    eq("matchbox", n)
end)

test("'PLEASE LOOK AROUND' → look (uppercase + politeness)", function()
    local v, n = preprocess.natural_language("PLEASE LOOK AROUND")
    eq("look", v)
    eq("", n)
end)

test("'What's in the nightstand?' → examine nightstand (question + normalize)", function()
    local v, n = preprocess.natural_language("What's in the nightstand?")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("'could you try to quickly open the crate' → open crate", function()
    local v, n = preprocess.natural_language("could you try to quickly open the crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("'I'd like to pry open the crate' → open crate (preamble + compound)", function()
    local v, n = preprocess.natural_language("I'd like to pry open the crate")
    eq("open", v)
    truthy(n and n:find("crate"), "Should target crate")
end)

test("'please find everything' → search sweep", function()
    local v, n = preprocess.natural_language("please find everything")
    eq("search", v)
    truthy(n == "" or n == "around" or n == nil,
           "sweep should produce empty/around target")
end)

test("'Could you check the nightstand?' → examine nightstand", function()
    local v, n = preprocess.natural_language("Could you check the nightstand?")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("'I want to look for the key' → find key (preamble + look for)", function()
    local v, n = preprocess.natural_language("I want to look for the key")
    eq("find", v)
    eq("key", n)
end)

test("'please slowly hunt for matches' → search matches", function()
    local v, n = preprocess.natural_language("please slowly hunt for matches")
    eq("search", v)
    eq("matches", n)
end)

test("'Would you thoroughly rummage around?' → search around", function()
    local v, n = preprocess.natural_language("Would you thoroughly rummage around?")
    eq("search", v)
    truthy(n == "around" or n == "", "Should produce 'around' or empty target")
end)

test("'CAREFULLY PUT OUT THE CANDLE' → extinguish candle", function()
    local v, n = preprocess.natural_language("CAREFULLY PUT OUT THE CANDLE")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("'I want to take off the gloves' → remove gloves", function()
    local v, n = preprocess.natural_language("I want to take off the gloves")
    eq("remove", v)
    truthy(n and n:find("gloves"), "Should target gloves")
end)

test("'WHAT AM I HOLDING?' → inventory", function()
    local v, n = preprocess.natural_language("WHAT AM I HOLDING?")
    eq("inventory", v)
    eq("", n)
end)

test("'WHERE AM I?' → look", function()
    local v, n = preprocess.natural_language("WHERE AM I?")
    eq("look", v)
    eq("", n)
end)

-------------------------------------------------------------------------------
h.suite("Pipeline Integration: stage ordering verification")
-------------------------------------------------------------------------------

test("normalize runs before strip_filler (case stripped then politeness)", function()
    local v, n = preprocess.natural_language("PLEASE LOOK AROUND")
    eq("look", v, "Must lowercase before stripping 'please'")
end)

test("strip_filler runs before transform_questions (politeness then question)", function()
    -- "could you" is stripped by filler, not needed for question transform
    local v, n = preprocess.natural_language("Could you please look around?")
    eq("look", v, "Politeness stripped then look around handled")
end)

test("transform_questions runs before transform_look_patterns", function()
    -- "what's in X" is handled by questions stage, not look patterns
    local v, n = preprocess.natural_language("What's in the nightstand?")
    eq("examine", v, "Question transform should handle this before look patterns")
end)

test("transform_search_phrases runs after transform_look_patterns", function()
    -- "look for X" → "find X" by look_patterns, then find handled by search_phrases
    local v, n = preprocess.natural_language("look for everything")
    -- look_for → find everything → search (sweep)
    eq("search", v, "look for everything should chain through look → find → search sweep")
end)

-------------------------------------------------------------------------------
h.suite("Pipeline Integration: disabled stage handling")
-------------------------------------------------------------------------------

test("disabled stage is skipped (nil in pipeline)", function()
    -- Save original pipeline
    local saved = {}
    for i, fn in ipairs(preprocess.pipeline) do saved[i] = fn end

    -- Disable stage 2 (strip_filler) by setting to nil and compacting
    local disabled_stage = preprocess.pipeline[2]
    table.remove(preprocess.pipeline, 2)

    -- "please look" should NOT strip "please" since filler stripping is disabled
    local v, n = preprocess.natural_language("please look around")
    -- With filler stripping disabled, "please look around" won't match
    -- look_patterns stage will still see "please look around" which won't match
    -- It should either return nil (unrecognized) or pass through
    truthy(v == nil or v == "please",
           "With filler disabled, 'please' should remain; got: " .. tostring(v))

    -- Restore pipeline
    for i = 1, #preprocess.pipeline do preprocess.pipeline[i] = nil end
    for i, fn in ipairs(saved) do preprocess.pipeline[i] = fn end
end)

-------------------------------------------------------------------------------
h.suite("Pipeline Integration: edge cases")
-------------------------------------------------------------------------------

test("empty string returns nil", function()
    local v, n = preprocess.natural_language("")
    h.assert_nil(v, "empty input should return nil verb")
end)

test("nil input returns nil", function()
    local v, n = preprocess.natural_language(nil)
    h.assert_nil(v, "nil input should return nil verb")
end)

test("whitespace-only returns nil", function()
    local v, n = preprocess.natural_language("   ")
    h.assert_nil(v, "whitespace-only should return nil verb")
end)

test("unrecognized phrase returns nil", function()
    local v, n = preprocess.natural_language("examine nightstand")
    h.assert_nil(v, "unrecognized bare verb+noun should return nil")
end)

test("question mark stripped before question transform", function()
    local v, n = preprocess.natural_language("Where am I???")
    eq("look", v, "Multiple question marks stripped then recognized")
end)

test("full pipeline: 'I'd like to carefully check the nightstand' → examine", function()
    local v, n = preprocess.natural_language("I'd like to carefully check the nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("full pipeline: 'Try to gently blow out the candle' → extinguish", function()
    local v, n = preprocess.natural_language("Try to gently blow out the candle")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
