-- test/parser/pipeline/test-transform-questions.lua
-- Unit tests for Stage 3: transform_questions (question → imperative command)
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

local transform_questions = preprocess.stages.transform_questions

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — 'what's in X' patterns")
-------------------------------------------------------------------------------

test("'what's in the nightstand' → 'examine nightstand'", function()
    eq("examine nightstand", transform_questions("what's in the nightstand"))
end)

test("'whats in the drawer' → 'examine drawer'", function()
    eq("examine drawer", transform_questions("whats in the drawer"))
end)

test("'what's in nightstand' (no article) → 'examine nightstand'", function()
    eq("examine nightstand", transform_questions("what's in nightstand"))
end)

test("'what's inside the wardrobe' → 'examine the wardrobe' (articles preserved)", function()
    eq("examine the wardrobe", transform_questions("what's inside the wardrobe"))
end)

test("'what is inside the crate' → 'examine the crate' (articles preserved)", function()
    eq("examine the crate", transform_questions("what is inside the crate"))
end)

test("'what is in the box' → 'examine the box' (articles preserved)", function()
    eq("examine the box", transform_questions("what is in the box"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — 'is there anything in X'")
-------------------------------------------------------------------------------

test("'is there anything in the drawer' → 'search the drawer' (articles preserved)", function()
    eq("search the drawer", transform_questions("is there anything in the drawer"))
end)

test("'is there anything in the nightstand' → 'search the nightstand'", function()
    eq("search the nightstand", transform_questions("is there anything in the nightstand"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — 'can I verb target'")
-------------------------------------------------------------------------------

test("'can i open the door' → 'open the door'", function()
    eq("open the door", transform_questions("can i open the door"))
end)

test("'can i take the key' → 'take the key'", function()
    eq("take the key", transform_questions("can i take the key"))
end)

test("'can i search the room' → 'search the room'", function()
    eq("search the room", transform_questions("can i search the room"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — 'what is this'")
-------------------------------------------------------------------------------

test("'what is this' → 'examine this'", function()
    eq("examine this", transform_questions("what is this"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — 'what can I find' (BUG-084)")
-------------------------------------------------------------------------------

test("'what can i find' → 'search'", function()
    eq("search", transform_questions("what can i find"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — look/location patterns")
-------------------------------------------------------------------------------

test("'where am i' → 'look'", function()
    eq("look", transform_questions("where am i"))
end)

test("'what do i see' → 'look'", function()
    eq("look", transform_questions("what do i see"))
end)

test("'what can i see' → 'look'", function()
    eq("look", transform_questions("what can i see"))
end)

test("'what is around' → 'look'", function()
    eq("look", transform_questions("what is around"))
end)

test("'what's around me' → 'look'", function()
    eq("look", transform_questions("what's around me"))
end)

test("'what's inside' (bare, no noun) → 'look'", function()
    eq("look", transform_questions("what's inside"))
end)

test("'what is inside' (bare, no noun) → 'look'", function()
    eq("look", transform_questions("what is inside"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — time patterns")
-------------------------------------------------------------------------------

test("'what time' → 'time'", function()
    eq("time", transform_questions("what time"))
end)

test("'what is the time' → 'time'", function()
    eq("time", transform_questions("what is the time"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — inventory patterns")
-------------------------------------------------------------------------------

test("'what am i carrying' → 'inventory'", function()
    eq("inventory", transform_questions("what am i carrying"))
end)

test("'what am i holding' → 'inventory'", function()
    eq("inventory", transform_questions("what am i holding"))
end)

test("'what do i have' → 'inventory'", function()
    eq("inventory", transform_questions("what do i have"))
end)

test("'what am i wearing' → 'inventory'", function()
    eq("inventory", transform_questions("what am i wearing"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — help patterns")
-------------------------------------------------------------------------------

test("'what can i do' → 'help'", function()
    eq("help", transform_questions("what can i do"))
end)

test("'how do i play' → 'help'", function()
    eq("help", transform_questions("how do i play"))
end)

-------------------------------------------------------------------------------
h.suite("Stage 3: transform_questions — passthrough / non-questions")
-------------------------------------------------------------------------------

test("non-question passes through unchanged: 'open door'", function()
    eq("open door", transform_questions("open door"))
end)

test("non-question passes through unchanged: 'search nightstand'", function()
    eq("search nightstand", transform_questions("search nightstand"))
end)

test("non-question passes through: 'look around'", function()
    eq("look around", transform_questions("look around"))
end)

test("question marks already stripped by normalize (no trailing ?)", function()
    -- Stage 3 receives input from Stage 1 which already stripped ?
    eq("examine nightstand", transform_questions("what's in the nightstand"))
end)

-------------------------------------------------------------------------------
-- Summary
-------------------------------------------------------------------------------
local failures = h.summary()
os.exit(failures > 0 and 1 or 0)
