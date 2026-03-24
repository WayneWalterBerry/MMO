-- test/parser/pipeline/test-transform-compound-actions.lua
-- Unit tests for Stage 6: transform_compound_actions (pry, use X on Y, put/take, pull, wear)
-- Tests the individual stage function in isolation.

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

local transform_compound_actions = preprocess.stages.transform_compound_actions

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'pry open X'")
-------------------------------------------------------------------------------

test("'pry open crate' → 'open crate'", function()
    eq("open crate", transform_compound_actions("pry open crate"))
end)

test("'pry open the door' → 'open the door'", function()
    eq("open the door", transform_compound_actions("pry open the door"))
end)

test("'pry open rusty lock' → 'open rusty lock'", function()
    eq("open rusty lock", transform_compound_actions("pry open rusty lock"))
end)

test("'pry open chest with crowbar' → 'open chest with crowbar'", function()
    eq("open chest with crowbar", transform_compound_actions("pry open chest with crowbar"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'pry X with Y' (BUG-049)")
-------------------------------------------------------------------------------

test("'pry crate with crowbar' → 'open crate with crowbar'", function()
    eq("open crate with crowbar", transform_compound_actions("pry crate with crowbar"))
end)

test("'pry door with bar' → 'open door with bar'", function()
    eq("open door with bar", transform_compound_actions("pry door with bar"))
end)

test("'pry lid with knife' → 'open lid with knife'", function()
    eq("open lid with knife", transform_compound_actions("pry lid with knife"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'force open X'")
-------------------------------------------------------------------------------

test("'force open crate' → 'open crate'", function()
    eq("open crate", transform_compound_actions("force open crate"))
end)

test("'force open the door' → 'open the door'", function()
    eq("open the door", transform_compound_actions("force open the door"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'use crowbar/bar on X'")
-------------------------------------------------------------------------------

test("'use crowbar on crate' → 'open crate'", function()
    eq("open crate", transform_compound_actions("use crowbar on crate"))
end)

test("'use bar on the door' → 'open the door'", function()
    eq("open the door", transform_compound_actions("use bar on the door"))
end)

test("'use prybar on crate' → 'open crate'", function()
    eq("open crate", transform_compound_actions("use prybar on crate"))
end)

test("'use pry bar on lock' → 'open lock'", function()
    eq("open lock", transform_compound_actions("use pry bar on lock"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'use X on Y' tool dispatch")
-------------------------------------------------------------------------------

test("'use key on door' → 'unlock door with key'", function()
    eq("unlock door with key", transform_compound_actions("use key on door"))
end)

test("'use match on candle' → 'light candle with match'", function()
    eq("light candle with match", transform_compound_actions("use match on candle"))
end)

test("'use lighter on torch' → 'light torch with lighter'", function()
    eq("light torch with lighter", transform_compound_actions("use lighter on torch"))
end)

test("'use needle on cloth' → 'sew cloth with needle'", function()
    eq("sew cloth with needle", transform_compound_actions("use needle on cloth"))
end)

test("'use thread on fabric' → 'sew fabric with thread'", function()
    eq("sew fabric with thread", transform_compound_actions("use thread on fabric"))
end)

test("'use rock on window' → 'apply rock to window' (#109: default apply)", function()
    eq("apply rock to window", transform_compound_actions("use rock on window"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'put out X' / 'blow out X' → extinguish")
-------------------------------------------------------------------------------

test("'put out candle' → 'extinguish candle'", function()
    eq("extinguish candle", transform_compound_actions("put out candle"))
end)

test("'blow out the torch' → 'extinguish the torch'", function()
    eq("extinguish the torch", transform_compound_actions("blow out the torch"))
end)

test("'put out the fire' → 'extinguish the fire'", function()
    eq("extinguish the fire", transform_compound_actions("put out the fire"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'put on X' / 'dress in X' → wear")
-------------------------------------------------------------------------------

test("'put on gloves' → 'wear gloves'", function()
    eq("wear gloves", transform_compound_actions("put on gloves"))
end)

test("'dress in the robe' → 'wear the robe'", function()
    eq("wear the robe", transform_compound_actions("dress in the robe"))
end)

test("'put on the cloak' → 'wear the cloak'", function()
    eq("wear the cloak", transform_compound_actions("put on the cloak"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'take off X' → remove")
-------------------------------------------------------------------------------

test("'take off gloves' → 'remove gloves'", function()
    eq("remove gloves", transform_compound_actions("take off gloves"))
end)

test("'take off the hat' → 'remove the hat'", function()
    eq("remove the hat", transform_compound_actions("take off the hat"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'take out X' / 'pull out X' → pull")
-------------------------------------------------------------------------------

test("'take out the drawer' → 'pull the drawer'", function()
    eq("pull the drawer", transform_compound_actions("take out the drawer"))
end)

test("'pull out the nail' → 'pull the nail'", function()
    eq("pull the nail", transform_compound_actions("pull out the nail"))
end)

test("'yank out the wire' → 'pull the wire'", function()
    eq("pull the wire", transform_compound_actions("yank out the wire"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'roll up X' → move")
-------------------------------------------------------------------------------

test("'roll up the rug' → 'move the rug'", function()
    eq("move the rug", transform_compound_actions("roll up the rug"))
end)

test("'roll the rug up' → 'move the rug'", function()
    eq("move the rug", transform_compound_actions("roll the rug up"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'pull back X' → move")
-------------------------------------------------------------------------------

test("'pull back curtain' → 'move curtain'", function()
    eq("move curtain", transform_compound_actions("pull back curtain"))
end)

test("'pull back the drapes' → 'move the drapes'", function()
    eq("move the drapes", transform_compound_actions("pull back the drapes"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'report bug'")
-------------------------------------------------------------------------------

test("'report bug' → 'report_bug'", function()
    eq("report_bug", transform_compound_actions("report bug"))
end)

test("'report a bug' → 'report_bug'", function()
    eq("report_bug", transform_compound_actions("report a bug"))
end)

test("'bug report' → 'report_bug'", function()
    eq("report_bug", transform_compound_actions("bug report"))
end)

test("'file a bug' → 'report_bug'", function()
    eq("report_bug", transform_compound_actions("file a bug"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'put X back in Y'")
-------------------------------------------------------------------------------

test("'put key back in drawer' → 'put key in drawer'", function()
    eq("put key in drawer", transform_compound_actions("put key back in drawer"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — 'pop cork'")
-------------------------------------------------------------------------------

test("'pop cork' → 'uncork bottle'", function()
    eq("uncork bottle", transform_compound_actions("pop cork"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 6: transform_compound_actions — passthrough / non-compound")
-------------------------------------------------------------------------------

test("'open door' passes through unchanged", function()
    eq("open door", transform_compound_actions("open door"))
end)

test("'take key' passes through unchanged", function()
    eq("take key", transform_compound_actions("take key"))
end)

test("'look around' passes through unchanged", function()
    eq("look around", transform_compound_actions("look around"))
end)

test("'search nightstand' passes through unchanged", function()
    eq("search nightstand", transform_compound_actions("search nightstand"))
end)

test("single word 'look' passes through unchanged", function()
    eq("look", transform_compound_actions("look"))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
