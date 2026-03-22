-- test/parser/pipeline/test-expand-idioms.lua
-- Unit tests for Tier 3 idiom expansion pipeline stage.
-- Tests all idiom patterns and ensures table-driven extensibility.

local script_dir = arg[0]:match("(.+)[/\\][^/\\]+$") or "."
package.path = script_dir .. "/../../../src/?.lua;"
             .. script_dir .. "/../../../src/?/init.lua;"
             .. script_dir .. "/../../?.lua;"
             .. package.path

local h = require("test.parser.test-helpers")
local preprocess = require("engine.parser.preprocess")

local test = h.test
local eq   = h.assert_eq
local truthy = h.assert_truthy

local expand_idioms = preprocess.stages.expand_idioms

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — expand_idioms stage")
-------------------------------------------------------------------------------

test("'set fire to candle' → 'light candle'", function()
    local result = expand_idioms("set fire to candle")
    eq("light candle", result)
end)

test("'set fire to the torch' → 'light the torch'", function()
    local result = expand_idioms("set fire to the torch")
    eq("light the torch", result)
end)

test("'put down sword' → 'drop sword'", function()
    local result = expand_idioms("put down sword")
    eq("drop sword", result)
end)

test("'put down the matchbox' → 'drop the matchbox'", function()
    local result = expand_idioms("put down the matchbox")
    eq("drop the matchbox", result)
end)

test("'blow out candle' → 'extinguish candle'", function()
    local result = expand_idioms("blow out candle")
    eq("extinguish candle", result)
end)

test("'have a look' → 'look'", function()
    local result = expand_idioms("have a look")
    eq("look", result)
end)

test("'take a look' → 'look'", function()
    local result = expand_idioms("take a look")
    eq("look", result)
end)

test("'take a peek' → 'look'", function()
    local result = expand_idioms("take a peek")
    eq("look", result)
end)

test("'have a look at nightstand' → 'examine nightstand'", function()
    local result = expand_idioms("have a look at nightstand")
    eq("examine nightstand", result)
end)

test("'take a look at the bed' → 'examine the bed'", function()
    local result = expand_idioms("take a look at the bed")
    eq("examine the bed", result)
end)

test("'take a peek at wardrobe' → 'examine wardrobe'", function()
    local result = expand_idioms("take a peek at wardrobe")
    eq("examine wardrobe", result)
end)

test("'get rid of bottle' → 'drop bottle'", function()
    local result = expand_idioms("get rid of bottle")
    eq("drop bottle", result)
end)

test("'make use of crowbar' → 'use crowbar'", function()
    local result = expand_idioms("make use of crowbar")
    eq("use crowbar", result)
end)

test("'go to sleep' → 'sleep'", function()
    local result = expand_idioms("go to sleep")
    eq("sleep", result)
end)

test("'lay down' → 'sleep'", function()
    local result = expand_idioms("lay down")
    eq("sleep", result)
end)

test("'lie down' → 'sleep'", function()
    local result = expand_idioms("lie down")
    eq("sleep", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — non-matching input passes through")
-------------------------------------------------------------------------------

test("non-matching input unchanged", function()
    local result = expand_idioms("open wardrobe")
    eq("open wardrobe", result)
end)

test("partial idiom match does not transform", function()
    local result = expand_idioms("set fire")
    eq("set fire", result)
end)

test("empty string passes through", function()
    local result = expand_idioms("")
    eq("", result)
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — full pipeline integration")
-------------------------------------------------------------------------------

test("pipeline: 'please set fire to the candle' → light candle", function()
    local v, n = preprocess.natural_language("please set fire to the candle")
    eq("light", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

test("pipeline: 'could you put down the sword' → drop sword", function()
    local v, n = preprocess.natural_language("could you put down the sword")
    eq("drop", v)
    truthy(n and n:find("sword"), "Should target sword")
end)

test("pipeline: 'I want to have a look' → look", function()
    local v, n = preprocess.natural_language("I want to have a look")
    eq("look", v)
    eq("", n)
end)

test("pipeline: 'take a peek at the nightstand' → examine nightstand", function()
    local v, n = preprocess.natural_language("take a peek at the nightstand")
    eq("examine", v)
    truthy(n and n:find("nightstand"), "Should target nightstand")
end)

test("pipeline: 'get rid of the bottle' → drop bottle", function()
    local v, n = preprocess.natural_language("get rid of the bottle")
    eq("drop", v)
    truthy(n and n:find("bottle"), "Should target bottle")
end)

test("pipeline: 'make use of the key' → use key", function()
    local v, n = preprocess.natural_language("make use of the key")
    eq("use", v)
    truthy(n and n:find("key"), "Should target key")
end)

test("pipeline: 'blow out the candle' → extinguish candle", function()
    local v, n = preprocess.natural_language("blow out the candle")
    eq("extinguish", v)
    truthy(n and n:find("candle"), "Should target candle")
end)

-------------------------------------------------------------------------------
h.suite("Tier 3: Idiom Library — IDIOM_TABLE is extensible")
-------------------------------------------------------------------------------

test("IDIOM_TABLE is accessible from preprocess module", function()
    truthy(preprocess.IDIOM_TABLE, "IDIOM_TABLE should be exposed")
    truthy(#preprocess.IDIOM_TABLE > 0, "IDIOM_TABLE should have entries")
end)

test("adding custom idiom works at runtime", function()
    local original_len = #preprocess.IDIOM_TABLE
    table.insert(preprocess.IDIOM_TABLE, {
        pattern = "^chuck%s+(.+)$",
        replacement = "throw %1"
    })
    local result = expand_idioms("chuck ball")
    eq("throw ball", result)
    -- Clean up
    table.remove(preprocess.IDIOM_TABLE)
    eq(original_len, #preprocess.IDIOM_TABLE)
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
