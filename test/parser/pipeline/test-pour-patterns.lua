-- test/parser/pipeline/test-pour-patterns.lua
-- Issue #108: Unit tests for "pour X into Y", "pour X in Y", "fill Y with X" patterns.
-- Tests both the individual stage function and full pipeline integration.

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

local transform = preprocess.stages.transform_compound_actions

-------------------------------------------------------------------------------
h.suite("#108: transform_compound_actions — 'pour X into Y'")
-------------------------------------------------------------------------------

test("'pour oil into lantern' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", transform("pour oil into lantern"))
end)

test("'pour water into bowl' → 'pour water into bowl'", function()
    eq("pour water into bowl", transform("pour water into bowl"))
end)

test("'pour wine into goblet' → 'pour wine into goblet'", function()
    eq("pour wine into goblet", transform("pour wine into goblet"))
end)

-------------------------------------------------------------------------------
h.suite("#108: transform_compound_actions — 'pour X in Y' shorthand")
-------------------------------------------------------------------------------

test("'pour oil in lantern' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", transform("pour oil in lantern"))
end)

test("'pour water in bowl' → 'pour water into bowl'", function()
    eq("pour water into bowl", transform("pour water in bowl"))
end)

-------------------------------------------------------------------------------
h.suite("#108: transform_compound_actions — 'fill Y with X' → reverse")
-------------------------------------------------------------------------------

test("'fill lantern with oil' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", transform("fill lantern with oil"))
end)

test("'fill bowl with water' → 'pour water into bowl'", function()
    eq("pour water into bowl", transform("fill bowl with water"))
end)

test("'fill goblet with wine' → 'pour wine into goblet'", function()
    eq("pour wine into goblet", transform("fill goblet with wine"))
end)

-------------------------------------------------------------------------------
h.suite("#108: full pipeline — pour/fill patterns")
-------------------------------------------------------------------------------

local function pipeline(input)
    local v, n = preprocess.natural_language(input)
    if v then return v .. " " .. n end
    v, n = preprocess.parse(input)
    return v .. " " .. n
end

test("pipeline: 'pour oil into lantern' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", pipeline("pour oil into lantern"))
end)

test("pipeline: 'Pour oil in lantern' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", pipeline("Pour oil in lantern"))
end)

test("pipeline: 'fill lantern with oil' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", pipeline("fill lantern with oil"))
end)

test("pipeline: 'please pour water into bowl' → 'pour water into bowl'", function()
    eq("pour water into bowl", pipeline("please pour water into bowl"))
end)

test("pipeline: 'Fill the goblet with wine' → 'pour wine into the goblet'", function()
    -- "the" survives in target; verb handler keyword matching ignores articles
    eq("pour wine into the goblet", pipeline("Fill the goblet with wine"))
end)

-------------------------------------------------------------------------------
h.suite("#108: regression — bare 'pour X' still works")
-------------------------------------------------------------------------------

test("bare 'pour wine' passes through unchanged", function()
    eq("pour wine", transform("pour wine"))
end)

test("bare 'pour' passes through unchanged", function()
    eq("pour", transform("pour"))
end)

-------------------------------------------------------------------------------
h.suite("#108: gerund — 'pouring/filling' strips to base verb")
-------------------------------------------------------------------------------

test("'pouring oil into lantern' → 'pour oil into lantern'", function()
    eq("pour oil into lantern", pipeline("pouring oil into lantern"))
end)

test("'filling bowl with water' → 'pour water into bowl'", function()
    eq("pour water into bowl", pipeline("filling bowl with water"))
end)

h.summary()
