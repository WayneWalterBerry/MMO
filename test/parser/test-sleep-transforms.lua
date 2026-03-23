-- test/parser/test-sleep-transforms.lua
-- Regression tests for play-test bug #42:
-- "sleep to dawn", "sleep til dawn", "sleep till dawn" not recognized.
-- These should all transform to "sleep until dawn/morning/etc."

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
h.suite("#42 — 'sleep to/til/till dawn' → 'sleep until dawn'")
-------------------------------------------------------------------------------

test("#42: 'sleep to dawn' → sleep until dawn", function()
    local v, n = preprocess.natural_language("sleep to dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should transform 'to' → 'until'. Got: " .. tostring(n))
end)

test("#42: 'sleep til dawn' → sleep until dawn", function()
    local v, n = preprocess.natural_language("sleep til dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should transform 'til' → 'until'. Got: " .. tostring(n))
end)

test("#42: 'sleep till dawn' → sleep until dawn", function()
    local v, n = preprocess.natural_language("sleep till dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should transform 'till' → 'until'. Got: " .. tostring(n))
end)

test("#42: 'sleep to morning' → sleep until morning", function()
    local v, n = preprocess.natural_language("sleep to morning")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+morning"), "Should transform 'to morning' → 'until morning'. Got: " .. tostring(n))
end)

test("#42: 'sleep til morning' → sleep until morning", function()
    local v, n = preprocess.natural_language("sleep til morning")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+morning"), "Should transform 'til morning' → 'until morning'. Got: " .. tostring(n))
end)

test("#42: 'sleep till morning' → sleep until morning", function()
    local v, n = preprocess.natural_language("sleep till morning")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+morning"), "Should transform 'till morning' → 'until morning'. Got: " .. tostring(n))
end)

test("#42: Existing 'sleep until dawn' still works (already canonical)", function()
    -- "sleep until dawn" is already canonical — no pipeline transform fires
    -- Falls through to parse() which correctly splits verb/noun
    local v, n = preprocess.parse("sleep until dawn")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+dawn"), "Should preserve 'until dawn'. Got: " .. tostring(n))
end)

test("#42: 'sleep to night' → sleep until night", function()
    local v, n = preprocess.natural_language("sleep to night")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("until%s+night"), "Should transform 'to night' → 'until night'. Got: " .. tostring(n))
end)

test("#42: Existing 'go to sleep' idiom still works", function()
    local v, n = preprocess.natural_language("go to sleep")
    eq("sleep", v, "Should transform to sleep verb")
    eq("", n, "'go to sleep' should have empty noun")
end)

test("#42: 'sleep for 2 hours' NOT affected by to/til/till transforms", function()
    -- "sleep for 2 hours" is already canonical — no idiom transform fires
    local v, n = preprocess.parse("sleep for 2 hours")
    eq("sleep", v, "Should parse as sleep verb")
    truthy(n and n:find("2"), "Should preserve duration. Got: " .. tostring(n))
end)

-------------------------------------------------------------------------------

h.summary()
