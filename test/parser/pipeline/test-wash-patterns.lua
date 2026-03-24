-- test/parser/pipeline/test-wash-patterns.lua
-- Issue #112: Unit tests for wash verb aliases and preprocess patterns.
-- Tests: clean→wash, rinse→wash, scrub→wash, "wash X in Y", gerunds.
--
-- Usage: lua test/parser/pipeline/test-wash-patterns.lua

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
h.suite("#112: transform_compound_actions — wash synonym verbs")
-------------------------------------------------------------------------------

test("'clean bandage' → 'wash bandage'", function()
    eq("wash bandage", transform("clean bandage"))
end)

test("'rinse bandage' → 'wash bandage'", function()
    eq("wash bandage", transform("rinse bandage"))
end)

test("'scrub bandage' → 'wash bandage'", function()
    eq("wash bandage", transform("scrub bandage"))
end)

test("'clean hands' → 'wash hands'", function()
    eq("wash hands", transform("clean hands"))
end)

test("'rinse cloth' → 'wash cloth'", function()
    eq("wash cloth", transform("rinse cloth"))
end)

-------------------------------------------------------------------------------
h.suite("#112: transform_compound_actions — 'wash X in Y'")
-------------------------------------------------------------------------------

test("'wash bandage in barrel' → 'wash bandage in barrel'", function()
    eq("wash bandage in barrel", transform("wash bandage in barrel"))
end)

test("'wash bandage in rain barrel' → 'wash bandage in rain barrel'", function()
    eq("wash bandage in rain barrel", transform("wash bandage in rain barrel"))
end)

test("'wash bandage with water' → 'wash bandage in water'", function()
    eq("wash bandage in water", transform("wash bandage with water"))
end)

-------------------------------------------------------------------------------
h.suite("#112: transform_compound_actions — synonym + preposition combos")
-------------------------------------------------------------------------------

test("'clean bandage in barrel' → 'wash bandage in barrel'", function()
    eq("wash bandage in barrel", transform("clean bandage in barrel"))
end)

test("'rinse bandage in water' → 'wash bandage in water'", function()
    eq("wash bandage in water", transform("rinse bandage in water"))
end)

test("'scrub bandage with water' → 'wash bandage in water'", function()
    eq("wash bandage in water", transform("scrub bandage with water"))
end)

-------------------------------------------------------------------------------
h.suite("#112: full pipeline — wash patterns")
-------------------------------------------------------------------------------

local function pipeline(input)
    local v, n = preprocess.natural_language(input)
    if v then return v .. " " .. n end
    v, n = preprocess.parse(input)
    return v .. " " .. n
end

test("pipeline: 'wash bandage' → 'wash bandage'", function()
    eq("wash bandage", pipeline("wash bandage"))
end)

test("pipeline: 'Clean the bandage' → 'wash the bandage'", function()
    eq("wash the bandage", pipeline("Clean the bandage"))
end)

test("pipeline: 'Rinse bandage in barrel' → 'wash bandage in barrel'", function()
    eq("wash bandage in barrel", pipeline("Rinse bandage in barrel"))
end)

test("pipeline: 'please wash bandage' → 'wash bandage'", function()
    eq("wash bandage", pipeline("please wash bandage"))
end)

test("pipeline: 'Scrub the cloth with water' → 'wash the cloth in water'", function()
    eq("wash the cloth in water", pipeline("Scrub the cloth with water"))
end)

-------------------------------------------------------------------------------
h.suite("#112: regression — bare 'wash X' still works")
-------------------------------------------------------------------------------

test("bare 'wash bandage' passes through unchanged", function()
    eq("wash bandage", transform("wash bandage"))
end)

test("bare 'wash' passes through unchanged", function()
    eq("wash", transform("wash"))
end)

-------------------------------------------------------------------------------
h.suite("#112: gerund — 'washing/cleaning/rinsing/scrubbing' strips to base verb")
-------------------------------------------------------------------------------

test("'washing bandage' → 'wash bandage'", function()
    eq("wash bandage", pipeline("washing bandage"))
end)

test("'cleaning bandage in barrel' → 'wash bandage in barrel'", function()
    eq("wash bandage in barrel", pipeline("cleaning bandage in barrel"))
end)

test("'rinsing cloth' → 'wash cloth'", function()
    eq("wash cloth", pipeline("rinsing cloth"))
end)

test("'scrubbing hands' → 'wash hands'", function()
    eq("wash hands", pipeline("scrubbing hands"))
end)

h.summary()
