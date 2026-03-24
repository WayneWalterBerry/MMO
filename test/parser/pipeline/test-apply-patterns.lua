-- test/parser/pipeline/test-apply-patterns.lua
-- Issue #109: Unit tests for "apply X to Y", "rub X on Y", "use X on Y" patterns.
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
h.suite("#109: transform_compound_actions — 'apply X to Y' (canonical)")
-------------------------------------------------------------------------------

test("'apply salve to wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", transform("apply salve to wound"))
end)

test("'apply bandage to arm' → 'apply bandage to arm'", function()
    eq("apply bandage to arm", transform("apply bandage to arm"))
end)

test("'apply poultice to cut' → 'apply poultice to cut'", function()
    eq("apply poultice to cut", transform("apply poultice to cut"))
end)

-------------------------------------------------------------------------------
h.suite("#109: transform_compound_actions — 'rub X on Y' → apply")
-------------------------------------------------------------------------------

test("'rub salve on wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", transform("rub salve on wound"))
end)

test("'rub bandage on arm' → 'apply bandage to arm'", function()
    eq("apply bandage to arm", transform("rub bandage on arm"))
end)

test("'rub ointment on cut' → 'apply ointment to cut'", function()
    eq("apply ointment to cut", transform("rub ointment on cut"))
end)

-------------------------------------------------------------------------------
h.suite("#109: transform_compound_actions — 'rub X to/into Y' variants")
-------------------------------------------------------------------------------

test("'rub salve to wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", transform("rub salve to wound"))
end)

test("'rub salve into wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", transform("rub salve into wound"))
end)

-------------------------------------------------------------------------------
h.suite("#109: transform_compound_actions — 'use X on Y' → apply")
-------------------------------------------------------------------------------

test("'use salve on wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", transform("use salve on wound"))
end)

test("'use bandage on arm' → 'apply bandage to arm'", function()
    eq("apply bandage to arm", transform("use bandage on arm"))
end)

test("'use poultice on cut' → 'apply poultice to cut'", function()
    eq("apply poultice to cut", transform("use poultice on cut"))
end)

-------------------------------------------------------------------------------
h.suite("#109: 'use X on Y' — specific tools still dispatch correctly")
-------------------------------------------------------------------------------

test("'use needle on cloth' → 'sew cloth with needle' (not apply)", function()
    eq("sew cloth with needle", transform("use needle on cloth"))
end)

test("'use key on door' → 'unlock door with key' (not apply)", function()
    eq("unlock door with key", transform("use key on door"))
end)

test("'use match on candle' → 'light candle with match' (not apply)", function()
    eq("light candle with match", transform("use match on candle"))
end)

-------------------------------------------------------------------------------
h.suite("#109: full pipeline — apply patterns")
-------------------------------------------------------------------------------

local function pipeline(input)
    local v, n = preprocess.natural_language(input)
    if v then return v .. " " .. n end
    v, n = preprocess.parse(input)
    return v .. " " .. n
end

test("pipeline: 'apply salve to wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", pipeline("apply salve to wound"))
end)

test("pipeline: 'Apply bandage to arm' → 'apply bandage to arm'", function()
    eq("apply bandage to arm", pipeline("Apply bandage to arm"))
end)

test("pipeline: 'rub salve on wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", pipeline("rub salve on wound"))
end)

test("pipeline: 'use salve on wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", pipeline("use salve on wound"))
end)

test("pipeline: 'please apply salve to wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", pipeline("please apply salve to wound"))
end)

test("pipeline: 'Rub the ointment on the cut' → 'apply the ointment to the cut'", function()
    eq("apply the ointment to the cut", pipeline("Rub the ointment on the cut"))
end)

-------------------------------------------------------------------------------
h.suite("#109: regression — bare 'apply X' still works")
-------------------------------------------------------------------------------

test("bare 'apply salve' passes through unchanged", function()
    eq("apply salve", transform("apply salve"))
end)

test("bare 'apply' passes through unchanged", function()
    eq("apply", transform("apply"))
end)

test("bare 'rub salve' passes through unchanged", function()
    eq("rub salve", transform("rub salve"))
end)

-------------------------------------------------------------------------------
h.suite("#109: gerunds — 'applying/rubbing' strips to base verb")
-------------------------------------------------------------------------------

test("'applying salve to wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", pipeline("applying salve to wound"))
end)

test("'rubbing salve on wound' → 'apply salve to wound'", function()
    eq("apply salve to wound", pipeline("rubbing salve on wound"))
end)

h.summary()
